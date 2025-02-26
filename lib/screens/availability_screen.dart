import 'package:flutter/material.dart';

class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({Key? key}) : super(key: key);

  @override
  _AvailabilityScreenState createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  final List<TimeOfDay> _availableHours = [];
  final List<TimeOfDay> _blockedHours = [];

  void _addAvailableHour() {
    showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    ).then((selectedTime) {
      if (selectedTime != null) {
        setState(() {
          _availableHours.add(selectedTime);
        });
      }
    });
  }

  void _addBlockedHour() {
    showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    ).then((selectedTime) {
      if (selectedTime != null) {
        setState(() {
          _blockedHours.add(selectedTime);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Availability'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Available Hours',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildTimeList(_availableHours),
            ElevatedButton(
              onPressed: _addAvailableHour,
              child: const Text('Add Available Hour'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Blocked Hours',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildTimeList(_blockedHours),
            ElevatedButton(
              onPressed: _addBlockedHour,
              child: const Text('Add Blocked Hour'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeList(List<TimeOfDay> times) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: times.length,
      itemBuilder: (context, index) {
        final time = times[index];
        return ListTile(
          title: Text('${time.format(context)}'),
          trailing: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              setState(() {
                times.removeAt(index);
              });
            },
          ),
        );
      },
    );
  }
}