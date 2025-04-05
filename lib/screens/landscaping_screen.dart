import 'package:flutter/material.dart';
import 'package:gardencare_app/screens/booking_form.dart';
import 'landscaping_service_details.dart';

class LandscapingScreen extends StatefulWidget {
  @override
  _LandscapingScreenState createState() => _LandscapingScreenState();
}

class _LandscapingScreenState extends State<LandscapingScreen> {
  final List<Map<String, String>> landscapingServices = [
    {
      'name': 'Garden Design',
      'description': 'Transform your outdoor space with professional design and planning.',
      'image_url': 'assets/images/garden design.jpg',
      'price': '₱4500',
    },
    {
      'name': 'Fencing',
      'description': 'Keep your lawn neat and tidy with our fencing services.',
      'image_url': 'assets/images/fencing.jpg',
      'price': '₱4000',
    },
    {
      'name': 'Pathway Construction',
      'description': 'Professional pathway construction to enhance your garden.',
      'image_url': 'assets/images/pathway.jpg',
      'price': '₱5000',
    },
    {
      'name': 'Hedge Trimming',
      'description': 'Maintain the perfect shape of your hedges.',
      'image_url': 'assets/images/hedge trimming.jpg',
      'price': '₱2000',
    },
    {
      'name': 'Outdoor Furniture',
      'description': 'Stylish and comfortable outdoor furniture.',
      'image_url': 'assets/images/outdoor.jpg',
      'price': '₱7000',
    },
    {
      'name': 'Irrigation System Installation',
      'description': 'Efficient irrigation systems for your garden.',
      'image_url': 'assets/images/irrigation.jpg',
      'price': '₱8000',
    },
  ];

  
  List<Map<String, String>> filteredServices = [];

  @override
  void initState() {
    super.initState();
    filteredServices = landscapingServices; // Initially show all services
  }

  void _filterServices(String query) {
    setState(() {
      filteredServices = landscapingServices
          .where((service) =>
              service['name']!.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Landscaping Services"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Bar
            TextField(
              onChanged: _filterServices,
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

            // Service List
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
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(
                                service['image_url']!,
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          const SizedBox(height: 10),

                          // Service Name
                          Text(
                            service['name']!,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
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
                              color: Colors.green[700],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Align "View Service Details" and "Book Now" in a row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => BookingForm()
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                child: const Text('Book Now'),
                              ),
                              // View Details Button
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => LandscapingServiceDetails(
                                        serviceName: service['name']!,
                                        serviceDescription: service['description']!,
                                        serviceImage: service['image_url']!,
                                        price: service['price']!,
                                        serviceType: 'Landscaping', // Add the required serviceType argument
                                      ),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'View Service Details',
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
                          const SizedBox(height: 16),
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