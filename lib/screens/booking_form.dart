import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gardencare_app/screens/bookings_screen.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:gardencare_app/providers/booking_provider.dart';
import 'package:gardencare_app/providers/user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FormLayout extends StatelessWidget {
  final Widget child;
  
  const FormLayout({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // For large screens, center the form with a max width
    if (screenWidth > 600) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 800),
          child: child,
        ),
      );
    }
    
    // For small screens, use the full width
    return child;
  }
}

class BookingForm extends StatefulWidget {
  final int? preselectedServiceId;
  final String? serviceType;
  
  const BookingForm({
    Key? key,
    this.preselectedServiceId,
    this.serviceType,
  }) : super(key: key);

  @override
  _BookingFormState createState() => _BookingFormState();
}

class _BookingFormState extends State<BookingForm> {
  final _formKey = GlobalKey<FormState>();

  String? selectedType;
  int? selectedGardenerId;
  int? selectedServiceProviderId;
  String address = "";
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String? specialInstructions;
  bool _isLoading = false;
  String? account;
  String? otp;
  String? enteredOtp;
  bool showAccountRegistration = false;
  bool isSendingOtp = false;
  bool isVerifyingOtp = false;
  double walletBalance = 0.0;

  // Payment related variables
  String paymentType = "Full Payment"; // Default to full payment
  String paymentMethod = "Credit Card"; // Default payment method
  double downPaymentAmount = 0.0;
  double remainingBalance = 0.0;
  bool isProcessingPayment = false;
  File? paymentProofImage;
  
  List<int> selectedServiceIds = [];
  double totalPrice = 0.0;

  List<Map<String, dynamic>> gardeners = [];
  List<Map<String, dynamic>> services = [];
  List<Map<String, dynamic>> serviceProviders = [];
  List<String> paymentMethods = ["Credit Card", "Debit Card", "Garden Care", "PayMaya", "Bank Transfer"];

