import 'package:flutter/material.dart';
import 'package:gardencare_app/auth_service.dart';
import 'package:gardencare_app/screens/booking_history.dart';
import 'package:gardencare_app/screens/homeowner_screen.dart';
import 'package:gardencare_app/screens/calendar_screen.dart';
import 'package:gardencare_app/screens/login_screen.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String name;
  final String email;
  final String address;
  final String phone;

  const ProfileScreen({
    Key? key,
    required this.name,
    required this.email,
    required this.address,
    required this.phone,
  }) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late String name;
  late String email;
  late String address;
  late String phone;
  File? _image; // To store the selected image

  @override
  void initState() {
    super.initState();
    name = widget.name;
    email = widget.email;
    address = widget.address;
    phone = widget.phone;
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
          image: _image, // Pass the current image to the edit screen
        ),
      ),
    );

    if (updatedProfile != null) {
      setState(() {
        name = updatedProfile['name'];
        email = updatedProfile['email'];
        address = updatedProfile['address'];
        phone = updatedProfile['phone'];
        _image = updatedProfile['image']; // Update the image
      });
    }
  }

  void _viewBookingHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => const BookingHistoryScreen(userRole: 'homeowner')),
    );
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
  void _logout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Add your logout logic here
                Navigator.of(context).pop(); // Close the dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                ); // Navigate to the HomeownerScreen
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
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
                  image: _image)), // Pass _image to _TopPortion
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

class EditProfileScreen extends StatefulWidget {
  final String name;
  final String email;
  final String address;
  final String phone;

  const EditProfileScreen({
    Key? key,
    required this.name,
    required this.email,
    required this.address,
    required this.phone,
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

  void _saveChanges() {
    final updatedProfile = {
      'name': _nameController.text,
      'email': _emailController.text,
      'address': _addressController.text,
      'phone': _phoneController.text,
    };

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Saved Successfully"),
        duration: Duration(seconds: 2),
      ),
    );

    // Delay navigation back to the profile screen
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context, updatedProfile);
    });
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
  final File? image;

  const _TopPortion({
    Key? key,
    required this.name,
    required this.email,
    required this.address,
    required this.phone,
    this.image,
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
              child: CircleAvatar(
                backgroundImage: image != null
                    ? FileImage(image!) // Display the selected image
                    : const AssetImage('assets/images/violet.jpg')
                        as ImageProvider, // Default image
              ),
            ),
          ),
        ),
      ],
    );
  }
}