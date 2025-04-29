import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gardencare_app/auth_service.dart';
import 'package:gardencare_app/providers/user_provider.dart';
import 'package:gardencare_app/screens/booking_notification_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:gardencare_app/screens/booking_history.dart';
import 'package:gardencare_app/screens/feedback_screen.dart';
import 'package:gardencare_app/screens/gardener_profile_screen.dart';
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
  final String account;
  

  GardenerDashboard({
    required this.name,
    required this.role,
    required this.email,
    required this.phone,
    required this.address,
    required this.account,
  });

  @override
  _GardenerDashboardState createState() => _GardenerDashboardState();
}

class _GardenerDashboardState extends State<GardenerDashboard> {
  int bookingCount = 0;
  bool isLoading = true;
  double balance = 0.0;
  double totalEarnings = 0.0;
List<dynamic> transactions = [];
bool isLoadingWallet = false;
 bool isLoadingEarnings = false; 

  @override
  void initState() {
    super.initState();
    _fetchBookingCount();
    _loadWalletData(); 
     _fetchTotalEarnings();
  }

      Future<void> _fetchTotalEarnings() async {
    setState(() => isLoadingEarnings = true);
    try {
      final bookingService = BookingService();
      final earnings = await bookingService.fetchTotalEarnings();
      setState(() {
        totalEarnings = earnings;
      });
    } catch (e) {
      print('Error fetching total earnings: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load earnings data')),
      );
    } finally {
      setState(() => isLoadingEarnings = false);
    }
  }

    void _showWalletDetails(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return Container(
        padding: EdgeInsets.all(16),
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Text(
              'Wallet Balance',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '\$${balance.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _openCashInDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('Cash In'),
                ),
                ElevatedButton(
                  onPressed: _openWithdrawDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  child: const Text('Withdraw'),
                ),
              ],
            ),
            SizedBox(height: 16),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadWalletData,
                child: transactions.isEmpty
                    ? Center(child: Text('No transactions yet'))
                    : ListView.builder(
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final transaction = transactions[index];
                          final amount = transaction['amount'] is double 
                              ? transaction['amount'] as double
                              : double.tryParse(transaction['amount'].toString()) ?? 0.0;
                          
                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: Icon(
                                transaction['transaction_type'] == 'credit' 
                                    ? Icons.arrow_circle_up 
                                    : Icons.arrow_circle_down,
                                color: transaction['transaction_type'] == 'credit' 
                                    ? Colors.green 
                                    : Colors.red,
                              ),
                              title: Text(transaction['description'] ?? 'No description'),
                              subtitle: Text(transaction['created_at'] ?? ''),
                              trailing: Text(
                                '${transaction['transaction_type'] == 'credit' ? '+' : '-'}\$${amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: transaction['transaction_type'] == 'credit' 
                                      ? Colors.green 
                                      : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      );
    },
  );
} 

  void _openCashInDialog() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      String amount = '';
      String accountNumber = widget.account;

      return AlertDialog(
        title: const Text('Cash In'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount'),
              onChanged: (value) => amount = value,
            ),
            TextFormField(
              initialValue: accountNumber,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(labelText: 'Account Number'),
              onChanged: (value) => accountNumber = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (amount.isEmpty || accountNumber.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              final token = await AuthService.getToken();
              if (token == null) return;

              try {
                final String baseUrl = dotenv.get('BASE_URL');
                final response = await http.post(
                  Uri.parse('$baseUrl/api/wallet/cash-in'),
                  headers: {
                    'Content-Type': 'application/json',
                    'Authorization': 'Bearer $token',
                  },
                  body: json.encode({
                    'amount': amount,
                    'account_number': accountNumber,
                  }),
                );

                if (response.statusCode == 200) {
                  await _loadWalletData();
                  Navigator.pop(context);
                  _showSuccessScreen(amount, 'cash-in');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${response.body}')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      );
    },
  );
}

  // Add this new method inside the _GardenerDashboardState class

void _showSuccessScreen(String amount, String transactionType) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 80,
                ),
              ),
              SizedBox(height: 20),
              Text(
                "Success!",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              SizedBox(height: 10),
              Text(
                transactionType == 'cash-in' 
                  ? "\$${amount} has been added to your wallet"
                  : "\$${amount} has been withdrawn from your wallet",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 5),
              Text(
                "New Balance: \$${balance.toStringAsFixed(2)}",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  // Auto-dismiss the success screen after 3 seconds
  Future.delayed(Duration(seconds: 3), () {
    Navigator.of(context).pop();
  });
}


  Future<void> _refreshAllData() async {
  setState(() {
    isLoading = true;
    isLoadingWallet = true;
     isLoadingEarnings = true;
  });
  
  // Refresh all data sources
    await Future.wait([
      _fetchBookingCount(),
      _loadWalletData(),
      _fetchTotalEarnings(),
    ]);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dashboard refreshed')),
      );
    }
  
  // Show a confirmation to the user
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dashboard refreshed'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}

