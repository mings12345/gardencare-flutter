import 'package:flutter/material.dart';
import 'package:gardencare_app/screens/booking_form.dart';
import 'provider_details_screen.dart'; // Import the provider details screen

class LandscapingServiceDetails extends StatelessWidget {
  final String serviceName;
  final String serviceDescription;
  final String serviceImage;
  final String serviceType;
  final String price; // Add price parameter
  final List<Map<String, String>> serviceProviders; // Add serviceProviders parameter

  const LandscapingServiceDetails({
    Key? key,
    required this.serviceName,
    required this.serviceDescription,
    required this.serviceImage,
    required this.price, // Add price parameter
    required this.serviceType,
    required this.serviceProviders, // Add serviceProviders parameter
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(serviceName),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Service Image
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  serviceImage,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),

              // Service Name
              Text(
                serviceName,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Service Description
              Text(
                serviceDescription,
                style: const TextStyle(fontSize: 18, color: Colors.black87),
              ),
              const SizedBox(height: 16),

              // Service Price
              Text(
                'Price: $price', // Display the price
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
              const SizedBox(height: 16),

              // Book Now Button
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookingForm(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Book Service'),
              ),
              const SizedBox(height: 24),

              // Available Service Providers Section
              const Text(
                'Available Service Providers',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: serviceProviders.length,
                itemBuilder: (context, index) {
                  final provider = serviceProviders[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 4,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: AssetImage(provider['image']!), // Display provider's image
                        backgroundColor: Colors.green,
                      ),
                      title: Text(
                        provider['name']!,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Experience: ${provider['experience']}'),
                          Text('Rating: ${provider['rating']}⭐'),
                        ],
                      ),
                      trailing: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProviderDetailsScreen(provider: provider),
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
      ),
    );
  }
}