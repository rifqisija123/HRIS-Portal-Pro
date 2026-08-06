import 'package:flutter/material.dart';
import 'dashboard_page.dart';

class AttendanceHistoryPage extends StatefulWidget {
  const AttendanceHistoryPage({super.key});

  @override
  State<AttendanceHistoryPage> createState() => _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends State<AttendanceHistoryPage> {
  String _selectedFilter = 'Semua';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface, // Match dashboard
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Riwayat Presensi',
          style: TextStyle(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilterTabs(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  if (_selectedFilter == 'Semua' || _selectedFilter == 'Hari Ini') ...[
                    _buildSectionHeader('Hari Ini'),
                    const SizedBox(height: 16),
                    const HistoryItemCard(
                      date: 'Senin, 24 Juli 2026',
                      timeAndLocation: '08:45:00 - 17:00:00 WIB',
                      status: 'Hadir',
                      isLate: false,
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (_selectedFilter == 'Semua' || _selectedFilter == 'Kemarin') ...[
                    _buildSectionHeader('Kemarin'),
                    const SizedBox(height: 16),
                    const HistoryItemCard(
                      date: 'Selasa, 23 Juli 2026',
                      timeAndLocation: '08:45:00 - 17:00:00 WIB',
                      status: 'Hadir',
                      isLate: false,
                    ),
                    const SizedBox(height: 12),
                    const HistoryItemCard(
                      date: 'Jumat, 22 Juli 2026',
                      timeAndLocation: '08:45:00 - 17:00:00 WIB',
                      status: 'Hadir',
                      isLate: false,
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (_selectedFilter == 'Semua' || _selectedFilter == 'Minggu Lalu') ...[
                    _buildSectionHeader('Minggu Lalu'),
                    const SizedBox(height: 16),
                    const HistoryItemCard(
                      date: 'Jumat, 21 Juli 2026',
                      timeAndLocation: '08:45:00 - 17:00:00 WIB',
                      status: 'Hadir',
                      isLate: false,
                    ),
                    const SizedBox(height: 12),
                    const HistoryItemCard(
                      date: 'Kamis, 20 Juli 2026',
                      timeAndLocation: '09:00:00 - 17:00:00 WIB',
                      status: 'Telat',
                      isLate: true,
                      lateDuration: '15 Menit',
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (_selectedFilter == 'Semua' || _selectedFilter == 'Bulan Lalu') ...[
                    _buildSectionHeader('Bulan Lalu'),
                    const SizedBox(height: 16),
                    const HistoryItemCard(
                      date: 'Rabu, 21 Juni 2026',
                      timeAndLocation: '09:55:00 - 17:00:00 WIB',
                      status: 'Telat',
                      isLate: true,
                      lateDuration: '1 Jam 10 Menit',
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
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

}

class HistoryItemCard extends StatefulWidget {
  final String date;
  final String timeAndLocation;
  final String status;
  final bool isLate;
  final String location;
  final String totalTime;
  final String? lateDuration;

  const HistoryItemCard({
    super.key,
    required this.date,
    required this.timeAndLocation,
    required this.status,
    required this.isLate,
    this.location = 'Gelora Bung Karno, Senayan',
    this.totalTime = '8 Jam 15 Menit 05 Detik',
    this.lateDuration,
  });

  @override
  State<HistoryItemCard> createState() => _HistoryItemCardState();
}

class _HistoryItemCardState extends State<HistoryItemCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: widget.isLate ? AppColors.error.withOpacity(0.1) : AppColors.secondaryContainer.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.login,
                          color: widget.isLate ? AppColors.error : AppColors.onSecondaryContainer,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.date,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.timeAndLocation,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.outline,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (widget.isLate && widget.lateDuration != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Telat ${widget.lateDuration}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: widget.isLate ? AppColors.error.withOpacity(0.1) : AppColors.secondaryContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        widget.status,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: widget.isLate ? AppColors.error : AppColors.onSecondaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _isExpanded ? Icons.keyboard_arrow_down : Icons.chevron_right,
                      color: AppColors.outline,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_isExpanded) ...[
            const SizedBox(height: 16),
            Divider(color: AppColors.surfaceContainerHigh),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            'Lokasi Presensi',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.outline,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.location.replaceAll(', ', ',\n'),
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.timer, size: 14, color: AppColors.tertiary),
                          const SizedBox(width: 4),
                          Text(
                            'Total Waktu Kerja',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.outline,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.totalTime,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

