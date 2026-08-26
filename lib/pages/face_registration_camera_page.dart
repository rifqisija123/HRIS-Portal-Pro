import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:ui';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../services/face_recognition_service.dart';

class FaceRegistrationCameraPage extends StatefulWidget {
  const FaceRegistrationCameraPage({super.key});

  @override
  State<FaceRegistrationCameraPage> createState() => _FaceRegistrationCameraPageState();
}

class _FaceRegistrationCameraPageState extends State<FaceRegistrationCameraPage> with SingleTickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitializing = true;
  bool _isCapturing = false;

  late AnimationController _scanController;
  late Animation<double> _scanAnimation;
  final FaceRecognitionService _faceRecognitionService = FaceRecognitionService();

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _scanAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );
    _initializeCamera();
    _faceRecognitionService.initialize();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        // Find front camera
        final frontCamera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras!.first,
        );
        _controller = CameraController(
          frontCamera,
          ResolutionPreset.medium,
          enableAudio: false,
        );
        await _controller!.initialize();
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _scanController.dispose();
    _controller?.dispose();
    _faceRecognitionService.dispose();
    super.dispose();
  }

  Future<void> _captureFace() async {
    if (_controller == null || !_controller!.value.isInitialized || _isCapturing) {
      return;
    }
    
    setState(() {
      _isCapturing = true;
    });
    
    try {
      final XFile file = await _controller!.takePicture();
      
      // Deteksi Wajah menggunakan ML Kit
      final inputImage = InputImage.fromFilePath(file.path);
      final faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableContours: false,
          enableLandmarks: false,
        ),
      );
      
      final List<Face> faces = await faceDetector.processImage(inputImage);
      await faceDetector.close();

      if (faces.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Wajah tidak terdeteksi!'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isCapturing = false;
        });
        return; // Hentikan proses jika bukan wajah
      }

      if (faces.length > 1) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Terdapat lebih dari satu wajah! Pastikan hanya wajah Anda.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() {
          _isCapturing = false;
        });
        return;
      }

      // Membaca file gambar untuk mengetahui dimensi dan mengonversi ke Base64 nanti
      final File imageFile = File(file.path);
      final List<int> imageBytes = await imageFile.readAsBytes();
      
      // Validasi posisi dan ukuran wajah agar tidak terpotong (setengah)
      final face = faces.first;
      final rect = face.boundingBox;
      
      final codec = await instantiateImageCodec(Uint8List.fromList(imageBytes));
      final FrameInfo frameInfo = await codec.getNextFrame();
      final double imageWidth = frameInfo.image.width.toDouble();
      final double imageHeight = frameInfo.image.height.toDouble();
      
      // Margin aman (wajah tidak boleh menyentuh pinggiran ini agar dianggap utuh di tengah kotak)
      // Kotak UI relatif kecil di tengah layar, jadi margin kamera harus diperbesar agar akurat dengan area kotak.
      final double marginX = imageWidth * 0.20;
      final double marginY = imageHeight * 0.25;
      
      if (rect.left < marginX || rect.right > imageWidth - marginX || 
          rect.top < marginY || rect.bottom > imageHeight - marginY) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Posisi wajah belum pas! Pastikan seluruh wajah Anda utuh dan berada di dalam kotak.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isCapturing = false;
        });
        return;
      }
      
      if (rect.width < imageWidth * 0.25) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Wajah terlalu jauh! Dekatkan wajah Anda ke kamera.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isCapturing = false;
        });
        return;
      }

      // Ekstrak sidik jari wajah (Embedding) dengan MobileFaceNet TFLite
      final newEmbedding = await _faceRecognitionService.predict(imageFile, rect);

      if (newEmbedding == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal mengekstrak data fitur wajah. Silakan coba lagi.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isCapturing = false;
        });
        return;
      }

      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception("Pengguna belum login!");
      }
      final String uid = currentUser.uid;

      // Cek apakah wajah ini sudah terdaftar pada akun lain di Firebase
      DatabaseEvent? event;
      try {
        event = await FirebaseDatabase.instance.ref().child('users').once().timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint('Firebase query timeout or error: $e');
      }

      if (event != null && event.snapshot.value != null && event.snapshot.value is Map) {
        final Map usersData = event.snapshot.value as Map;
        for (final entry in usersData.entries) {
          final otherUid = entry.key.toString();
          if (otherUid == uid) continue; // abaikan akun sendiri jika re-register

          final userData = entry.value;
          if (userData is Map && userData['face_embedding'] != null) {
            final List rawEmbedding = userData['face_embedding'] as List;
            final List<double> existingEmbedding = rawEmbedding.map((e) => (e as num).toDouble()).toList();
            
            final double distance = _faceRecognitionService.euclideanDistance(newEmbedding, existingEmbedding);
            debugPrint('Distance to user $otherUid: $distance');
            
            // Threshold 1.0 untuk L2-normalized MobileFaceNet embeddings
            if (distance < 1.0) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Gagal! Wajah ini sudah terdaftar pada akun lain!'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 4),
                  ),
                );
              }
              setState(() {
                _isCapturing = false;
              });
              return; // Hentikan pendaftaran!
            }
          }
        }
      }

      // Konversi gambar ke format Base64
      final String base64Image = base64Encode(imageBytes);

      // Simpan Base64 dan Face Embedding ke Firebase Realtime Database
      await FirebaseDatabase.instance.ref().child('users').child(uid).update({
        'face_base64': base64Image,
        'face_embedding': newEmbedding,
        'has_registered_face': true,
        'face_updated_at': ServerValue.timestamp,
      });

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF0FDF4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF16A34A),
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Pendaftaran Berhasil!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Data wajah Anda telah sukses disimpan dan sudah dapat digunakan untuk presensi.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF4B5563),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext); // Tutup dialog
                          Navigator.pop(context); // Kembali ke halaman instruksi
                          Navigator.pop(context); // Kembali ke halaman pengaturan
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Selesai',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }
    } catch (e) {
      debugPrint('Error capturing picture: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan saat menyimpan wajah: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isInitializing
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : (_controller == null || !_controller!.value.isInitialized)
              ? const Center(
                  child: Text(
                    'Kamera tidak tersedia.',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    // Camera Preview
                    SizedBox.expand(
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: 100,
                          height: 100 * _controller!.value.aspectRatio,
                          child: CameraPreview(_controller!),
                        ),
                      ),
                    ),
                    
                    // Blur Overlay with Hole
                    ClipPath(
                      clipper: _HoleClipper(
                        width: MediaQuery.of(context).size.width * 0.7,
                        height: MediaQuery.of(context).size.width * 0.9,
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                    
                    // Scanner Box Overlay
                    Center(
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.7,
                        height: MediaQuery.of(context).size.width * 0.9,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blue, width: 3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: AnimatedBuilder(
                            animation: _scanAnimation,
                            builder: (context, child) {
                              return Align(
                                alignment: Alignment(0, _scanAnimation.value),
                                child: Container(
                                  height: 3,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blue.withValues(alpha: 0.8),
                                        blurRadius: 12,
                                        spreadRadius: 2,
                                      )
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    
                    // Instructions
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 40,
                      left: 24,
                      right: 24,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Posisikan wajah Anda tepat di dalam area kotak dan pastikan pencahayaan cukup.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    
                    // Capture Button & Back Button
                    Positioned(
                      bottom: 40,
                      left: 0,
                      right: 0,
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _captureFace,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 4),
                                color: _isCapturing ? Colors.grey : Colors.transparent,
                              ),
                              child: Center(
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _isCapturing ? Colors.grey : Colors.white,
                                  ),
                                  child: _isCapturing
                                      ? const CircularProgressIndicator(
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextButton.icon(
                            onPressed: () {
                              if (!_isCapturing) {
                                Navigator.pop(context);
                              }
                            },
                            icon: const Icon(Icons.close, color: Colors.white),
                            label: const Text(
                              'Batal',
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _HoleClipper extends CustomClipper<Path> {
  final double width;
  final double height;

  _HoleClipper({required this.width, required this.height});

  @override
  Path getClip(Size size) {
    final Path path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
      
    final Rect holeRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: width,
      height: height,
    );
    
    final Path holePath = Path()
      ..addRRect(RRect.fromRectAndRadius(holeRect, const Radius.circular(16)));
      
    return Path.combine(PathOperation.difference, path, holePath);
  }

  @override
  bool shouldReclip(covariant _HoleClipper oldClipper) => 
      width != oldClipper.width || height != oldClipper.height;
}
