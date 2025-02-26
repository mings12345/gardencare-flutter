import 'package:flutter/material.dart';
import 'booking_details_screen.dart';

class TotalBookingScreen extends StatefulWidget {
  final String userRole;

  TotalBookingScreen({required this.userRole});

  @override
  State<TotalBookingScreen> createState() => _TotalBookingScreenState();
}

class _TotalBookingScreenState extends State<TotalBookingScreen> {
  final List<Map<String, String>> allBookings = [
    {
      'id': '1',
      'name': 'Nikki',
      'address': 'Seoul',
      'date': '23 April, 2022 11:00 am',
      'price': '₹800',
      'image': 'assets/images/Nikki.jpg',
      'status': 'Pending',
      'service_name': 'Plant Care',
      'role': 'gardener',
    },
    {
      'id': '2',
      'name': 'Nina',
      'address': 'Tokyo',
      'date': '23 April, 2022 11:00 am',
      'price': '₹1050',
      'image': 'assets/images/Nina.jpg',
      'status': 'Pending',
      'service_name': 'Mowing',
      'role': 'service_provider',
    },
    {
      'id': '3',
      'name': 'Nica',
      'address': 'Seoul',
      'date': '23 April, 2022 11:00 am',
      'price': '₹800',
      'image': 'assets/images/Nica.jpg',
      'status': 'Pending',
      'service_name': 'Trimming',
      'role': 'gardener',
    },
  ];

  List<Map<String, String>> get bookings {
    return allBookings.where((booking) => booking['role'] == widget.userRole).toList();
  }

  void _updateBookingStatus(String bookingId, String newStatus) {
    setState(() {
      final booking = allBookings.firstWhere((b) => b['id'] == bookingId);
      booking['status'] = newStatus;
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Confirmed':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      case 'Canceled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Total Bookings'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index];
            final isEven = index % 1 == 0;
            return Card(
              margin: const EdgeInsets.only(bottom: 16.0),
              color: isEven ? Colors.grey[100] : Colors.white,
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Booking Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        booking['image']!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Booking Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name
                          Text(
                            booking['name']!,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Address with Icon
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  booking['address']!,
                                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Date with Icon
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  booking['date']!,
                                  style: const TextStyle(fontSize: 14, color: Colors.blue),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Service Name
                          Row(
                            children: [
                              const Icon(Icons.local_offer, size: 16, color: Colors.green),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  booking['service_name']!,
                                  style: const TextStyle(fontSize: 14, color: Colors.green),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Price
                          Text(
                            'Price: ${booking['price']}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Details Button
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                          decoration: BoxDecoration(
                            color: _getStatusColor(booking['status']!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            booking['status']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final updatedStatus = await Navigator.push<String>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BookingDetailsScreen(
                                  booking: booking,
                                  onStatusUpdate: (newStatus) {
                                    _updateBookingStatus(booking['id']!, newStatus);
                                  },
                                ),
                              ),
                            );

                            if (updatedStatus != null) {
                              _updateBookingStatus(booking['id']!, updatedStatus);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.greenAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            minimumSize: const Size(100, 36), // Ensures button does not overflow
                          ),
                          icon: const Icon(Icons.arrow_forward, size: 16),
                          label: const Text('Details'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}