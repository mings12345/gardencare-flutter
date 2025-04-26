import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:gardencare_app/providers/booking_provider.dart';
import 'package:gardencare_app/providers/user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookingForm extends StatefulWidget {
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
  String? gcashNo;
  String? otp;
  String? enteredOtp;
  bool showGcashRegistration = false;
  bool isSendingOtp = false;
  bool isVerifyingOtp = false;

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
  List<String> paymentMethods = ["Credit Card", "Debit Card", "GCash", "PayMaya", "Bank Transfer"];

  @override
  void initState() {
    super.initState();
    _loadData();
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
    if (selectedType == "Gardening") {
      return services.where((service) => service["type"] == "Gardening").toList();
    } else if (selectedType == "Landscaping") {
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
  
  // Check if user has GCash number
  if (userProvider.gcashNo == null || userProvider.gcashNo!.isEmpty) {
    setState(() {
      showGcashRegistration = true;
    });
    _showGcashRegistration();
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
              Text('GCash Number: ${userProvider.gcashNo}'),
              SizedBox(height: 10),
              Text('Selected Services:', style: TextStyle(fontWeight: FontWeight.bold)),
              // ... rest of your existing receipt content
              // Make sure to include the GCash number in the receipt
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
void _showGcashRegistration() {
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
                    await _verifyOtp();
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
      
      // Now show the receipt
      _showReceipt();
    } else {
      _showError("Failed to save GCash number: ${response.body}");
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
        "sender_gcash_no": userProvider.gcashNo,
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

    // Navigate to bookings screen
    Navigator.pushNamed(context, '/bookings');
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
        title: Text("Book Service"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
    );
  }

  Widget _buildServiceTypeDropdown() {
    return DropdownButtonFormField<String>(
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            "Select Services:",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        ...getFilteredServices().map((service) {
          return CheckboxListTile(
            title: Text("${service['name']} (₱${service['price']})"),
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
          );
        }).toList(),
      ],
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
  return Card(
    elevation: 4,
    margin: EdgeInsets.symmetric(vertical: 16),
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Payment Details",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          
          // Payment Type Selection
          Text("Payment Type:", style: TextStyle(fontWeight: FontWeight.bold)),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: Text("Full Payment"),
                  value: "Full Payment",
                  groupValue: paymentType,
                  onChanged: (value) {
                    setState(() {
                      paymentType = value!;
                      calculatePaymentAmounts();
                    });
                  },
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: Text("Down Payment (30%)"),
                  value: "Down Payment",
                  groupValue: paymentType,
                  onChanged: (value) {
                    setState(() {
                      paymentType = value!;
                      calculatePaymentAmounts();
                    });
                  },
                ),
              ),
            ],
          ),
          
          // GCash Payment Method (readonly)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: TextFormField(
              readOnly: true,
              initialValue: "GCash",
              decoration: InputDecoration(
                labelText: "Payment Method",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          
          // Payment Summary
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Payment Summary:", style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Total Service Cost:"),
                    Text("₱${totalPrice.toStringAsFixed(2)}"),
                  ],
                ),
                Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(paymentType == "Full Payment" 
                        ? "Amount to Pay:" 
                        : "Down Payment Amount (30%):", 
                        style: TextStyle(fontWeight: FontWeight.bold)
                    ),
                    Text("₱${downPaymentAmount.toStringAsFixed(2)}", 
                        style: TextStyle(fontWeight: FontWeight.bold)
                    ),
                  ],
                ),
                if (paymentType == "Down Payment") ...[
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Remaining Balance:", style: TextStyle(fontWeight: FontWeight.bold)),
                      Text("₱${remainingBalance.toStringAsFixed(2)}", style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Note: Remaining balance will be collected on service day.",
                    style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
 
  Widget _buildSubmitButton() {
    bool canProceed = true;
    String buttonText = "PROCEED PAYMENT";
    
    // Additional validation for GCash payment
    if (paymentMethod == "GCash" && paymentProofImage == null) {
      canProceed = false;
      buttonText = "PLEASE UPLOAD PAYMENT PROOF";
    }
    
    return ElevatedButton(
      onPressed: ((_isLoading || isProcessingPayment || !canProceed) ? null : _showReceipt),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        padding: EdgeInsets.symmetric(vertical: 16),
      ),
      child: (_isLoading || isProcessingPayment)
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  isProcessingPayment ? "PROCESSING PAYMENT..." : "CONFIRMING BOOKING...",
                  style: TextStyle(fontSize: 16),
                ),
              ],
            )
          : Text(
              buttonText,
              style: TextStyle(fontSize: 16),
            ),
    );
  }
}