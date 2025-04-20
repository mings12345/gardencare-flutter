import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  @override
  void initState() {
    super.initState();
    _initializePusher();
  }

 void _initializePusher() async {
    
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final userId = prefs.getInt('userId').toString() ?? '';
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
          _bookingNotifications.insert(0, bookingData);
        });
        _showBookingNotification(bookingData);
      },
      onBookingUpdated: (updatedBooking) {
        print('Booking updated: $updatedBooking');
        setState(() {
          final index = _bookingNotifications.indexWhere(
            (b) => b['id'] == updatedBooking['id']);
          if (index != -1) {
            _bookingNotifications[index] = updatedBooking;
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
      setState(() => _isLoading = false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to initialize notifications: $e")),
      );
      setState(() => _isLoading = false);
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
    try {
      // Update the booking status via your booking service
      await _pusherService.updateBookingStatus(booking['id'].toString(), 'accepted');
      
      // Update local state
      setState(() {
        final index = _bookingNotifications.indexWhere((b) => b['id'] == booking['id']);
        if (index != -1) {
          _bookingNotifications[index]['status'] = 'accepted';
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Booking accepted")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to accept booking: $e")),
      );
    }
  }

  Future<void> _declineBooking(Map<String, dynamic> booking) async {
    try {
      // Update the booking status via your booking service
      await _pusherService.updateBookingStatus(booking['id'].toString(), 'declined');
      
      // Update local state
      setState(() {
        final index = _bookingNotifications.indexWhere((b) => b['id'] == booking['id']);
        if (index != -1) {
          _bookingNotifications[index]['status'] = 'declined';
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Booking declined")),
      );
    } catch (e) {
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

  @override
  Widget build(BuildContext context) {
    final bool isPending = booking['status'] == 'pending';

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                _buildStatusChip(booking['status']),
              ],
            ),
            SizedBox(height: 8),
            Text("Service: ${booking['type']}"),
            Text("Date: ${booking['date']}"),
            Text("Time: ${booking['time']}"),
            Text("Address: ${booking['address']}"),
            Text("Total: ₱${booking['total_price']}"),
            SizedBox(height: 8),
            if (isPending)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onDecline,
                    child: Text("Decline"),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: onAccept,
                    child: Text("Accept"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ],
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
        style: TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
      padding: EdgeInsets.symmetric(horizontal: 8),
    );
  }
}