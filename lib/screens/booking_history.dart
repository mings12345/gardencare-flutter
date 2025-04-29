import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class BookingHistoryScreen extends StatefulWidget {
  final int userId;
  final String authToken;

  const BookingHistoryScreen({
    Key? key,
    required this.userId,
    required this.authToken,
  }) : super(key: key);

  @override
  _BookingHistoryScreenState createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  late Future<Map<String, dynamic>> _bookingsFuture;

  @override
  void initState() {
    super.initState();
    _bookingsFuture = _fetchAllBookings();
  }

  Future<Map<String, dynamic>> _fetchAllBookings() async {
    final url = Uri.parse('${dotenv.get('BASE_URL')}/api/bookings/all/${widget.userId}');
    
    print('Calling URL: ${url.toString()}');
    // Safely print token info for debugging
    print('Auth Token ${widget.authToken.isEmpty ? 'is empty' : 'exists'}: ${widget.authToken.isNotEmpty ? widget.authToken.length : 0} characters');
    
    // Check token before making request
    if (widget.authToken.isEmpty) {
      print('WARNING: Auth token is empty! Authentication will fail.');
    }
    
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer ${widget.authToken}',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Failed with status ${response.statusCode}, body: ${response.body}');
        throw Exception('Failed to load bookings: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Network or parsing error: $e');
      throw Exception('Connection error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Booking History'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Recent Bookings'),
              Tab(text: 'Past Bookings'),
            ],
          ),
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _bookingsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading bookings',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text('${snapshot.error}', textAlign: TextAlign.center),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _bookingsFuture = _fetchAllBookings();
                          });
                        },
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              );
            } else if (!snapshot.hasData) {
              return const Center(child: Text('No bookings found'));
            }

            final recentBookings = snapshot.data!['recent_bookings'] as List;
            final pastBookings = snapshot.data!['past_bookings'] as List;

            return TabBarView(
              children: [
                _buildBookingsList(recentBookings),
                _buildBookingsList(pastBookings),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBookingsList(List<dynamic> bookings) {
    if (bookings.isEmpty) {
      return const Center(child: Text('No bookings found'));
    }

    return ListView.builder(
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return BookingCard(
          booking: booking,
        );
      },
    );
  }
}

class BookingCard extends StatelessWidget {
  final dynamic booking;

  const BookingCard({
    Key? key,
    required this.booking,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine the other party based on booking type - handle all possible scenarios
    String otherPartyName = 'Unknown';
    String? otherPartyImage;
    
    if (booking['homeowner'] != null) {
      otherPartyName = booking['homeowner']['name'] ?? 'Homeowner';
      otherPartyImage = booking['homeowner']['profile_image'];
    } else if (booking['gardener'] != null) {
      otherPartyName = booking['gardener']['name'] ?? 'Gardener';
      otherPartyImage = booking['gardener']['profile_image'];
    } else if (booking['serviceProvider'] != null) {
      otherPartyName = booking['serviceProvider']['name'] ?? 'Service Provider';
      otherPartyImage = booking['serviceProvider']['profile_image'];
    }
    
    final services = (booking['services'] as List?)
        ?.map((s) => s['name'])
        .join(', ') ?? 'No services listed';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: otherPartyImage != null
                      ? NetworkImage(otherPartyImage)
                      : null,
                  child: otherPartyImage == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        otherPartyName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (booking['address'] != null)
                        Text(
                          booking['address'],
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  booking['status'].toString().toUpperCase(),
                  style: TextStyle(
                    color: _getStatusColor(booking['status']),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              services,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${booking['date'] ?? 'No date'} • ${booking['time'] ?? 'No time'}',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '₱${booking['total_price'] ?? '0'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'declined':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}