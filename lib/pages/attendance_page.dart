import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dashboard_page.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> with SingleTickerProviderStateMixin {
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;
  DateTime _currentTime = DateTime.now();
  late Timer _timer;
  bool _isProcessing = false;
  CameraController? _cameraController;
  String? _errorMessage;

  bool _isLoadingLocation = true;
  LatLng? _currentPosition;
  double _currentAccuracy = 0.0;
  bool _showMapPopup = false;
  String _placeName = "Memuat lokasi...";
  String _addressDetail = "";
  final MapController _mapController = MapController();

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

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });

    _initializeCamera();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _placeName = "Memuat lokasi...";
      _addressDetail = "";
    });

    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Layanan lokasi tidak aktif.');
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Izin lokasi ditolak.');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Izin lokasi ditolak secara permanen.');
      } 

      Position position = await Geolocator.getCurrentPosition();
      
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _currentAccuracy = position.accuracy;
        });
      }

      if (kIsWeb) {
        if (mounted) {
          setState(() {
            _placeName = "Lokasi Anda (Web)";
            _addressDetail = "Koordinat: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";
          });
        }
      } else {
        List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          if (mounted) {
            setState(() {
              _placeName = place.name ?? place.street ?? "Lokasi Anda";
              _addressDetail = "${place.street != null && place.street != place.name ? '${place.street}, ' : ''}${place.subLocality != null ? '${place.subLocality}, ' : ''}${place.locality != null ? '${place.locality}, ' : ''}${place.administrativeArea != null ? '${place.administrativeArea} ' : ''}${place.postalCode ?? ''}";
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _placeName = "Gagal memuat lokasi";
          _addressDetail = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _errorMessage = "Tidak ada kamera ditemukan di perangkat ini.";
          });
        }
        return;
      }

      CameraDescription? frontCamera;
      try {
        frontCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
        );
      } catch (_) {
        frontCamera = cameras.first;
      }

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      if (mounted) {
        setState(() {
          _errorMessage = "Gagal mengakses kamera. Pastikan kamera tidak sedang digunakan oleh aplikasi lain dan Anda telah memberikan izin akses.";
        });
      }
    }
  }

  @override
  void dispose() {
    _scanController.dispose();
    _timer.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  void _handleCapture() {
    setState(() {
      _isProcessing = true;
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        _showSuccessDialog();
      }
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierColor: AppColors.onSurface.withOpacity(0.4),
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: AppColors.surface,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: AppColors.onSecondaryContainer,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Absen Berhasil!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Wajah Anda berhasil diverifikasi. Selamat bekerja!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Lanjutkan',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

  String _formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildInstructionCard(),
                      const SizedBox(height: 24),
                      _buildCameraPreview(),
                      const SizedBox(height: 24),
                      _buildLocationInfo(),
                      const SizedBox(height: 32),
                      _buildActionSection(),
                      const SizedBox(height: 32), // Adjusted padding since no nav bar
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: AppColors.primary),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              const SizedBox(width: 8),
              Text(
                'Presensi Wajah',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.help_outline, color: AppColors.onSurfaceVariant),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info, color: AppColors.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Arahkan wajah Anda ke Kamera',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_errorMessage != null) {
      return Container(
        height: 400,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.surfaceContainerHigh,
        ),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.videocam_off, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _errorMessage = null;
                  });
                  _initializeCamera();
                },
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Container(
        height: 400,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.surfaceContainerHigh,
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 1 / _cameraController!.value.aspectRatio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CameraPreview(_cameraController!),
            AnimatedBuilder(
              animation: _scanAnimation,
              builder: (context, child) {
                return Align(
                  alignment: Alignment(0, _scanAnimation.value),
                  child: Container(
                    height: 3,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.8),
                          blurRadius: 12,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInfo() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: Color(0xFF69F0AE),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Color(0xFF004D40),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lokasi Saat Ini',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _placeName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.onSurface,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (_addressDetail.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                _addressDetail,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.sync, color: AppColors.onSurfaceVariant),
                  onPressed: _isLoadingLocation ? null : _fetchLocation,
                ),
              ],
            ),
          ),
          
          // Map View
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 220,
                color: AppColors.surfaceContainerHigh,
                child: _isLoadingLocation
                    ? Center(
                        child: Text(
                          'Memuat lokasi...',
                          style: TextStyle(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 16,
                          ),
                        ),
                      )
                    : _currentPosition == null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                _addressDetail.isNotEmpty ? _addressDetail : 'Gagal mendapatkan lokasi',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.error),
                              ),
                            ),
                          )
                        : Stack(
                            children: [
                              FlutterMap(
                                mapController: _mapController,
                                options: MapOptions(
                                  initialCenter: _currentPosition!,
                                  initialZoom: 16.0,
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName: 'com.example.flutter_test_application',
                                  ),
                                  CircleLayer(
                                    circles: [
                                      CircleMarker(
                                        point: _currentPosition!,
                                        color: Colors.blue.withOpacity(0.2),
                                        borderColor: Colors.blue,
                                        borderStrokeWidth: 2,
                                        useRadiusInMeter: true,
                                        radius: _currentAccuracy > 0 ? _currentAccuracy : 50.0,
                                      ),
                                    ],
                                  ),
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: _currentPosition!,
                                        width: 40,
                                        height: 40,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _showMapPopup = !_showMapPopup;
                                            });
                                          },
                                          child: Icon(
                                            Icons.location_on,
                                            color: AppColors.error,
                                            size: 40,
                                          ),
                                        ),
                                      ),
                                      if (_showMapPopup)
                                        Marker(
                                          point: _currentPosition!,
                                          width: 180,
                                          height: 80,
                                          alignment: Alignment.bottomCenter,
                                          child: Container(
                                            margin: const EdgeInsets.only(bottom: 30),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(8),
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: Colors.black26,
                                                  blurRadius: 6,
                                                  offset: Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: const Center(
                                              child: Text(
                                                "Titik lokasi anda saat ini",
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                              // Zoom Controls
                              Positioned(
                                right: 12,
                                bottom: 12,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1);
                                        },
                                        child: const Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Icon(Icons.add, size: 20),
                                        ),
                                      ),
                                      Container(height: 1, width: 36, color: Colors.grey[200]),
                                      InkWell(
                                        onTap: () {
                                          _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1);
                                        },
                                        child: const Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Icon(Icons.remove, size: 20),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            ],
                          ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildActionSection() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _isProcessing ? null : _handleCapture,
            icon: _isProcessing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary),
                  )
                : const Icon(Icons.face_retouching_natural),
            label: Text(
              _isProcessing ? 'Memproses...' : 'Attendance',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Waktu: ${_formatTime(_currentTime)} WIB',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }


}

