import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'booking_details_screen.dart';

class TotalBookingScreen extends StatefulWidget {
  final String userId;
  final String userRole; // 'gardener' or 'service_provider'
   final String authToken;

  TotalBookingScreen({required this.userId, required this.userRole, required this.authToken});

  @override
  State<TotalBookingScreen> createState() => _TotalBookingScreenState();
}

class _TotalBookingScreenState extends State<TotalBookingScreen> {
  List<Map<String, dynamic>> bookings = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    try {
  final String baseUrl = dotenv.get('BASE_URL'); 
      
      final String endpoint = widget.userRole == 'gardener'
          ? '$baseUrl/api/gardeners/${widget.userId}/bookings'
          : '$baseUrl/api/service_providers/${widget.userId}/bookings';

             print("Full Endpoint URL: $endpoint"); // Debug 2
    print("User Role: ${widget.userRole}"); // Debug 3
    print("User ID: ${widget.userId}"); // Debug 4

      final response = await http.get(Uri.parse(endpoint),
          headers: {
        'Authorization': 'Bearer ${widget.authToken}',
        'Accept': 'application/json',
      },);
       print("Response Status: ${response.statusCode}"); // Debug 5
    print("Response Body: ${response.body}"); // Debug 6

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          bookings = List<Map<String, dynamic>>.from(data['bookings'].map((booking) {
                return {
            'id': booking['id'].toString(),
            'name': booking['homeowner']['name'] ?? 'Unknown',
            'address': booking['address'] ?? 'Not specified',
            'date': _formatDate(booking['date']),
            'total_price': '₱${_calculateTotalPrice(booking['services'])}',
            'status': booking['status'] ?? 'Pending',
            'time': booking['time'] ?? 'No time specified',
            'service_names': _getServiceNames(booking['services']),
            'homeowner_image': booking['homeowner']['profile_image'] ?? 'assets/images/default_profile.jpg',
          };
          }));
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load bookings: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching bookings: $e';
        isLoading = false;
      });
    }
  }

    // Add these helper methods:
  String _getServiceNames(List<dynamic> services) {
  if (services.isEmpty) return 'No services';
  return services.map((s) => s['name']?.toString() ?? 'Unnamed Service').join(', ');
}

   double parsePrice(dynamic price) {
  if (price is num) return price.toDouble();
  if (price is String) {
    // Remove any non-numeric characters except decimal point
    String numericString = price.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(numericString) ?? 0;
  }
  return 0;
}

String _calculateTotalPrice(List<dynamic> services) {
  double total = 0;
  for (var service in services) {
    total += parsePrice(service['price']);
  }
  return total.toStringAsFixed(2);
}

  Map<String, String> _formatDateAndTime(String dateString) {
  try {
    final date = DateTime.parse(dateString);
    return {
      'date': '${date.day} ${_getMonthName(date.month)}, ${date.year}',
      'time': '${date.hour}:${date.minute.toString().padLeft(2, '0')}'
    };
  } catch (e) {
    return {'date': dateString, 'time': ''};
  }
}

// Then update your existing _formatDate method to just call this one:
String _formatDate(String dateString) {
  final dateTimeInfo = _formatDateAndTime(dateString);
  return dateTimeInfo['date'] ?? dateString;
}

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  void _updateBookingStatus(String bookingId, String newStatus) {
    setState(() {
      final booking = bookings.firstWhere((b) => b['id'] == bookingId);
      booking['status'] = newStatus;
    });
  }

  Future<void> _refreshBookings() async {
    setState(() {
      isLoading = true;
    });
    await _fetchBookings();
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
        title: Text(widget.userRole == 'gardener' ? 'My Bookings' : 'My Bookings'),
        backgroundColor: Colors.green,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshBookings,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(errorMessage),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshBookings,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (bookings.isEmpty) {
      return Center(
        child: Text(
          'No bookings found',
          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
        ),
      );
    }

    return ListView.builder(
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16.0),
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Booking Image - Fixed width
                SizedBox(
                  width: 80,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      booking['homeowner_image'] ?? 'assets/images/default_profile.jpg',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/images/default_profile.jpg',
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12), // Reduced spacing
                // Booking Details - Takes remaining space
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      Text(
                        booking['name'],
                        style: const TextStyle(
                          fontSize: 16, // Reduced font size
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Address with Icon
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              booking['address'],
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Date with Icon
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 14, color: Colors.blue),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              booking['date'],
                              style: const TextStyle(fontSize: 12, color: Colors.blue),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Service Name
                          Row(
                      children: [
                        const Icon(Icons.local_offer, size: 14, color: Colors.green),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            booking['service_names'],
                            style: const TextStyle(fontSize: 12, color: Colors.green),
                            maxLines: 2, // Allow for multiple services
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                      const SizedBox(height: 8),

                      Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: Colors.blue),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            booking['time'],
                            style: const TextStyle(fontSize: 12, color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                      // Price
                     Text(
                    'Total: ${booking['total_price']}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                    ],
                  ),
                ),
                // Details Button Column
                SizedBox(
                  width: 90, // Fixed width for the right column
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: _getStatusColor(booking['status']),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          booking['status'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity, // Make button fill available width
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final updatedStatus = await Navigator.push<String>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BookingDetailsScreen(
                                  booking: booking.map((key, value) => MapEntry(key, value.toString())),
                                  onStatusUpdate: (newStatus) {
                                    _updateBookingStatus(booking['id'], newStatus);
                                  },
                                ),
                              ),
                            );
                            if (updatedStatus != null) {
                              _updateBookingStatus(booking['id'], updatedStatus);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.greenAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                          icon: const Icon(Icons.arrow_forward, size: 14),
                          label: const Text('Details', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}