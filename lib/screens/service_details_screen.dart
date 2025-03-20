import 'package:flutter/material.dart';
import 'booking_form.dart';
import 'gardener_details_screen.dart';

class ServiceDetailsScreen extends StatelessWidget {
  final String serviceName;
  final String serviceDescription;
  final String serviceImage;
  final String price;
  final String serviceType;
  final List<Map<String, dynamic>> availableGardeners;

  const ServiceDetailsScreen({
    Key? key,
    required this.serviceName,
    required this.serviceDescription,
    required this.serviceImage,
    required this.price,
    required this.serviceType,
    required this.availableGardeners,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(serviceName),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                serviceImage, // Use Image.asset to load the image from assets
                fit: BoxFit.cover,
                width: double.infinity,
                height: 200,
              ),
            ),
            const SizedBox(height: 16),

            // Service Name
            Text(serviceName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Service Description
            Text(serviceDescription, style: const TextStyle(fontSize: 18, color: Colors.black87)),
            const SizedBox(height: 16),

            // Service Price
            Text(
              'Price: $price',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const SizedBox(height: 16),
            
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookingForm(
                    ),
                  ),
                );
              },
              child: const Text('Book Service'),
            ),
            const SizedBox(height: 16),
            // Available Gardeners Section
            const Text('Available Gardeners', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: availableGardeners.length,
              itemBuilder: (context, index) {
                final gardener = availableGardeners[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 4,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: AssetImage(gardener['image']!), // Display gardener's image
                      backgroundColor: Colors.green,
                    ),
                    title: Text(
                      gardener['name']!,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Experience: ${gardener['experience']}'),
                        Text('Rating: ${gardener['rating']}⭐'),
                      ],
                    ),
                    trailing: TextButton(
                      onPressed: () {
                        // Navigate to GardenerDetailsScreen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GardenerDetailsScreen(
                              name: gardener['name']!,
                              experience: gardener['experience']!,
                              rating: gardener['rating']!,
                              image: gardener['image']!,
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'View',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}