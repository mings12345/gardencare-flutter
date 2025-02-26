import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ServiceProviderProfile extends StatefulWidget {
  final String name;
  final String role;
  final String email;
  final String phone;
  final String address;

  const ServiceProviderProfile({
    Key? key,
    required this.name,
    required this.role,
    required this.email,
    required this.phone,
    required this.address,
  }) : super(key: key);

  @override
  State<ServiceProviderProfile> createState() => _ServiceProviderProfileState();
}

class _ServiceProviderProfileState extends State<ServiceProviderProfile> {
  late String name;
  late String role;
  late String email;
  late String phone;
  late String address;
  String? _imagePath;

  bool isEditing = false; // Toggle between view and edit mode

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

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imagePath = pickedFile.path;
      });
    }
  }

  void _toggleEdit() {
    setState(() {
      if (isEditing) {
        // Save changes
        email = emailController.text;
        phone = phoneController.text;
        address = addressController.text;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
      isEditing = !isEditing; // Toggle editing mode
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 16),

              // Circle Avatar with Upload Icon
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: _imagePath != null
                          ? FileImage(File(_imagePath!))
                          : const AssetImage('assets/images/haise.jpg') as ImageProvider,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 17,
                        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, color: Colors.green, size: 20,),
                          onPressed: _pickImage,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

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
                enabled: isEditing, // Enable only in edit mode
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
                enabled: isEditing, // Enable only in edit mode
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
                enabled: isEditing, // Enable only in edit mode
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.home),
                ),
              ),
              const SizedBox(height: 24),
              // Edit / Save Changes Button
              ElevatedButton(
                onPressed: _toggleEdit,
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
    );
  }
}