  @override
  void initState() {
    super.initState();
    if (widget.serviceType != null) {
    selectedType = widget.serviceType;
  }
  
  _loadData().then((_) {
    // After data is loaded, check if we have a preselected service
    if (widget.preselectedServiceId != null) {
      setState(() {
        if (!selectedServiceIds.contains(widget.preselectedServiceId)) {
          selectedServiceIds.add(widget.preselectedServiceId!);
          updateTotalPrice();
        }
      });
    }
  });
    _loadData();
     _fetchWalletBalance(); 
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      fetchGardeners(),
      fetchServices(),
      fetchServiceProviders(),
    ]);
    setState(() => _isLoading = false);
  }

    Future<void> _fetchWalletBalance() async {
  try {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = dotenv.get('BASE_URL');
    final token = prefs.getString('token') ?? '';

    final response = await http.get(
      Uri.parse('$baseUrl/api/wallet'),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        walletBalance = double.tryParse(data['balance'].toString()) ?? 0.0;
      });
    }
  } catch (e) {
    debugPrint("Error fetching wallet balance: $e");
  }
}

  Future<void> fetchGardeners() async {
    try {
      final baseUrl = dotenv.get('BASE_URL'); 
      final response = await http.get(
        Uri.parse('$baseUrl/api/gardeners'),
        headers: {"Accept": "application/json"},
      );

      if (response.statusCode == 200) {
        setState(() {
          gardeners = List<Map<String, dynamic>>.from(jsonDecode(response.body));
        });
      } else {
        _showError("Failed to load gardeners");
      }
    } catch (e) {
      _showError("Network error: ${e.toString()}");
    }
  }
  
  Future<void> fetchServices() async {
    try {
      final baseUrl = dotenv.get('BASE_URL'); 
      final response = await http.get(
        Uri.parse('$baseUrl/api/services'),
        headers: {"Accept": "application/json"},
      );

      if (response.statusCode == 200) {
        setState(() {
          services = List<Map<String, dynamic>>.from(jsonDecode(response.body)["services"]);
        });
      } else {
        _showError("Failed to load services");
      }
    } catch (e) {
      _showError("Network error: ${e.toString()}");
    }
  }

  Future<void> fetchServiceProviders() async {
    try {
      final baseUrl = dotenv.get('BASE_URL'); 
      final response = await http.get(
        Uri.parse('$baseUrl/api/service_providers'),
        headers: {"Accept": "application/json"},
      );

      if (response.statusCode == 200) {
        setState(() {
          serviceProviders = List<Map<String, dynamic>>.from(jsonDecode(response.body));
        });
      } else {
        _showError("Failed to load service providers");
      }
    } catch (e) {
      _showError("Network error: ${e.toString()}");
    }
  }

  List<Map<String, dynamic>> getFilteredServices() {
  final type = selectedType ?? widget.serviceType;
  if (type == "Gardening") {
    return services.where((service) => service["type"] == "Gardening").toList();
  } else if (type == "Landscaping") {
    return services.where((service) => service["type"] == "Landscaping").toList();
  }
  return [];
}

  void updateTotalPrice() {
    double sum = 0.0;
    for (var service in services) {
      if (selectedServiceIds.contains(service["id"])) {
        sum += double.tryParse(service["price"].toString()) ?? 0.0;
      }
    }
    setState(() {
      totalPrice = sum;
      calculatePaymentAmounts();
    });
  }

  void calculatePaymentAmounts() {
    if (paymentType == "Down Payment") {
      // Calculate 30% of the total price for down payment
      downPaymentAmount = totalPrice * 0.3;
      remainingBalance = totalPrice - downPaymentAmount;
    } else {
      // Full payment
      downPaymentAmount = totalPrice;
      remainingBalance = 0.0;
    }
  }

  

  void _showReceipt() {
  final userProvider = Provider.of<UserProvider>(context, listen: false);
  
  // Check if user has number
  if (userProvider.account == null || userProvider.account!.isEmpty) {
    setState(() {
      showAccountRegistration = true;
    });
    _showAccountRegistration();
    return;
  }

     // Check wallet balance
  if (walletBalance < downPaymentAmount) {
    _showError("Insufficient wallet balance. Please cash in first.");
    return;
  }

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Row(
          children: [
            Icon(Icons.receipt_long, color: Colors.green),
            SizedBox(width: 10),
            Text('Payment Receipt'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Garden Care Services', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Divider(),
              SizedBox(height: 10),
              Text('Service Type: $selectedType'),
              SizedBox(height: 5),
              Text('Date: ${selectedDate?.day}/${selectedDate?.month}/${selectedDate?.year}'),
              Text('Time: ${selectedTime?.format(context)}'),
              SizedBox(height: 10),
              Text('Wallet Number: ${userProvider.account}'),
              SizedBox(height: 10),
              Text('Selected Services:', style: TextStyle(fontWeight: FontWeight.bold)),
              
              // Selected services list
              ...selectedServiceIds.map((serviceId) {
                final service = services.firstWhere((s) => s['id'] == serviceId);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text('- ${service['name']} (₱${service['price']})'),
                );
              }).toList(),
              
              SizedBox(height: 10),
              Divider(),
              Text('Payment Summary:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Payment Method:'),
                  Text('GCare Wallet', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Subtotal:'),
                  Text('₱${totalPrice.toStringAsFixed(2)}'),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Payment Type:'),
                  Text(paymentType),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Amount Paid:'),
                  Text('₱${downPaymentAmount.toStringAsFixed(2)}'),
                ],
              ),
              if (paymentType == "Down Payment")
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Remaining Balance:'),
                    Text('₱${remainingBalance.toStringAsFixed(2)}'),
                  ],
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: Text('Confirm Booking'),
            onPressed: () {
              Navigator.of(context).pop();
              submitBooking();
            },
          ),
        ],
      );
    },
  );
}

  void _showCashInDialog() {
  String amount = '';
  String accountNumber = Provider.of<UserProvider>(context, listen: false).account ?? '';

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

              setState(() => _isLoading = true);
              try {
                final prefs = await SharedPreferences.getInstance();
                final baseUrl = dotenv.get('BASE_URL');
                final token = prefs.getString('token') ?? '';

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
                    walletBalance = data['new_balance']?.toDouble() ?? walletBalance;
                  });
                  Navigator.pop(context); // Close the cash-in dialog
                  
                  // Show success screen overlay
                  _showSuccessScreen(amount);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${response.body}')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              } finally {
                setState(() => _isLoading = false);
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
void _showSuccessScreen(String amount) {
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
                "₱$amount has been added to your wallet",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 5),
              Text(
                "New Balance: ₱${walletBalance.toStringAsFixed(2)}",
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
  
void _showAccountRegistration() {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {  // Renamed to make clear it's for dialog state
          return AlertDialog(
            title: Stack(
              children: [
                Row(
                  children: [
                    Icon(Icons.phone_android, color: Colors.green),
                    SizedBox(width: 10),
                    Text('Register Wallet'),
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
                      labelText: "Mobile Number",
                      hintText: "09XXXXXXXXX",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    onChanged: (value) => account = value,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your phone number';
                      }
                      if (!RegExp(r'^09\d{9}$').hasMatch(value)) {
                        return 'Please enter a valid phone number (09XXXXXXXXX)';
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
                      onPressed: () async {
                        await _resendOtp();
                        setDialogState(() {}); // Refresh dialog with updated state
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
                    setDialogState(() {}); // Use dialog's setState
                  } else {
                    await _verifyOtp();
                    setDialogState(() {}); // Update button state in dialog
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
          Text("Wallet OTP Sent!", style: TextStyle(fontWeight: FontWeight.bold)),
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
  
  // Generate new random 6-digit OTP
  final random = Random();
  otp = List.generate(6, (index) => random.nextInt(10)).join();
  
  await Future.delayed(Duration(seconds: 1));
  
  // Important: Reset the sending state
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

Future<void> _verifyOtp() async {
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
    // Save number to backend
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
      // Update user provider
      userProvider.updateAccountNo(account!);
      
      // Close dialog
      Navigator.of(context).pop();
      setState(() {
        showAccountRegistration = false;
      });
      
      // Show success dialog that auto-closes after 2 seconds
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          // Auto-close after 2 seconds
          Future.delayed(const Duration(seconds: 2), () {
            Navigator.of(context).pop();
            _showReceipt();
          });
          
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 60),
                  SizedBox(height: 16),
                  Text(
                    "Verified Successfully!",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Your account number has been verified.",
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(Colors.green),
                    strokeWidth: 2,
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      print(response.body);
      _showError("Failed to save Account number: ${response.body}");
    }
  } catch (e) {
    _showError("Error: ${e.toString()}");
  } finally {
    setState(() => isVerifyingOtp = false);
  }
}

  Future<bool> processPayment() async {
    // Simulate payment processing
    setState(() => isProcessingPayment = true);
    
    try {
      // Here you would integrate with a real payment gateway API
      // For now, we'll simulate a payment process with a delay
      await Future.delayed(Duration(seconds: 2));
      
      // Simulate successful payment
      return true;
    } catch (e) {
      _showError("Payment processing failed: ${e.toString()}");
      return false;
    } finally {
      setState(() => isProcessingPayment = false);
    }
  }

 // In booking_form.dart, modify the submitBooking method:

Future<void> submitBooking() async {
  if (!_formKey.currentState!.validate()) return;
  _formKey.currentState!.save();

  setState(() => _isLoading = true);

  try {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final int? homeownerId = userProvider.homeownerId;

    if (homeownerId == null) {
      _showError("Please login to book services");
      return;
    }
    
    final formattedTime = 
        "${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}";

    final Map<String, dynamic> payload = {
      "type": selectedType,
      "homeowner_id": homeownerId,
      "service_ids": selectedServiceIds,
      "address": address,
      "date": selectedDate!.toIso8601String(),
      "time": formattedTime,
      "total_price": totalPrice,
      "payment_status": paymentType == "Full Payment" ? "paid" : "partially_paid",
      "special_instructions": specialInstructions ?? "",
      "payment": {
        "amount_paid": downPaymentAmount,
        "payment_date": DateTime.now().toIso8601String(),
        "sender_no": userProvider.account,
        "wallet_balance": walletBalance,
      }
    };

    if (selectedType == "Gardening") {
      payload["gardener_id"] = selectedGardenerId;
    } else if (selectedType == "Landscaping") {
      payload["serviceprovider_id"] = selectedServiceProviderId;
    }
    
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = dotenv.get('BASE_URL');
    final token = prefs.getString('token') ?? '';
    
    final response = await http.post(
      Uri.parse('$baseUrl/api/create_booking'),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer ${token}",
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 201) {
      _handleSuccessfulBooking(payload);
    } else {
      _showError("Booking failed: ${response.body}");
    }
  } catch (e) {
    _showError("Error: ${e.toString()}");
  } finally {
    setState(() => _isLoading = false);
  }
}

  void _handleSuccessfulBooking(Map<String, dynamic> bookingData) {
  // Update local state
  Provider.of<BookingProvider>(context, listen: false).addBooking(bookingData);
  
  // Show success message
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text("Booking and Payment Successful!"),
      backgroundColor: Colors.green,
    ),
  );

  // Navigate to bookings screen and remove all previous routes
 
  
  // Then navigate to bookings screen
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => BookingsScreen()),
  );
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
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text("Booking Form")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
      title: const Text(
        "Reservation Service",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Colors.green,
      iconTheme: const IconThemeData(color: Colors.white),
    ),

      body: FormLayout(
        child: Padding(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width > 600 ? 32.0 : 16.0,
        vertical: 16.0,
      ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildServiceTypeDropdown(),
                if (selectedType == "Gardening") _buildGardenerDropdown(),
                if (selectedType == "Landscaping") _buildServiceProviderDropdown(),
                if (selectedType != null) _buildServiceSelection(),
                if (selectedType != null) _buildTotalPrice(),
                _buildAddressField(),
                _buildDatePicker(),
                _buildTimePicker(),
                _buildSpecialInstructions(),
                SizedBox(height: 16),
                _buildPaymentSection(),
                SizedBox(height: 24),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    ));
  }

  Widget _buildServiceTypeDropdown() {
    return LayoutBuilder(
      builder: (context, constraints){
    return DropdownButtonFormField<String>(
      isExpanded: true,
      value: selectedType,
      onChanged: (value) {
        setState(() {
          selectedType = value;
          selectedServiceIds = [];
          totalPrice = 0.0;
        });
      },
      items: ["Gardening", "Landscaping"]
          .map((type) => DropdownMenuItem(
                value: type,
                child: Text(type),
              ))
          .toList(),
      decoration: InputDecoration(
        labelText: "Service Type",
        border: OutlineInputBorder(),
      ),
      validator: (value) => value == null ? "Please select service type" : null,
    );
   });
  }

  Widget _buildGardenerDropdown() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: DropdownButtonFormField<int>(
        value: selectedGardenerId,
        onChanged: (value) => setState(() => selectedGardenerId = value),
        items: gardeners.map((gardener) {
          return DropdownMenuItem<int>(
            value: gardener["id"],
            child: Text(gardener["name"]),
          );
        }).toList(),
        decoration: InputDecoration(
          labelText: "Select Gardener",
          border: OutlineInputBorder(),
        ),
        validator: (value) => value == null ? "Please select a gardener" : null,
      ),
    );
  }

  Widget _buildServiceProviderDropdown() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: DropdownButtonFormField<int>(
        value: selectedServiceProviderId,
        onChanged: (value) => setState(() => selectedServiceProviderId = value),
        items: serviceProviders.map((provider) {
          return DropdownMenuItem<int>(
            value: provider["id"],
            child: Text(provider["name"]),
          );
        }).toList(),
        decoration: InputDecoration(
          labelText: "Select Service Provider",
          border: OutlineInputBorder(),
        ),
        validator: (value) => value == null ? "Please select a provider" : null,
      ),
    );
  }

  Widget _buildServiceSelection() {
  return LayoutBuilder(
    builder: (context, constraints) {
      final isLargeScreen = constraints.maxWidth > 600;
      final filteredServices = getFilteredServices();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(
              top: isLargeScreen ? 24 : 16,
              bottom: isLargeScreen ? 16 : 8,
            ),
            child: Text(
              "Select Services:",
              style: TextStyle(
                fontSize: isLargeScreen ? 18 : 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (isLargeScreen)
            // Grid layout for large screens
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2, // Two columns on large screens
              childAspectRatio: 4, // Width to height ratio
              crossAxisSpacing: 16,
              mainAxisSpacing: 8,
              children: filteredServices.map((service) {
                return _buildServiceCheckbox(service);
              }).toList(),
            )
          else
            // List layout for small screens
            Column(
              children: filteredServices.map((service) {
                return _buildServiceCheckbox(service);
              }).toList(),
            ),
        ],
      );
    },
  );
}

