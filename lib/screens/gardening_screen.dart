import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'service_details_screen.dart';
import 'booking_form.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GardeningScreen extends StatefulWidget {
  @override
  _GardeningScreenState createState() => _GardeningScreenState();
}

class _GardeningScreenState extends State<GardeningScreen> {
  List<dynamic> gardeningServices = [];
  List<dynamic> filteredServices = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchGardeningServices();
  }

  Future<void> _fetchGardeningServices() async {
    try {
      final String baseUrl = dotenv.get('BASE_URL'); 
      final response = await http.get(
        Uri.parse('$baseUrl/api/services/gardening'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          gardeningServices = data['services'];
          filteredServices = gardeningServices;
          isLoading = false;
        });
        print('Fetched services: ${gardeningServices.length}');
        if (gardeningServices.isNotEmpty) {
          print('First service image URL: ${gardeningServices[0]['image']}');
        }
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
      print('Error fetching services: ${e.toString()}');
    }
  }

  void _filterServices(String query) {
    setState(() {
      filteredServices = gardeningServices
          .where((service) =>
              service['name'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     appBar: AppBar(
      title: Text(
        "Gardening Services",
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 20,
        ),
      ),
      backgroundColor: Colors.green[800],
        centerTitle: true,
        elevation: 2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(15),
          ),
        ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Text Field
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
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : errorMessage.isNotEmpty
                      ? Center(child: Text(errorMessage))
                      : filteredServices.isEmpty
                          ? const Center(child: Text('No services found'))
                          : ListView.builder(
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
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: service['image'] != null && service['image'].toString().isNotEmpty
                                              ? Image.network(
                                                  service['image'],
                                                  height: 150,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    print('Error loading image: $error');
                                                    print('Image URL: ${service['image']}');
                                                    return Container(
                                                      height: 150,
                                                      color: Colors.grey[200],
                                                      child: Center(
                                                        child: Column(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: [
                                                            Icon(Icons.image_not_supported, size: 40),
                                                            SizedBox(height: 8),
                                                            Text('Image not available', 
                                                              style: TextStyle(color: Colors.grey[600]))
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                )
                                              : Container(
                                                  height: 150,
                                                  color: Colors.grey[200],
                                                  child: Center(
                                                    child: Column(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        Icon(Icons.image, size: 40, color: Colors.grey[400]),
                                                        SizedBox(height: 8),
                                                        Text('No Image', style: TextStyle(color: Colors.grey[600])),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                        ),
                                        const SizedBox(height: 10),
                                        // Service Name
                                        Text(
                                          service['name'],
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.green[900],
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        // Service Description
                                        Text(
                                          service['description'] ?? 'No description available',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.black87,
                                            height: 1.5,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        // Service Price
                                        Text(
                                          'Price: ₱${service['price']}',
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
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => BookingForm(
                                                preselectedServiceId: service['id'],
                                                serviceType: 'Gardening',
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
                                                      service: service,
                                                      serviceName: service['name'],
                                                      serviceDescription: service['description'] ?? '',
                                                      serviceImage: service['image'] ?? '',
                                                      price: '₱${service['price']}',
                                                      serviceType: 'Gardening',
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
            )],
        ),
      ),
    );
  }
}