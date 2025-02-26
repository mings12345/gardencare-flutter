import 'package:flutter/material.dart';
import 'service_details_screen.dart';
import 'booking_form.dart'; // Import the booking form screen

class GardeningScreen extends StatefulWidget {
  @override
  _GardeningScreenState createState() => _GardeningScreenState();
}

class _GardeningScreenState extends State<GardeningScreen> {
  final List<Map<String, String>> gardeningServices = [
    {
      'name': 'Lawn Mowing',
      'description': 'Keep your lawn neat and tidy with our professional mowing service.',
      'image_url': 'assets/images/lawn mowing.jpg',
      'price': '₱50', // Added price
    },
    {
      'name': 'Plant Trimming',
      'description': 'Expert trimming to maintain the shape and health of your plants.',
      'image_url': 'assets/images/plant trimming.jpg',
      'price': '₱40', // Added price
    },
    {
      'name': 'Garden Maintenance',
      'description': 'Complete care for your garden, including weeding and fertilizing.',
      'image_url': 'assets/images/garden maintenance.jpg',
      'price': '₱70', // Added price
    },
    {
      'name': 'Soil Preparation',
      'description': 'Prepare your soil for planting with expert advice and service.',
      'image_url': 'assets/images/soil preparation.jpg',
      'price': '₱60', // Added price
    },
  ];

  final List<Map<String, String>> availableGardeners = [
    {'name': 'Dwight', 'experience': '5 years', 'rating': '4.8', 'image': 'assets/images/Dwight.jpg'},
    {'name': 'Nikki', 'experience': '5 years', 'rating': '5.3', 'image': 'assets/images/Nikki.jpg'},
    {'name': 'Nina', 'experience': '4 years', 'rating': '4.3', 'image': 'assets/images/Nina.jpg'},
    {'name': 'JL', 'experience': '4 years', 'rating': '4.3', 'image': 'assets/images/Pain.jpg'},
  ];

  List<Map<String, String>> filteredServices = [];

  @override
  void initState() {
    super.initState();
    filteredServices = gardeningServices; // Initially show all services
  }

  void _filterServices(String query) {
    setState(() {
      filteredServices = gardeningServices
          .where((service) =>
              service['name']!.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gardening Services"),
        backgroundColor: Colors.green,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Text Field
            TextField(
              onChanged: _filterServices, // Call the filter function
              decoration: InputDecoration(
                hintText: 'Search for services...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                prefixIcon: const Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: filteredServices.length,
                itemBuilder: (context, index) {
                  final service = filteredServices[index];
                  return Card(
                    elevation: 8,
                    margin: const EdgeInsets.symmetric(vertical: 10.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Service Image
                          if (service['image_url'] != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                service['image_url']!,
                                height: 150, // Fixed height for consistency
                                width: double.infinity, // Full width
                                fit: BoxFit.cover,
                              ),
                            ),
                          const SizedBox(height: 10),
                          // Service Name
                          Text(
                            service['name']!,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: Colors.green[900],
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Service Description
                          Text(
                            service['description']!,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Service Price
                          Text(
                            'Price: ${service['price']}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[800],
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Book Now Button and View Details Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Book Now Button
                              ElevatedButton(
                                onPressed: () {

                                  // Navigate to the booking form screen and pass the gardener list
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => BookingForm(
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[800],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Book Now',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              // View Details Link
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ServiceDetailsScreen(
                                        serviceName: service['name']!,
                                        serviceDescription: service['description']!,
                                        serviceImage: service['image_url']!,
                                        price: service['price']!,
                                        serviceType: 'Gardening', // Add the required serviceType argument
                                        availableGardeners: availableGardeners, // Pass the gardener list
                                      ),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'View Details',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}