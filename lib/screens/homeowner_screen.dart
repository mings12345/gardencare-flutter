import 'package:flutter/material.dart';
import 'package:gardencare_app/screens/bookings_screen.dart';
import 'package:gardencare_app/screens/messaging_screen.dart';
import 'package:gardencare_app/screens/seasonal_tips_screen.dart';
import 'package:gardencare_app/screens/service_details_screen.dart';
import 'package:gardencare_app/screens/landscaping_service_details.dart';
import 'package:gardencare_app/screens/landscaping_screen.dart';
import 'package:gardencare_app/screens/profile_screen.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import '../widgets/banner_widget.dart';
import './gardening_screen.dart';

class HomeownerScreen extends StatefulWidget {
  final String name;
  final String email;
  final String address;
  final String phone;

  HomeownerScreen({
    required this.name,
    required this.email,
    required this.address,
    required this.phone,
  });

  @override
  _HomeownerScreenState createState() => _HomeownerScreenState();
}

class _HomeownerScreenState extends State<HomeownerScreen> {
  int _selectedIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
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
          BookingsScreen(), // Replace with your actual BookingsScreen
          MessagingScreen(gardenerName: widget.name), // Provide the gardenerName parameter
          ProfileScreen(
            name: widget.name,
            email: widget.email,
            address: widget.address,
            phone: widget.phone,
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
            title: const Text('Bookings'),
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
  return ListView(
    padding: const EdgeInsets.all(16.0),
    children: [
      BannerWidget(),
      const SizedBox(height: 18),
      Image.asset(
        'assets/images/gardening.jpg',
        height: 250,
        fit: BoxFit.cover,
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
      const SizedBox(height: 32),

      // Seasonal Tips Section
      const Text(
        'Seasonal Tips',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 16),
      GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SeasonalTipsScreen(),
            ),
          );
        },
        child: Card(
          color: Colors.green.shade100,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.eco, color: Colors.green, size: 40),
                const SizedBox(width: 16),
                Text(
                  'View Seasonal Tips',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                Icon(Icons.arrow_forward, color: Colors.green),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 32),

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
                  context, MaterialPageRoute(builder: (context) => GardeningScreen()));
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
        children: [
          _buildGardeningServiceCard(
            context,
            icon: Icons.spa,
            title: "Plant Care",
            description: "A service for caring for plants.",
            image: 'assets/images/plant care.jpg',
            price: '₱500',
          ),
          _buildGardeningServiceCard(
            context,
            icon: Icons.water_drop,
            title: "Watering",
            description: "Regular watering of your plants.",
            image: 'assets/images/watering.jpg',
            price: '₱300',
          ),
          _buildGardeningServiceCard(
            context,
            icon: Icons.pest_control,
            title: "Pest Control",
            description: "Protection against garden pests.",
            image: 'assets/images/pest control.jpg',
            price: '₱700',
          ),
          _buildGardeningServiceCard(
            context,
            icon: Icons.grass,
            title: "Lawn Mowing",
            description: "Keep your lawn neatly trimmed.",
            image: 'assets/images/lawn mowing.jpg',
            price: '₱400',
          ),
        ],
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
                  context, MaterialPageRoute(builder: (context) => LandscapingScreen()));
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
        children: [
          _buildLandscapingServiceCard(
            context,
            icon: Icons.landscape,
            title: "Garden Design",
            description: "A service for designing beautiful and functional gardens.",
            image: 'assets/images/garden design.jpg',
            price: '₱4500',
          ),
          _buildLandscapingServiceCard(
            context,
            icon: Icons.park,
            title: "Pathway Construction",
            description: "Create beautiful and durable pathways in your garden.",
            image: 'assets/images/pathway.jpg',
            price: '₱5000',
          ),
          _buildLandscapingServiceCard(
            context,
            icon: Icons.foundation,
            title: "Fencing",
            description: "Install fences for privacy, security, or aesthetic purposes.",
            image: 'assets/images/fencing.jpg',
            price: '₱4000',
          ),
          _buildLandscapingServiceCard(
            context,
            icon: Icons.bento,
            title: "Outdoor Furniture",
            description: "Beautiful and comfortable outdoor furniture solutions.",
            image: 'assets/images/outdoor.jpg',
            price: '₱5100',
          ),
        ],
      ),
    ],
  );
}

  Widget _buildGardeningServiceCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required String image,
    required String price,
  }) {
    return GestureDetector(
      onTap: () => _navigateToGardeningService(context, title, description, image, price),
      child: SizedBox(
        width: 140,
        height: 180,
        child: Card(
          color: Colors.green.shade100,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48.0, color: Colors.green),
              const SizedBox(height: 8.0),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToGardeningService(BuildContext context, String title, String description, String image, String price) {
    final List<Map<String, String>> availableGardeners = [
      {'name': 'Dwight', 'experience': '5 years', 'rating': '4.8', 'image': 'assets/images/Dwight.jpg'},
      {'name': 'Nikki', 'experience': '5 years', 'rating': '5.3', 'image': 'assets/images/Nikki.jpg'},
      {'name': 'Nina', 'experience': '4 years', 'rating': '4.3', 'image': 'assets/images/Nina.jpg'},
      {'name': 'JL', 'experience': '4 years', 'rating': '4.3', 'image': 'assets/images/Pain.jpg'},
    ];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceDetailsScreen(
          serviceName: title,
          serviceDescription: description,
          serviceImage: image,
          price: price,
          serviceType: 'Gardening',
          availableGardeners: availableGardeners,
        ),
      ),
    );
  }

  void _navigateToLandscapingService(BuildContext context, String title, String description, String image, String price) {
    final List<Map<String, String>> serviceProviders = [
      {
        'name': 'Green Thumb Landscaping',
        'experience': '10 years',
        'rating': '4.9',
        'image': 'assets/images/lands1.jpg',
      },
      {
        'name': 'Eco Garden Services',
        'experience': '8 years',
        'rating': '4.7',
        'image': 'assets/images/lands2.jpg',
      },
      {
        'name': 'Nature’s Touch Lawn Care',
        'experience': '12 years',
        'rating': '4.8',
        'image': 'assets/images/lands3.jpg',
      },
      {
        'name': 'Goys Landscaping service',
        'experience': '5 years',
        'rating': '4.5',
        'image': 'assets/images/lands4.jpg',
      },
      {
        'name': 'Alice Landscaping',
        'experience': '29 years',
        'rating': '4.5',
        'image': 'assets/images/lands5.jpg',
      },
    ];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LandscapingServiceDetails(
          serviceName: title,
          serviceDescription: description,
          serviceImage: image,
          price: price,
          serviceType: 'Landscaping',
          serviceProviders: serviceProviders,
        ),
      ),
    );
  }

  Widget _buildLandscapingServiceCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required String image,
    required String price,
  }) {
    return GestureDetector(
      onTap: () => _navigateToLandscapingService(context, title, description, image, price),
      child: SizedBox(
        width: 140,
        height: 160,
        child: Card(
          color: Colors.green.shade100,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48.0, color: Colors.green),
              const SizedBox(height: 8.0),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),
            ],
          ),
        ),
      ),
    );
  }
}