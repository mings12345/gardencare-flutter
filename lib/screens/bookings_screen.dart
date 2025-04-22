import 'package:flutter/material.dart';
import 'package:gardencare_app/screens/homeowner_screen.dart';
import 'package:gardencare_app/services/booking_service.dart';
import 'package:gardencare_app/services/pusher_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookingsScreen extends StatefulWidget {
  @override
  _BookingsScreenState createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
    late PusherService _pusherService;
  final BookingService _bookingService = BookingService();
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
      _initializePusher();
    _fetchHomeownerBookings();
  }
    
     void _initializePusher() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final userId = prefs.getInt('userId')?.toString() ?? '';
    
    if (userId.isEmpty) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("User ID not found")),
      );
      return;
    }

     _pusherService = PusherService(
      authToken: token,
      currentUserId: userId,
      onMessagesFetched: (_) {}, 
      onBookingReceived: (_) {
        // Refresh bookings when a new one is received
        _fetchHomeownerBookings();
      },
      onBookingUpdated: (updatedBooking) {
        print('Booking updated event received in BookingsScreen!');
        print('Updated booking data: $updatedBooking');
        // Update the specific booking in our list
        setState(() {
          final index = _bookings.indexWhere((b) => b['id'] == updatedBooking['id']);
          if (index != -1) {
            _bookings[index] = updatedBooking;
          } else {
            // If not found, refresh all bookings
            _fetchHomeownerBookings();
          }
        });
      },
      onError: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Pusher Error: $error")),
        );
      },
    );
    
    try {
      await _pusherService.initPusher(userId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to initialize notifications: $e")),
      );
    }
  }


  @override
  void dispose() {
    // Make sure to disconnect Pusher when leaving the screen
    final prefs = SharedPreferences.getInstance();
    prefs.then((value) {
      final userId = value.getInt('userId').toString();
      if (userId.isNotEmpty) {
        _pusherService.disconnect(userId);
      }
    });
    super.dispose();
  }

  Future<void> _fetchHomeownerBookings() async {
    try {
      final bookings = await _bookingService.fetchHomeownerBookings();
    print(bookings);

      setState(() {
        _bookings = bookings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load bookings: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Booking Details"),
        backgroundColor: Colors.green,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            // Replace the current screen with the homeowner screen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomeownerScreen(name: '', email: '', address: '', phone: '',)),
            );
          },
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: Colors.red)))
              : _bookings.isEmpty
                  ? Center(
                      child: Text("No bookings found.", style: TextStyle(fontSize: 18)),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchHomeownerBookings,
                      child: ListView.builder(
                        itemCount: _bookings.length,
                        itemBuilder: (context, index) {
                          final booking = _bookings[index];
                          // Extract service type from services relationship if available
                                        String getServiceTypes(Map<String, dynamic> booking) {
                    if (booking['services'] != null && booking['services'].isNotEmpty) {
                      return (booking['services'] as List).map((s) => s['name'].toString()).join(', ');
                    } else if (booking['type'] != null) {
                      return booking['type'].toString();
                    }
                    return "Garden Service";
                  }
                          
                          return Card(
                            margin: EdgeInsets.all(10),
                            elevation: 3,
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                  "Service Type: ${getServiceTypes(booking)}",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                  SizedBox(height: 5),
                                  if (booking['gardener'] != null)
                                    Text("Gardener: ${booking['gardener']['name']}"),
                                  Text("Address: ${booking['address'] ?? 'Not specified'}"),
                                  Text("Date: ${booking['date'] ?? 'Not specified'}"),
                                  Text("Time: ${booking['time'] ?? 'Not specified'}"),
                                  Text(
                                    "Total Price: ₱${(booking['total_price'] ?? 0).toString()}",
                                    style: TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  if (booking['special_instructions'] != null &&
                                      booking['special_instructions'].toString().isNotEmpty)
                                    Text("Special Instructions: ${booking['special_instructions']}"),
                                  SizedBox(height: 5),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(booking['status']).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      "Status: ${booking['status'] ?? 'Pending'}",
                                      style: TextStyle(
                                        color: _getStatusColor(booking['status']),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
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
  
  Color _getStatusColor(String? status) {
    switch(status?.toString().toLowerCase() ?? 'pending') {
      case 'confirmed': return Colors.green;
      case 'completed': return Colors.blue;
      case 'pending': return Colors.orange;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }
}