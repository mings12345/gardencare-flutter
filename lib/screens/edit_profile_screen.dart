import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gardencare_app/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:gardencare_app/providers/user_provider.dart';
import 'dart:math';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

class EditProfileScreen extends StatefulWidget {
  final String name;
  final String email;
  final String address;
  final String phone;
  final String account;
  final String? profileImageUrl; 

  const EditProfileScreen({
    Key? key,
    required this.name,
    required this.email,
    required this.address,
    required this.phone,
    required this.account,
    this.profileImageUrl,
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
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

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

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _sendOtp() async {
    if (_accountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter your Account number"),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!RegExp(r'^09\d{9}$').hasMatch(_accountController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a valid Account number (09XXXXXXXXX)"),
          behavior: SnackBarBehavior.floating,
        ),
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
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("OTP Sent to your account number", 
              style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Your OTP is: $_otp", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
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
        const SnackBar(
          content: Text("Please enter the OTP"),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_enteredOtp != _otp) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invalid OTP. Please try again."),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isVerifyingOtp = true);
    await _saveChanges();
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
    await _saveChanges();
  }

  Future<void> _saveChanges() async {
  final String baseUrl = dotenv.get('BASE_URL'); 
  final token = await AuthService.getToken();

  try {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/profile/update'),
    )
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['name'] = _nameController.text
      ..fields['email'] = _emailController.text
      ..fields['address'] = _addressController.text
      ..fields['phone'] = _phoneController.text
      ..fields['account'] = _accountController.text;

    // Add image if selected
    if (_profileImage != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'profile_image',
          _profileImage!.path,
        ),
      );
    }

    final response = await request.send();
    final responseData = await response.stream.bytesToString();
    final Map<String, dynamic> responseJson = json.decode(responseData);

    if (response.statusCode == 200) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.setName(_nameController.text);
      userProvider.setEmail(_emailController.text);
      userProvider.setAddress(_addressController.text);
      userProvider.setPhone(_phoneController.text);
      userProvider.updateAccountNo(_accountController.text);
      
     String? imageUrl;
if (_profileImage != null) {
  // Prefer the full URL from backend
  imageUrl = responseJson['profile_image_url'] ?? 
            (responseJson['user'] != null ? responseJson['user']['profile_image_url'] : null);
  
  // Fallback to constructing URL if needed
  if (imageUrl == null && responseJson['profile_image'] != null) {
    final String baseUrl = dotenv.get('BASE_URL');
    imageUrl = '$baseUrl/storage/${responseJson['profile_image']}';
  }

  if (imageUrl != null) {
    print("Final image URL to use: $imageUrl");
    userProvider.updateProfileImage(imageUrl);
  }
}
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          content: const Text("Profile updated successfully!"),
          backgroundColor: Colors.green,
        ),
      );
      
      // Return updated data including image URL
      Navigator.pop(context, {
        'name': _nameController.text,
        'email': _emailController.text,
        'address': _addressController.text,
        'phone': _phoneController.text,
        'profileImageUrl': imageUrl ?? widget.profileImageUrl,
      });
    } else {
      final errorMessage = responseJson['message'] ?? 
          "Failed to update profile. Status Code: ${response.statusCode}";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text("Error: ${e.toString()}"),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        centerTitle: true,
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Profile Picture Section
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[200],
                            border: Border.all(
                              color: Colors.green[300]!,
                              width: 2,
                            ),
                            image: _profileImage != null
                                ? DecorationImage(
                                    image: FileImage(_profileImage!),
                                    fit: BoxFit.cover,
                                  )
                                : widget.profileImageUrl != null
                                    ? DecorationImage(
                                        image: NetworkImage(widget.profileImageUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                          ),
                          child: _profileImage == null && widget.profileImageUrl == null
                              ? const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.grey,
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.green[700],
                            ),
                            child: const Icon(
                              Icons.edit,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Form Fields
                _buildInputField(
                  controller: _nameController,
                  label: "Full Name",
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  controller: _emailController,
                  label: "Email Address",
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  controller: _addressController,
                  label: "Address",
                  icon: Icons.location_on_outlined,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  controller: _phoneController,
                  label: "Phone Number",
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 24),
                
                // Account Number Section
                Text(
                  "Account Verification",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Verify your account number to enable payments",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildInputField(
                        controller: _accountController,
                        label: "Account Number",
                        hintText: "09XXXXXXXXX",
                        icon: Icons.account_balance_wallet_outlined,
                        keyboardType: TextInputType.phone,
                        suffixIcon: _accountController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: _removeAccount,
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
                
                if (_showOtpField) ...[
                  const SizedBox(height: 16),
                  _buildInputField(
                    label: "Enter OTP",
                    hintText: "6-digit code",
                    controller: TextEditingController(),   
                    icon: Icons.lock_outline,
                    keyboardType: TextInputType.number,
                    onChanged: (value) => _enteredOtp = value,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      TextButton(
                        onPressed: _isSendingOtp ? null : _sendOtp,
                        child: Text(
                          "Resend OTP",
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: _isVerifyingOtp ? null : _verifyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: _isVerifyingOtp
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                "Verify OTP",
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                      ),
                    ],
                  ),
                ] else if (_accountController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isSendingOtp ? null : _sendOtp,
                      child: Text(
                        "Update Account Number",
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
                
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : 
                            (_accountController.text.isNotEmpty && !_showOtpField
                      ? _saveChanges
                      : _showOtpField
                          ? null
                          : _saveChanges),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        )
                      : const Text(
                          "SAVE CHANGES",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController? controller,
    required String label,
    String? hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        labelStyle: TextStyle(color: Colors.grey[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green[400]!, width: 2),
        ),
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }
}