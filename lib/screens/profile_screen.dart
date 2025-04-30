import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gardencare_app/auth_service.dart';
import 'package:gardencare_app/screens/booking_history.dart';
import 'package:gardencare_app/screens/edit_profile_screen.dart';
import 'package:gardencare_app/screens/homeowner_screen.dart';
import 'package:gardencare_app/screens/calendar_screen.dart';
import 'package:gardencare_app/screens/login_screen.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


class ProfileScreen extends StatefulWidget {
  final String name;
  final String email;
  final String address;
  final String phone;
  final String account;

  const ProfileScreen({
    Key? key,
    required this.name,
    required this.email,
    required this.address,
    required this.phone,
    required this.account,
  }) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late String name;
  late String email;
  late String address;
  late String phone;
  late String account;
  double balance = 0.0;
List<dynamic> transactions = [];

  @override
  void initState() {
    super.initState();
    name = widget.name;
    email = widget.email;
    address = widget.address;
    account = widget.account;
    phone = widget.phone;
      _loadWalletData();
  }
     Future<void> _loadWalletData() async {
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
      
      // Safe parsing of balance
      final dynamic balanceValue = data['balance'];
      final double parsedBalance = balanceValue is String 
          ? double.tryParse(balanceValue) ?? 0.0
          : (balanceValue as num?)?.toDouble() ?? 0.0;

      // Safe parsing of transactions
      final List<dynamic> transactionList = data['transactions'] ?? [];
      final List<Map<String, dynamic>> parsedTransactions = transactionList.map((t) {
        final dynamic amountValue = t['amount'];
        final double parsedAmount = amountValue is String
            ? double.tryParse(amountValue) ?? 0.0
            : (amountValue as num?)?.toDouble() ?? 0.0;

        return {
          'id': t['id'],
          'amount': parsedAmount,
          'transaction_type': t['transaction_type'],
          'description': t['description'],
          'created_at': t['created_at'],
        };
      }).toList();

      setState(() {
        balance = parsedBalance;
        transactions = parsedTransactions;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load wallet data: ${response.statusCode}')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error loading wallet: $e')),
    );
    debugPrint('Error details: $e');
  }
}

  void _editProfile() async {
    final updatedProfile = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          name: name,
          email: email,
          address: address,
          phone: phone,
          account: account,
        ),
      ),
    );

    if (updatedProfile != null) {
      setState(() {
        name = updatedProfile['name'];
        email = updatedProfile['email'];
        address = updatedProfile['address'];
        phone = updatedProfile['phone'];
      });
    }
  }

    void _openCashInDialog() {
  String amount = '';
  String accountNumber = widget.account;

  showDialog(
    context: context,
    builder: (BuildContext context) {
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
                  final data = json.decode(response.body);
                  setState(() {
                    balance = data['new_balance']?.toDouble() ?? balance;
                  });
                  _loadWalletData(); // Refresh transactions
                  Navigator.pop(context); // Close the cash-in dialog
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

  // Add this new method for showing the success screen
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
                  ? "₱$amount has been added to your wallet"
                  : "₱$amount has been withdrawn from your wallet",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 5),
              Text(
                "New Balance: ₱${balance.toStringAsFixed(2)}",
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

    void _openWithdrawDialog() {
  String amount = '';
  String accountNumber = widget.account;

  showDialog(
    context: context,
    builder: (BuildContext context) {
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
                  final data = json.decode(response.body);
                  setState(() {
                    balance = data['new_balance']?.toDouble() ?? balance;
                  });
                  _loadWalletData(); // Refresh transactions
                  Navigator.pop(context); // Close the withdraw dialog
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

  void _viewBookingHistory() async {
  try {
    // Get the required data from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userId = prefs.getInt('userId');
    final userRole = prefs.getString('userRole');
    
    if (token == null || userId == null || userRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session expired. Please login again')),
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
}

  void _openCalendar() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => const CalendarScreen(
              userRole: 'homeowner', loggedInUser: '')),
    );
  }

  // New method to handle logout
  void _logout() async {
  final token = await AuthService.getToken();
  print("Retrieved Token: $token"); // Debugging: Print the token

  if (token == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("No token found. Please log in again."),
        duration: Duration(seconds: 2),
      ),
    );
    return;
  }

  try {
      final String baseUrl = dotenv.get('BASE_URL'); 
    final response = await http.post(
      Uri.parse('$baseUrl/api/logout'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    print("Response Status Code: ${response.statusCode}"); // Debugging: Print status code
    print("Response Body: ${response.body}"); // Debugging: Print response body

    if (response.statusCode == 200) {
      await AuthService.clearToken();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to logout. Status Code: ${response.statusCode}"),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Error: $e"),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
              flex: 2,
              child: _TopPortion(
                  name: name,
                  email: email,
                  address: address,
                  phone: phone,
                  account: account,
                  )), 
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text(
                    name.split(" ")[0], // Display first name only
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ProfileInfoCard(
                    name: name,
                    email: email,
                    address: address,
                    phone: phone,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                    ElevatedButton(
                      onPressed: _editProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Edit Profile",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _logout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Logout",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                    ],
                  ),
                  Card(
  elevation: 4,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
  child: Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Wallet Balance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '₱${balance.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 16),
      if (transactions.isNotEmpty) ...[
  const Padding(
    padding: EdgeInsets.symmetric(vertical: 8.0),
    child: Text(
      'Transaction History',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
  RefreshIndicator( 
   onRefresh: _loadWalletData,
   child: SizedBox(
    height: 200, // Fixed height for scrollable list
    child: ListView.builder(
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
          '${transaction['transaction_type'] == 'credit' ? '+' : '-'}₱${amount.toStringAsFixed(2)}',
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
)
  ),
  )
],
        ],
      ),
    ),
  ),
  const SizedBox(height: 20),
                  const SizedBox(height: 30),
                  _buildActionCard(
                    context,
                    icon: Icons.history,
                    label: 'View Booking History',
                    onTap: _viewBookingHistory,
                  ),
                  const SizedBox(height: 20),
                  _buildActionCard(
                    context,
                    icon: Icons.calendar_today,
                    label: 'Calendar',
                    onTap: _openCalendar,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, color: Colors.green, size: 25),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
              const Icon(Icons.arrow_forward, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileInfoCard extends StatelessWidget {
  final String name;
  final String email;
  final String address;
  final String phone;

  const ProfileInfoCard({
    Key? key,
    required this.name,
    required this.email,
    required this.address,
    required this.phone,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(Icons.person, "Name", name),
            _buildInfoRow(Icons.email, "Email", email),
            _buildInfoRow(Icons.location_on, "Address", address),
            _buildInfoRow(Icons.phone, "Phone", phone),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.green),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "$label: $value",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopPortion extends StatelessWidget {
  final String name;
  final String email;
  final String address;
  final String phone;
  final String account;

  const _TopPortion({
    Key? key,
    required this.name,
    required this.email,
    required this.address,
    required this.phone,
    required this.account,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Color(0xff00b300), Color(0xff006600)],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(50),
              bottomRight: Radius.circular(50),
            ),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 40, left: 12, right: 16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => HomeownerScreen(
                                name: name,
                                email: email,
                                address: address,
                                account: account,
                                phone: phone,
                              )),
                    );
                  },
                ),
                const SizedBox(width: 8),
                Text(
                  "My Profile",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 50.0),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              width: 135,
              height: 130,
              
            ),
          ),
        ),
      ],
    );
  }
}