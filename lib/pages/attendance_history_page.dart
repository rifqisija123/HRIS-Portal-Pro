import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dashboard_page.dart';

class AttendanceRecord {
  final String dateKey;
  final DateTime date;
  final String checkInTime;
  final String checkOutTime;
  final String status;
  final bool isLate;
  final String? lateDuration;
  final String location;
  final String totalTime;

  AttendanceRecord({
    required this.dateKey,
    required this.date,
    required this.checkInTime,
    required this.checkOutTime,
    required this.status,
    required this.isLate,
    this.lateDuration,
    required this.location,
    required this.totalTime,
  });

  static String _formatTotalWorkTime(String? rawTime) {
    if (rawTime == null || rawTime.isEmpty || rawTime == '-') {
      return '-';
    }
    return rawTime
        .replaceAll('H', ' Jam')
        .replaceAll('M', ' Menit')
        .replaceAll('S', ' Detik');
  }

  factory AttendanceRecord.fromMap(String key, Map<dynamic, dynamic> map) {
    DateTime parsedDate;
    try {
      final parts = key.split('-');
      parsedDate = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    } catch (_) {
      parsedDate = DateTime.now();
    }

    final String checkIn = map['check_in_time']?.toString() ?? '-';
    final String? checkOutRaw = map['check_out_time']?.toString();
    final String checkOut = (checkOutRaw != null && checkOutRaw.isNotEmpty) ? checkOutRaw : 'Belum Pulang';

    final String statusStr = map['status']?.toString() ?? 'Hadir';
    final bool isLateBool = statusStr.toLowerCase().contains('telat') || (map['is_late'] == true);
    final String? lateDur = map['late_duration']?.toString();

    String loc = map['location_name']?.toString() ?? '';
    final String locAddr = map['location_address']?.toString() ?? '';
    if (loc.isEmpty && locAddr.isNotEmpty) {
      loc = locAddr;
    } else if (loc.isEmpty) {
      loc = 'Lokasi Tidak Diketahui';
    } else if (locAddr.isNotEmpty && locAddr != loc) {
      loc = '$loc, $locAddr';
    }

    final String rawTotalWork = map['total_work_time']?.toString() ?? '';
    final String totalWork = _formatTotalWorkTime(rawTotalWork);

    return AttendanceRecord(
      dateKey: key,
      date: parsedDate,
      checkInTime: checkIn,
      checkOutTime: checkOut,
      status: statusStr,
      isLate: isLateBool,
      lateDuration: lateDur,
      location: loc,
      totalTime: totalWork,
    );
  }
}

class AttendanceHistoryPage extends StatefulWidget {
  const AttendanceHistoryPage({super.key});

  @override
  State<AttendanceHistoryPage> createState() => _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends State<AttendanceHistoryPage> {
  String _selectedFilter = 'Semua';

  String _formatIndonesianDate(String dateKey) {
    try {
      final parts = dateKey.split('-');
      if (parts.length == 3) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        final dt = DateTime(year, month, day);

        const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
        const months = [
          'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
          'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
        ];
        final dayName = days[dt.weekday - 1];
        final monthName = months[dt.month - 1];
        return '$dayName, ${dt.day} $monthName ${dt.year}';
      }
    } catch (_) {}
    return dateKey;
  }

  bool _matchesFilter(AttendanceRecord record, String filter, DateTime todayDate) {
    final recordDate = DateTime(record.date.year, record.date.month, record.date.day);
    final diffDays = todayDate.difference(recordDate).inDays;

    if (filter == 'Semua') return true;
    if (filter == 'Hari Ini') return diffDays == 0;
    if (filter == 'Kemarin') return diffDays == 1;
    if (filter == 'Minggu Lalu') return diffDays >= 0 && diffDays <= 7;
    if (filter == 'Bulan Lalu') return diffDays >= 0 && diffDays <= 30;
    return true;
  }

  String _getSectionTitle(DateTime recordDate, DateTime todayDate) {
    final rDate = DateTime(recordDate.year, recordDate.month, recordDate.day);
    final diffDays = todayDate.difference(rDate).inDays;
    if (diffDays == 0) return 'Hari Ini';
    if (diffDays == 1) return 'Kemarin';
    if (diffDays > 1 && diffDays <= 7) return 'Minggu Lalu';
    if (diffDays > 7 && diffDays <= 30) return 'Bulan Lalu';
    return 'Sebelumnya';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

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
              child: user == null
                  ? const Center(child: Text('Pengguna belum terautentikasi.'))
                  : StreamBuilder<DatabaseEvent>(
                      stream: FirebaseDatabase.instance
                          .ref()
                          .child('attendances')
                          .child(user.uid)
                          .onValue,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                'Gagal memuat riwayat: ${snapshot.error}',
                                style: TextStyle(color: AppColors.error),
                              ),
                            ),
                          );
                        }

                        final data = snapshot.data?.snapshot.value;
                        if (data == null || data is! Map) {
                          return _buildEmptyState();
                        }

                        final Map<dynamic, dynamic> attendancesMap = data;
                        final List<AttendanceRecord> records = [];

                        attendancesMap.forEach((key, value) {
                          if (value is Map) {
                            records.add(AttendanceRecord.fromMap(key.toString(), value));
                          }
                        });

                        records.sort((a, b) => b.dateKey.compareTo(a.dateKey));

                        final now = DateTime.now();
                        final todayDate = DateTime(now.year, now.month, now.day);

                        final filteredRecords = records
                            .where((r) => _matchesFilter(r, _selectedFilter, todayDate))
                            .toList();

                        if (filteredRecords.isEmpty) {
                          return _buildEmptyState();
                        }

                        final Map<String, List<AttendanceRecord>> grouped = {};
                        for (var record in filteredRecords) {
                          final section = _getSectionTitle(record.date, todayDate);
                          grouped.putIfAbsent(section, () => []).add(record);
                        }

                        return ListView(
                          padding: const EdgeInsets.all(16.0),
                          children: grouped.entries.expand((entry) {
                            final sectionTitle = entry.key;
                            final items = entry.value;

                            return [
                              _buildSectionHeader(sectionTitle),
                              const SizedBox(height: 16),
                              ...items.map((item) {
                                final timeStr = item.checkOutTime == 'Belum Pulang'
                                    ? '${item.checkInTime} - Belum Pulang'
                                    : '${item.checkInTime} - ${item.checkOutTime}';

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: HistoryItemCard(
                                    date: _formatIndonesianDate(item.dateKey),
                                    timeAndLocation: timeStr,
                                    status: item.status,
                                    isLate: item.isLate,
                                    lateDuration: item.lateDuration,
                                    location: item.location,
                                    totalTime: item.totalTime,
                                  ),
                                );
                              }),
                              const SizedBox(height: 16),
                            ];
                          }).toList(),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_outlined,
              size: 72,
              color: AppColors.outline.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum Ada Riwayat Presensi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Data riwayat presensi Anda akan muncul di sini setelah Anda melakukan presensi.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.outline,
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
            color: Colors.black.withValues(alpha: 0.05),
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
                          color: widget.isLate ? AppColors.error.withValues(alpha: 0.1) : AppColors.secondaryContainer.withValues(alpha: 0.3),
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
                        color: widget.isLate ? AppColors.error.withValues(alpha: 0.1) : AppColors.secondaryContainer.withValues(alpha: 0.3),
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