import 'package:flutter/material.dart';
import 'package:gardencare_app/screens/homeowner_screen.dart';
import 'package:gardencare_app/services/booking_service.dart';

class BookingsScreen extends StatefulWidget {
  @override
  _BookingsScreenState createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  final BookingService _bookingService = BookingService();
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchHomeownerBookings();
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
                          String serviceType = "Garden Service";
                          if (booking['services'] != null && booking['services'].isNotEmpty) {
                            serviceType = booking['services'][0]['name'];
                          } else if (booking['type'] != null) {
                            serviceType = booking['type'];
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
                                    "Service Type: $serviceType",
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