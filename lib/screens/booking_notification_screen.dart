import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
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
  String? account;
  String? otp;
  String? enteredOtp;
  bool showAccountRegistration = false;
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
      onBookingReceived: (bookingData) {
        print('New booking received: $bookingData');
        setState(() {
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
      final existingBookings = await _pusherService.fetchUserBookings(userId);
      setState(() {
        _bookingNotifications = existingBookings.cast<Map<String, dynamic>>();
      });
    } catch (e) {
      print('Error fetching existing bookings: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load existing bookings: $e")),
      );
    }
  }

  void _showBookingNotification(Map<String, dynamic> bookingData) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("New booking received!"),
        action: SnackBarAction(
          label: "View",
          onPressed: () {
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

  void _showAccountRegistration(Map<String, dynamic> booking) {
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
                      Text('Register Account'),
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
                          showAccountRegistration = false;
                          otp = null;
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
                        labelText: "Account Number",
                        hintText: "09XXXXXXXXX",
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      onChanged: (value) => account = value,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your account number';
                        }
                        if (!RegExp(r'^09\d{9}$').hasMatch(value)) {
                          return 'Please enter a valid account number (09XXXXXXXXX)';
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
                          setState(() {}); // Refresh dialog
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
                        showAccountRegistration = false;
                        otp = null;
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
                      setState(() {});
                    } else {
                      await _verifyOtp(booking);
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
    if (account == null || account!.isEmpty) {
      _showError("Please enter your account number");
      return;
    }

    if (!RegExp(r'^09\d{9}$').hasMatch(account!)) {
      _showError("Please enter a valid account number (09XXXXXXXXX)");
      return;
    }

    setState(() => isSendingOtp = true);

    await Future.delayed(Duration(seconds: 2));

    final random = Random();
    setState(() {
      otp = List.generate(6, (index) => random.nextInt(10)).join();
      isSendingOtp = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("OTP Sent!", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text("Your OTP is $otp", style: TextStyle(fontSize: 16)),
            SizedBox(height: 4),
            Text("Please enter it to verify your account number"),
          ],
        ),
        duration: Duration(seconds: 10),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _resendOtp() async {
    setState(() => isSendingOtp = true);

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
            Text("New OTP Sent!", style: TextStyle(fontWeight: FontWeight.bold)),
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
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final prefs = await SharedPreferences.getInstance();
      final baseUrl = dotenv.get('BASE_URL');
      final token = prefs.getString('token') ?? '';

      final response = await http.post(
        Uri.parse('$baseUrl/api/update_account'),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"account": account}),
      );

      if (response.statusCode == 200) {
        userProvider.updateAccountNo(account ?? '');

        Navigator.of(context).pop();
        setState(() {
          showAccountRegistration = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Account number verified successfully!"),
            backgroundColor: Colors.green,
          ),
        );

        await _processBookingAcceptance(booking);
      } else {
        _showError("Failed to save Account number: ${response.body}");
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
        appBar: AppBar(title: Text("Bookings")
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar:AppBar(
      iconTheme: const IconThemeData(color: Colors.white), // Makes back/leading icon white
      title: Text(
        "Booking Notifications",
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
                  onViewPayments: () => _showPaymentDetails(booking),
                );
              },
            ),
    );
  }

  Future<void> _acceptBooking(Map<String, dynamic> booking) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.account == null || userProvider.account!.isEmpty) {
      setState(() {
        showAccountRegistration = true;
      });
      _showAccountRegistration(booking);
      return;
    }
    await _processBookingAcceptance(booking);
  }

  Future<void> _processBookingAcceptance(Map<String, dynamic> booking) async {
    try {
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

      final Map<String, dynamic> response = await _pusherService.updateBookingStatus(
        booking['id'].toString(),
        'accepted',
      );

      if (response['status'] != 'accepted') {
        throw Exception('Server did not confirm acceptance');
      }

      setState(() {
        final index = _bookingNotifications.indexWhere((b) => b['id'] == booking['id']);
        if (index != -1) {
          _bookingNotifications[index] = {
            ..._bookingNotifications[index],
            ...response,
          };
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Booking accepted")),
      );
    } catch (e) {
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

      final Map<String, dynamic> response = await _pusherService.updateBookingStatus(
        booking['id'].toString(),
        'declined',
      );

      if (response['status'] != 'declined') {
        throw Exception('Server did not confirm decline');
      }

      setState(() {
        final index = _bookingNotifications.indexWhere((b) => b['id'] == booking['id']);
        if (index != -1) {
          _bookingNotifications[index] = {
            ..._bookingNotifications[index],
            ...response,
          };
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Booking declined")),
      );
    } catch (e) {
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
  final VoidCallback onViewPayments;

  const BookingNotificationCard({
    Key? key,
    required this.booking,
    required this.onAccept,
    required this.onDecline,
    required this.onViewPayments,
  }) : super(key: key);

  String getServiceType(Map<String, dynamic> booking) {
    if (booking['type'] != null) {
      String type = booking['type'].toString().toLowerCase();
      if (type.contains('garden')) {
        return 'Gardening';
      } else if (type.contains('landscape')) {
        return 'Landscaping';
      }
      return type;
    }
    if (booking['services'] != null && booking['services'].isNotEmpty) {
      bool isLandscaping = (booking['services'] as List).any(
          (s) => s['name'].toString().toLowerCase().contains('landscape'));
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
    final hasPayments = booking['payments'] != null && 
                    (booking['payments'] as List).isNotEmpty;
    
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
            // Payment details button
            if (hasPayments || status == 'accepted' || status == 'completed')
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.payment, size: 18),
                  label: const Text(
                    "View Payment Details",
                    style: TextStyle(color: Colors.green),
                  ),
                  onPressed: onViewPayments,
                ),
              ),
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
              )
            else if (status == 'completed')
              Text(
                "Completed on ${_formatDate(booking['updated_at'])}",
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.blue,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    IconData chipIcon;
    
    switch (status) {
      case 'pending':
        chipColor = Colors.orange;
        chipIcon = Icons.pending_actions;
        break;
      case 'accepted':
        chipColor = Colors.green;
        chipIcon = Icons.check_circle;
        break;
      case 'declined':
        chipColor = Colors.red;
        chipIcon = Icons.cancel;
        break;
      case 'completed':
        chipColor = Colors.blue;
        chipIcon = Icons.task_alt;
        break;
      default:
        chipColor = Colors.grey;
        chipIcon = Icons.help_outline;
    }

    return Chip(
      label: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      avatar: Icon(
        chipIcon,
        color: Colors.white,
        size: 16,
      ),
      backgroundColor: chipColor,
      padding: EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: onDecline,
          child: Text(
            "Decline",
            style: TextStyle(color: Colors.red),
          ),
        ),
        SizedBox(width: 8),
        ElevatedButton(
          onPressed: onAccept,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: Text("Accept"),
        ),
      ],
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString).toLocal();
      return DateFormat('MMM dd, yyyy h:mm a').format(date);
    } catch (e) {
      return 'Invalid date';
    }
  }
}