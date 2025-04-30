import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gardencare_app/screens/bookings_screen.dart';
import 'package:gardencare_app/screens/chat_list_screen.dart';
import 'package:gardencare_app/screens/plant_care_screen.dart';
import 'package:gardencare_app/screens/service_details_screen.dart';
import 'package:gardencare_app/screens/landscaping_screen.dart';
import 'package:gardencare_app/screens/profile_screen.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/banner_widget.dart';
import './gardening_screen.dart';

class HomeownerScreen extends StatefulWidget {
  final String name;
  final String email;
  final String address;
  final String phone;
  final String account;

  HomeownerScreen({
    required this.name,
    required this.email,
    required this.address,
    required this.phone,
    required this.account,
  });

  @override
  _HomeownerScreenState createState() => _HomeownerScreenState();
}

class _HomeownerScreenState extends State<HomeownerScreen> {
  int _selectedIndex = 0;
  late PageController _pageController;
  List<dynamic> gardeningServices = [];
  List<dynamic> landscapingServices = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    try {
      final String baseUrl = dotenv.get('BASE_URL');
      
      // Fetch gardening services
      final gardeningResponse = await http.get(
        Uri.parse('$baseUrl/api/services/gardening'),
      );
      
      // Fetch landscaping services
      final landscapingResponse = await http.get(
        Uri.parse('$baseUrl/api/services/landscaping'),
      );

      if (gardeningResponse.statusCode == 200 && landscapingResponse.statusCode == 200) {
        final gardeningData = json.decode(gardeningResponse.body);
        final landscapingData = json.decode(landscapingResponse.body);
        
        setState(() {
          gardeningServices = gardeningData['services'].take(4).toList(); // Get first 4 services
          landscapingServices = landscapingData['services'].take(4).toList(); // Get first 4 services
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
      print('Error fetching services: ${e.toString()}');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 0
          ? AppBar(
              title: const Text("Welcome to GardenCare"),
              backgroundColor: Colors.green,
               automaticallyImplyLeading: false, 
            )
          : null,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: [
          _buildHomePage(),
          BookingsScreen(),
          ChatListScreen(),
          ProfileScreen(
            name: widget.name,
            email: widget.email,
            address: widget.address,
            phone: widget.phone,
            account: widget.account,
          ),
        ],
      ),
      bottomNavigationBar: SalomonBottomBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          SalomonBottomBarItem(
            icon: const Icon(Icons.home),
            title: const Text('Home'),
            selectedColor: Colors.green,
          ),
          SalomonBottomBarItem(
            icon: const Icon(Icons.bookmark),
            title: const Text('Appointments'),
            selectedColor: Colors.green,
          ),
          SalomonBottomBarItem(
            icon: const Icon(Icons.message),
            title: const Text('Messages'),
            selectedColor: Colors.green,
          ),
          SalomonBottomBarItem(
            icon: const Icon(Icons.account_circle),
            title: const Text('Profile'),
            selectedColor: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildHomePage() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (errorMessage.isNotEmpty) {
      return Center(child: Text(errorMessage));
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        BannerWidget(),
        const SizedBox(height: 18),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            'assets/images/gardening.jpg',
            height: 250,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            "Book a Service",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text("View Plant Care Tips"),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PlantCareScreen()),
            );
          },
        ),
        const SizedBox(height: 24),

        // Gardening Services Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Gardening Services',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => GardeningScreen())
                );
              },
              child: const Text(
                'View All',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.green,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16.0,
          crossAxisSpacing: 16.0,
          childAspectRatio: 1.2,
          children: gardeningServices.map((service) {
            return _buildServiceCard(
              context,
              icon: _getServiceIcon(service['name']),
              title: service['name'],
              description: service['description'] ?? '',
              image: service['image'] ?? '',
              price: '₱${service['price']}',
              isGardening: true,
            );
          }).toList(),
        ),

        const SizedBox(height: 32),

        // Landscaping Services Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Landscaping Services',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => LandscapingScreen())
                );
              },
              child: const Text(
                'View All',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.green,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16.0,
          crossAxisSpacing: 16.0,
          childAspectRatio: 1.2,
          children: landscapingServices.map((service) {
            return _buildServiceCard(
              context,
              icon: _getServiceIcon(service['name']),
              title: service['name'],
              description: service['description'] ?? '',
              image: service['image'] ?? '',
              price: '₱${service['price']}',
              isGardening: false,
            );
          }).toList(),
        ),
      ],
    );
  }

  IconData _getServiceIcon(String serviceName) {
    // Map service names to appropriate icons
    if (serviceName.toLowerCase().contains('plant')) return Icons.spa;
    if (serviceName.toLowerCase().contains('water')) return Icons.water_drop;
    if (serviceName.toLowerCase().contains('pest')) return Icons.pest_control;
    if (serviceName.toLowerCase().contains('lawn')) return Icons.grass;
    if (serviceName.toLowerCase().contains('design')) return Icons.landscape;
    if (serviceName.toLowerCase().contains('path')) return Icons.park;
    if (serviceName.toLowerCase().contains('fence')) return Icons.foundation;
    if (serviceName.toLowerCase().contains('furniture')) return Icons.bento;
    return Icons.eco; // default icon
  }

  Widget _buildServiceCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required String image,
    required String price,
    required bool isGardening,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => isGardening
            ? _navigateToServiceDetails(
                context,
                title,
                description,
                image,
                price,
                'Gardening',
              )
            : _navigateToServiceDetails(
                context,
                title,
                description,
                image,
                price,
                'Landscaping',
              ),
        child: Stack(
          children: [
            Positioned.fill(
              child: image.isNotEmpty
                  ? Image.network(
                      image,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPlaceholderImage();
                      },
                    )
                  : _buildPlaceholderImage(),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    price,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Icon(
                      icon,
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(Icons.image_not_supported, size: 40),
      ),
    );
  }

  void _navigateToServiceDetails(
    BuildContext context,
    String title,
    String description,
    String image,
    String price,
    String serviceType,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceDetailsScreen(
          serviceName: title,
          serviceDescription: description,
          serviceImage: image,
          price: price,
          serviceType: serviceType,
        ),
      ),
    );
  }
}