Widget _buildServiceCheckbox(Map<String, dynamic> service) {
  // If this is the preselected service, ensure it's selected
  final isPreselected = widget.preselectedServiceId == service['id'];
  if (isPreselected && !selectedServiceIds.contains(service['id'])) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        selectedServiceIds.add(service['id']);
        updateTotalPrice();
      });
    });
  }

  return CheckboxListTile(
    title: Text(
      "${service['name']} (₱${service['price']})",
      style: TextStyle(
        fontSize: MediaQuery.of(context).size.width > 600 ? 16 : 14,
      ),
    ),
    value: selectedServiceIds.contains(service['id']),
    onChanged: (bool? value) {
      setState(() {
        if (value == true) {
          selectedServiceIds.add(service['id']);
        } else {
          selectedServiceIds.remove(service['id']);
        }
        updateTotalPrice();
      });
    },
    contentPadding: EdgeInsets.symmetric(
      horizontal: MediaQuery.of(context).size.width > 600 ? 24 : 8,
    ),
  );
}

  Widget _buildTotalPrice() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        "Total Price: ₱${totalPrice.toStringAsFixed(2)}",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildAddressField() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: "Address",
          border: OutlineInputBorder(),
        ),
        validator: (value) => value!.isEmpty ? "Please enter address" : null,
        onSaved: (value) => address = value!,
      ),
    );
  }

  Widget _buildDatePicker() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: InkWell(
        onTap: () async {
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(Duration(days: 365)),
          );
          if (picked != null) setState(() => selectedDate = picked);
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: "Date",
            border: OutlineInputBorder(),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                selectedDate == null
                    ? "Select date"
                    : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
              ),
              Icon(Icons.calendar_today),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: InkWell(
        onTap: () async {
          final TimeOfDay? picked = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.now(),
          );
          if (picked != null) setState(() => selectedTime = picked);
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: "Time",
            border: OutlineInputBorder(),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                selectedTime == null
                    ? "Select time"
                    : selectedTime!.format(context),
              ),
              Icon(Icons.access_time),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialInstructions() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: "Special Instructions (Optional)",
          border: OutlineInputBorder(),
        ),
        maxLines: 3,
        onSaved: (value) => specialInstructions = value,
      ),
    );
  }

