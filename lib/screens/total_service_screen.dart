import 'package:flutter/material.dart';

class TotalServiceScreen extends StatefulWidget {
  final String userRole;

  TotalServiceScreen({required this.userRole});

  @override
  State<TotalServiceScreen> createState() => _TotalServiceScreenState();
}

class _TotalServiceScreenState extends State<TotalServiceScreen> {
  // Services list with price, image, and background color
  List<Map<String, dynamic>> allServices = [
    // Gardening services
    {
      'name': 'Plant Care',
      'image': 'assets/images/plantcare.jpg',
      'price': '50',
      'backgroundColor': '#B2DDE1FF',
      'role': 'gardener',
    },
    {
      'name': 'Plant Trimming',
      'image': 'assets/images/plant trimming.jpg',
      'price': '30',
      'backgroundColor': '#B2DDE1FF',
      'role': 'gardener',
    },
    {
      'name': 'Weeding',
      'image': 'assets/images/weeding-services.jpg',
      'price': '40',
      'backgroundColor': '#B2DDE1FF',
      'role': 'gardener',
    },
    {
      'name': 'Watering',
      'image': 'assets/images/watering.jpg',
      'price': '20',
      'backgroundColor': '#B2DDE1FF',
      'role': 'gardener',
    },
    // Landscaping services
    {
      'name': 'Lawn Mowing',
      'image': 'assets/images/lawn_mowing.jpg',
      'price': '60',
      'backgroundColor': '#B2DDE1FF',
      'role': 'service_provider',
    },
    {
      'name': 'Garden Design',
      'image': 'assets/images/garden_design.jpg',
      'price': '150',
      'backgroundColor': '#B2DDE1FF',
      'role': 'service_provider',
    },
    {
      'name': 'Tree Pruning',
      'image': 'assets/images/tree_pruning.jpg',
      'price': '80',
      'backgroundColor': '#B2DDE1FF',
      'role': 'service_provider',
    },
    {
      'name': 'Mulching',
      'image': 'assets/images/mulching.jpg',
      'price': '70',
      'backgroundColor': '#B2DDE1FF',
      'role': 'service_provider',
    },
  ];

  List<Map<String, dynamic>> get services {
    return allServices.where((service) => service['role'] == widget.userRole).toList();
  }

  // Convert HEX color code to Flutter's Color object
  Color _hexToColor(String hex) {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  }

  // Show Add Service Dialog
  void _showAddServiceDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController priceController = TextEditingController();
    final TextEditingController imageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Service'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Service Name'),
                ),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price',
                    hintText: 'Enter the price in dollars',
                  ),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: imageController,
                  decoration: const InputDecoration(
                    labelText: 'Image Path',
                    hintText: 'e.g., assets/images/service.jpg',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog without action
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    priceController.text.isNotEmpty &&
                    imageController.text.isNotEmpty) {
                  setState(() {
                    allServices.add({
                      'name': nameController.text,
                      'price': priceController.text,
                      'image': imageController.text,
                      'backgroundColor': '#B2DDE1FF', // Default color
                      'role': widget.userRole, // Add role to the new service
                    });
                  });
                  Navigator.pop(context); // Close dialog after adding
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  // Method to delete a service
  void _deleteService(int index) {
    setState(() {
      allServices.removeWhere((service) => service['role'] == widget.userRole && services[index] == service);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Total Services'),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // Two items per row
                  crossAxisSpacing: 16.0, // Horizontal spacing
                  mainAxisSpacing: 16.0, // Vertical spacing
                  childAspectRatio: 2 / 3, // Adjust aspect ratio for card size
                ),
                itemCount: services.length,
                itemBuilder: (context, index) {
                  final service = services[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: _hexToColor(service['backgroundColor']),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Image with consistent size
                        SizedBox(
                          height: 120, // Set fixed height
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                            child: Image.asset(
                              service['image'],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.broken_image,
                                  size: 50,
                                  color: Colors.grey,
                                );
                              },
                            ),
                          ),
                        ),
                        // Service Name and Price
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Column(
                            children: [
                              Text(
                                service['name'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '\$${service['price']}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Delete Button
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () => _deleteService(index),
                            child: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          // Add Service Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextButton(
              onPressed: _showAddServiceDialog,
              style: TextButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(
                  vertical: 12.0,
                  horizontal: 24.0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Add New Service',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}