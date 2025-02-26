import 'package:flutter/material.dart';
import 'screens/registration_screen.dart';

class UserType extends StatefulWidget {
  @override
  _UserTypeSelectionScreenState createState() =>
      _UserTypeSelectionScreenState();
}

class _UserTypeSelectionScreenState extends State<UserType> {
  String _selectedUserType = 'homeowner'; // Lowercase user type

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(title: const Text('Select User Type')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            Text(
              'Please select your user type',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ListTile(
              title: const Text('Homeowner'),
              leading: Radio<String>(
                value: 'homeowner', // Lowercase value
                groupValue: _selectedUserType,
                onChanged: (value) {
                  setState(() {
                    _selectedUserType = value!;
                  });
                },
              ),
            ),
            ListTile(
              title: const Text('Gardener'),
              leading: Radio<String>(
                value: 'gardener', // Lowercase value
                groupValue: _selectedUserType,
                onChanged: (value) {
                  setState(() {
                    _selectedUserType = value!;
                  });
                },
              ),
            ),
            ListTile(
              title: const Text('Service Provider'),
              leading: Radio<String>(
                value: 'service_provider', // Lowercase value
                groupValue: _selectedUserType,
                onChanged: (value) {
                  setState(() {
                    _selectedUserType = value!;
                  });
                },
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RegistrationScreen(userType: _selectedUserType),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text('Proceed to Registration'),
            ),
          ],
        ),
      ),
    );
  }
}
