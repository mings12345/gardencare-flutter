import 'package:flutter/material.dart';
import 'package:gardencare_app/screens/homeowner_screen.dart';
import 'package:gardencare_app/services/booking_service.dart';
import 'package:gardencare_app/services/pusher_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

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
        SnackBar(
          content: Text("User ID not found"),
          backgroundColor: Colors.red,
        ),
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
          SnackBar(
            content: Text("Pusher Error: $error"),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
    
    try {
      await _pusherService.initPusher(userId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to initialize notifications: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  void _showPaymentDetails(Map<String, dynamic> booking) {
  final payments = booking['payments'] ?? [];
  
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Row(
          children: [
            Icon(Icons.payment, color: Colors.green),
            SizedBox(width: 10),
            Text('Payment Details'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Booking #${booking['id'] ?? ''}',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 10),
              Text(
                'Total Amount: ₱${booking['total_price']}',
                style: TextStyle(fontSize: 15),
              ),
              SizedBox(height: 10),
              Divider(),
              if (payments.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(
                    child: Text(
                      'No payment records found',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Transactions:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    ...payments.map((payment) => _buildPaymentCard(payment)).toList(),
                  ],
                ),
              Divider(),
              _buildPaymentSummary(booking, payments),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text("Close"),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );
    },
  );
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
    
    Widget _buildPaymentCard(Map<String, dynamic> payment) {
        var amountPaid = payment['amount_paid'] ?? 0;
  if (amountPaid is String) {
    amountPaid = double.tryParse(amountPaid) ?? 0.0;
  }
  return Card(
    margin: EdgeInsets.only(bottom: 10),
    elevation: 2,
    child: Padding(
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Amount Paid:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                 '₱${(amountPaid)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Date:'),
              Text(
                DateFormat('MMM dd, yyyy • h:mm a').format(
                  DateTime.parse(payment['payment_date']).toLocal()
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Status:'),
              Chip(
                label: Text(
                  payment['payment_status'] ?? 'Pending',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
                backgroundColor: payment['payment_status'] == 'Received' 
                  ? Colors.green 
                  : Colors.orange,
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('From:'),
              Text(payment['sender_gcash_no'] ?? 'N/A'),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('To:'),
              Text(payment['receiver_gcash_no'] ?? 'N/A'),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _buildPaymentSummary(Map<String, dynamic> booking, List<dynamic> payments) {
    final totalPaid = payments.fold(0.0, (sum, payment) {
    var amountPaid = payment['amount_paid'] ?? 0;
    // Convert to double if it's a string
    if (amountPaid is String) {
      amountPaid = double.tryParse(amountPaid) ?? 0.0;
    }
    return sum + (amountPaid as num);
  });
  
    var totalPrice = booking['total_price'] ?? 0;
  if (totalPrice is String) {
    totalPrice = double.tryParse(totalPrice) ?? 0.0;
  }

    final remainingBalance = (totalPrice as num) - totalPaid;
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Payment Summary:',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Total Paid:'),
          Text(
            '₱${(totalPaid)}',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      SizedBox(height: 4),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Remaining Balance:'),
          Text(
            '₱${(remainingBalance)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: remainingBalance > 0 ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
      if (remainingBalance > 0) ...[
        SizedBox(height: 8),
        Text(
          'Note: Remaining balance of ₱${remainingBalance} will be automatically deducted to your account after completion.',
          style: TextStyle(
            color: Colors.orange.shade700,
            fontStyle: FontStyle.italic,
            fontSize: 12,
          ),
        ),
      ],
    ],
  );
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

  String getServiceTypes(Map<String, dynamic> booking) {
    if (booking['services'] != null && booking['services'].isNotEmpty) {
      return (booking['services'] as List).map((s) => s['name'].toString()).join(', ');
    } else if (booking['type'] != null) {
      return booking['type'].toString();
    }
    return "Garden Service";
  }

  IconData getServiceIcon(Map<String, dynamic> booking) {
    String serviceType = '';
    
    if (booking['type'] != null) {
      serviceType = booking['type'].toString().toLowerCase();
    }
    
    if (serviceType.contains('landscap')) {
      return Icons.landscape;
    } else if (serviceType.contains('garden')) {
      return Icons.yard;
    }
    
    return Icons.grass; // Default icon
  }

  Color getServiceColor(Map<String, dynamic> booking) {
    String serviceType = '';
    
    if (booking['type'] != null) {
      serviceType = booking['type'].toString().toLowerCase();
    }
    
    if (serviceType.contains('landscap')) {
      return Colors.blue.shade700;
    } else if (serviceType.contains('garden')) {
      return Colors.green.shade700;
    }
    
    return Colors.teal.shade700; // Default color
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "My Bookings",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.green.shade700,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomeownerScreen(name: '', email: '', address: '', phone: '', gcashNo: '',)),
            );
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade50, Colors.white],
          ),
        ),
        child: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
                      SizedBox(height: 16),
                      Text(
                        _error!,
                        style: GoogleFonts.poppins(
                          color: Colors.red.shade700,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : _bookings.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today_outlined, 
                            size: 80, 
                            color: Colors.green.shade200
                          ),
                          SizedBox(height: 16),
                          Text(
                            "No bookings found",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Your booking history will appear here",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchHomeownerBookings,
                      color: Colors.green,
                      child: ListView.builder(
                        padding: EdgeInsets.all(12),
                        itemCount: _bookings.length,
                        itemBuilder: (context, index) {
                          final booking = _bookings[index];
                          final serviceType = booking['type']?.toString() ?? "Garden Service";
                          
                          return Card(
                            margin: EdgeInsets.only(bottom: 16),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                // Service Type Tag
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(vertical: 6),
                                  decoration: BoxDecoration(
                                    color: getServiceColor(booking).withOpacity(0.8),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      topRight: Radius.circular(16),
                                    ),
                                  ),
                                  child: Center(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          getServiceIcon(booking),
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          serviceType.toUpperCase(),
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                
                                // Header section with service type and status
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                  ),
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          getServiceTypes(booking),
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.green.shade800,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(booking['status']).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          booking['status'] ?? 'Pending',
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: _getStatusColor(booking['status']),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Booking details section
                                Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.confirmation_number_outlined, 
                                               size: 18, 
                                               color: Colors.grey.shade600),
                                          SizedBox(width: 8),
                                          Text(
                                            "Booking #${booking['id'] ?? ''}",
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 12),
                                      
                                      
                                      if (booking['gardener'] != null) ...[
                                        _buildInfoRow(
                                          Icons.person_outline,
                                          "Gardener",
                                          booking['gardener']['name'],
                                        ),
                                        SizedBox(height: 10),
                                      ],
                                      
                                      _buildInfoRow(
                                        Icons.location_on_outlined,
                                        "Address",
                                        booking['address'] ?? 'Not specified',
                                      ),
                                      SizedBox(height: 10),
                                      
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildInfoRow(
                                              Icons.calendar_today_outlined,
                                              "Date",
                                              booking['date'] ?? 'Not specified',
                                            ),
                                          ),
                                          Expanded(
                                            child: _buildInfoRow(
                                              Icons.access_time_outlined,
                                              "Time",
                                              booking['time'] ?? 'Not specified',
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 10),
                                      
                                      _buildInfoRow(
                                        Icons.event_note_outlined,
                                        "Created on",
                                        booking['created_at'] != null 
                                          ? DateFormat('MMM dd, yyyy • h:mm a').format(
                                              DateTime.parse(booking['created_at']).toLocal()
                                            )
                                          : 'Not available',
                                      ),
                                      SizedBox(height: 10),
                                      
                                      if (booking['special_instructions'] != null &&
                                          booking['special_instructions'].toString().isNotEmpty) ...[
                                        SizedBox(height: 16),
                                        Text(
                                          "Special Instructions:",
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade800,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Container(
                                          padding: EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            booking['special_instructions'],
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ),
                                      ],
                                      if ((booking['payments'] != null && booking['payments'].isNotEmpty) || 
                          (booking['payment_status'] != null && booking['payment_status'] != 'pending')) ...[
                        SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            icon: Icon(Icons.payment, size: 18),
                            label: Text(
                              "View Payment Details",
                              style: TextStyle(color: Colors.green),
                            ),
                            onPressed: () => _showPaymentDetails(booking),
                          ),
                        ),
                      ],
                                                        ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
      ),
    );
  }
  
  Widget _buildInfoRow(IconData icon, String label, String value, {bool isHighlighted = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon, 
          size: 18, 
          color: isHighlighted ? Colors.green.shade700 : Colors.grey.shade600
        ),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w500,
                  color: isHighlighted ? Colors.green.shade700 : Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Color _getStatusColor(String? status) {
    switch(status?.toString().toLowerCase() ?? 'pending') {
      case 'confirmed': 
      case 'accepted': return Colors.green.shade700;
      case 'completed': return Colors.blue.shade700;
      case 'pending': return Colors.orange.shade700;
      case 'cancelled': 
      case 'declined': return Colors.red.shade700;
      default: return Colors.grey.shade700;
    }
  }
}