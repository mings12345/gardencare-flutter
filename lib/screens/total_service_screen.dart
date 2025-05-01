import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TotalServiceScreen extends StatefulWidget {
  final String userRole;

  TotalServiceScreen({required this.userRole});

  @override
  State<TotalServiceScreen> createState() => _TotalServiceScreenState();
}

class _TotalServiceScreenState extends State<TotalServiceScreen> {
  List<dynamic> allServices = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    try {
      final String baseUrl = dotenv.get('BASE_URL');
      final response = await http.get(
        Uri.parse('$baseUrl/api/services/${widget.userRole == 'gardener' ? 'gardening' : 'landscaping'}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          allServices = data['services'];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load services. Please try again.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'An error occurred: ${e.toString()}';
        isLoading = false;
      });
    }
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
    final TextEditingController descriptionController = TextEditingController();

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
                    hintText: 'Enter the price',
                  ),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: imageController,
                  decoration: const InputDecoration(
                    labelText: 'Image URL',
                    hintText: 'Enter image URL',
                  ),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Enter service description',
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
              onPressed: () async {
                if (nameController.text.isNotEmpty &&
                    priceController.text.isNotEmpty) {
                  try {
                    final String baseUrl = dotenv.get('BASE_URL');
                    final response = await http.post(
                      Uri.parse('$baseUrl/api/services'),
                      headers: {'Content-Type': 'application/json'},
                      body: json.encode({
                        'name': nameController.text,
                        'price': priceController.text,
                        'image': imageController.text,
                        'description': descriptionController.text,
                        'type': widget.userRole == 'gardener' ? 'gardening' : 'landscaping'
                      }),
                    );

                    if (response.statusCode == 201) {
                      _fetchServices(); // Refresh the list
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to add service: ${response.body}')),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
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
  void _deleteService(String serviceId) async {
    try {
      final String baseUrl = dotenv.get('BASE_URL');
      final response = await http.delete(
        Uri.parse('$baseUrl/api/services/$serviceId'),
      );

      if (response.statusCode == 200) {
        _fetchServices(); // Refresh the list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete service')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
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
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage.isNotEmpty
                    ? Center(child: Text(errorMessage))
                    : Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16.0,
                            mainAxisSpacing: 16.0,
                            childAspectRatio: 2 / 3,
                          ),
                          itemCount: allServices.length,
                          itemBuilder: (context, index) {
                            final service = allServices[index];
                            return Container(
                              decoration: BoxDecoration(
                                color: _hexToColor('#B2DDE1FF'),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Image with consistent size
                                  SizedBox(
                                    height: 120,
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        topRight: Radius.circular(12),
                                      ),
                                      child: service['image'] != null && service['image'].toString().isNotEmpty
                                          ? Image.network(
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
                                            )
                                          : const Icon(
                                              Icons.image,
                                              size: 50,
                                              color: Colors.grey,
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
                                          '₱${service['price']}',
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
                                      onPressed: () => _deleteService(service['_id']),
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