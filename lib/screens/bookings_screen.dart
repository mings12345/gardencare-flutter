import 'package:flutter/material.dart';
import 'package:gardencare_app/providers/user_provider.dart';
import 'package:gardencare_app/screens/homeowner_screen.dart';
import 'package:gardencare_app/services/booking_service.dart';
import 'package:gardencare_app/services/pusher_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

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
        const SnackBar(
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
        title: const Row(
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
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
              Text(
                'Total Amount: ₱${booking['total_price']}',
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 10),
              const Divider(),
              if (payments.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
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
                    const Text(
                      'Payment Transactions:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    ...payments.map((payment) => _buildPaymentCard(payment)).toList(),
                  ],
                ),
              const Divider(),
              _buildPaymentSummary(booking, payments),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Close"),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );
    },
  );
}

    void _showRatingDialog(Map<String, dynamic> booking) {
  double _rating = 0;
  final _feedbackController = TextEditingController();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.star, color: Colors.amber),
            SizedBox(width: 10),
            Text('Rate '),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How would you rate your service with ${booking['gardener']?['name'] ?? 'the gardener'}?',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              RatingBar.builder(
                initialRating: _rating,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                itemBuilder: (context, _) => const Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                onRatingUpdate: (rating) {
                  _rating = rating;
                },
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _feedbackController,
                decoration: const InputDecoration(
                  labelText: 'Feedback (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            child: const Text("Submit"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            onPressed: () async {
              if (_rating == 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select a rating')),
                );
                return;
              }

              try {
                // Show loading indicator
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 10),
                        Text("Submitting rating..."),
                      ],
                    ),
                    duration: Duration(seconds: 5),
                  ),
                );

                // Submit rating
                await _bookingService.submitRating(
                  bookingId: booking['id'],
                  rating: _rating,
                  feedback: _feedbackController.text,
                );

                // Update local state
                setState(() {
                  final index = _bookings.indexWhere((b) => b['id'] == booking['id']);
                  if (index != -1) {
                    _bookings[index] = {
                      ..._bookings[index], // Keep existing data
                      'rating': _rating,
                      'feedback': _feedbackController.text,
                    };
                  }
                });

                // Close dialog and loading indicator
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).hideCurrentSnackBar();

                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Thank you for your feedback!')),
                );

              } catch (e) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to submit rating: $e')),
                );
                print('Rating submission error details: $e');
              }
            },
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
  
    Widget _buildRatingSection(Map<String, dynamic> booking) {
   if (booking['rating'] == null) {
    return Column(
      children: [
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () => _showRatingDialog(booking),
          child: const Text(
            'Rate This Service',
            style: TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
        ),
      ],
    );
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 10),
      Text(
        "Your Rating:",
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade800,
        ),
      ),
      const SizedBox(height: 4),
      Row(
        children: [
          RatingBarIndicator(
            rating: booking['rating']?.toDouble() ?? 0,
            itemBuilder: (context, index) => const Icon(
              Icons.star,
              color: Colors.amber,
            ),
            itemCount: 5,
            itemSize: 20.0,
            direction: Axis.horizontal,
          ),
          const SizedBox(width: 8),
          Text(
            booking['rating']?.toStringAsFixed(1) ?? '0',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      if (booking['feedback'] != null && booking['feedback'].toString().isNotEmpty) ...[
        const SizedBox(height: 8),
        Text(
          "Your Feedback:",
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 4),
        Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          booking['feedback'],
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.grey.shade700,
          ),
        ),
      ),],
    ],
  );
}

    
    Widget _buildPaymentCard(Map<String, dynamic> payment) {
        var amountPaid = payment['amount_paid'] ?? 0;
  if (amountPaid is String) {
    amountPaid = double.tryParse(amountPaid) ?? 0.0;
  }
  return Card(
    margin: const EdgeInsets.only(bottom: 10),
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
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
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Date:'),
              Text(
                DateFormat('MMM dd, yyyy').format(
                  DateTime.parse(payment['payment_date']).toLocal()
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Status:'),
              Chip(
                label: Text(
                  payment['payment_status'] ?? 'Pending',
                  style: const TextStyle(
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
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('From:'),
              Text(payment['sender_no'] ?? 'N/A'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('To:'),
              Text(payment['receiver_no'] ?? 'N/A'),
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
      const Text(
        'Payment Summary:',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),

      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Payment Method:'),
          Text(
            'Garden Care',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Total Paid:'),
          Text(
            '₱${(totalPaid)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      const SizedBox(height: 4),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Remaining Balance:'),
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
        const SizedBox(height: 8),
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
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () {
          // Get the current user data from provider
          final userProvider = Provider.of<UserProvider>(context, listen: false);
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeownerScreen(
                name: userProvider.name ?? 'Default Name',
                email: userProvider.email ?? 'default@email.com',
                address: userProvider.address ?? '',
                phone: userProvider.phone ?? '',
                account: userProvider.account ?? '',
              ),
            ),
          );
        },
      ),
      title: Text(
        "My Appointments",
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600, 
          color: Colors.white,
        ),
      ),
      backgroundColor: Colors.green.shade700,
      elevation: 0,
      centerTitle: true,
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
          ? const Center(
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
                      const SizedBox(height: 16),
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
                          const SizedBox(height: 16),
                          Text(
                            "No Appointments found",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Your appointments will appear here",
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
                        padding: const EdgeInsets.all(12),
                        itemCount: _bookings.length,
                        itemBuilder: (context, index) {
                          final booking = _bookings[index];
                          final serviceType = booking['type']?.toString() ?? "Garden Service";
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                // Service Type Tag
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  decoration: BoxDecoration(
                                    color: getServiceColor(booking).withOpacity(0.8),
                                    borderRadius: const BorderRadius.only(
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
                                        const SizedBox(width: 6),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.confirmation_number_outlined, 
                                               size: 18, 
                                               color: Colors.grey.shade600),
                                          const SizedBox(width: 8),
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
                                      const SizedBox(height: 12),
                                      
                                      
                                      if (booking['gardener'] != null) ...[
                                        _buildInfoRow(
                                          Icons.person_outline,
                                          "Gardener",
                                          booking['gardener']['name'],
                                        ),
                                        const SizedBox(height: 10),
                                      ]else if (booking['service_provider'] != null) ...[
                                    _buildInfoRow(
                                      Icons.person_outline,
                                      "Service Provider",
                                      booking['service_provider']['name'],
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                                                        
                                      _buildInfoRow(
                                        Icons.location_on_outlined,
                                        "Address",
                                        booking['address'] ?? 'Not specified',
                                      ),
                                      const SizedBox(height: 10),
                                      
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
                                      const SizedBox(height: 10),
                                      
                                      _buildInfoRow(
                                        Icons.event_note_outlined,
                                        "Created on",
                                        booking['created_at'] != null 
                                          ? DateFormat('MMM dd, yyyy').format(
                                              DateTime.parse(booking['created_at']).toLocal()
                                            )
                                          : 'Not available',
                                      ),
                                      const SizedBox(height: 10),
                                      
                                      if (booking['special_instructions'] != null &&
                                          booking['special_instructions'].toString().isNotEmpty) ...[
                                        const SizedBox(height: 16),
                                        Text(
                                          "Special Instructions:",
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade800,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.all(12),
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
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            icon: const Icon(Icons.payment, size: 18),
                            label: const Text(
                              "View Payment Details",
                              style: TextStyle(color: Colors.green),
                            ),
                            onPressed: () => _showPaymentDetails(booking),
                          ),
                        ),
                      ],
                           if (booking['status']?.toLowerCase() == 'completed') ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _buildRatingSection(booking),
                          ),
                          const SizedBox(height: 16),
                                            ],
                              ]),
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
        const SizedBox(width: 8),
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