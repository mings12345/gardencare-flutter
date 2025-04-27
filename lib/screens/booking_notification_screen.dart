import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:gardencare_app/providers/user_provider.dart';
import 'package:gardencare_app/services/pusher_service.dart';

class BookingNotificationsScreen extends StatefulWidget {
  @override
  _BookingNotificationsScreenState createState() => _BookingNotificationsScreenState();
}

class _BookingNotificationsScreenState extends State<BookingNotificationsScreen> {
  late PusherService _pusherService;
  List<Map<String, dynamic>> _bookingNotifications = [];
  bool _isLoading = true;
  String? gcashNo;
  String? otp;
  String? enteredOtp;
  bool showGcashRegistration = false;
  bool isSendingOtp = false;
  bool isVerifyingOtp = false;
  

  @override
  void initState() {
    super.initState();
    _initializePusher();
  }

 void _initializePusher() async {
    
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final userId = prefs.getInt('userId')?.toString() ?? '';
    // Get the user ID from the provider (should match Laravel's user ID)
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
      onMessagesFetched: (_) {}, // Not used here
      onBookingReceived: (bookingData) {
        print('New booking received: $bookingData');
         setState(() {
        // Check if booking already exists before adding
        if (!_bookingNotifications.any((b) => b['id'] == bookingData['id'])) {
          _bookingNotifications.insert(0, bookingData);
        }
      });
        _showBookingNotification(bookingData);
      },
      onBookingUpdated: (updatedBooking) {
        print('Booking updated: $updatedBooking');
        setState(() {
          final index = _bookingNotifications.indexWhere(
            (b) => b['id'] == updatedBooking['id']);
               if (index != -1) {
          // Only update if something actually changed
          if (_bookingNotifications[index]['status'] != updatedBooking['status'] ||
              _bookingNotifications[index]['updated_at'] != updatedBooking['updated_at']) {
            _bookingNotifications[index] = updatedBooking;
          }
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
       await _fetchExistingBookings(userId);
      setState(() => _isLoading = false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to initialize notifications: $e")),
      );
      setState(() => _isLoading = false);
    }
  }
    
   Future<void> _fetchExistingBookings(String userId) async {
  try {
    print('Fetching bookings for user ID: $userId');
    
    // This is where you fetch the bookings
    final existingBookings = await _pusherService.fetchUserBookings(userId);
    
    print('API returned bookings: $existingBookings');
    print('Bookings type: ${existingBookings.runtimeType}');
    
    if (existingBookings.isEmpty) {
      print('Returned bookings list is empty');
    }
    
    // Ensure each booking has all the required fields
    for (var booking in existingBookings) {
      print('Booking: $booking');
      print('Booking contains id: ${booking.containsKey('id')}');
      print('Booking contains status: ${booking.containsKey('status')}');
      print('Booking contains type: ${booking.containsKey('type')}');
      // Add other field checks as needed
    }
    
    setState(() {
      _bookingNotifications = existingBookings.cast<Map<String, dynamic>>();
      print('Updated _bookingNotifications: $_bookingNotifications');
    });
  } catch (e) {
    print('Error fetching existing bookings: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Failed to load existing bookings: $e")),
    );
  }
}


  void _showBookingNotification(Map<String, dynamic> bookingData) {
    // Show a notification to the user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("New booking received!"),
        action: SnackBarAction(
          label: "View",
          onPressed: () {
            // Navigate to booking details
            Navigator.pushNamed(
              context, 
              '/booking_details',
              arguments: bookingData,
            );
          },
        ),
      ),
    );
  }

    void _showGcashRegistration(Map<String, dynamic> booking) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Stack(
              children: [
                Row(
                  children: [
                    Icon(Icons.phone_android, color: Colors.green),
                    SizedBox(width: 10),
                    Text('Register GCash   '),
                  ],
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () {
                      Navigator.of(context).pop();
                      setState(() {
                        showGcashRegistration = false;
                        otp = null; // Reset OTP if user cancels
                      });
                    },
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: "GCash Mobile Number",
                      hintText: "09XXXXXXXXX",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    onChanged: (value) => gcashNo = value,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your GCash number';
                      }
                      if (!RegExp(r'^09\d{9}$').hasMatch(value)) {
                        return 'Please enter a valid GCash number (09XXXXXXXXX)';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  if (otp != null) ...[
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: "Enter OTP",
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => enteredOtp = value,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the OTP';
                        }
                        if (value.length != 6) {
                          return 'OTP must be 6 digits';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10),
                    TextButton(
                      onPressed: () {
                        _resendOtp();
                        setState(() {}); // Refresh the dialog
                      },
                      child: Text("Resend OTP"),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              if (otp == null)
                TextButton(
                  child: Text("Cancel"),
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      showGcashRegistration = false;
                      otp = null; // Reset OTP if user cancels
                    });
                  },
                ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: isSendingOtp || isVerifyingOtp
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(otp == null ? "Send OTP" : "Verify OTP"),
                onPressed: () async {
                  if (otp == null) {
                    await _sendOtp();
                    setState(() {}); // Refresh the dialog to show OTP field
                  } else {
                    await _verifyOtp(booking); // Pass the booking to verification
                  }
                },
              ),
            ],
          );
        },
      );
    },
  );
}   

    Future<void> _sendOtp() async {
  if (gcashNo == null || gcashNo!.isEmpty) {
    _showError("Please enter your GCash number");
    return;
  }

  if (!RegExp(r'^09\d{9}$').hasMatch(gcashNo!)) {
    _showError("Please enter a valid GCash number (09XXXXXXXXX)");
    return;
  }

  setState(() => isSendingOtp = true);

  // Simulate OTP sending
  await Future.delayed(Duration(seconds: 2));

  // Generate random 6-digit OTP
  final random = Random();
  setState(() {
    otp = List.generate(6, (index) => random.nextInt(10)).join();
    isSendingOtp = false;
  });

  // Show fancy OTP message
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("GCash OTP Sent!", style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text("Your OTP is $otp", style: TextStyle(fontSize: 16)),
          SizedBox(height: 4),
          Text("Please enter it to verify your GCash number"),
        ],
      ),
      duration: Duration(seconds: 10),
      backgroundColor: Colors.green,
    ),
  );
}

