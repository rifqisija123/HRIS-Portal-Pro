import 'package:flutter/material.dart';
import 'dashboard_page.dart';
import 'attendance_page.dart';
import 'login_page.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final int _currentIndex = 3;
  bool _pushNotifications = true;
  bool _biometrics = false;

  @override
  void initState() {
    super.initState();
    _pushNotifications = OneSignal.User.pushSubscription.optedIn ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppColors.current;
    return Column(
      children: [
        _buildAppBar(theme),
        Expanded(
          child: _buildContent(theme),
        ),
      ],
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

  Widget _buildContent(ThemeColors theme) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProfileSummary(theme),
            const SizedBox(height: 24),
            _buildSettingsCategories(theme),
            const SizedBox(height: 24),
            _buildLogoutButton(theme),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSummary(ThemeColors theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.outlineVariant.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.primary.withOpacity(0.1), width: 4),
                  image: const DecorationImage(
                    image: NetworkImage(
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuCalfK_8lG7uaRXApW1OwdK-HnwRc9FlbgbVdH0gG-_8bngw4GdcRQE9edwen2Gh2VRrkyiBBoP849THdl4c1KQ6MtYYMUITpGRmsGCs10_9mp3RGCGgef9HKpZfb1R1JBm5zj_2wOva5ECaZbErD3BnhgVMXYw_YQcFKe7CeHQ8tpoLfgA1_BI4A-rgm0IUajy7LtnSeqV8lV3Q1tNf8L54AH4dkT5HPe22z_y6Iv_O_FxySKmC8L-'),
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
                    Icons.edit,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
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

  Widget _buildSettingsCategories(ThemeColors theme) {
    return Column(
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
              title: 'Biometrik (Wajah/Sidik Jari)',
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
                              color: theme.error.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.logout_rounded,
                              color: theme.error,
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
                                    backgroundColor: theme.error,
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
              backgroundColor: theme.error.withOpacity(0.1),
              foregroundColor: theme.error,
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
