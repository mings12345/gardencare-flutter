import 'package:flutter/material.dart';

class BookingHistoryScreen extends StatelessWidget {
  final String userRole; // homeowner, gardener, or service_provider

  const BookingHistoryScreen({Key? key, required this.userRole}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Booking History'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Recent Bookings'),
              Tab(text: 'Past Bookings'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            RecentBookingsTab(userRole: userRole),
            PastBookingsTab(userRole: userRole),
          ],
        ),
      ),
    );
  }
}

class RecentBookingsTab extends StatelessWidget {
  final String userRole;

  const RecentBookingsTab({Key? key, required this.userRole}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Example bookings for different roles
    final allBookings = [
      {
        'date': '2025-01-22',
        'time': '10:00 AM',
        'client': 'John Doe',
        'service': 'Lawn Mowing',
        'status': 'Pending',
        'role': 'homeowner',
      },
      {
        'date': '2025-01-24',
        'time': '02:00 PM',
        'client': 'Jane Smith',
        'service': 'Garden Cleaning',
        'status': 'Confirmed',
        'role': 'gardener',
      },
      {
        'date': '2025-01-26',
        'time': '01:00 PM',
        'client': 'Alice Green',
        'service': 'Landscape Design',
        'status': 'Pending',
        'role': 'service_provider',
      },
    ];

    // Filter bookings based on user role
    final filteredBookings = allBookings.where((booking) => booking['role'] == userRole).toList();

    return ListView.builder(
      itemCount: filteredBookings.length,
      itemBuilder: (context, index) {
        final booking = filteredBookings[index];
        return BookingCard(
          date: booking['date']!,
          time: booking['time']!,
          client: booking['client']!,
          service: booking['service']!,
          status: booking['status']!,
        );
      },
    );
  }
}

class PastBookingsTab extends StatelessWidget {
  final String userRole;

  const PastBookingsTab({Key? key, required this.userRole}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final allBookings = [
      {
        'date': '2025-01-15',
        'time': '11:00 AM',
        'client': 'Michael Brown',
        'service': 'Tree Pruning',
        'status': 'Completed',
        'role': 'homeowner',
      },
      {
        'date': '2025-01-10',
        'time': '03:00 PM',
        'client': 'Sarah Blue',
        'service': 'Weeding',
        'status': 'Completed',
        'role': 'gardener',
      },
      {
        'date': '2025-01-05',
        'time': '09:00 AM',
        'client': 'Ethan Grey',
        'service': 'Landscape Installation',
        'status': 'Completed',
        'role': 'service_provider',
      },
    ];

    final filteredBookings = allBookings.where((booking) => booking['role'] == userRole).toList();

    return ListView.builder(
      itemCount: filteredBookings.length,
      itemBuilder: (context, index) {
        final booking = filteredBookings[index];
        return BookingCard(
          date: booking['date']!,
          time: booking['time']!,
          client: booking['client']!,
          service: booking['service']!,
          status: booking['status']!,
        );
      },
    );
  }
}

class BookingCard extends StatelessWidget {
  final String date;
  final String time;
  final String client;
  final String service;
  final String status;

  const BookingCard({
    Key? key,
    required this.date,
    required this.time,
    required this.client,
    required this.service,
    required this.status,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text('$service with $client'),
        subtitle: Text('Date: $date, Time: $time'),
        trailing: Text(
          status,
          style: TextStyle(
            color: status == 'Pending'
                ? Colors.orange
                : status == 'Confirmed'
                    ? Colors.green
                    : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
