import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends StatefulWidget {
  final String userRole; // 'homeowner', 'gardener', or 'service_provider'
  final String loggedInUser; // Name or ID of the logged-in user

  const CalendarScreen({
    Key? key,
    required this.userRole,
    required this.loggedInUser,
  }) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Sample events for demonstration
  final Map<DateTime, List<Map<String, String>>> _events = {
    DateTime.utc(2025, 1, 25): [
      {'time': '10:00 AM', 'client': 'John Doe', 'service': 'Lawn Mowing', 'gardener': 'Alice'},
      {'time': '02:00 PM', 'client': 'Jane Smith', 'service': 'Garden Cleaning', 'gardener': 'Bob'},
    ],
    DateTime.utc(2025, 1, 26): [
      {'time': '11:00 AM', 'client': 'Alice Brown', 'service': 'Tree Pruning', 'gardener': 'Charlie'},
    ],
    DateTime.utc(2025, 1, 27): [
      {'time': '09:00 AM', 'client': 'John Doe', 'service': 'Weeding', 'gardener': 'Alice'},
    ],
  };

  // Availability data
  final Map<DateTime, List<Map<String, String>>> _availability = {};

  // Get filtered events based on user role and logged-in user
  List<Map<String, String>> _getFilteredEventsForDay(DateTime date) {
    final events = _events[DateTime.utc(date.year, date.month, date.day)] ?? [];

    switch (widget.userRole) {
      case 'homeowner':
        // Homeowner sees their own bookings (filter by client name)
        return events.where((event) => event['client'] == widget.loggedInUser).toList();
      case 'gardener':
        // Gardener sees their assigned tasks (filter by gardener name)
        return events.where((event) => event['gardener'] == widget.loggedInUser).toList();
      case 'service_provider':
        // Service provider sees all bookings (no filter)
        return events;
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2000, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            calendarFormat: CalendarFormat.month,
            headerStyle: const HeaderStyle(formatButtonVisible: false),
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
            eventLoader: (day) {
              return _getFilteredEventsForDay(day);
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _selectedDay == null
                ? const Center(
                    child: Text(
                      'Select a date to see events.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : _buildEventList(),
          ),
        ],
      ),
      floatingActionButton: widget.userRole != 'homeowner' && _selectedDay != null
          ? Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  onPressed: () => _showAddEventDialog(_selectedDay!),
                  backgroundColor: Colors.green,
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 16),
                FloatingActionButton(
                  onPressed: () => _showSetAvailabilityDialog(_selectedDay!),
                  backgroundColor: Colors.blue,
                  child: const Icon(Icons.schedule),
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildEventList() {
    final events = _getFilteredEventsForDay(_selectedDay!);
    final availability = _availability[DateTime.utc(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day)] ?? [];

    if (events.isEmpty && availability.isEmpty) {
      return const Center(
        child: Text(
          'No events or availability for this day.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView(
      children: [
        if (availability.isNotEmpty)
          ...availability.map((availability) => Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.schedule, color: Colors.blue),
                  title: Text(availability['status'] == 'available'
                      ? 'Available at ${availability['time']}'
                      : 'Unavailable at ${availability['time']}'),
                ),
              )),
        if (events.isNotEmpty)
          ...events.map((event) => Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.event, color: Colors.green),
                  title: Text(event['service']!),
                  subtitle: widget.userRole == 'homeowner'
                      ? Text('Gardener: ${event['gardener']} at ${event['time']}')
                      : Text('Client: ${event['client']} at ${event['time']}'),
                ),
              )),
      ],
    );
  }

  void _showAddEventDialog(DateTime date) {
    final TextEditingController timeController = TextEditingController();
    final TextEditingController clientController = TextEditingController();
    final TextEditingController serviceController = TextEditingController();
    final TextEditingController gardenerController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Event'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: timeController,
                decoration: const InputDecoration(labelText: 'Time'),
              ),
              TextField(
                controller: clientController,
                decoration: const InputDecoration(labelText: 'Client'),
              ),
              TextField(
                controller: serviceController,
                decoration: const InputDecoration(labelText: 'Service'),
              ),
              TextField(
                controller: gardenerController,
                decoration: const InputDecoration(labelText: 'Gardener'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _events.putIfAbsent(
                    DateTime.utc(date.year, date.month, date.day),
                    () => [],
                  ).add({
                    'time': timeController.text,
                    'client': clientController.text,
                    'service': serviceController.text,
                    'gardener': gardenerController.text,
                  });
                });
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showSetAvailabilityDialog(DateTime date) {
    final TextEditingController timeController = TextEditingController();
    bool isUnavailable = false;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Set Availability'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: timeController,
                decoration: const InputDecoration(labelText: 'Time'),
              ),
              Row(
                children: [
                  const Text('Unavailable'),
                  Checkbox(
                    value: isUnavailable,
                    onChanged: (value) {
                      setState(() {
                        isUnavailable = value!;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _availability.putIfAbsent(
                    DateTime.utc(date.year, date.month, date.day),
                    () => [],
                  ).add({
                    'time': timeController.text,
                    'status': isUnavailable ? 'unavailable' : 'available',
                  });
                });
                Navigator.pop(context);
              },
              child: const Text('Set'),
            ),
          ],
        );
      },
    );
  }
}