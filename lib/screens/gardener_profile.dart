import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gardencare_app/auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GardenerProfile extends StatefulWidget {
  final String name;
  final String role;
  final String email;
  final String phone;
  final String address;

  const GardenerProfile({
    Key? key,
    required this.name,
    required this.role,
    required this.email,
    required this.phone,
    required this.address,
  }) : super(key: key);

  @override
  State<GardenerProfile> createState() => _GardenerProfileState();
}

class _GardenerProfileState extends State<GardenerProfile> {
  late String name;
  late String role;
  late String email;
  late String phone;
  late String address;
  File? _profileImage;

  bool isEditing = false;
  bool isLoading = false;

  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController addressController;

  @override
  void initState() {
    super.initState();
    name = widget.name;
    role = widget.role;
    email = widget.email;
    phone = widget.phone;
    address = widget.address;

    emailController = TextEditingController(text: email);
    phoneController = TextEditingController(text: phone);
    addressController = TextEditingController(text: address);
  }

  Future<void> _updateProfile() async {
    setState(() {
      isLoading = true;
    });
    final String baseUrl = dotenv.get('BASE_URL'); 
    final token = await AuthService.getToken();
    final url = Uri.parse('$baseUrl/api/profile/update');

    try {
      // Create multipart request for potential image upload
      var request = http.MultipartRequest('PUT', url);
      request.headers['Authorization'] = 'Bearer $token';

      // Add text fields
      request.fields['name'] = name;
      request.fields['email'] = emailController.text;
      request.fields['phone'] = phoneController.text;
      request.fields['address'] = addressController.text;

      // Add image if selected
      if (_profileImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            _profileImage!.path,
          ),
        );
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        // Update local state with new values
        setState(() {
          email = emailController.text;
          phone = phoneController.text;
          address = addressController.text;
          isEditing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: ${json.decode(responseData)['message']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _toggleEdit() {
    if (isEditing) {
      _updateProfile(); // Save changes when exiting edit mode
    } else {
      setState(() {
        isEditing = !isEditing; // Enter edit mode
      });
    }
  }

  Future<void> _pickImage() async {
    if (!isEditing) return; // Only allow image picking in edit mode

    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.green,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // Profile Image
                  GestureDetector(
                    onTap: isEditing ? _pickImage : null,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: _profileImage != null
                              ? FileImage(_profileImage!)
                              : const AssetImage('assets/images/Pain.jpg') as ImageProvider,
                        ),
                        if (isEditing)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 15,
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.camera_alt,
                                color: Colors.green,
                                size: 20,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Name and Role
                  Text(
                    name,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    role,
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  // Email Field
                  TextField(
                    controller: emailController,
                    enabled: isEditing,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Phone Field
                  TextField(
                    controller: phoneController,
                    enabled: isEditing,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Address Field
                  TextField(
                    controller: addressController,
                    enabled: isEditing,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.home),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Edit/Save Button
                  ElevatedButton(
                    onPressed: isLoading ? null : _toggleEdit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    ),
                    child: Text(
                      isEditing ? 'SAVE CHANGES' : 'EDIT',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}