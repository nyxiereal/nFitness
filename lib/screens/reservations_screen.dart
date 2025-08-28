import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/efitness_service.dart';
import 'dart:convert';

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  final EfitnessService _service = EfitnessService();
  List<Map<String, dynamic>> _classes = [];
  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now();
  int? _clubId;

  @override
  void initState() {
    super.initState();
    _loadClubData();
  }

  Future<void> _loadClubData() async {
    final prefs = await SharedPreferences.getInstance();
    final clubJson = prefs.getString('selectedClub');
    if (clubJson != null) {
      final club = Map<String, dynamic>.from(jsonDecode(clubJson));
      _clubId = club['clubId'] as int;
      await _loadClasses();
    }
  }

  Future<void> _loadClasses() async {
    if (_clubId == null) return;

    setState(() => _isLoading = true);

    final dateString = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final classes = await _service.getClasses(
      clubId: _clubId!,
      dateFrom: dateString,
      dateTo: dateString,
    );

    classes.sort((a, b) {
      final startA = DateTime.parse(a['startDate']);
      final startB = DateTime.parse(b['startDate']);
      return startA.compareTo(startB);
    });

    setState(() {
      _classes = classes;
      _isLoading = false;
    });
  }

  Future<void> _handleClassReservation(Map<String, dynamic> classData) async {
    final classId = classData['classId'] as int;
    final className = classData['name'] ?? 'Class';

    final colorScheme = Theme.of(context).colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reserve Class'),
        content: Text('Do you want to reserve "$className"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Reserve'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('Reserving class...'),
              ],
            ),
          ),
        ),
      ),
    );

    final result = await _service.reserveClass(
      clubId: _clubId!,
      classId: classId,
    );

    Navigator.of(context).pop();

    if (result != null) {
      if (result.containsKey('errors')) {
        final errors = result['errors'] as List<dynamic>;
        final errorMessage = errors.isNotEmpty
            ? errors.first['message'] ?? 'Unknown error'
            : 'Unknown error';

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error, color: colorScheme.error),
                const SizedBox(width: 8),
                Text('Reservation Failed'),
              ],
            ),
            content: Text(errorMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          ),
        );
      } else if (result.containsKey('classReservations')) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Text('Success!'),
              ],
            ),
            content: Text('Class "$className" reserved successfully!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          ),
        );

        await _loadClasses();
      }
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error, color: colorScheme.error),
              const SizedBox(width: 8),
              Text('Error'),
            ],
          ),
          content: Text('Failed to reserve class. Please try again.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _handleClassCancellation(Map<String, dynamic> classData) async {
    final classReservationId = classData['classReservationId'] as int;
    final className = classData['name'] ?? 'Class';

    final colorScheme = Theme.of(context).colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Reservation'),
        content: Text(
          'Do you want to cancel your reservation for "$className"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
            child: Text('Cancel'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('Cancelling reservation...'),
              ],
            ),
          ),
        ),
      ),
    );

    final success = await _service.cancelClassReservation(
      clubId: _clubId!,
      classReservationId: classReservationId,
    );

    Navigator.of(context).pop();

    if (success) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              Text('Cancelled!'),
            ],
          ),
          content: Text(
            'Your reservation for "$className" has been cancelled.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );

      await _loadClasses();
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error, color: colorScheme.error),
              const SizedBox(width: 8),
              Text('Error'),
            ],
          ),
          content: Text('Failed to cancel reservation. Please try again.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _showClassDetails(Map<String, dynamic> classData) async {
    final classId = classData['classId'] as int;
    final className = classData['name'] ?? 'Class';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('Loading participants...'),
              ],
            ),
          ),
        ),
      ),
    );

    final participants = await _service.getClassReservations(
      clubId: _clubId!,
      classId: classId,
    );

    Navigator.of(context).pop();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.group),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        className,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: participants == null
                    ? Center(
                        child: Text(
                          'You are unauthorized to view this!',
                        ),
                      )
                    : participants.isEmpty
                    ? Center(child: Text('No participants yet'))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: participants.length,
                        itemBuilder: (context, index) {
                          final participant = participants[index];
                          final isLoggedMember =
                              participant['isLoggedMember'] == true;
                          final waitingList =
                              participant['waitingList'] == true;

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage:
                                  participant['personalPhoto'] != null
                                  ? NetworkImage(participant['personalPhoto'])
                                  : null,
                              child: participant['personalPhoto'] == null
                                  ? Icon(Icons.person)
                                  : null,
                            ),
                            title: Text(
                              '${participant['firstName'] ?? ''} ${participant['lastName'] ?? ''}'
                                  .trim(),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (waitingList)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Waiting',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                if (isLoggedMember) ...[
                                  const SizedBox(width: 8),
                                  Icon(Icons.person, color: Colors.blue),
                                ],
                              ],
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

  String _formatTime(String dateString) {
    final date = DateTime.parse(dateString);
    return DateFormat('HH:mm').format(date);
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '${minutes}min';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '${hours}h';
      } else {
        return '${hours}h ${remainingMinutes}min';
      }
    }
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
    } catch (e) {
      return Colors.grey;
    }
  }

  Widget _buildDateSelector() {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 14,
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index));
          final isSelected =
              DateFormat('yyyy-MM-dd').format(date) ==
              DateFormat('yyyy-MM-dd').format(_selectedDate);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                setState(() => _selectedDate = date);
                _loadClasses();
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 60,
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('EEE').format(date),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? colorScheme.onPrimary
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date.day.toString(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                      ),
                    ),
                    if (index == 0)
                      Text(
                        'Today',
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected
                              ? colorScheme.onPrimary
                              : colorScheme.onSurfaceVariant,
                        ),
                      )
                    else if (index == 1)
                      Text(
                        'Tomorrow',
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected
                              ? colorScheme.onPrimary
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildClassCard(Map<String, dynamic> classData) {
    final colorScheme = Theme.of(context).colorScheme;
    final startTime = _formatTime(classData['startDate']);
    final endTime = _formatTime(classData['endDate']);
    final duration = _formatDuration(classData['duration']);
    final participantsNumber = classData['participantsNumber'] ?? 0;
    final participantsLimit = classData['participantsLimit'] ?? 0;
    final isAvailable = classData['isAvailable'] == true;
    final isFull = participantsNumber >= participantsLimit;
    final isReserved = classData['classReservationId'] != null;
    final backgroundColor = _parseColor(
      classData['backgroundColor'] ?? '#8c6b6b',
    );
    final instructorPhotoUrl = classData['instructorPhotoUrl'] ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => _showClassDetails(classData),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                // avoid using network images for classes, they cause more lag than they good UX to the table
                child: Icon(
                  Icons.fitness_center,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      classData['name'] ?? 'Unnamed Class',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$startTime - $endTime ($duration)',
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (instructorPhotoUrl.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              instructorPhotoUrl,
                              width: 16,
                              height: 16,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.person,
                                size: 16,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          )
                        else
                          Icon(
                            Icons.person,
                            size: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            classData['instructorFullName'] ??
                                'Unknown Instructor',
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (isReserved)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Reserved',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isFull
                                  ? colorScheme.error
                                  : isAvailable
                                  ? Colors.green
                                  : colorScheme.outline,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isFull
                                  ? 'Full'
                                  : isAvailable
                                  ? 'Available'
                                  : 'Unavailable',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.black
                                    : Colors.white,
                              ),
                            ),
                          ),
                        Row(
                          children: [
                            Text(
                              '$participantsNumber/$participantsLimit',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (isReserved) ...[
                              const SizedBox(width: 8),
                              FilledButton(
                                onPressed: () =>
                                    _handleClassCancellation(classData),
                                style: FilledButton.styleFrom(
                                  backgroundColor: colorScheme.error,
                                  minimumSize: Size(60, 32),
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ] else if (isAvailable && !isFull) ...[
                              const SizedBox(width: 8),
                              FilledButton(
                                onPressed: () =>
                                    _handleClassReservation(classData),
                                style: FilledButton.styleFrom(
                                  minimumSize: Size(60, 32),
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                ),
                                child: Text(
                                  'Reserve',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ],
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          _buildDateSelector(),
          const SizedBox(height: 16),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadClasses,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _classes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_busy,
                            size: 64,
                            color: colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No classes available for ${DateFormat('MMMM d').format(_selectedDate)}',
                            style: TextStyle(
                              fontSize: 16,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: _classes.length,
                      itemBuilder: (context, index) {
                        return _buildClassCard(_classes[index]);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
