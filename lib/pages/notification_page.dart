import 'package:flutter/material.dart';
import 'dashboard_page.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  String _selectedFilter = 'Semua';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Scaffold(
            backgroundColor: AppColors.surface,
            appBar: _buildAppBar(context),
            body: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilterTabs(),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                      children: [
                        if (_selectedFilter == 'Semua' || _selectedFilter == 'Hari Ini') ...[
                          _buildSectionHeader('Hari Ini'),
                          const SizedBox(height: 8),
                          _buildNotificationCard(
                            icon: Icons.check_circle,
                            iconColor: const Color(0xFF00714D),
                            iconBgColor: const Color(0xFF6CF8BB),
                            title: 'Pengajuan Cuti Disetujui',
                            time: '09:45',
                            description:
                                'Permohonan cuti tahunan Anda untuk tanggal 24-25 Oktober telah disetujui oleh Manager.',
                            badgeText: 'Leave',
                            badgeColor: const Color(0xFF006C49),
                            isUnread: true,
                          ),
                          const SizedBox(height: 16),
                          _buildNotificationCard(
                            icon: Icons.alarm,
                            iconColor: const Color(0xFF93000A),
                            iconBgColor: const Color(0xFFFFDAD6),
                            title: 'Jangan Lupa Absen Pagi Ini!',
                            time: '08:00',
                            description:
                                'Waktu kerja telah dimulai. Segera lakukan check-in melalui aplikasi untuk mencatat kehadiran Anda.',
                            badgeText: 'Attendance',
                            badgeColor: const Color(0xFFBA1A1A),
                            isUnread: true,
                          ),
                          const SizedBox(height: 32),
                        ],
                        if (_selectedFilter == 'Semua' || _selectedFilter == 'Kemarin') ...[
                          _buildSectionHeader('Kemarin'),
                          const SizedBox(height: 8),
                          _buildNotificationCard(
                            icon: Icons.payments,
                            iconColor: AppColors.primary,
                            iconBgColor: AppColors.surfaceVariant,
                            title: 'Gaji Bulan Oktober Telah Tersedia',
                            time: 'Kemarin, 17:00',
                            description:
                                'Slip gaji periode Oktober 2023 sudah dapat Anda unduh. Silakan periksa rincian pembayaran Anda.',
                            badgeText: 'Payroll',
                            badgeColor: AppColors.primary,
                            isUnread: false,
                          ),
                          const SizedBox(height: 16),
                          _buildNotificationCard(
                            icon: Icons.campaign,
                            iconColor: const Color(0xFF653E00),
                            iconBgColor: const Color(0xFFFFDDB8),
                            title: 'Townhall Meeting Q4',
                            time: 'Kemarin, 10:30',
                            description:
                                'Sesi pertemuan rutin kuartal keempat akan diadakan secara daring pada hari Jumat mendatang.',
                            badgeText: 'Announcement',
                            badgeColor: const Color(0xFF825100),
                            isUnread: false,
                          ),
                          const SizedBox(height: 32),
                        ],
                        if (_selectedFilter == 'Semua' || _selectedFilter == 'Minggu Lalu') ...[
                          _buildSectionHeader('Minggu Lalu'),
                          const SizedBox(height: 16),
                          _buildNotificationCard(
                            icon: Icons.history,
                            iconColor: AppColors.primary,
                            iconBgColor: AppColors.surfaceVariant,
                            title: 'Laporan Mingguan HR',
                            time: '14 Okt',
                            description:
                                'Laporan performa dan absensi mingguan departemen Anda sudah dapat diakses di portal.',
                            badgeText: 'Report',
                            badgeColor: AppColors.primary,
                            isUnread: false,
                          ),
                          const SizedBox(height: 16),
                          _buildNotificationCard(
                            icon: Icons.event,
                            iconColor: const Color(0xFF653E00),
                            iconBgColor: const Color(0xFFFFDDB8),
                            title: 'Jadwal Cuti Anda Diperbarui',
                            time: '12 Okt',
                            description:
                                'Jadwal cuti tahunan Anda telah disinkronkan dengan kalender tim.',
                            badgeText: 'Leave',
                            badgeColor: const Color(0xFF825100),
                            isUnread: false,
                          ),
                          const SizedBox(height: 32),
                        ],
                        if (_selectedFilter == 'Semua' || _selectedFilter == 'Bulan Lalu') ...[
                          _buildSectionHeader('Bulan Lalu'),
                          const SizedBox(height: 16),
                          _buildNotificationCard(
                            icon: Icons.assignment_turned_in,
                            iconColor: const Color(0xFF006C49),
                            iconBgColor: const Color(0xFF6CF8BB),
                            title: 'Penilaian Kinerja Q3 Selesai',
                            time: '28 Sep',
                            description:
                                'Hasil evaluasi kinerja kuartal 3 telah dirilis. Silakan jadwalkan diskusi dengan atasan Anda.',
                            badgeText: 'Performance',
                            badgeColor: const Color(0xFF006C49),
                            isUnread: false,
                          ),
                          const SizedBox(height: 24),
                        ],
                        if (_selectedFilter == 'Semua') _buildEmptyState(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(Icons.arrow_back, color: AppColors.onSurfaceVariant),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Notifikasi',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(Icons.settings, color: AppColors.primary),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildTab('Semua'),
          const SizedBox(width: 8),
          _buildTab('Hari Ini'),
          const SizedBox(width: 8),
          _buildTab('Kemarin'),
          const SizedBox(width: 8),
          _buildTab('Minggu Lalu'),
          const SizedBox(width: 8),
          _buildTab('Bulan Lalu'),
        ],
      ),
    );
  }

  Widget _buildTab(String label) {
    bool isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: AppColors.outline,
            fontWeight: FontWeight.w600,
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Divider(
            color: AppColors.outlineVariant,
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String time,
    required String description,
    required String badgeText,
    required Color badgeColor,
    required bool isUnread,
  }) {
    return Opacity(
      opacity: isUnread ? 1.0 : 0.8,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUnread ? AppColors.surfaceContainerLowest : AppColors.surfaceContainerLowest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.outlineVariant),
          boxShadow: isUnread
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  )
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                            height: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.outline,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: badgeColor.withOpacity(0.2)),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: badgeColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isUnread) ...[
              const SizedBox(width: 12),
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      )
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.notifications_off, size: 48, color: AppColors.outlineVariant),
            SizedBox(height: 16),
            Text(
              'Tidak ada notifikasi lebih lanjut',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

