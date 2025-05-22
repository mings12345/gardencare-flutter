import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gardencare_app/services/pusher_service.dart';
import 'package:google_fonts/google_fonts.dart';
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
  late PusherService _pusherService; 

  @override
  void initState() {
    super.initState();
     _initializePusher(); 
    _fetchBookings();
  }   

      @override
  void dispose() {
    // Disconnect Pusher when leaving the screen
    _pusherService.disconnect(widget.userId);
    super.dispose();
  }

        void _initializePusher() {
    _pusherService = PusherService(
      authToken: widget.authToken,
      currentUserId: widget.userId,
      onMessagesFetched: (_) {}, // Not used here
      onBookingReceived: (_) {
        // Refresh bookings when a new one is received
        _refreshBookings();
      },
      onBookingUpdated: (updatedBooking) {
        print('Booking updated event received!');
        print('Updated booking data: $updatedBooking');
        // Refresh all bookings when any booking is updated
        _refreshBookings();
      },
      onError: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Pusher Error: $error"),
            backgroundColor: Colors.red,
          ),
        );
      },
    );

       _pusherService.initPusher(widget.userId).catchError((e) {
      print("Failed to initialize Pusher: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to initialize notifications: $e"),
          backgroundColor: Colors.red,
        ),
      );
    });
  } 

       Future<void> _markAsComplete(String bookingId) async {
  // First show confirmation dialog
  bool confirm = await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Confirm Completion"),
        content: Text("Are you sure you want to mark this booking as completed?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
            ),
            child: Text("Confirm", style: TextStyle(color: Colors.white)),
          ),
        ],
      );
    },
  );

  // If user didn't confirm, return without doing anything
  if (confirm != true) return;

  try {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Updating status..."),
            ],
          ),
        );
      },
    );

    final response = await _pusherService.updateBookingStatus(
      bookingId, 
      'completed'
    );

    Navigator.of(context).pop(); // Close loading dialog

    if (response['status'] == 'completed') {
      // Update local UI
      setState(() {
        final index = bookings.indexWhere((b) => b['id'] == bookingId);
        if (index != -1) {
          bookings[index]['status'] = 'Completed';
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Booking marked as completed"),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      throw Exception('Server did not confirm status update');
    }
  } catch (e) {
    // Close loading dialog if it's still open
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Failed to update booking status: $e"),
        backgroundColor: Colors.red,
      ),
    );
  }
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
            'homeowner_image': booking['homeowner']['profile_image'] ?? '',
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
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'accepted':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'canceled':
      case 'cancelled':
      case 'declined':
        return Colors.red;
      case 'completed':
        return Colors.blue.shade700;
      default:
        return Colors.grey;
    }
  }

    Widget _buildDefaultProfileImage() {
  return CircleAvatar(
    radius: 40,
    backgroundColor: Colors.grey[300],
    child: Icon(Icons.person, size: 40, color: Colors.grey[600]),
  );
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      iconTheme: const IconThemeData(color: Colors.white), // Makes back/leading icon white
      title: Text(
        widget.userRole == 'gardener' ? 'My Bookings' : 'My Bookings',
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 20,
        ),
      ),
       backgroundColor: Colors.green[800],
        centerTitle: true,
        elevation: 2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(15),
          ),
        ),
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
        final isCompleted = booking['status'].toString().toLowerCase() == 'completed';
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16.0),
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Booking Image - Fixed width
                   SizedBox(
                width: 80,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: booking['homeowner_image'] != null && 
                        booking['homeowner_image'].toString().isNotEmpty
                      ? Image.network(
                          booking['homeowner_image'],
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildDefaultProfileImage();
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[200],
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                        )
                      : _buildDefaultProfileImage(),
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
                
                // Add "Mark as Complete" button if the booking is accepted but not completed
                if (booking['status'].toString().toLowerCase() == 'accepted') 
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _markAsComplete(booking['id']),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: Icon(Icons.check_circle_outline),
                        label: Text('Mark as Complete'),
                      ),
                    ),
                  ),
                
                // Show completed message if already completed
                if (isCompleted)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Service Completed',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
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