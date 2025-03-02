import 'package:flutter/material.dart';

class AdminTotalBookings extends StatelessWidget {
  const AdminTotalBookings({super.key});

  // Dummy data for demonstration
  final List<Map<String, dynamic>> bookings = const [
    {
      "id": "001",
      "homeownerName": "John Doe", // Ensure this key matches
      "serviceType": "Lawn Mowing",
      "bookingDate": "2023-10-15",
      "status": "Pending",
    },
    {
      "id": "002",
      "homeownerName": "Jane Smith", // Ensure this key matches
      "serviceType": "Tree Trimming",
      "bookingDate": "2023-10-16",
      "status": "Completed",
    },
    {
      "id": "003",
      "homeownerName": "Alice Johnson", // Ensure this key matches
      "serviceType": "Pest Control",
      "bookingDate": "2023-10-17",
      "status": "Cancelled",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Total Bookings"),
        backgroundColor: Colors.green,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          // Debug: Print the booking data
          print("Booking Data: $booking");

          return Card(
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Booking ID: ${booking["id"]}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text("Homeowner: ${booking["homeownerName"] ?? "N/A"}"), // Fallback for null
                  const SizedBox(height: 8),
                  Text("Service: ${booking["serviceType"]}"),
                  const SizedBox(height: 8),
                  Text("Date: ${booking["bookingDate"]}"),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        "Status: ${booking["status"]}",
                        style: TextStyle(
                          color: _getStatusColor(booking["status"]),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Helper function to get status color
  Color _getStatusColor(String status) {
    switch (status) {
      case "Pending":
        return Colors.orange;
      case "Completed":
        return Colors.green;
      case "Cancelled":
        return Colors.red;
      default:
        return Colors.black;
    }
  }
}