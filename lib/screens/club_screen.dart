import 'dart:convert';
import 'package:crypto/crypto.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/efitness_service.dart';
import '../screens/settings_screen.dart';
import '../screens/reservations_screen.dart';
import '../widgets/qrcode_widget.dart';
import '../widgets/installments_widget.dart';
import 'dart:async';
import 'store_screen.dart';
import '../screens/account_screen.dart';

class ClubScreen extends StatefulWidget {
  final Map<String, dynamic> club;

  const ClubScreen({required this.club, super.key});

  @override
  State<ClubScreen> createState() => _ClubScreenState();
}

class _ClubScreenState extends State<ClubScreen> {
  final EfitnessService _service = EfitnessService();
  int _selectedIndex = 0;
  Map<String, dynamic>? _memberCount;
  Map<String, dynamic>? _membershipInfo;
  bool _isLoading = true;
  Timer? _countdownTimer;
  String _statusText = '';
  String _countdownText = '';
  List<Map<String, dynamic>> _attendanceHistory = [];
  bool _attendanceLoading = false;
  List<Map<String, dynamic>> _installments = [];
  bool _installmentsLoading = false;
  int _notificationCount = 0;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('pl_PL', null);
    _loadData();
    _startCountdownTimer();
    _loadNotificationCount();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final clubId = widget.club['clubId'];

    final memberCount = await _service.getClubMembers(clubId);
    final membership = await _service.getMembershipInfo(clubId);

