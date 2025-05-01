import 'package:flutter/material.dart';
import 'package:gardencare_app/models/user.dart';
import 'package:gardencare_app/screens/chat_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GardenerDetailsScreen extends StatelessWidget {
  final User gardener;

  const GardenerDetailsScreen({Key? key, required this.gardener}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      title: Text(
        gardener.name,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Colors.green[800],
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
    ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Center(
              child: Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.green[200]!,
                        width: 3,
                      ),
                    ),
                    child: Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.green[800],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    gardener.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    gardener.email,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Ratings Section
            _buildSectionHeader('Ratings & Reviews'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildRatingStat('4.8', 'Average Rating'),
                _buildRatingStat('24', 'Completed Jobs'),
                _buildRatingStat('2', 'Years Experience'),
              ],
            ),
            const SizedBox(height: 24),

            // Experience Section
            _buildSectionHeader('Experience'),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                gardener.bio ?? 'Professional gardener with extensive experience in care.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Highlighted Works
            _buildSectionHeader('Highlighted Works'),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildWorkImage('assets/images/garden1.jpg'),
                  _buildWorkImage('assets/images/garden2.jpg'),
                  _buildWorkImage('assets/images/garden3.jpg'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Contact Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.green[800],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _navigateToChat(context),
                child: const Text(
                  'Message Gardener',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Navigate to chat screen with the gardener
  Future<void> _navigateToChat(BuildContext context) async {
    try {
      // Get current user details from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getInt('userId');
      final authToken = prefs.getString('token');

      // Check if we have the required auth data
      if (currentUserId == null || authToken == null || authToken.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to message gardeners')),
        );
        return;
      }

      // Navigate to chat screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            currentUserId: currentUserId,
            otherUserId: gardener.id,
            userId: gardener.id, // The gardener's ID
            authToken: authToken,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening chat: ${e.toString()}')),
      );
    }
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          color: Colors.green,
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildRatingStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildWorkImage(String imagePath) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}