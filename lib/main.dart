import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:gardencare_app/providers/booking_provider.dart';
import 'package:gardencare_app/screens/admin_dashboard_screen.dart';
import 'package:gardencare_app/screens/gardener_dashboard.dart';
import 'package:gardencare_app/screens/messaging_screen.dart';
import 'package:gardencare_app/screens/login_screen.dart';
import 'package:gardencare_app/screens/onboarding_screen.dart';
import 'package:gardencare_app/screens/profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:gardencare_app/screens/service_provider_screen.dart';
import 'package:gardencare_app/services/pusher_service.dart';
import 'package:gardencare_app/screens/booking_form.dart';
import 'package:gardencare_app/screens/bookings_screen.dart';
import 'package:gardencare_app/screens/gardening_screen.dart';
import 'package:gardencare_app/screens/homeowner_screen.dart';
import 'package:gardencare_app/screens/landscaping_screen.dart';
import 'package:gardencare_app/services/notification_service.dart';
import 'package:gardencare_app/providers/user_provider.dart';
import 'package:gardencare_app/providers/seasonal_tips_provider.dart';

// Firebase background message handler (must be top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  final notificationService = NotificationService();
  await notificationService.init();
  notificationService.showNotification(
    title: message.notification?.title ?? "New Notification",
    body: message.notification?.body ?? "You have a new message",
  );
}

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Notification Service
  final notificationService = NotificationService();
  await notificationService.init();

  // Initialize FCM and get token
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  await firebaseMessaging.requestPermission(); // For iOS
  
  // Declare fcmToken at the top level of main()
  String? fcmToken;
  
  try {
    // Get initial token
    fcmToken = await firebaseMessaging.getToken();
    print("Initial FCM Token: $fcmToken");

    // Handle token refreshes
    firebaseMessaging.onTokenRefresh.listen((newToken) {
      print("Refreshed FCM Token: $newToken");
      fcmToken = newToken; // Update the variable
      // You might want to send this to your backend here
      // await updateTokenOnBackend(newToken);
    });

    // Optional: Send token to your backend server
    if (fcmToken != null) {
      // await sendTokenToServer(fcmToken!);
    }
  } catch (e) {
    print("Error getting FCM token: $e");
  }

  // Set background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize Pusher with FCM token (if available)
  final pusherService = PusherService();
  try {
    await pusherService.initPusher(
      channelName: "gardening-updates",
      userId: fcmToken ?? "default-user", // Now fcmToken is accessible here
    );
    print("✅ Pusher initialized and connected successfully!");
  } catch (e) {
    print("❌ Error initializing Pusher: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => SeasonalTipsProvider()),
        ChangeNotifierProvider(create: (context) => BookingProvider()),
        Provider<PusherService>(create: (_) => pusherService),
        Provider<NotificationService>(create: (_) => notificationService),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Listen to foreground FCM messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notificationService = NotificationService();
      notificationService.showNotification(
        title: message.notification?.title ?? "New Notification",
        body: message.notification?.body ?? "You have a new message",
      );
    });

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
        '/message': (context) => const MessagingScreen(gardenerName: 'John Doe'),
      },
    );
  }
}