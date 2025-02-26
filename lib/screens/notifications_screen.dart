import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ListTile(
            leading: const Icon(Icons.notification_important),
            title: const Text('Notification 1'),
            subtitle: const Text('This is the detail of notification 1.'),
            onTap: () {
              // Handle notification tap
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationDetailScreen(notificationId: 1)),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.notification_important),
            title: const Text('Notification 2'),
            subtitle: const Text('This is the detail of notification 2.'),
            onTap: () {
              // Handle notification tap
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationDetailScreen(notificationId: 2)),
              );
            },
          ),
          // Add more notifications here
        ],
      ),
    );
  }
}

class NotificationDetailScreen extends StatelessWidget {
  final int notificationId;

  const NotificationDetailScreen({Key? key, required this.notificationId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Detail'),
      ),
      body: Center(
        child: Text('Details for notification $notificationId'),
      ),
    );
  }
}