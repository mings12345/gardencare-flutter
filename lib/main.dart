import 'package:flutter/material.dart';
import 'package:gardencare_app/providers/booking_provider.dart';
import 'package:gardencare_app/screens/admin_dashboard_screen.dart';
import 'package:gardencare_app/screens/gardener_dashboard.dart';
import 'package:gardencare_app/screens/messaging_screen.dart';
import 'package:gardencare_app/screens/login_screen.dart';
import 'package:gardencare_app/screens/onboarding_screen.dart';
import 'package:gardencare_app/screens/profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:gardencare_app/screens/service_provider_screen.dart';
import 'package:gardencare_app/services/pusher_service.dart'; // Import the Pusher service
import 'screens/booking_form.dart';
import 'screens/bookings_screen.dart';
import 'screens/gardening_screen.dart';
import 'screens/homeowner_screen.dart';
import 'screens/landscaping_screen.dart';
import 'services/notification_service.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  final notificationService = NotificationService();
  await notificationService.init();

  // Initialize Pusher
  final pusherService = PusherService();
  try {
    await pusherService.initPusher(channelName: "gardening-updates"); // Pass the channel name here
    print("✅ Pusher initialized and connected successfully!");
  } catch (e) {
    print("❌ Error initializing Pusher: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => BookingProvider()),
        Provider<PusherService>(create: (_) => pusherService), // Provide PusherService
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gardencare App',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/', // Set the initial route
      routes: {
        '/admin-dashboard': (context) => const AdminDashboardScreen(),
        '/': (context) => const OnboardingScreen(),
        '/login': (context) => LoginScreen(), // Default screen
        '/profile': (context) => const ProfileScreen(
              name: 'John Doe',
              email: 'john.doe@example.com',
              address: '123 Garden St, Green City',
              phone: '123-456-7890',
            ),
        '/service-provider-screen': (context) => ServiceProviderScreen(
              name: 'John Doe',
              role: 'Service Provider',
              email: 'john.doe@example.com',
              phone: '123-456-7890',
              address: '123 Garden St, Green City',
            ),
        '/gardener-dashboard': (context) => GardenerDashboard(
              name: 'John Doe',
              role: 'Gardener',
              email: 'john.doe@example.com',
              phone: '123-456-7890',
              address: '123 Garden St, Green City',
            ),
        '/gardening': (context) => GardeningScreen(), // Gardening services screen
        '/landscaping': (context) => LandscapingScreen(), // Landscaping services screen
        '/bookings': (context) => BookingsScreen(),
        '/booking-form': (context) => BookingForm(),
        '/home': (context) => HomeownerScreen(
              name: 'John Doe',
              email: 'john.doe@example.com',
              address: '123 Garden St, Green City',
              phone: '123-456-7890',
            ), // Homeowner screen/dashboard
        '/message': (context) => const MessagingScreen(gardenerName: 'John Doe'),
      },
    );
  }
}