import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'dashboard_page.dart';
import 'login_page.dart';
import 'face_registration_instruction_page.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with SingleTickerProviderStateMixin {
  bool _pushNotifications = true;
  bool _biometrics = false;
  
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  @override
  void initState() {
    super.initState();
    _pushNotifications = OneSignal.User.pushSubscription.optedIn ?? false;
    
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    _blinkAnimation = Tween<double>(begin: 0.1, end: 1.0).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  void _showPhotoSourceBottomSheet(ThemeColors theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Ubah Foto Profil',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.photo_library, color: theme.primary),
                ),
                title: Text(
                  'Pilih dari Galeri',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.onSurface,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.secondary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.camera_alt, color: theme.secondary),
                ),
                title: Text(
                  'Ambil Foto Kamera',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.onSurface,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 1080,
        maxHeight: 1080,
      );

      if (picked != null && mounted) {
        _showCropperDialog(File(picked.path));
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih gambar: $e')),
        );
      }
    }
  }

  void _showCropperDialog(File imageFile) {
    final TransformationController transformController = TransformationController();
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = AppColors.current;
            return Dialog(
              backgroundColor: theme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  Text(
                    'Potong Foto Profil',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Crop atau geser untuk menyesuaikan posisi foto',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: 280,
                    height: 280,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: theme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.outlineVariant, width: 1.5),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                          child: InteractiveViewer(
                            transformationController: transformController,
                            boundaryMargin: const EdgeInsets.all(100),
                            minScale: 0.5,
                            maxScale: 5.0,
                            child: Image.file(
                              imageFile,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        // White circle crop guide
                        IgnorePointer(
                          child: Container(
                            width: 230,
                            height: 230,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Batal'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    setDialogState(() {
                                      isSaving = true;
                                    });
                                    await _cropAndSaveImage(imageFile, transformController);
                                    if (dialogContext.mounted) {
                                      Navigator.pop(dialogContext);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primary,
                              foregroundColor: theme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Simpan Foto'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _cropAndSaveImage(File imageFile, TransformationController controller) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final img.Image? decoded = img.decodeImage(bytes);
      if (decoded == null) return;

      final int minSide = decoded.width < decoded.height ? decoded.width : decoded.height;
      final int cropX = (decoded.width - minSide) ~/ 2;
      final int cropY = (decoded.height - minSide) ~/ 2;

      final img.Image cropped = img.copyCrop(
        decoded,
        x: cropX,
        y: cropY,
        width: minSide,
        height: minSide,
      );

      final img.Image resized = img.copyResize(cropped, width: 300, height: 300);
      final Uint8List jpgBytes = Uint8List.fromList(img.encodeJpg(resized, quality: 85));
      final String base64String = base64Encode(jpgBytes);

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseDatabase.instance
            .ref()
            .child('users')
            .child(user.uid)
            .child('profile_photo')
            .set(base64String);
      }

      profilePhotoNotifier.value = base64String;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Foto profil berhasil diperbarui!'),
              ],
            ),
            backgroundColor: AppColors.secondary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error cropping & saving image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan foto profil: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDarkMode, child) {
        final theme = AppColors.current;
        return Column(
          children: [
            _buildAppBar(theme),
            Expanded(
              child: _buildContent(theme),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAppBar(ThemeColors theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.surface,
        boxShadow: [
          BoxShadow(
            color: const Color(0x0C000000), // shadow-sm
            blurRadius: 2,
            offset: const Offset(0, 1),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Pengaturan',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: theme.primary,
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {},
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                child: Icon(
                  Icons.search,
                  color: theme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisabledWrapper({required bool isDisabled, required Widget child}) {
    if (isDisabled) {
      return Opacity(
        opacity: 0.4,
        child: IgnorePointer(
          ignoring: true,
          child: child,
        ),
      );
    }
    return child;
  }

  Widget _buildContent(ThemeColors theme) {
    return StreamBuilder(
      stream: FirebaseAuth.instance.currentUser != null 
          ? FirebaseDatabase.instance.ref().child('users').child(FirebaseAuth.instance.currentUser!.uid).child('has_registered_face').onValue
          : null,
      builder: (context, snapshot) {
        bool hasRegistered = false;
        if (snapshot.hasData && snapshot.data?.snapshot.value != null) {
          hasRegistered = snapshot.data!.snapshot.value == true;
        }

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildDisabledWrapper(
                  isDisabled: !hasRegistered,
                  child: _buildProfileSummary(theme),
                ),
                const SizedBox(height: 24),
                _buildSettingsCategories(theme, hasRegistered),
                const SizedBox(height: 24),
                _buildLogoutButton(theme),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileSummary(ThemeColors theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          ValueListenableBuilder<String?>(
            valueListenable: profilePhotoNotifier,
            builder: (context, photoBase64, child) {
              ImageProvider imageProvider;
              if (photoBase64 != null && photoBase64.isNotEmpty) {
                try {
                  final Uint8List bytes = base64Decode(photoBase64);
                  imageProvider = MemoryImage(bytes);
                } catch (_) {
                  imageProvider = const NetworkImage(
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuCalfK_8lG7uaRXApW1OwdK-HnwRc9FlbgbVdH0gG-_8bngw4GdcRQE9edwen2Gh2VRrkyiBBoP849THdl4c1KQ6MtYYMUITpGRmsGCs10_9mp3RGCGgef9HKpZfb1R1JBm5zj_2wOva5ECaZbErD3BnhgVMXYw_YQcFKe7CeHQ8tpoLfgA1_BI4A-rgm0IUajy7LtnSeqV8lV3Q1tNf8L54AH4dkT5HPe22z_y6Iv_O_FxySKmC8L-');
                }
              } else {
                imageProvider = const NetworkImage(
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuCalfK_8lG7uaRXApW1OwdK-HnwRc9FlbgbVdH0gG-_8bngw4GdcRQE9edwen2Gh2VRrkyiBBoP849THdl4c1KQ6MtYYMUITpGRmsGCs10_9mp3RGCGgef9HKpZfb1R1JBm5zj_2wOva5ECaZbErD3BnhgVMXYw_YQcFKe7CeHQ8tpoLfgA1_BI4A-rgm0IUajy7LtnSeqV8lV3Q1tNf8L54AH4dkT5HPe22z_y6Iv_O_FxySKmC8L-');
              }

              return GestureDetector(
                onTap: () => _showPhotoSourceBottomSheet(theme),
                child: Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.primary.withValues(alpha: 0.1), width: 4),
                        image: DecorationImage(
                          image: imageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: theme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Budi Santoso',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: theme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: EMP-882910',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: theme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.secondaryContainer,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: theme.secondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Karyawan Tetap',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCategories(ThemeColors theme, bool hasRegistered) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!hasRegistered)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: InkWell(
              onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FaceRegistrationInstructionPage(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: AnimatedBuilder(
                  animation: _blinkAnimation,
                  builder: (context, child) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                      decoration: BoxDecoration(
                        color: theme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.primary.withOpacity(_blinkAnimation.value), 
                          width: 2.5
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.primary.withOpacity(_blinkAnimation.value * 0.3),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: child,
                    );
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.face_retouching_natural,
                          size: 48,
                          color: theme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Daftarkan Wajah',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: theme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Silakan klik area ini untuk memproses pendaftaran wajah Anda.',
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.onSurfaceVariant,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        _buildDisabledWrapper(
          isDisabled: !hasRegistered,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('NOTIFIKASI', theme),
        _buildSectionCard(
          theme,
          [
            _buildSwitchItem(
              icon: Icons.notifications,
              title: 'Push Notifikasi',
              value: _pushNotifications,
              onChanged: (val) {
                setState(() => _pushNotifications = val);
                if (val) {
                  OneSignal.User.pushSubscription.optIn();
                } else {
                  OneSignal.User.pushSubscription.optOut();
                }
              },
              theme: theme,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('KEAMANAN', theme),
        _buildSectionCard(
          theme,
          [
            _buildSwitchItem(
              icon: Icons.fingerprint,
              title: 'Biometrik (Sidik Jari)',
              value: _biometrics,
              onChanged: (val) => setState(() => _biometrics = val),
              theme: theme,
            ),
            _buildDivider(theme),
            _buildActionItem(
              icon: Icons.devices,
              title: 'Perangkat Terhubung',
              onTap: () {},
              theme: theme,
            ),
            _buildDivider(theme),
            _buildActionItem(
              icon: Icons.security,
              title: 'Izin Aplikasi',
              onTap: () {},
              theme: theme,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('UMUM', theme),
        _buildSectionCard(
          theme,
          [
            _buildActionItem(
              icon: Icons.language,
              title: 'Bahasa',
              subtitle: 'Bahasa Indonesia',
              onTap: () {},
              theme: theme,
            ),
            _buildDivider(theme),
            _buildActionItem(
              icon: Icons.settings,
              title: 'Pengaturan Aplikasi',
              onTap: () {},
              theme: theme,
            ),
            _buildDivider(theme),
            _buildActionItem(
              icon: Icons.folder_open,
              title: 'Penyimpanan & Data',
              onTap: () {},
              theme: theme,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('BANTUAN & TENTANG', theme),
        _buildSectionCard(
          theme,
          [
            _buildActionItem(
              icon: Icons.help_center,
              title: 'Pusat Bantuan',
              onTap: () {},
              theme: theme,
            ),
            _buildDivider(theme),
            _buildActionItem(
              icon: Icons.policy,
              title: 'Kebijakan Privasi',
              onTap: () {},
              theme: theme,
            ),
            _buildDivider(theme),
            _buildActionItem(
              icon: Icons.description,
              title: 'Syarat & Ketentuan',
              onTap: () {},
              theme: theme,
            ),
            _buildDivider(theme),
            _buildActionItem(
              icon: Icons.delete_sweep,
              title: 'Hapus Cache',
              onTap: () {},
              theme: theme,
            ),
            _buildDivider(theme),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Icon(Icons.info, color: theme.onSurfaceVariant),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Versi Aplikasi',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.onSurface,
                      ),
                    ),
                  ),
                  Text(
                    'v2.4.1',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, ThemeColors theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: theme.primary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSectionCard(ThemeColors theme, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.outlineVariant.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required ThemeColors theme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: theme.onSurfaceVariant),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: theme.onSurface,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: theme.primary,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: theme.outlineVariant,
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    required ThemeColors theme,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: theme.onSurfaceVariant),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.onSurface,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: theme.outline,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: theme.outlineVariant),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(ThemeColors theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        color: theme.outlineVariant.withOpacity(0.2),
        height: 1,
        thickness: 1,
      ),
    );
  }

  Widget _buildLogoutButton(ThemeColors theme) {
    final errorColor = isDarkModeNotifier.value ? const Color(0xFFEF4444) : theme.error;
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext dialogContext) {
                  return Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                    backgroundColor: theme.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: errorColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.logout_rounded,
                              color: errorColor,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Keluar Akun?',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: theme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Apakah Anda yakin ingin keluar dari akun ini?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.onSurfaceVariant,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 28),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(dialogContext),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    side: BorderSide(color: theme.outlineVariant),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Batal',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: theme.onSurface,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(dialogContext); // Close dialog first
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(builder: (context) => const LoginPage()),
                                      (route) => false,
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF0FDF4), // light green background
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: const Color(0xFFBBF7D0)), // green border
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.05),
                                                blurRadius: 10,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.check_circle_rounded,
                                                color: Color(0xFF16A34A), // green icon
                                                size: 24,
                                              ),
                                              const SizedBox(width: 12),
                                              const Expanded(
                                                child: Text(
                                                  'Anda telah berhasil keluar dari akun Anda.',
                                                  style: TextStyle(
                                                    color: Color(0xFF166534), // dark green text
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                        backgroundColor: Colors.transparent,
                                        elevation: 0,
                                        margin: EdgeInsets.only(
                                          bottom: MediaQuery.of(context).size.height - 160,
                                          left: 16,
                                          right: 16,
                                        ),
                                        duration: const Duration(seconds: 3),
                                        dismissDirection: DismissDirection.up,
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: errorColor,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Ya, Keluar',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: errorColor.withOpacity(0.1),
              foregroundColor: errorColor,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout),
                SizedBox(width: 8),
                Text(
                  'Keluar Akun',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'HRIS Portal Pro © ${DateTime.now().year}',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: theme.outlineVariant,
          ),
        ),
      ],
    );
  }
}