    setState(() {
      _memberCount = memberCount;
      _membershipInfo = membership;
      _isLoading = false;
    });
  }

  void _startCountdownTimer() {
    // Initial call to set status immediately
    _updateClubStatus();
    // Subsequent calls every second to update countdowns
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateClubStatus();
    });
  }

  void _updateClubStatus() {
    final hours = widget.club['mobileClubOpeningHours'] ?? '';
    if (hours.isEmpty) {
      setState(() {
        _statusText = 'Hours Unknown';
        _countdownText = '';
      });
      return;
    }

    final now = DateTime.now();
    final dayNames = {
      1: ['poniedziałek', 'pon'],
      2: ['wtorek', 'wt'],
      3: ['środa', 'śr'],
      4: ['czwartek', 'czw'],
      5: ['piątek', 'pt'],
      6: ['sobota', 'sob'],
      7: ['niedziela', 'nie'],
    };

    // Parse all days from opening hours
    final daySchedules = <int, List<Map<String, TimeOfDay>>>{};
    for (final line in hours.split(';')) {
      for (int dayNum = 1; dayNum <= 7; dayNum++) {
        final dayKeys = dayNames[dayNum] ?? [];
        if (dayKeys.any(
          (key) => line.toLowerCase().contains(key.toLowerCase()),
        )) {
          final parsedRanges = _parseTimeRanges(line);
          if (parsedRanges.isNotEmpty) {
            daySchedules[dayNum] = parsedRanges;
          }
          break;
        }
      }
    }

    final todaySchedule = daySchedules[now.weekday];
    if (todaySchedule != null) {
      // Check if currently open
      for (final range in todaySchedule) {
        final openTime = DateTime(
          now.year,
          now.month,
          now.day,
          range['open']!.hour,
          range['open']!.minute,
        );
        final closeTime = DateTime(
          now.year,
          now.month,
          now.day,
          range['close']!.hour,
          range['close']!.minute,
        );

        if (now.isAfter(openTime) && now.isBefore(closeTime)) {
          final timeUntilClose = closeTime.difference(now);
          setState(() {
            _statusText = 'Open';
            _countdownText = 'Closes in ${_formatDuration(timeUntilClose)}';
          });
          return;
        }
      }

      // Check for later opening today
      final futureRanges = todaySchedule.where((range) {
        final openTime = DateTime(
          now.year,
          now.month,
          now.day,
          range['open']!.hour,
          range['open']!.minute,
        );
        return now.isBefore(openTime);
      }).toList();

      if (futureRanges.isNotEmpty) {
        final nextOpenTime = futureRanges.first['open']!;
        setState(() {
          _statusText = 'Closed';
          _countdownText = 'Opens today at ${_formatTime(nextOpenTime)}';
        });
        return;
      }
    }

    // Find next opening day
    for (int i = 1; i <= 7; i++) {
      final dayToCheck = (now.weekday % 7) + i;
      final dayNum = dayToCheck > 7 ? dayToCheck - 7 : dayToCheck;
      final nextDaySchedule = daySchedules[dayNum];

      if (nextDaySchedule != null && nextDaySchedule.isNotEmpty) {
        final dayName = _getDayName(dayNum);
        final openTime = nextDaySchedule.first['open']!;
        setState(() {
          _statusText = 'Closed';
          _countdownText = i == 1
              ? 'Opens tomorrow at ${_formatTime(openTime)}'
              : 'Opens $dayName at ${_formatTime(openTime)}';
        });
        return;
      }
    }

    setState(() {
      _statusText = 'Closed';
      _countdownText = 'Hours not available';
    });
  }

  String _getDayName(int dayNum) {
    const dayNames = {
      1: 'Monday',
      2: 'Tuesday',
      3: 'Wednesday',
      4: 'Thursday',
      5: 'Friday',
      6: 'Saturday',
      7: 'Sunday',
    };
    return dayNames[dayNum] ?? '';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  List<Map<String, TimeOfDay>> _parseTimeRanges(String line) {
    // i fucking hate how they overcomplicated this, why couldn't they just use a NORMAL
    // fucking format like "7:00-12:00" instead of fucking mix and matching with : and .
    final sanitizedLine = line.replaceAll('.', ':');

    final ranges = <Map<String, TimeOfDay>>[];
    // stupid fucking regex
    final timePattern = RegExp(r'(\d{1,2}):(\d{2})-(\d{1,2}):(\d{2})');
    final matches = timePattern.allMatches(sanitizedLine);

    for (final match in matches) {
      try {
        final openHour = int.parse(match.group(1)!);
        final openMinute = int.parse(match.group(2)!);
        final closeHour = int.parse(match.group(3)!);
        final closeMinute = int.parse(match.group(4)!);

        ranges.add({
          'open': TimeOfDay(hour: openHour, minute: openMinute),
          'close': TimeOfDay(hour: closeHour, minute: closeMinute),
        });
      } catch (e) {
        // i have to put something here to avoid the linter complaining
        if (kDebugMode) {
          print(
            'Error parsing time range from match: ${match.group(0)}. Error: $e',
          );
        }
      }
    }
    return ranges;
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative) return '0m';

    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Future<void> _showAttendanceHistory() async {
    setState(() => _attendanceLoading = true);
    final clubId = widget.club['clubId'];
    final now = DateTime.now();
    final dateFrom = '2015-01-01';
    final dateTo = DateFormat('yyyy-MM-dd').format(now);

    final history = await _service.getAttendanceHistory(
      clubId: clubId,
      dateFrom: dateFrom,
      dateTo: dateTo,
    );

    setState(() {
      _attendanceHistory = history.reversed.toList();
      _attendanceLoading = false;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.history, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Attendance History',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _attendanceLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _attendanceHistory.isEmpty
                    ? const Center(child: Text('No attendance history found.'))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: _attendanceHistory.length,
                        itemBuilder: (context, index) {
                          final item = _attendanceHistory[index];
                          final className = item['className'] ?? '';
                          final startDate = item['startDate'];
                          final duration = item['duration'];
                          final status = item['attendanceStatus'];
                          final dt = startDate != null
                              ? DateTime.tryParse(startDate)
                              : null;
                          final formattedDate = dt != null
                              ? DateFormat(
                                  'dd/MM/yyyy HH:mm',
                                  'pl_PL',
                                ).format(dt)
                              : '';

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 16,
                            ),
                            child: Card(
                              child: InkWell(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 64,
                                        height: 64,
                                        decoration: BoxDecoration(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.fitness_center,
                                          size: 32,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              className,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.access_time,
                                                  size: 16,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  formattedDate,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.timer,
                                                  size: 16,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  duration != null
                                                      ? '$duration min'
                                                      : 'N/A',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  status == 1
                                                      ? Icons.cancel
                                                      : Icons.check_circle,
                                                  size: 16,
                                                  color: status == 1
                                                      ? Colors.red
                                                      : Colors.green,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  status == 1
                                                      ? 'Absent'
                                                      : 'Present',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showInstallments() async {
    if (_membershipInfo == null || _membershipInfo!['membershipId'] == null) {
      return;
    }
    setState(() => _installmentsLoading = true);
    final clubId = widget.club['clubId'];
    final membershipId = _membershipInfo!['membershipId'];
    final installments = await _service.getInstallments(
      clubId: clubId,
      membershipId: membershipId,
    );
    setState(() {
      _installments = installments;
      _installmentsLoading = false;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          if (_installmentsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return InstallmentsWidget(
            installments: _installments,
            clubId: clubId,
          );
        },
      ),
    );
  }

  Future<void> _loadNotificationCount() async {
    final clubId = widget.club['clubId'];
    final service = EfitnessService();
    final notifs = await service.getNotifications(clubId: clubId);
    final prefs = await SharedPreferences.getInstance();
    final hashes = prefs.getStringList('readNotificationHashes') ?? [];
    final Set<String> readHashes = hashes.toSet();
    int unread = 0;
    for (final notif in notifs) {
      final jsonStr = jsonEncode({
        'content': notif['content'],
        'date': notif['date'],
        'title': notif['title'],
      });
      final hash = sha256.convert(utf8.encode(jsonStr)).toString();
      if (!readHashes.contains(hash)) {
        unread++;
      }
    }
    setState(() {
      _notificationCount = unread;
    });
  }

  Future<void> _openAccountScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AccountScreen(
          club: widget.club,
          membershipInfo: _membershipInfo,
        ),
      ),
    );
    _loadNotificationCount();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.club['name'] ?? '';
    final logoUrl = widget.club['mobileClubLogo'] ?? '';
    final primaryColor = widget.club['mobileClubStyle']?['primaryColor'];
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Row(
          children: [
            if (logoUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  logoUrl,
                  width: 28,
                  height: 28,
                  errorBuilder: (_, __, ___) => Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.fitness_center,
                      size: 16,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            if (logoUrl.isNotEmpty) const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: primaryColor != null
            ? Color(
                int.parse(primaryColor.substring(1), radix: 16) + 0xFF000000,
              )
            : colorScheme.surface,
        foregroundColor: primaryColor != null
            ? Colors.white
            : colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_2),
            tooltip: 'Show QR Code',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => Dialog(
                  backgroundColor: Colors.transparent,
                  insetPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 40,
                  ),
                  child: QrCodeWidget(clubId: widget.club['clubId']),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showAttendanceHistory,
            tooltip: 'Attendance History',
          ),
          Stack(
  children: [
    IconButton(
      icon: const Icon(Icons.account_circle),
      tooltip: 'Account',
      onPressed: _openAccountScreen,
    ),
    if (_notificationCount > 0)
      Positioned(
        right: 8,
        top: 8,
        child: GestureDetector(
          onTap: _openAccountScreen,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(10),
            ),
            constraints: const BoxConstraints(
              minWidth: 20,
              minHeight: 20,
            ),
            child: Text(
              '$_notificationCount',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
  ],
)
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildOverviewTab(),
          const ReservationsScreen(),
          StoreScreen(club: widget.club),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_outlined),
            selectedIcon: Icon(Icons.event),
            label: 'Classes',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart),
            label: 'Store',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final desc = widget.club['mobileClubDescription'] ?? '';
    final hours = widget.club['mobileClubOpeningHours'] ?? '';
    final colorScheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.groups_outlined,
                                    color: colorScheme.onSurfaceVariant,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Club Capacity',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (_isLoading)
                                const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              else if (_memberCount != null) ...[
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${_memberCount!['membersInsideClub'] ?? 0}',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                    Text(
                                      '/ ${_memberCount!['limit'] ?? 'N/A'}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value:
                                        _memberCount!['limit'] != null &&
                                            _memberCount!['membersInsideClub'] !=
                                                null
                                        ? (_memberCount!['membersInsideClub'] /
                                                  _memberCount!['limit'])
                                              .clamp(0.0, 1.0)
                                        : 0.0,
                                    backgroundColor:
                                        colorScheme.surfaceContainerHighest,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      _memberCount!['limit'] != null &&
                                              _memberCount!['membersInsideClub'] !=
                                                  null
                                          ? (_memberCount!['membersInsideClub'] /
                                                        _memberCount!['limit']) >
                                                    0.8
                                                ? colorScheme.error
                                                : (_memberCount!['membersInsideClub'] /
                                                          _memberCount!['limit']) >
                                                      0.6
                                                ? Colors.orange
                                                : Colors.green
                                          : colorScheme.outline,
                                    ),
                                  ),
                                ),
                              ] else
                                Text(
                                  'Unable to load',
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _statusText == 'Open'
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_unchecked,
                                    color: _statusText == 'Open'
                                        ? Colors.green
                                        : colorScheme.error,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _statusText,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: _statusText == 'Open'
                                          ? Colors.green
                                          : colorScheme.error,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _countdownText.isEmpty
                                    ? 'Check hours below'
                                    : _countdownText,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          if (_membershipInfo != null) ...[
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.card_membership_outlined,
                          color: colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _membershipInfo!['name'] ?? 'Membership Info',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.payments_outlined),
                          tooltip: 'Show Installments',
                          onPressed: _showInstallments,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          _membershipInfo!['isValid'] == true
                              ? Icons.check_circle
                              : Icons.error,
                          color: _membershipInfo!['isValid'] == true
                              ? Colors.green
                              : colorScheme.error,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _membershipInfo!['isValid'] == true
                              ? 'Active'
                              : 'Inactive',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _membershipInfo!['isValid'] == true
                                ? Colors.green
                                : colorScheme.error,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _membershipInfo!['to'] != null &&
                                  _membershipInfo!['to'].toString().isNotEmpty
                              ? 'Expires in ${_daysUntil(_membershipInfo!['to'])} days (${_formatDate(_membershipInfo!['to'])})'
                              : 'Expires: N/A',
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],

          if (hours.isNotEmpty) ...[
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_outlined,
                          color: colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Opening Hours',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...hours.split(';').map((line) {
                      final parts = line.split(',');
                      final day = parts[0].trim();
                      // Combine all time parts, replace . with :, remove "oraz", join with ", "
                      final times = parts
                          .skip(1)
                          .join(',')
                          .replaceAll('oraz', ',')
                          .replaceAll('.', ':')
                          .split(',')
                          .map((t) => t.trim())
                          .toList();
                      final formattedTimes = times.join(', ');
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              day,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              formattedTimes,
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],

          if (desc.isNotEmpty) ...[
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'About',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      desc,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  int _daysUntil(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 0;
    try {
      final now = DateTime.now();
      final date = DateTime.parse(dateString);
      final diff = date
          .difference(DateTime(now.year, now.month, now.day))
          .inDays;
      return diff >= 0 ? diff : 0;
    } catch (e) {
      return 0;
    }
  }
}