void _openWithdrawDialog() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      String amount = '';
      String accountNumber = widget.account;

      return AlertDialog(
        title: const Text('Withdraw'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount'),
              onChanged: (value) => amount = value,
            ),
            TextFormField(
              initialValue: accountNumber,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(labelText: 'Account Number'),
              onChanged: (value) => accountNumber = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (amount.isEmpty || accountNumber.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              final token = await AuthService.getToken();
              if (token == null) return;

              try {
                final String baseUrl = dotenv.get('BASE_URL');
                final response = await http.post(
                  Uri.parse('$baseUrl/api/wallet/withdraw'),
                  headers: {
                    'Content-Type': 'application/json',
                    'Authorization': 'Bearer $token',
                  },
                  body: json.encode({
                    'amount': amount,
                    'account_number': accountNumber,
                  }),
                );

                if (response.statusCode == 200) {
                  await _loadWalletData();
                  Navigator.pop(context);
                  _showSuccessScreen(amount, 'withdraw');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${response.body}')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      );
    },
  );
}

    Future<void> _loadWalletData() async {
  setState(() => isLoadingWallet = true);
  final token = await AuthService.getToken();
  if (token == null) return;

  try {
    final String baseUrl = dotenv.get('BASE_URL');
    final response = await http.get(
      Uri.parse('$baseUrl/api/wallet'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        balance = (data['balance'] as num?)?.toDouble() ?? 0.0;
        transactions = List<Map<String, dynamic>>.from(data['transactions'] ?? []);
      });
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error loading wallet: $e')),
    );
  } finally {
    setState(() => isLoadingWallet = false);
  }
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
                    builder: (context) => GardenerProfileScreen(
                      name: widget.name, // Changed to widget.name
                      email: widget.email,
                      phone: widget.phone,
                      account: widget.account,
                      address: widget.address,
                    ),
                  ),
                );
              },
            ),
           ListTile(
  leading: const Icon(Icons.book),
  title: const Text('Booking History'),
  onTap: () async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userId = prefs.getInt('userId');
      final userRole = prefs.getString('userRole');
      
      if (token == null || userId == null || userRole == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login again')),
        );
        return;
      }
      
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookingHistoryScreen(
              userId: userId,
              authToken: token,
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
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
      body:  RefreshIndicator(
      onRefresh: _refreshAllData,
      child:SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(), 
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
                  child: isLoadingEarnings
                      ? _buildLoadingCard()
                      : _buildDashboardCard(
                          '\$${totalEarnings.toStringAsFixed(2)}',
                          'Total Earning',
                          Icons.monetization_on,
                        ),
                ),
                GestureDetector(
                onTap: () {
                  _showWalletDetails(context);
                },
                child: isLoadingWallet
                    ? _buildLoadingCard()
                    : _buildDashboardCard(
                        '\$${balance.toStringAsFixed(2)}',
                        'Wallet',
                        Icons.account_balance_wallet,
                      ),
              ),
              ],
            ),
          ],
        ),
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