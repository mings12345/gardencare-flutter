import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class BookingService {
  final String baseUrl = dotenv.get('BASE_URL');

  // Fetch bookings for the current homeowner
  Future<List<Map<String, dynamic>>> fetchHomeownerBookings() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userId = prefs.getInt('userId');
    
    if (token == null || userId == null) {
      throw Exception('No token or user ID found. Please log in again.');
    }

    try {
      // Updated to use the working endpoint format
      final response = await http.get(
        Uri.parse('$baseUrl/api/homeowners/$userId/bookings'), // Changed here
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['bookings']);
      } else {
        throw Exception('Failed to load bookings: ${response.body}');
      }
    } catch (e) {
      print('Error fetching homeowner bookings: $e');
      rethrow;
    }
  }
}