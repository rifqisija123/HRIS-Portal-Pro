import 'package:flutter/material.dart';
import 'dashboard_page.dart';
import 'face_registration_camera_page.dart';

class FaceRegistrationInstructionPage extends StatelessWidget {
  const FaceRegistrationInstructionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDarkMode, child) {
        final theme = AppColors.current;
        return Scaffold(
          backgroundColor: theme.surface,
          appBar: AppBar(
            backgroundColor: theme.surface,
            elevation: 0,
            iconTheme: IconThemeData(color: theme.onSurface),
            title: Text(
              'Instruksi Pendaftaran Wajah',
              style: TextStyle(
                color: theme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: theme.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.face_retouching_natural,
                            size: 80,
                            color: theme.primary,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Sebelum Memulai',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: theme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Untuk memastikan proses pendaftaran wajah berjalan lancar dan akurat, perhatikan instruksi berikut:',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.onSurfaceVariant,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        _buildInstructionItem(
                          icon: Icons.masks,
                          title: 'Lepaskan Masker',
                          description: 'Pastikan seluruh area wajah Anda terlihat jelas tanpa tertutup masker.',
                          theme: theme,
                          isProhibited: true,
                        ),
                        const SizedBox(height: 16),
                        _buildInstructionItem(
                          icon: Icons.face, // Using standard face icon for glasses replacement
                          title: 'Lepaskan Kacamata/Topi',
                          description: 'Lepaskan aksesoris yang menutupi wajah seperti kacamata gelap atau topi.',
                          theme: theme,
                          isProhibited: true,
                        ),
                        const SizedBox(height: 16),
                        _buildInstructionItem(
                          icon: Icons.light_mode,
                          title: 'Pencahayaan Cukup',
                          description: 'Pastikan Anda berada di tempat yang terang, namun hindari cahaya langsung dari belakang (backlight).',
                          theme: theme,
                          isProhibited: false,
                        ),
                        const SizedBox(height: 16),
                        _buildInstructionItem(
                          icon: Icons.center_focus_strong,
                          title: 'Hadap Kamera',
                          description: 'Posisikan wajah Anda tepat di tengah area kotak yang disediakan dan tatap lurus ke kamera.',
                          theme: theme,
                          isProhibited: false,
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FaceRegistrationCameraPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Mengerti & Lanjut Pendaftaran',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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

  Widget _buildInstructionItem({
    required IconData icon,
    required String title,
    required String description,
    required ThemeColors theme,
    required bool isProhibited,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isProhibited ? theme.error.withOpacity(0.1) : theme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isProhibited ? theme.error : theme.primary,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