Widget _buildPaymentSection() {
  return LayoutBuilder(
    builder: (context, constraints) {
      final isLargeScreen = constraints.maxWidth > 600;
      final padding = isLargeScreen ? 24.0 : 16.0;
      final titleFontSize = isLargeScreen ? 20.0 : 18.0;
      final textFontSize = isLargeScreen ? 16.0 : 14.0;
      final smallTextFontSize = isLargeScreen ? 14.0 : 12.0;

      return Card(
        elevation: 4,
        margin: EdgeInsets.symmetric(
          vertical: isLargeScreen ? 20 : 16,
          horizontal: isLargeScreen ? 8 : 0,
        ),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Payment Details",
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: isLargeScreen ? 20 : 16),
              
              // Payment Type Selection
              Text(
                "Payment Type:", 
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: textFontSize,
                ),
              ),
              if (isLargeScreen)
                Row(
                  children: [
                    Expanded(child: _buildPaymentRadio("Full Payment", textFontSize)),
                    SizedBox(width: 16),
                    Expanded(child: _buildPaymentRadio("Down Payment (30%)", textFontSize)),
                  ],
                )
              else
                Column(
                  children: [
                    _buildPaymentRadio("Full Payment", textFontSize),
                    _buildPaymentRadio("Down Payment (30%)", textFontSize),
                  ],
                ),
              
              // Payment Method (readonly)
              Padding(
                padding: EdgeInsets.only(top: padding / 2),
                child: TextFormField(
                  readOnly: true,
                  initialValue: "GCare Wallet",
                  decoration: InputDecoration(
                    labelText: "Payment Method",
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: isLargeScreen ? 18 : 14,
                      horizontal: 16,
                    ),
                    labelStyle: TextStyle(fontSize: textFontSize),
                  ),
                  style: TextStyle(fontSize: textFontSize),
                ),
              ),
              
              // Payment Summary
              Padding(
                padding: EdgeInsets.only(top: padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Payment Summary:", 
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: textFontSize,
                      ),
                    ),
                    SizedBox(height: 8),
                    _buildPaymentRow(
                      "Total Service Cost:", 
                      "₱${totalPrice.toStringAsFixed(2)}",
                      textFontSize,
                    ),
                    Divider(thickness: 1),
                    _buildPaymentRow(
                      paymentType == "Full Payment" 
                          ? "Amount to Pay:" 
                          : "Down Payment Amount (30%):", 
                      "₱${downPaymentAmount.toStringAsFixed(2)}",
                      textFontSize,
                      isBold: true,
                    ),
                    if (paymentType == "Down Payment") ...[
                      SizedBox(height: 4),
                      _buildPaymentRow(
                        "Remaining Balance:", 
                        "₱${remainingBalance.toStringAsFixed(2)}",
                        textFontSize,
                        isBold: true,
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Note: Remaining balance will be automatically deducted to your account after completion.",
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: smallTextFontSize,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildPaymentRadio(String value, double fontSize) {
  return RadioListTile<String>(
    title: Text(
      value,
      style: TextStyle(fontSize: fontSize),
    ),
    value: value.contains("Full") ? "Full Payment" : "Down Payment",
    groupValue: paymentType,
    onChanged: (value) {
      setState(() {
        paymentType = value!;
        calculatePaymentAmounts();
      });
    },
    contentPadding: EdgeInsets.zero,
    dense: true,
  );
}

Widget _buildPaymentRow(String label, String value, double fontSize, {bool isBold = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    ),
  );
}
 
 Widget _buildSubmitButton() {
  return LayoutBuilder(
    builder: (context, constraints) {
      final isLargeScreen = constraints.maxWidth > 600;
      final bool hasSufficientBalance = walletBalance >= downPaymentAmount;
      final bool hasAccount = Provider.of<UserProvider>(context, listen: false).account != null && 
                            Provider.of<UserProvider>(context, listen: false).account!.isNotEmpty;

      // Common button style
      final ButtonStyle greenButtonStyle = ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        padding: EdgeInsets.symmetric(
          vertical: isLargeScreen ? 18 : 16,
          horizontal: isLargeScreen ? 32 : 16,
        ),
        textStyle: TextStyle(
          fontSize: isLargeScreen ? 18 : 16,
          fontWeight: FontWeight.bold,
        ),
      );

      final ButtonStyle orangeButtonStyle = ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        padding: EdgeInsets.symmetric(
          vertical: isLargeScreen ? 16 : 12,
          horizontal: isLargeScreen ? 24 : 16,
        ),
        textStyle: TextStyle(
          fontSize: isLargeScreen ? 16 : 14,
          fontWeight: FontWeight.bold,
        ),
      );

      if (!hasAccount) {
        return ElevatedButton(
          onPressed: _showReceipt,
          style: greenButtonStyle,
          child: Text("PROCEED PAYMENT"),
        );
      }

      if (!hasSufficientBalance) {
        return Column(
          children: [
            Text(
              "Insufficient wallet balance",
              style: TextStyle(
                color: Colors.red,
                fontSize: isLargeScreen ? 18 : 16,
              ),
            ),
            SizedBox(height: isLargeScreen ? 16 : 10),
            ElevatedButton(
              onPressed: _showCashInDialog,
              style: orangeButtonStyle,
              child: Text("CASH IN NOW"),
            ),
          ],
        );
      }

      return ElevatedButton(
        onPressed: ((_isLoading || isProcessingPayment) ? null : _showReceipt),
        style: greenButtonStyle,
        child: (_isLoading || isProcessingPayment)
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: isLargeScreen ? 24 : 20,
                    height: isLargeScreen ? 24 : 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: isLargeScreen ? 16 : 10),
                  Text(
                    isProcessingPayment ? "PROCESSING PAYMENT..." : "CONFIRMING BOOKING...",
                    style: TextStyle(
                      fontSize: isLargeScreen ? 16 : 14,
                    ),
                  ),
                ],
              )
            : Text("PROCEED PAYMENT"),
      );
    },
  );
}
}