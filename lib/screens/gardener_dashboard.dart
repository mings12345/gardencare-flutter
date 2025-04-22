import 'package:flutter/material.dart';
import 'package:gardencare_app/providers/user_provider.dart';
import 'package:gardencare_app/screens/booking_notification_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gardencare_app/screens/booking_history.dart';
import 'package:gardencare_app/screens/feedback_screen.dart';
import 'package:gardencare_app/screens/gardener_profile.dart';
import 'package:gardencare_app/services/booking_service.dart';
import 'calendar_screen.dart';
import 'chat_list_screen.dart';
import 'total_booking.dart';
import 'total_service_screen.dart';
import 'total_earnings.dart';

class GardenerDashboard extends StatefulWidget { 
  final String name;
  final String role;
  final String email;
  final String phone;
  final String address;

  GardenerDashboard({
    required this.name,
    required this.role,
    required this.email,
    required this.phone,
    required this.address,
  });

  @override
  _GardenerDashboardState createState() => _GardenerDashboardState();
}

class _GardenerDashboardState extends State<GardenerDashboard> {
  int bookingCount = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBookingCount();
  }

  Future<void> _fetchBookingCount() async {
    try {
      final bookingService = BookingService();
      final count = await bookingService.fetchBookingCount();
      
      setState(() {
        bookingCount = count;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching booking count: $e');
      // Optionally show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load booking count')),
      );
    }
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 17, 101, 90),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gardener Dashboard'),
        backgroundColor: Colors.green,
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xff00b300), Color(0xff006600)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundImage: AssetImage('assets/images/anne.jpg'),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.name, // Changed to widget.name
                    style: const TextStyle(color: Colors.white, fontSize: 24),
                  ),
                  const Text(
                    'Gardener',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.account_circle),
              title: const Text('My Profile'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GardenerProfile(
                      name: widget.name, // Changed to widget.name
                      role: widget.role,
                      email: widget.email,
                      phone: widget.phone,
                      address: widget.address,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.book),
              title: const Text('Booking History'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BookingHistoryScreen(userRole: 'gardener'),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.message),
              title: const Text('Messages'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatListScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Calendar'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CalendarScreen(userRole: 'gardener', loggedInUser: ''),
                  ),
                ); // Navigate to CalendarScreen
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notifications'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BookingNotificationsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.feedback),
              title: const Text('View Feedback'), // New ListTile for Feedback
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FeedbackScreen()),
                );
              },
            ),
            const Divider(), // Adds another separator before logout
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirm Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context), // Close dialog
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () async {
                          // Clear any stored user data here
                          SharedPreferences prefs = await SharedPreferences.getInstance();
                          await prefs.clear();
                          Navigator.pop(context); // Close dialog
                          Navigator.pushReplacementNamed(context, '/'); // Navigate to login screen
                        },
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hello, Gardener',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Welcome back!',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                GestureDetector(
                  onTap: () {
                    final user = Provider.of<UserProvider>(context, listen: false);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TotalBookingScreen(
                          userId: user.userId!, // Add ! to force non-nullable
                          userRole: user.role!,
                          authToken: user.token!,
                        ),
                      ),
                    );
                  },
                  child: isLoading
                      ? _buildLoadingCard()
                      : _buildDashboardCard(bookingCount.toString(), 'Total Booking', Icons.calendar_today),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => TotalServiceScreen(userRole: 'gardener')),
                    );
                  },
                  child: _buildDashboardCard('3', 'Total Service', Icons.list_alt),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => TotalEarningsScreen()),
                    );
                  },
                  child: _buildDashboardCard('\$19,906.97', 'Total Earning', Icons.monetization_on),
                ),
                _buildDashboardCard('\$2,000.00', 'Wallet', Icons.account_balance_wallet),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(String value, String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 17, 101, 90),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                  overflow: TextOverflow.ellipsis, // Prevent overflow
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}