import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gardencare_app/auth_service.dart';
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

  Future<double> fetchTotalEarnings() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('No authentication token');

    final String baseUrl = dotenv.get('BASE_URL');
    final response = await http.get(
      Uri.parse('$baseUrl/api/get_total_earnings'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['total_earnings'] as num).toDouble();
    } else {
      throw Exception('Failed to load total earnings');
    }
  } catch (e) {
    print('Error fetching total earnings: $e');
    throw e;
  }
}

  Future<Map<String, dynamic>> fetchEarningsSummary() async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/api/earnings/summary'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load earnings summary');
    }
  }

  Future<void> submitRating({
  required int bookingId,
  required double rating,
  String? feedback,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';
  
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/api/bookings/$bookingId/rate'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'rating': rating,
        'feedback': feedback,
      }),
    );

    if (response.statusCode == 201) {
      return;
    } else if (response.statusCode == 422) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Rating already exists for this booking');
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to submit rating: Status ${response.statusCode}');
    }
  } catch (e) {
    print('Error submitting rating: $e');
    rethrow;
  }
}
  // Add this new method to fetch booking count
  Future<int> fetchBookingCount() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userId = prefs.getInt('userId');
    
    if (token == null || userId == null) {
      throw Exception('No token or user ID found. Please log in again.');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/bookings/count/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['count'] ?? 0;
      } else {
        throw Exception('Failed to load booking count: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching booking count: $e');
      return 0; // Return 0 if there's an error
    }
  }

  }