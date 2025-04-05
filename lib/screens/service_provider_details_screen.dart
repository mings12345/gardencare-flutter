import 'package:flutter/material.dart';
import 'package:gardencare_app/models/user.dart';

class ServiceProviderDetailsScreen extends StatelessWidget {
  final User provider;

  const ServiceProviderDetailsScreen({Key? key, required this.provider}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(provider.name),
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
                    provider.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    provider.email,
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
                _buildRatingStat('4.9', 'Average Rating'),
                _buildRatingStat('32', 'Completed Jobs'),
                _buildRatingStat('3', 'Years Experience'),
              ],
            ),
            const SizedBox(height: 24),

            // Experience Section
            _buildSectionHeader('Experience'),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                provider.bio ?? 'Professional service provider with extensive experience in landscaping and garden care.',
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
                  _buildWorkImage('assets/images/landscape1.jpg'),
                  _buildWorkImage('assets/images/landscape2.jpg'),
                  _buildWorkImage('assets/images/landscape3.jpg'),
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
                onPressed: () {
                  // Implement contact functionality
                },
                child: const Text(
                  'Contact Provider',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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