import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:gardencare_app/providers/booking_provider.dart';
import 'package:gardencare_app/screens/admin_dashboard_screen.dart';
import 'package:gardencare_app/screens/gardener_dashboard.dart';
import 'package:gardencare_app/screens/chat_list_screen.dart';
import 'package:gardencare_app/screens/login_screen.dart';
import 'package:gardencare_app/screens/onboarding_screen.dart';
import 'package:gardencare_app/screens/profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:gardencare_app/screens/service_provider_screen.dart';
import 'package:gardencare_app/screens/booking_form.dart';
import 'package:gardencare_app/screens/bookings_screen.dart';
import 'package:gardencare_app/screens/gardening_screen.dart';
import 'package:gardencare_app/screens/homeowner_screen.dart';
import 'package:gardencare_app/screens/landscaping_screen.dart';
import 'package:gardencare_app/providers/user_provider.dart';
import 'package:gardencare_app/providers/seasonal_tips_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
      await dotenv.load(fileName: ".env");
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => SeasonalTipsProvider()),
        ChangeNotifierProvider(create: (context) => BookingProvider()),
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
      initialRoute: '/',
      routes: {
        '/admin-dashboard': (context) => const AdminDashboardScreen(),
        '/': (context) => const OnboardingScreen(),
        '/login': (context) => LoginScreen(),
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
        '/gardening': (context) => GardeningScreen(),
        '/landscaping': (context) => LandscapingScreen(),
        '/bookings': (context) => BookingsScreen(),
        '/booking-form': (context) => BookingForm(),
        '/home': (context) => HomeownerScreen(
              name: 'John Doe',
              email: 'john.doe@example.com',
              address: '123 Garden St, Green City',
              phone: '123-456-7890',
            ),
        '/message': (context) => ChatListScreen()
      }
    );
  }
}