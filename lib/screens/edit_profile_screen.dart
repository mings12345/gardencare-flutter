import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gardencare_app/auth_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:gardencare_app/providers/user_provider.dart';
import 'dart:math';
import 'package:provider/provider.dart';

class EditProfileScreen extends StatefulWidget {
  final String name;
  final String email;
  final String address;
  final String phone;
  final String account;

  const EditProfileScreen({
    Key? key,
    required this.name,
    required this.email,
    required this.address,
    required this.phone,
    required this.account,
  }) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _accountController;

  // OTP Verification State
  String? _otp;
  String? _enteredOtp;
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  bool _showOtpField = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _emailController = TextEditingController(text: widget.email);
    _addressController = TextEditingController(text: widget.address);
    _phoneController = TextEditingController(text: widget.phone);
    _accountController = TextEditingController(text: widget.account);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _accountController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_accountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your Account number")),
      );
      return;
    }

    if (!RegExp(r'^09\d{9}$').hasMatch(_accountController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid Account number (09XXXXXXXXX)")),
      );
      return;
    }

    setState(() => _isSendingOtp = true);

    // Simulate OTP sending
    await Future.delayed(const Duration(seconds: 2));

    // Generate random 6-digit OTP
    final random = Random();
    setState(() {
      _otp = List.generate(6, (index) => random.nextInt(10)).join();
      _showOtpField = true;
      _isSendingOtp = false;
    });

    // Show OTP to user (in production, this would be sent via SMS)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("OTP Sent to your account number", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text("Your OTP is: $_otp"),
            const SizedBox(height: 4),
            const Text("Enter this code to verify your account number"),
          ],
        ),
        duration: const Duration(seconds: 10),
      ),
    );
  }

  Future<void> _verifyOtp() async {
    if (_enteredOtp == null || _enteredOtp!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter the OTP")),
      );
      return;
    }

    if (_enteredOtp != _otp) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid OTP. Please try again.")),
      );
      return;
    }

    setState(() => _isVerifyingOtp = true);

    // If OTP is correct, proceed with saving
    _saveChanges();

    setState(() {
      _isVerifyingOtp = false;
      _showOtpField = false;
    });
  }

  Future<void> _removeAccount() async {
    setState(() {
      _accountController.clear();
      _showOtpField = false;
    });
    _saveChanges();
  }

  void _saveChanges() async {
    final updatedProfile = {
      'name': _nameController.text,
      'email': _emailController.text,
      'address': _addressController.text,
      'phone': _phoneController.text,
      'account': _accountController.text,
    };
    print("Updated Profile: $updatedProfile");

    final String baseUrl = dotenv.get('BASE_URL'); 
    final token = await AuthService.getToken();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/profile/update'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(updatedProfile),
      );

      if (response.statusCode == 200) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.updateAccountNo(_accountController.text);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile updated successfully!"),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, updatedProfile);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to update profile. Status Code: ${response.statusCode}"),
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
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: "Address"),
            ),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: "Phone"),
            ),
            const SizedBox(height: 16),
            
            //  Number Section
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _accountController,
                    decoration: const InputDecoration(
                      labelText: "Account Number",
                      hintText: "09XXXXXXXXX",
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ),
                if (_accountController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: _removeAccount,
                  ),
              ],
            ),
            
            if (_showOtpField) ...[
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Enter OTP",
                  hintText: "6-digit code",
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) => _enteredOtp = value,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton(
                    onPressed: _isSendingOtp ? null : _sendOtp,
                    child: const Text("Resend OTP"),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _isVerifyingOtp ? null : _verifyOtp,
                    child: _isVerifyingOtp
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text("Verify OTP"),
                  ),
                ],
              ),
            ] else if (_accountController.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isSendingOtp ? null : _sendOtp,
                  child: const Text("Update Account Number"),
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _accountController.text.isNotEmpty && !_showOtpField
                  ? _saveChanges
                  : _showOtpField
                      ? null
                      : _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text(
                "Save Changes",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}