import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'attendance_page.dart';
import 'attendance_history_page.dart';
import 'notification_page.dart';
import '../data/holiday_data.dart';
import 'settings_page.dart';

final ValueNotifier<bool> isDarkModeNotifier = ValueNotifier<bool>(false);
final ValueNotifier<String?> profilePhotoNotifier = ValueNotifier<String?>(null);

class AppColors {
  static ThemeColors get current => isDarkModeNotifier.value ? ThemeColors.dark : ThemeColors.light;

  static Color get primary => current.primary;
  static Color get onPrimary => current.onPrimary;
  static Color get primaryContainer => current.primaryContainer;
  static Color get onPrimaryContainer => current.onPrimaryContainer;
  static Color get secondary => current.secondary;
  static Color get onSecondary => current.onSecondary;
  static Color get secondaryContainer => current.secondaryContainer;
  static Color get onSecondaryContainer => current.onSecondaryContainer;
  static Color get tertiary => current.tertiary;
  static Color get tertiaryFixedDim => current.tertiaryFixedDim;
  static Color get tertiaryContainer => current.tertiaryContainer;
  static Color get surface => current.surface;
  static Color get onSurface => current.onSurface;
  static Color get surfaceVariant => current.surfaceVariant;
  static Color get onSurfaceVariant => current.onSurfaceVariant;
  static Color get surfaceContainerLowest => current.surfaceContainerLowest;
  static Color get surfaceContainerLow => current.surfaceContainerLow;
  static Color get surfaceContainer => current.surfaceContainer;
  static Color get surfaceContainerHigh => current.surfaceContainerHigh;
  static Color get outlineVariant => current.outlineVariant;
  static Color get outline => current.outline;
  static Color get error => current.error;
  static Color get outerBackground => current.outerBackground;
}

class ThemeColors {
  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color secondary;
  final Color onSecondary;
  final Color secondaryContainer;
  final Color onSecondaryContainer;
  final Color tertiary;
  final Color tertiaryFixedDim;
  final Color tertiaryContainer;
  final Color surface;
  final Color onSurface;
  final Color surfaceVariant;
  final Color onSurfaceVariant;
  final Color surfaceContainerLowest;
  final Color surfaceContainerLow;
  final Color surfaceContainer;
  final Color surfaceContainerHigh;
  final Color outlineVariant;
  final Color outline;
  final Color error;
  final Color outerBackground;

  ThemeColors({
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.secondary,
    required this.onSecondary,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.tertiary,
    required this.tertiaryFixedDim,
    required this.tertiaryContainer,
    required this.surface,
    required this.onSurface,
    required this.surfaceVariant,
    required this.onSurfaceVariant,
    required this.surfaceContainerLowest,
    required this.surfaceContainerLow,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.outlineVariant,
    required this.outline,
    required this.error,
    required this.outerBackground,
  });

  static final light = ThemeColors(
    primary: const Color(0xFF0058BE),
    onPrimary: const Color(0xFFFFFFFF),
    primaryContainer: const Color(0xFF2170E4),
    onPrimaryContainer: const Color(0xFFFEFCFF),
    secondary: const Color(0xFF006C49),
    onSecondary: const Color(0xFFFFFFFF),
    secondaryContainer: const Color(0xFF6CF8BB),
    onSecondaryContainer: const Color(0xFF00714D),
    tertiary: const Color(0xFF825100),
    tertiaryFixedDim: const Color(0xFFFFB95F),
    tertiaryContainer: const Color(0xFFFFDDB8),
    surface: const Color(0xFFF8F9FF),
    onSurface: const Color(0xFF0B1C30),
    surfaceVariant: const Color(0xFFD3E4FE),
    onSurfaceVariant: const Color(0xFF424754),
    surfaceContainerLowest: const Color(0xFFFFFFFF),
    surfaceContainerLow: const Color(0xFFEFF4FF),
    surfaceContainer: const Color(0xFFE5EEFF),
    surfaceContainerHigh: const Color(0xFFDCE9FF),
    outlineVariant: const Color(0xFFC2C6D6),
    outline: const Color(0xFF727785),
    error: const Color(0xFFBA1A1A),
    outerBackground: const Color(0xFFF0F4FF),
  );

  static final dark = ThemeColors(
    primary: const Color(0xFF9EC9FF),
    onPrimary: const Color(0xFF003063),
    primaryContainer: const Color(0xFF0048A0),
    onPrimaryContainer: const Color(0xFFD8E2FF),
    secondary: const Color(0xFF50E3A0),
    onSecondary: const Color(0xFF003824),
    secondaryContainer: const Color(0xFF005236),
    onSecondaryContainer: const Color(0xFF6CF8BB),
    tertiary: const Color(0xFFFFB95F),
    tertiaryFixedDim: const Color(0xFFFFDDB8),
    tertiaryContainer: const Color(0xFF6A3D00),
    surface: const Color(0xFF0B1C30),
    onSurface: const Color(0xFFE5EEFF),
    surfaceVariant: const Color(0xFF1E3050),
    onSurfaceVariant: const Color(0xFFB8C4D8),
    surfaceContainerLowest: const Color(0xFF0A1520),
    surfaceContainerLow: const Color(0xFF12223A),
    surfaceContainer: const Color(0xFF1A2D4A),
    surfaceContainerHigh: const Color(0xFF22385A),
    outlineVariant: const Color(0xFF3A4560),
    outline: const Color(0xFF8890A0),
    error: const Color(0xFFFFB4AB),
    outerBackground: const Color(0xFF060E1A),
  );
}

