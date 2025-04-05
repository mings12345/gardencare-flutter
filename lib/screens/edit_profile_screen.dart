import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gardencare_app/auth_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class EditProfileScreen extends StatefulWidget {
  final String name;
  final String email;
  final String address;
  final String phone;
  final File? image;

  const EditProfileScreen({
    Key? key,
    required this.name,
    required this.email,
    required this.address,
    required this.phone,
    this.image,
  }) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _emailController = TextEditingController(text: widget.email);
    _addressController = TextEditingController(text: widget.address);
    _phoneController = TextEditingController(text: widget.phone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _saveChanges() async {
    final updatedProfile = {
      'name': _nameController.text,
      'email': _emailController.text,
      'address': _addressController.text,
      'phone': _phoneController.text,
      'image': widget.image, // Include the image in the updated profile
    };

    final token = await AuthService.getToken();
    print("Retrieved Token: $token"); // Debugging: Print the token

    try {
      final response = await http.post(
        Uri.parse('https://devjeffrey.dreamhosters.com/api/profile/update'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(updatedProfile),
      );

      print("Response Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
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
      body: Padding(
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
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveChanges,
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