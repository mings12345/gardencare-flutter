import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';

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
  File? _image; 

  final String _updateProfileUrl = "http://gardencare.test/api/update-profile"; // Replace with your Laravel API URL

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _emailController = TextEditingController(text: widget.email);
    _addressController = TextEditingController(text: widget.address);
    _phoneController = TextEditingController(text: widget.phone);
    _image = widget.image;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveChanges() async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(_updateProfileUrl));
      
      // Add form fields
      request.fields['name'] = _nameController.text;
      request.fields['email'] = _emailController.text;
      request.fields['address'] = _addressController.text;
      request.fields['phone'] = _phoneController.text;
      
      // Add image if selected
      if (_image != null) {
        request.files.add(await http.MultipartFile.fromPath('image', _image!.path));
      }

      // Send request
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var responseData = json.decode(responseBody);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'] ?? 'Profile updated successfully')),
        );
        Navigator.pop(context, {
          'name': _nameController.text,
          'email': _emailController.text,
          'address': _addressController.text,
          'phone': _phoneController.text,
          'image': _image,
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: ${response.reasonPhrase}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
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
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _image != null
                    ? FileImage(_image!)
                    : const AssetImage('assets/images/violet.jpg') as ImageProvider,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: "Name")),
            TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: "Email")),
            TextFormField(controller: _addressController, decoration: const InputDecoration(labelText: "Address")),
            TextFormField(controller: _phoneController, decoration: const InputDecoration(labelText: "Phone")),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text("Save Changes", style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