Future<void> _resendOtp() async {
  setState(() => isSendingOtp = true);
  
  // Generate new random 6-digit OTP
  final random = Random();
  otp = List.generate(6, (index) => random.nextInt(10)).join();
  
  await Future.delayed(Duration(seconds: 1));
  
  setState(() => isSendingOtp = false);
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("New GCash OTP Sent!", style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text("Your new OTP is $otp", style: TextStyle(fontSize: 16)),
        ],
      ),
      duration: Duration(seconds: 10),
      backgroundColor: Colors.green,
    ),
  );
}

Future<void> _verifyOtp(Map<String, dynamic> booking) async {
  if (enteredOtp == null || enteredOtp!.isEmpty) {
    _showError("Please enter the OTP");
    return;
  }

  if (enteredOtp!.length != 6) {
    _showError("OTP must be 6 digits");
    return;
  }

  if (enteredOtp != otp) {
    _showError("Invalid OTP. Please try again.");
    return;
  }

  setState(() => isVerifyingOtp = true);

  try {
    // Save GCash number to backend
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = dotenv.get('BASE_URL');
    final token = prefs.getString('token') ?? '';

    final response = await http.post(
      Uri.parse('$baseUrl/api/update_gcash'),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"gcash_no": gcashNo}),
    );

    if (response.statusCode == 200) {
      // Update user provider
      userProvider.updateGcashNo(gcashNo!);
      
      // Close dialog
      Navigator.of(context).pop();
      setState(() {
        showGcashRegistration = false;
      });
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("GCash number verified successfully!"),
          backgroundColor: Colors.green,
        ),
      );
      
      // Now proceed with booking acceptance
      await _processBookingAcceptance(booking);
    } else {
      _showError("Failed to save GCash number: ${response.body}");
    }
  } catch (e) {
    _showError("Error: ${e.toString()}");
  } finally {
    setState(() => isVerifyingOtp = false);
  }
}

