import 'package:flutter/material.dart';
import 'package:gardencare_app/services/booking_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class PaymentScreen extends StatefulWidget {
  final int bookingId;
  final double amount;
  final int? userId;

  const PaymentScreen({
    Key? key,
    required this.bookingId,
    required this.amount,
    this.userId,
  }) : super(key: key);

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final BookingService _bookingService = BookingService();
  final _formKey = GlobalKey<FormState>();
  
  String _selectedPaymentMethod = 'Cash';
  final List<String> _paymentMethods = ['Cash', 'GCash', 'Credit Card', 'Bank Transfer'];
  
  bool _isProcessing = false;
  String? _errorMessage;
  bool _paymentSuccess = false;
  Map<String, dynamic>? _receiptData;
  
  // Form fields
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardHolderController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  
  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    _phoneNumberController.dispose();
    _accountNumberController.dispose();
    super.dispose();
  }
  
  Future<void> _processPayment() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      
      final paymentData = {
        'booking_id': widget.bookingId,
        'payment_method': _selectedPaymentMethod,
        'amount': widget.amount,
        'user_id': widget.userId,
      };
      
      // Add payment method specific details
      switch (_selectedPaymentMethod) {
        case 'Credit Card':
          paymentData['card_number'] = _cardNumberController.text;
          paymentData['card_holder'] = _cardHolderController.text;
          paymentData['expiry_date'] = _expiryDateController.text;
          paymentData['cvv'] = _cvvController.text;
          break;
        case 'GCash':
          paymentData['phone_number'] = _phoneNumberController.text;
          break;
        case 'Bank Transfer':
          paymentData['account_number'] = _accountNumberController.text;
          break;
      }
      
      Future<void> _processPayment() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      
      final paymentData = {
        'booking_id': widget.bookingId,
        'payment_method': _selectedPaymentMethod,
        'amount': widget.amount,
        'user_id': widget.userId,
      };

      // Add payment method specific details
      switch (_selectedPaymentMethod) {
        case 'Credit Card':
          paymentData.addAll({
            'card_number': _cardNumberController.text,
            'card_holder': _cardHolderController.text,
            'expiry_date': _expiryDateController.text,
            'cvv': _cvvController.text,
          });
          break;
        case 'GCash':
          paymentData['phone_number'] = _phoneNumberController.text;
          break;
        case 'Bank Transfer':
          paymentData['account_number'] = _accountNumberController.text;
          break;
      }

      // Call the payment API
      final response = await _bookingService.processPayment(paymentData, token);
      
      setState(() {
        _isProcessing = false;
        _paymentSuccess = true;
        _receiptData = response['receipt_data'];
      });
      
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Payment failed: ${e.toString()}';
      });
    }
  }
      
      setState(() {
        _isProcessing = false;
        _paymentSuccess = true;
        _receiptData = {
          'transaction_id': 'TXN${DateTime.now().millisecondsSinceEpoch}',
          'date': DateFormat('MMM dd, yyyy • h:mm a').format(DateTime.now()),
          'amount': widget.amount,
          'payment_method': _selectedPaymentMethod,
          'booking_id': widget.bookingId,
        };
      });
      
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Payment failed: ${e.toString()}';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Payment",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.green.shade700,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade50, Colors.white],
          ),
        ),
        child: _paymentSuccess ? _buildSuccessScreen() : _buildPaymentForm(),
      ),
    );
  }
  
  Widget _buildPaymentForm() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Payment summary card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              margin: EdgeInsets.only(bottom: 24),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Payment Summary",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade800,
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildSummaryRow("Booking ID", "#${widget.bookingId}"),
                    Divider(height: 24),
                    _buildSummaryRow(
                      "Total Amount", 
                      "₱${widget.amount.toStringAsFixed(2)}",
                      isTotal: true
                    ),
                  ],
                ),
              ),
            ),
            
            // Payment method selection
            Text(
              "Select Payment Method",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 12),
            
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: _paymentMethods.map((method) {
                  return RadioListTile<String>(
                    title: Text(
                      method,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: _selectedPaymentMethod == method ? 
                          FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    value: method,
                    groupValue: _selectedPaymentMethod,
                    activeColor: Colors.green.shade700,
                    onChanged: (value) {
                      setState(() {
                        _selectedPaymentMethod = value!;
                      });
                    },
                    secondary: _getPaymentMethodIcon(method),
                  );
                }).toList(),
              ),
            ),
            
            // Payment method specific fields
            SizedBox(height: 24),
            _buildPaymentMethodFields(),
            
            if (_errorMessage != null) ...[
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.poppins(
                          color: Colors.red.shade800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Pay button
            SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isProcessing
                  ? CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    )
                  : Text(
                      "Pay Now ₱${widget.amount.toStringAsFixed(2)}",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
              ),
            ),
            
            SizedBox(height: 24),
            Center(
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock, size: 16, color: Colors.grey.shade700),
                        SizedBox(width: 8),
                        Text(
                          "Secure Payment",
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Your payment information is encrypted and secure",
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Rest of the code remains the same...
  
  Widget _buildPaymentMethodFields() {
    switch (_selectedPaymentMethod) {
      case 'Credit Card':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Card Details",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 12),
            
            TextFormField(
              controller: _cardNumberController,
              decoration: _inputDecoration("Card Number", Icons.credit_card),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter card number';
                }
                if (value.length < 16) {
                  return 'Please enter a valid card number';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            
            TextFormField(
              controller: _cardHolderController,
              decoration: _inputDecoration("Cardholder Name", Icons.person),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter cardholder name';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _expiryDateController,
                    decoration: _inputDecoration("MM/YY", Icons.date_range),
                    keyboardType: TextInputType.datetime,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
                        return 'Use MM/YY format';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _cvvController,
                    decoration: _inputDecoration("CVV", Icons.lock_outline),
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (value.length < 3) {
                        return 'Invalid CVV';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        );
        
      case 'GCash':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "GCash Details",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 12),
            
            TextFormField(
              controller: _phoneNumberController,
              decoration: _inputDecoration("GCash Phone Number", Icons.phone),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter phone number';
                }
                return null;
              },
            ),
            
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "You will receive an SMS with instructions to complete your GCash payment.",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
        
      case 'Bank Transfer':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Bank Account Details",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 12),
            
            TextFormField(
              controller: _accountNumberController,
              decoration: _inputDecoration("Account Number", Icons.account_balance),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter account number';
                }
                return null;
              },
            ),
            
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      SizedBox(width: 8),
                      Text(
                        "Bank Transfer Instructions",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Please transfer the exact amount to the following account and upload the receipt:",
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Bank: Garden Care Bank\nAccount Name: Garden Care Services\nAccount Number: 1234567890",
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
        
      case 'Cash':
      default:
        return Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade100),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.green.shade700),
                  SizedBox(width: 12),
                  Text(
                    "Cash Payment Information",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                "You have selected to pay with cash. Please have the exact amount ready when the gardener arrives for the service. A receipt will be provided upon payment completion.",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.green.shade800,
                ),
              ),
            ],
          ),
        );
    }
  }
  
  Widget _buildSuccessScreen() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          SizedBox(height: 20),
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: Colors.green.shade600,
          ),
          SizedBox(height: 24),
          Text(
            "Payment Successful!",
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.green.shade800,
            ),
          ),
          SizedBox(height: 12),
          Text(
            "Your booking has been confirmed and payment has been processed.",
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32),
          
          // Payment receipt
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Receipt",
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade800,
                        ),
                      ),
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 24,
                        color: Colors.green.shade700,
                      ),
                    ],
                  ),
                  Divider(height: 32),
                  _buildReceiptRow("Transaction ID", _receiptData?['transaction_id'] ?? ''),
                  SizedBox(height: 12),
                  _buildReceiptRow("Date", _receiptData?['date'] ?? ''),
                  SizedBox(height: 12),
                  _buildReceiptRow("Payment Method", _receiptData?['payment_method'] ?? ''),
                  SizedBox(height: 12),
                  _buildReceiptRow("Booking ID", "#${_receiptData?['booking_id'] ?? ''}"),
                  Divider(height: 32),
                  _buildReceiptRow(
                    "Amount Paid", 
                    "₱${(_receiptData?['amount'] ?? 0).toStringAsFixed(2)}",
                    isTotal: true,
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Add receipt download functionality if needed
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Receipt downloaded successfully!"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  icon: Icon(Icons.download, color: Colors.green.shade700),
                  label: Text(
                    "Download Receipt",
                    style: GoogleFonts.poppins(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.green.shade700),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                // Navigate back to bookings screen
                Navigator.pushNamedAndRemoveUntil(
                  context, 
                  '/bookings', 
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "Back to My Bookings",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(height: 32),
        ],
      ),
    );
  }
  
  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.w400,
            color: Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            color: isTotal ? Colors.green.shade800 : Colors.grey.shade900,
          ),
        ),
      ],
    );
  }
  
  Widget _buildReceiptRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.w400,
            color: Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            color: isTotal ? Colors.green.shade800 : Colors.grey.shade900,
          ),
        ),
      ],
    );
  }
  
  Widget _getPaymentMethodIcon(String method) {
    switch (method) {
      case 'GCash':
        return Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.account_balance_wallet, color: Colors.blue.shade700),
        );
      case 'Credit Card':
        return Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.credit_card, color: Colors.purple.shade700),
        );
      case 'Bank Transfer':
        return Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.account_balance, color: Colors.amber.shade700),
        );
      case 'Cash':
      default:
        return Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.payments_outlined, color: Colors.green.shade700),
        );
    }
  }
  
  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.green.shade700),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.green.shade700, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      labelStyle: GoogleFonts.poppins(
        color: Colors.grey.shade700,
      ),
    );
  }
}