class DashboardPage extends StatefulWidget {
  final int initialIndex;
  const DashboardPage({super.key, this.initialIndex = 0});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late int _currentIndex;
  late DateTime _displayedMonth;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    final now = DateTime.now();
    _displayedMonth = DateTime(now.year, now.month, 1);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseDatabase.instance.ref().child('users').child(user.uid).child('profile_photo').onValue.listen((event) {
        if (event.snapshot.value != null && event.snapshot.value is String) {
          profilePhotoNotifier.value = event.snapshot.value as String;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = _isDarkMode ? ThemeColors.dark : ThemeColors.light;
    return Scaffold(
      backgroundColor: theme.outerBackground,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ClipRect(
            child: Scaffold(
              backgroundColor: theme.surface,
              body: SafeArea(
                child: Column(
                  children: [
                    if (_currentIndex != 1 && _currentIndex != 3) _buildAppBar(theme),
                    Expanded(
                      child: IndexedStack(
                        index: _currentIndex,
                        children: [
                          _buildHomeContent(theme),
                          const SizedBox.shrink(),
                          const Center(child: Text('Leave - Under Construction')),
                          const SettingsPage(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              bottomNavigationBar: _buildBottomNavigationBar(theme),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeContent(ThemeColors theme) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(
            left: 16, right: 16, top: 24, bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(theme),
            const SizedBox(height: 32),
            _buildMobileGrid(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(ThemeColors theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.surface,
        boxShadow: [
          BoxShadow(
            color: Color(0x0C000000), // shadow-sm
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

                  return Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.primaryContainer, width: 2),
                      image: DecorationImage(
                        image: imageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              Text(
                'HRIS Portal Pro',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: theme.primary,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    setState(() {
                      _isDarkMode = !_isDarkMode;
                      isDarkModeNotifier.value = _isDarkMode;
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    child: Icon(
                      _isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                      color: theme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const NotificationPage()),
                    );
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.notifications_outlined,
                      color: theme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(ThemeColors theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Halo, Admin!',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: theme.primary,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Selamat datang kembali di HRIS Portal Anda.',
          style: TextStyle(
            fontSize: 16,
            color: theme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileGrid(ThemeColors theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildAttendanceCard(theme),
        const SizedBox(height: 24),
        Text(
          'Ringkasan Aktivitas',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: theme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        _buildSmallSummaryCard(
          theme: theme,
          title: 'Sisa Cuti',
          value: '12 Hari',
          icon: Icons.event_available,
          iconColor: theme.primary,
          iconBgColor: theme.surfaceContainerHigh,
        ),
        const SizedBox(height: 16),
        _buildSmallSummaryCard(
          theme: theme,
          title: 'Pengajuan Menunggu',
          value: '8 Berkas',
          icon: Icons.pending_actions,
          iconColor: theme.tertiary,
          iconBgColor: theme.tertiaryFixedDim.withOpacity(0.3),
        ),
        const SizedBox(height: 16),
        _buildSmallSummaryCard(
          theme: theme,
          title: 'Izin / Sakit',
          value: '2 Hari',
          icon: Icons.medical_services_outlined,
          iconColor: theme.error,
          iconBgColor: theme.error.withOpacity(0.1),
        ),
        const SizedBox(height: 16),
        _buildTipsCard(theme),
        const SizedBox(height: 32),
        _buildCalendarCard(theme),
        const SizedBox(height: 24),
        _buildAnnouncementsSection(theme),
      ],
    );
  }

  String _getFormattedTodayDate() {
    final now = DateTime.now();
    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final dayName = days[now.weekday - 1];
    final monthName = months[now.month - 1];
    return '$dayName, ${now.day} $monthName ${now.year}';
  }

  String _getTodayKey() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  Widget _buildAttendanceCard(ThemeColors theme) {
    final user = FirebaseAuth.instance.currentUser;
    final dateKey = _getTodayKey();
    final formattedDate = _getFormattedTodayDate();

    final Stream? stream = user != null
        ? FirebaseDatabase.instance.ref().child('attendances').child(user.uid).child(dateKey).onValue
        : null;

    return StreamBuilder(
      stream: stream,
      builder: (context, AsyncSnapshot snapshot) {
        String checkInTime = '--:--:-- WIB';
        String checkOutTime = '--:--:-- WIB';
        String locationName = '-';
        String totalWorkTime = '-';
        bool hasCheckIn = false;
        bool hasCheckOut = false;

        if (snapshot.hasData && snapshot.data?.snapshot.value != null && snapshot.data!.snapshot.value is Map) {
          final data = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
          if (data['check_in_time'] != null) {
            checkInTime = data['check_in_time'].toString();
            hasCheckIn = true;
          }
          if (data['check_out_time'] != null) {
            checkOutTime = data['check_out_time'].toString();
            hasCheckOut = true;
          }
          if (data['location_name'] != null && data['location_name'].toString().isNotEmpty) {
            locationName = data['location_name'].toString();
          }
          if (data['total_work_time'] != null && data['total_work_time'].toString().isNotEmpty) {
            totalWorkTime = data['total_work_time'].toString();
          }
        }

        final statusText = hasCheckOut
            ? 'Presensi Pulang Berhasil'
            : (hasCheckIn ? 'Presensi Masuk Berhasil' : 'Belum Presensi');

        final statusBadge = hasCheckOut
            ? 'SELESAI'
            : (hasCheckIn ? 'HADIR' : 'BELUM ABSEN');

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: -10,
                top: -10,
                child: Icon(
                  Icons.check_circle,
                  size: 80,
                  color: (hasCheckIn ? theme.secondary : theme.outline).withOpacity(0.1),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Presensi Hari Ini',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: theme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formattedDate,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: hasCheckIn ? theme.secondary : theme.outline,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                statusText,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: hasCheckIn ? theme.secondary : theme.outline,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: (hasCheckIn ? theme.secondaryContainer : theme.surfaceContainerHigh).withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: hasCheckIn ? theme.secondaryContainer : theme.outlineVariant),
                        ),
                        child: Text(
                          statusBadge,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: hasCheckIn ? theme.onSecondaryContainer : theme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: theme.secondaryContainer.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.login, color: theme.secondary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'JAM MULAI KERJA',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: theme.onSurfaceVariant,
                                      letterSpacing: 0.5,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      checkInTime,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: hasCheckIn ? theme.primary : theme.outline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: theme.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.logout, color: theme.error, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'JAM SELESAI KERJA',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: theme.onSurfaceVariant,
                                      letterSpacing: 0.5,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      checkOutTime,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: hasCheckOut ? theme.primary : theme.outline,
                                      ),
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
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LOKASI PRESENSI',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: theme.onSurfaceVariant,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: theme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.location_on, color: theme.primary, size: 20),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    locationName,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: theme.onSurfaceVariant,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TOTAL WAKTU KERJA',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: theme.onSurfaceVariant,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: theme.tertiary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.timer, color: theme.tertiary, size: 20),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    totalWorkTime,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: theme.onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Divider(color: theme.outlineVariant, height: 1, thickness: 0.5),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AttendanceHistoryPage()),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Lihat Riwayat Presensi',
                            style: TextStyle(
                              color: theme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.chevron_right, color: theme.primary, size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Widget _buildHadirHariIniCard() {
  //   return Container(
  //     padding: const EdgeInsets.all(24),
  //     decoration: BoxDecoration(
  //       color: theme.secondaryContainer.withOpacity(0.3),
  //       borderRadius: BorderRadius.circular(12),
  //       border: Border.all(color: theme.secondaryContainer),
  //     ),
  //     child: Column(
  //       mainAxisAlignment: MainAxisAlignment.center,
  //       crossAxisAlignment: CrossAxisAlignment.center,
  //       children: [
  //         Container(
  //           width: 48,
  //           height: 48,
  //           decoration: BoxDecoration(
  //             color: theme.secondary,
  //             shape: BoxShape.circle,
  //           ),
  //           child: Icon(
  //             Icons.groups,
  //             color: theme.onSecondary,
  //           ),
  //         ),
  //         const SizedBox(height: 12),
  //         Text(
  //           'HADIR HARI INI',
  //           style: TextStyle(
  //             fontSize: 12,
  //             fontWeight: FontWeight.w600,
  //             color: theme.onSecondaryContainer,
  //             letterSpacing: 1.0,
  //           ),
  //         ),
  //         const SizedBox(height: 4),
  //         Text(
  //           '142/150',
  //           style: TextStyle(
  //             fontSize: 30,
  //             fontWeight: FontWeight.w700,
  //             color: theme.onSecondaryContainer,
  //           ),
  //         ),
  //         const SizedBox(height: 16),
  //         ClipRRect(
  //           borderRadius: BorderRadius.circular(4),
  //           child: LinearProgressIndicator(
  //             value: 142 / 150,
  //             minHeight: 6,
  //             backgroundColor: theme.secondaryContainer,
  //             valueColor: const AlwaysStoppedAnimation<Color>(theme.secondary),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildSmallSummaryCard({
    required ThemeColors theme,
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
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
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: theme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTipsCard(ThemeColors theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -40,
            bottom: -40,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                color: theme.onPrimaryContainer.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tips HR',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: theme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pastikan seluruh data lembur karyawan sudah divalidasi sebelum tanggal 20 setiap bulannya.',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.onPrimaryContainer.withOpacity(0.9),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              InkWell(
                onTap: () {},
                child: Text(
                  'Baca Selengkapnya',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.onPrimaryContainer,
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsSection(ThemeColors theme) {
    final double cardWidth = MediaQuery.sizeOf(context).width - 32;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'Pengumuman Terbaru',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: theme.onSurface,
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'Lihat Semua',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.primary,
                ),
              ),
            )
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildAnnouncementItem(
                  theme: theme,
                  title: 'Kebijakan Work From Home (WFH) 2026',
                  desc: 'Mulai bulan depan, seluruh karyawan berhak atas opsi WFH maksimal 2 hari per minggu dengan persetujuan atasan.',
                  time: '2 Jam Lalu',
                  icon: Icons.campaign,
                  iconColor: theme.primary,
                  iconBgColor: theme.primary.withOpacity(0.1),
                  width: cardWidth,
                ),
                const SizedBox(width: 16),
                _buildAnnouncementItem(
                  theme: theme,
                  title: 'Pendaftaran Asuransi Kesehatan',
                  desc: 'Mohon lengkapi data tanggungan keluarga untuk perpanjangan asuransi kesehatan tahunan sebelum 30 Juli 2026.',
                  time: 'Kemarin',
                  icon: Icons.health_and_safety,
                  iconColor: theme.secondary,
                  iconBgColor: theme.secondaryContainer.withOpacity(0.3),
                  width: cardWidth,
                ),
                const SizedBox(width: 16),
                _buildAnnouncementItem(
                  theme: theme,
                  title: 'Survei Lingkungan Kerja',
                  desc: 'Bantu kami menciptakan lingkungan kerja yang lebih baik dengan mengisi survei kepuasan karyawan kuartal ini.',
                  time: '2 Hari Lalu',
                  icon: Icons.assignment,
                  iconColor: theme.tertiary,
                  iconBgColor: theme.tertiaryContainer.withOpacity(0.3),
                  width: cardWidth,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnnouncementItem({
    required ThemeColors theme,
    required String title,
    required String desc,
    required String time,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    double? width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.outlineVariant.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor),
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
                    fontWeight: FontWeight.bold,
                    color: theme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.onSurfaceVariant,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.surfaceContainer,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    time,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Calendar Widget ──────────────────────────────────────────────────

  static const List<String> _monthNames = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  // Indonesian day headers starting from Monday
  static const List<String> _dayHeaders = ['M', 'S', 'S', 'R', 'K', 'J', 'S'];

  void _changeMonth(int delta) {
    setState(() {
      _displayedMonth = DateTime(
          _displayedMonth.year, _displayedMonth.month + delta, 1);
    });
  }

  Widget _buildCalendarCard(ThemeColors theme) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final year = _displayedMonth.year;
    final month = _displayedMonth.month;
    final firstDayOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    
    final holidaysThisMonth = HolidayService.getHolidaysForMonth(year, month);

    // Dart weekday: 1=Mon … 7=Sun → convert to Sunday-start (col 0 = Sunday)
    final leadingBlanks = firstDayOfMonth.weekday % 7; // Sun=0, Mon=1 … Sat=6

    // Previous month days for leading blanks
    final daysInPrevMonth = DateTime(year, month, 0).day;

    // Total cells needed (leading + month days), rounded up to full weeks
    final totalCells = leadingBlanks + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kalender',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: theme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Month header with navigation ──
              Padding(
                padding: const EdgeInsets.only(bottom: 16, left: 4, right: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_monthNames[month - 1]} $year',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.onSurface,
                      ),
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _changeMonth(-1),
                          child: Icon(
                            Icons.chevron_left,
                            color: theme.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _changeMonth(1),
                          child: Icon(
                            Icons.chevron_right,
                            color: theme.primary,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Day-of-week headers ──
              Row(
                children: List.generate(7, (col) {
                  Color headerColor;
                  if (col == 0) {
                    // Minggu (Sunday) → red
                    headerColor = const Color(0xFFD32F2F);
                  } else if (col == 5) {
                    // Jumat (Friday) → green
                    headerColor = const Color(0xFF2E7D32);
                  } else {
                    headerColor = theme.onSurfaceVariant;
                  }
                  return Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          _dayHeaders[col],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: headerColor,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 4),

              // ── Date grid ──
              ...List.generate(rows, (row) {
                return Row(
                  children: List.generate(7, (col) {
                    final index = row * 7 + col;
                    int dayNumber;
                    bool isCurrentMonth;

                    if (index < leadingBlanks) {
                      // Previous month
                      dayNumber = daysInPrevMonth - leadingBlanks + 1 + index;
                      isCurrentMonth = false;
                    } else if (index < leadingBlanks + daysInMonth) {
                      // Current month
                      dayNumber = index - leadingBlanks + 1;
                      isCurrentMonth = true;
                    } else {
                      // Next month
                      dayNumber = index - leadingBlanks - daysInMonth + 1;
                      isCurrentMonth = false;
                    }

                    final cellDate = isCurrentMonth
                        ? DateTime(year, month, dayNumber)
                        : (index < leadingBlanks
                            ? DateTime(year, month - 1, dayNumber)
                            : DateTime(year, month + 1, dayNumber));
                    final isToday = cellDate == today;
                    final isPast = cellDate.isBefore(today);
                    
                    Holiday? holidayToday;
                    if (isCurrentMonth) {
                      try {
                        holidayToday = holidaysThisMonth.firstWhere((h) => h.date.day == dayNumber);
                      } catch (e) {
                        holidayToday = null;
                      }
                    }

                    // Determine text color
                    Color textColor;
                    if (isToday) {
                      textColor = theme.onPrimary;
                    } else if (!isCurrentMonth) {
                      textColor = theme.outline.withOpacity(0.6);
                    } else if (col == 0) {
                      // Sunday (Minggu) → red
                      textColor = const Color(0xFFD32F2F);
                    } else if (col == 5) {
                      // Friday (Jumat) → green
                      textColor = const Color(0xFF2E7D32);
                    } else {
                      textColor = theme.onSurface;
                    }

                    // Fade out past dates in the current month
                    if (isPast && !isToday && isCurrentMonth) {
                      textColor = textColor.withOpacity(0.5);
                    }

                    return Expanded(
                      child: Center(
                        child: GestureDetector(
                          onTap: () => _showEventDialog(context, cellDate, theme),
                          child: Container(
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            decoration: isToday
                                ? BoxDecoration(
                                    color: theme.primary,
                                    shape: BoxShape.circle,
                                  )
                                : (isPast && isCurrentMonth)
                                    ? BoxDecoration(
                                        color: theme.primary.withOpacity(0.08), // Faded blue background for past days
                                        shape: BoxShape.circle,
                                      )
                                    : null,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$dayNumber',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isToday 
                                        ? FontWeight.bold 
                                        : (isCurrentMonth ? FontWeight.w600 : FontWeight.normal),
                                    color: textColor,
                                  ),
                                ),
                                if (holidayToday != null)
                                  Container(
                                    margin: const EdgeInsets.only(top: 2),
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: holidayToday.isCutiBersama ? Colors.orange : Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                );
              }),
              
              if (holidaysThisMonth.isNotEmpty) ...[
                const SizedBox(height: 16),
                Divider(color: theme.outlineVariant, thickness: 0.5),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 140),
                  child: SingleChildScrollView(
                    child: Column(
                      children: holidaysThisMonth.map((h) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: h.isCutiBersama ? Colors.orange.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${h.date.day}',
                                style: TextStyle(
                                  color: h.isCutiBersama ? Colors.orange[800] : Colors.red[800],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                h.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: theme.onSurface,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _showEventDialog(BuildContext context, DateTime date, ThemeColors theme) {
    final holidays = HolidayService.getHolidaysForMonth(date.year, date.month)
        .where((h) => h.date.day == date.day)
        .toList();

    final List<String> days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    final List<String> months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    
    final dayName = days[date.weekday - 1];
    final monthName = months[date.month - 1];
    final dateString = '$dayName, ${date.day} $monthName ${date.year}';

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: theme.surfaceContainerLowest,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Acara',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateString,
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Icon(Icons.close, color: theme.outline, size: 24),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: theme.surfaceContainer, height: 1),
                const SizedBox(height: 16),
                if (holidays.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(
                      child: Text(
                        'Tidak ada acara',
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                else
                  ...holidays.map((h) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.surfaceContainerHigh),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: h.isCutiBersama ? Colors.orange : Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              h.isCutiBersama ? 'Cuti Bersama' : 'Hari Libur',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: theme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          h.name,
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomNavigationBar(ThemeColors theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border(top: BorderSide(color: theme.outlineVariant, width: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          )
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, 'Home', Icons.home, theme),
              _buildNavItem(1, 'Attendance', Icons.face, theme),
              _buildNavItem(2, 'Leave', Icons.event_busy, theme),
              _buildNavItem(3, 'Settings', Icons.settings, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon, ThemeColors theme) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AttendancePage()),
          );
        } else {
          setState(() {
            _currentIndex = index;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.secondaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? theme.onSecondaryContainer
                  : theme.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: -0.2,
                color: isSelected
                    ? theme.onSecondaryContainer
                    : theme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Holiday Models & Service ──────────────────────────────────────────

class Holiday {
  final DateTime date;
  final String name;
  final bool isCutiBersama;

  Holiday({
    required this.date,
    required this.name,
    this.isCutiBersama = false,
  });
}

class HolidayService {
  static List<Holiday> getHolidaysForMonth(int year, int month) {
    List<Holiday> list = [];
    
    // --- EXACT DATA FOR 2011-2023 (From generated JSON static data) ---
    if (year >= 2011 && year <= 2023) {
      if (HolidayData.yearlyHolidays.containsKey(year)) {
        final yearly = HolidayData.yearlyHolidays[year]!;
        for (var h in yearly) {
          if (h.date.month == month) {
            list.add(h);
          }
        }
      }
      list.sort((a, b) => a.date.compareTo(b.date));
      return list;
    }
    
    // --- EXACT DATA FOR 2024-2026 (From SKB 3 Menteri) ---
    if (year == 2024) {
      if (month == 1) list.addAll([Holiday(date: DateTime(2024, 1, 1), name: 'Tahun Baru Masehi')]);
      if (month == 2) list.addAll([Holiday(date: DateTime(2024, 2, 8), name: 'Isra Mikraj'), Holiday(date: DateTime(2024, 2, 9), name: 'Cuti Bersama Tahun Baru Imlek', isCutiBersama: true), Holiday(date: DateTime(2024, 2, 10), name: 'Tahun Baru Imlek')]);
      if (month == 3) list.addAll([Holiday(date: DateTime(2024, 3, 11), name: 'Hari Suci Nyepi'), Holiday(date: DateTime(2024, 3, 12), name: 'Cuti Bersama Nyepi', isCutiBersama: true), Holiday(date: DateTime(2024, 3, 29), name: 'Wafat Isa Al Masih'), Holiday(date: DateTime(2024, 3, 31), name: 'Hari Paskah')]);
      if (month == 4) list.addAll([Holiday(date: DateTime(2024, 4, 8), name: 'Cuti Bersama Idul Fitri', isCutiBersama: true), Holiday(date: DateTime(2024, 4, 9), name: 'Cuti Bersama Idul Fitri', isCutiBersama: true), Holiday(date: DateTime(2024, 4, 10), name: 'Hari Raya Idul Fitri 1445 H'), Holiday(date: DateTime(2024, 4, 11), name: 'Hari Raya Idul Fitri 1445 H'), Holiday(date: DateTime(2024, 4, 12), name: 'Cuti Bersama Idul Fitri', isCutiBersama: true), Holiday(date: DateTime(2024, 4, 15), name: 'Cuti Bersama Idul Fitri', isCutiBersama: true)]);
      if (month == 5) list.addAll([Holiday(date: DateTime(2024, 5, 1), name: 'Hari Buruh Internasional'), Holiday(date: DateTime(2024, 5, 9), name: 'Kenaikan Isa Al Masih'), Holiday(date: DateTime(2024, 5, 10), name: 'Cuti Bersama Kenaikan Isa Al Masih', isCutiBersama: true), Holiday(date: DateTime(2024, 5, 23), name: 'Hari Raya Waisak'), Holiday(date: DateTime(2024, 5, 24), name: 'Cuti Bersama Waisak', isCutiBersama: true)]);
      if (month == 6) list.addAll([Holiday(date: DateTime(2024, 6, 1), name: 'Hari Lahir Pancasila'), Holiday(date: DateTime(2024, 6, 17), name: 'Hari Raya Idul Adha 1445 H'), Holiday(date: DateTime(2024, 6, 18), name: 'Cuti Bersama Idul Adha', isCutiBersama: true)]);
      if (month == 7) list.addAll([Holiday(date: DateTime(2024, 7, 7), name: 'Tahun Baru Islam 1446 H')]);
      if (month == 8) list.addAll([Holiday(date: DateTime(2024, 8, 17), name: 'Hari Kemerdekaan RI')]);
      if (month == 9) list.addAll([Holiday(date: DateTime(2024, 9, 16), name: 'Maulid Nabi Muhammad SAW')]);
      if (month == 12) list.addAll([Holiday(date: DateTime(2024, 12, 25), name: 'Hari Raya Natal'), Holiday(date: DateTime(2024, 12, 26), name: 'Cuti Bersama Natal', isCutiBersama: true)]);
    } else if (year == 2025) {
      if (month == 1) list.addAll([Holiday(date: DateTime(2025, 1, 1), name: 'Tahun Baru Masehi'), Holiday(date: DateTime(2025, 1, 27), name: 'Isra Mikraj'), Holiday(date: DateTime(2025, 1, 28), name: 'Cuti Bersama Imlek', isCutiBersama: true), Holiday(date: DateTime(2025, 1, 29), name: 'Tahun Baru Imlek')]);
      if (month == 3) list.addAll([Holiday(date: DateTime(2025, 3, 28), name: 'Cuti Bersama Idul Fitri', isCutiBersama: true), Holiday(date: DateTime(2025, 3, 29), name: 'Hari Suci Nyepi'), Holiday(date: DateTime(2025, 3, 31), name: 'Hari Raya Idul Fitri 1446 H')]);
      if (month == 4) list.addAll([Holiday(date: DateTime(2025, 4, 1), name: 'Hari Raya Idul Fitri 1446 H'), Holiday(date: DateTime(2025, 4, 2), name: 'Cuti Bersama Idul Fitri', isCutiBersama: true), Holiday(date: DateTime(2025, 4, 3), name: 'Cuti Bersama Idul Fitri', isCutiBersama: true), Holiday(date: DateTime(2025, 4, 4), name: 'Cuti Bersama Idul Fitri', isCutiBersama: true), Holiday(date: DateTime(2025, 4, 7), name: 'Cuti Bersama Idul Fitri', isCutiBersama: true), Holiday(date: DateTime(2025, 4, 18), name: 'Wafat Isa Al Masih'), Holiday(date: DateTime(2025, 4, 20), name: 'Hari Paskah')]);
      if (month == 5) list.addAll([Holiday(date: DateTime(2025, 5, 1), name: 'Hari Buruh Internasional'), Holiday(date: DateTime(2025, 5, 12), name: 'Hari Raya Waisak'), Holiday(date: DateTime(2025, 5, 13), name: 'Cuti Bersama Waisak', isCutiBersama: true), Holiday(date: DateTime(2025, 5, 29), name: 'Kenaikan Isa Al Masih'), Holiday(date: DateTime(2025, 5, 30), name: 'Cuti Bersama Kenaikan', isCutiBersama: true)]);
      if (month == 6) list.addAll([Holiday(date: DateTime(2025, 6, 1), name: 'Hari Lahir Pancasila'), Holiday(date: DateTime(2025, 6, 6), name: 'Hari Raya Idul Adha 1446 H'), Holiday(date: DateTime(2025, 6, 9), name: 'Cuti Bersama Idul Adha', isCutiBersama: true), Holiday(date: DateTime(2025, 6, 27), name: 'Tahun Baru Islam 1447 H')]);
      if (month == 8) list.addAll([Holiday(date: DateTime(2025, 8, 17), name: 'Hari Kemerdekaan RI')]);
      if (month == 9) list.addAll([Holiday(date: DateTime(2025, 9, 5), name: 'Maulid Nabi Muhammad SAW')]);
      if (month == 12) list.addAll([Holiday(date: DateTime(2025, 12, 25), name: 'Hari Raya Natal'), Holiday(date: DateTime(2025, 12, 26), name: 'Cuti Bersama Natal', isCutiBersama: true)]);
    } else if (year == 2026) {
      if (month == 1) list.addAll([Holiday(date: DateTime(2026, 1, 1), name: 'Tahun Baru Masehi'), Holiday(date: DateTime(2026, 1, 16), name: 'Isra Mikraj')]);
      if (month == 2) list.addAll([Holiday(date: DateTime(2026, 2, 16), name: 'Cuti Bersama Imlek', isCutiBersama: true), Holiday(date: DateTime(2026, 2, 17), name: 'Tahun Baru Imlek')]);
      if (month == 3) list.addAll([Holiday(date: DateTime(2026, 3, 18), name: 'Cuti Bersama Nyepi', isCutiBersama: true), Holiday(date: DateTime(2026, 3, 19), name: 'Hari Suci Nyepi'), Holiday(date: DateTime(2026, 3, 20), name: 'Cuti Bersama Idul Fitri', isCutiBersama: true), Holiday(date: DateTime(2026, 3, 21), name: 'Hari Raya Idul Fitri'), Holiday(date: DateTime(2026, 3, 22), name: 'Hari Raya Idul Fitri Hari Kedua'), Holiday(date: DateTime(2026, 3, 23), name: 'Cuti Bersama Idul Fitri', isCutiBersama: true), Holiday(date: DateTime(2026, 3, 24), name: 'Cuti Bersama Idul Fitri', isCutiBersama: true)]);
      if (month == 4) list.addAll([Holiday(date: DateTime(2026, 4, 3), name: 'Wafat Isa Al Masih'), Holiday(date: DateTime(2026, 4, 5), name: 'Hari Paskah')]);
      if (month == 5) list.addAll([Holiday(date: DateTime(2026, 5, 1), name: 'Hari Buruh Internasional'), Holiday(date: DateTime(2026, 5, 14), name: 'Kenaikan Isa Al Masih'), Holiday(date: DateTime(2026, 5, 15), name: 'Cuti Bersama Kenaikan', isCutiBersama: true), Holiday(date: DateTime(2026, 5, 27), name: 'Hari Raya Idul Adha'), Holiday(date: DateTime(2026, 5, 28), name: 'Cuti Bersama Idul Adha', isCutiBersama: true), Holiday(date: DateTime(2026, 5, 31), name: 'Hari Raya Waisak')]);
      if (month == 6) list.addAll([Holiday(date: DateTime(2026, 6, 1), name: 'Hari Lahir Pancasila'), Holiday(date: DateTime(2026, 6, 16), name: 'Tahun Baru Islam')]);
      if (month == 8) list.addAll([Holiday(date: DateTime(2026, 8, 17), name: 'Hari Kemerdekaan RI'), Holiday(date: DateTime(2026, 8, 25), name: 'Maulid Nabi Muhammad SAW')]);
      if (month == 12) list.addAll([Holiday(date: DateTime(2026, 12, 24), name: 'Cuti Bersama Natal', isCutiBersama: true), Holiday(date: DateTime(2026, 12, 25), name: 'Hari Raya Natal')]);
    } else {
      // --- ALGORITHMIC FALLBACK FOR ALL OTHER YEARS (Past & Future) ---
      
      // Fixed National Holidays
      if (month == 1) list.add(Holiday(date: DateTime(year, 1, 1), name: 'Tahun Baru Masehi'));
      if (month == 5) list.add(Holiday(date: DateTime(year, 5, 1), name: 'Hari Buruh Internasional'));
      if (month == 6) list.add(Holiday(date: DateTime(year, 6, 1), name: 'Hari Lahir Pancasila'));
      if (month == 8) list.add(Holiday(date: DateTime(year, 8, 17), name: 'Hari Kemerdekaan RI'));
      if (month == 12) {
        list.add(Holiday(date: DateTime(year, 12, 25), name: 'Hari Raya Natal'));
        list.add(Holiday(date: DateTime(year, 12, 26), name: 'Cuti Bersama Natal', isCutiBersama: true));
      }

      // Easter-based Christian Holidays Calculation (Computus algorithm)
      int a = year % 19;
      int b = year ~/ 100;
      int c = year % 100;
      int d = b ~/ 4;
      int e = b % 4;
      int f = (b + 8) ~/ 25;
      int g = (b - f + 1) ~/ 3;
      int h = (19 * a + b - d - g + 15) % 30;
      int i = c ~/ 4;
      int k = c % 4;
      int l = (32 + 2 * e + 2 * i - h - k) % 7;
      int m = (a + 11 * h + 22 * l) ~/ 451;
      int easterMonth = (h + l - 7 * m + 114) ~/ 31;
      int easterDay = ((h + l - 7 * m + 114) % 31) + 1;
      DateTime easter = DateTime(year, easterMonth, easterDay);
      DateTime goodFriday = easter.subtract(const Duration(days: 2));
      DateTime ascensionDay = easter.add(const Duration(days: 39));
      
      if (goodFriday.month == month) list.add(Holiday(date: goodFriday, name: 'Wafat Isa Al Masih'));
      if (easter.month == month) list.add(Holiday(date: easter, name: 'Hari Paskah'));
      if (ascensionDay.month == month) {
        list.add(Holiday(date: ascensionDay, name: 'Kenaikan Isa Al Masih'));
        list.add(Holiday(date: ascensionDay.add(const Duration(days: 1)), name: 'Cuti Bersama Kenaikan', isCutiBersama: true));
      }

      // Hijri/Lunar/Saka Approximations (-11 days drift per Gregorian year from 2026)
      int diff = year - 2026;
      DateTime approxIdulFitri = DateTime(2026, 3, 21).add(Duration(days: diff * -11));
      DateTime approxIdulAdha = DateTime(2026, 5, 27).add(Duration(days: diff * -11));
      DateTime approxIsraMikraj = DateTime(2026, 1, 16).add(Duration(days: diff * -11));
      DateTime approxTahunBaruIslam = DateTime(2026, 6, 16).add(Duration(days: diff * -11));
      DateTime approxMaulid = DateTime(2026, 8, 25).add(Duration(days: diff * -11));
      DateTime approxImlek = DateTime(2026, 2, 17).add(Duration(days: diff * -11));
      DateTime approxNyepi = DateTime(2026, 3, 19).add(Duration(days: diff * -11));
      DateTime approxWaisak = DateTime(2026, 5, 31).add(Duration(days: diff * -11));

      void addIfMatch(DateTime d, String name, [bool isCuti = false]) {
        if (d.month == month) list.add(Holiday(date: d, name: name, isCutiBersama: isCuti));
      }

      addIfMatch(approxImlek, 'Tahun Baru Imlek (Perkiraan)');
      addIfMatch(approxNyepi, 'Hari Suci Nyepi (Perkiraan)');
      addIfMatch(approxWaisak, 'Hari Raya Waisak (Perkiraan)');
      addIfMatch(approxIsraMikraj, 'Isra Mikraj (Perkiraan)');
      addIfMatch(approxTahunBaruIslam, 'Tahun Baru Islam (Perkiraan)');
      addIfMatch(approxMaulid, 'Maulid Nabi Muhammad SAW (Perkiraan)');
      
      // Idul Fitri & Cuti Bersama Approximation
      if (approxIdulFitri.month == month) {
        list.add(Holiday(date: approxIdulFitri.subtract(const Duration(days: 2)), name: 'Cuti Bersama Idul Fitri', isCutiBersama: true));
        list.add(Holiday(date: approxIdulFitri.subtract(const Duration(days: 1)), name: 'Cuti Bersama Idul Fitri', isCutiBersama: true));
        list.add(Holiday(date: approxIdulFitri, name: 'Hari Raya Idul Fitri (Perkiraan)'));
        list.add(Holiday(date: approxIdulFitri.add(const Duration(days: 1)), name: 'Hari Raya Idul Fitri Hari Kedua (Perkiraan)'));
        list.add(Holiday(date: approxIdulFitri.add(const Duration(days: 2)), name: 'Cuti Bersama Idul Fitri', isCutiBersama: true));
      }
      
      // Idul Adha & Cuti Bersama Approximation
      if (approxIdulAdha.month == month) {
        list.add(Holiday(date: approxIdulAdha, name: 'Hari Raya Idul Adha (Perkiraan)'));
        list.add(Holiday(date: approxIdulAdha.add(const Duration(days: 1)), name: 'Cuti Bersama Idul Adha', isCutiBersama: true));
      }
    }
    
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }
}