void _showError(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    ),
  );
}

  @override
  void dispose() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final String userId = userProvider.user?['gardener_id']?.toString() ?? 
                     userProvider.user?['serviceprovider_id']?.toString() ?? '';
    
    if (userId.isNotEmpty) {
      _pusherService.disconnect(userId);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text("Bookings")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Booking Notifications"),
        backgroundColor: Colors.green,
      ),
      body: _bookingNotifications.isEmpty
          ? Center(child: Text("No booking notifications yet"))
          : ListView.builder(
              itemCount: _bookingNotifications.length,
              itemBuilder: (context, index) {
                final booking = _bookingNotifications[index];
                return BookingNotificationCard(
                  booking: booking,
                  onAccept: () => _acceptBooking(booking),
                  onDecline: () => _declineBooking(booking),
                );
              },
            ),
    );
  }

      Future<void> _acceptBooking(Map<String, dynamic> booking) async {
         final userProvider = Provider.of<UserProvider>(context, listen: false);
          if (userProvider.gcashNo == null || userProvider.gcashNo!.isEmpty) {
    setState(() {
      showGcashRegistration = true;
    });
    _showGcashRegistration(booking); // Pass the booking to the dialog
    return;
  }
    await _processBookingAcceptance(booking);
  try {
    // Optimistic UI update
    setState(() {
      final index = _bookingNotifications.indexWhere((b) => b['id'] == booking['id']);
      if (index != -1) {
        _bookingNotifications[index] = {
          ..._bookingNotifications[index],
          'status': 'accepted',
          'updated_at': DateTime.now().toIso8601String(),
        };
      }
    });

    // Send update to server and await the response
    final Map<String, dynamic> response = await _pusherService.updateBookingStatus(
      booking['id'].toString(), 
      'accepted'
    );

    // Verify the response matches our update
    if (response['status'] != 'accepted') {
      throw Exception('Server did not confirm acceptance');
    }

    // Update with server's response which might have additional fields
    setState(() {
      final index = _bookingNotifications.indexWhere((b) => b['id'] == booking['id']);
      if (index != -1) {
        _bookingNotifications[index] = {
          ..._bookingNotifications[index],
          ...response, // Merge with server response
        };
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Booking accepted")),
    );
  } catch (e) {
    // Revert on failure
    setState(() {
      final index = _bookingNotifications.indexWhere((b) => b['id'] == booking['id']);
      if (index != -1) {
        _bookingNotifications[index]['status'] = 'pending';
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Failed to accept booking: $e")),
    );
  }
}
    Future<void> _processBookingAcceptance(Map<String, dynamic> booking) async {
  try {
    // Optimistic UI update
    setState(() {
      final index = _bookingNotifications.indexWhere((b) => b['id'] == booking['id']);
      if (index != -1) {
        _bookingNotifications[index] = {
          ..._bookingNotifications[index],
          'status': 'accepted',
          'updated_at': DateTime.now().toIso8601String(),
        };
      }
    });

    // Send update to server and await the response
    final Map<String, dynamic> response = await _pusherService.updateBookingStatus(
      booking['id'].toString(), 
      'accepted'
    );

    // Verify the response matches our update
    if (response['status'] != 'accepted') {
      throw Exception('Server did not confirm acceptance');
    }

    // Update with server's response which might have additional fields
    setState(() {
      final index = _bookingNotifications.indexWhere((b) => b['id'] == booking['id']);
      if (index != -1) {
        _bookingNotifications[index] = {
          ..._bookingNotifications[index],
          ...response, // Merge with server response
        };
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Booking accepted")),
    );
  } catch (e) {
    // Revert on failure
    setState(() {
      final index = _bookingNotifications.indexWhere((b) => b['id'] == booking['id']);
      if (index != -1) {
        _bookingNotifications[index]['status'] = 'pending';
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Failed to accept booking: $e")),
    );
  }
}
  Future<void> _declineBooking(Map<String, dynamic> booking) async {
  try {
    // Optimistic UI update
    setState(() {
      final index = _bookingNotifications.indexWhere((b) => b['id'] == booking['id']);
      if (index != -1) {
        _bookingNotifications[index] = {
          ..._bookingNotifications[index],
          'status': 'declined',
          'updated_at': DateTime.now().toIso8601String(),
        };
      }
    });

    // Send update to server and await the response
    final Map<String, dynamic> response = await _pusherService.updateBookingStatus(
      booking['id'].toString(), 
      'declined'
    );

    // Verify the response
    if (response['status'] != 'declined') {
      throw Exception('Server did not confirm decline');
    }

    // Update with server's response
    setState(() {
      final index = _bookingNotifications.indexWhere((b) => b['id'] == booking['id']);
      if (index != -1) {
        _bookingNotifications[index] = {
          ..._bookingNotifications[index],
          ...response, // Merge with server response
        };
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Booking declined")),
    );
  } catch (e) {
    // Revert on failure
    setState(() {
      final index = _bookingNotifications.indexWhere((b) => b['id'] == booking['id']);
      if (index != -1) {
        _bookingNotifications[index]['status'] = 'pending';
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Failed to decline booking: $e")),
    );
  }
}

 
}

class BookingNotificationCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const BookingNotificationCard({
    Key? key,
    required this.booking,
    required this.onAccept,
    required this.onDecline,
  }) : super(key: key);

   String getServiceType(Map<String, dynamic> booking) {
    // First check if there's an explicit type
    if (booking['type'] != null) {
      String type = booking['type'].toString().toLowerCase();
      if (type.contains('garden')) {
        return 'Gardening';
      } else if (type.contains('landscape')) {
        return 'Landscaping';
      }
      return type;
    }
    
    // If no explicit type, infer from services
    if (booking['services'] != null && booking['services'].isNotEmpty) {
      // Check if any service name suggests landscaping
      bool isLandscaping = (booking['services'] as List).any((s) => 
          s['name'].toString().toLowerCase().contains('landscape'));
      
      return isLandscaping ? 'Landscaping' : 'Gardening';
    }
    
    return "Garden Service";
  }

  String getServiceDetails(Map<String, dynamic> booking) {
    if (booking['services'] != null && booking['services'].isNotEmpty) {
      return (booking['services'] as List)
          .map((s) => s['name'].toString())
          .join(', ');
    }
    return booking['type']?.toString() ?? 'General Service';
  }
  
  @override
  Widget build(BuildContext context) {
    final status = booking['status']?.toString().toLowerCase() ?? 'pending';
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Booking #${booking['id']}",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.grey[800],
                  ),
                ),
                _buildStatusChip(status),
              ],
            ),
            SizedBox(height: 12),
            if (booking['homeowner'] != null) 
              Text(
                "Homeowner: ${booking['homeowner']['name'] ?? 'Not specified'}",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            SizedBox(height: 8),
            Text(
              "Service Type: ${getServiceType(booking)}",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.green[700],
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Services: ${getServiceDetails(booking)}",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Date: ${booking['date'] ?? 'Not specified'}",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Time: ${booking['time'] ?? 'Not specified'}",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Address: ${booking['address'] ?? 'Not specified'}",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Total: ₱${booking['total_price']?.toString() ?? '0.00'}",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.green[800],
              ),
            ),
            SizedBox(height: 12),
            
            if (status == 'pending')
              _buildActionButtons()
            else if (status == 'accepted')
              Text(
                "Accepted on ${_formatDate(booking['updated_at'])}",
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.green,
                  fontStyle: FontStyle.italic,
                ),
              )
            else if (status == 'declined')
              Text(
                "Declined on ${_formatDate(booking['updated_at'])}",
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.red,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'accepted':
        color = Colors.green;
        break;
      case 'declined':
        color = Colors.red;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(
        status.toUpperCase(),
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: color,
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: onDecline,
          child: Text(
            "DECLINE",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          style: TextButton.styleFrom(
            foregroundColor: Colors.red[700],
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        SizedBox(width: 8),
        ElevatedButton(
          onPressed: onAccept,
          child: Text(
            "ACCEPT",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[700],
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'unknown time';
    try {
      final date = DateTime.parse(dateString).toLocal();
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'unknown time';
    }
  }
}