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

   String getServiceTypes(Map<String, dynamic> booking) {
    if (booking['services'] != null && booking['services'].isNotEmpty) {
      return (booking['services'] as List).map((s) => s['name'].toString()).join(', ');
    } else if (booking['type'] != null) {
      return booking['type'].toString();
    }
    return "Garden Service";
  }
  
  @override
  Widget build(BuildContext context) {
    final status = booking['status']?.toString().toLowerCase() ?? 'pending';
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
                _buildStatusChip(status),
              ],
            ),
            SizedBox(height: 8),
            Text("Service: ${getServiceTypes(booking)}"),
            Text("Date: ${booking['date'] ?? 'Not specified'}"),
            Text("Time: ${booking['time'] ?? 'Not specified'}"),
            Text("Address: ${booking['address'] ?? 'Not specified'}"),
            Text("Total: ₱${booking['total_price']?.toString() ?? '0.00'}"),
            SizedBox(height: 8),
            
            if (status == 'pending')
              _buildActionButtons()
            else if (status == 'accepted')
              Text(
                "Accepted on ${_formatDate(booking['updated_at'])}",
                style: TextStyle(color: Colors.green),
              )
            else if (status == 'declined')
              Text(
                "Declined on ${_formatDate(booking['updated_at'])}",
                style: TextStyle(color: Colors.red),
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

  Widget _buildActionButtons() {
    return Row(
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