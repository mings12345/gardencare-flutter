import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gardencare_app/providers/user_provider.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/user.dart';

class AuthService {
  final String baseUrl = dotenv.get('BASE_URL'); 

  Future<User?> login(
    String email,
    String password,
    BuildContext context
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200 && response.headers['content-type']?.contains('application/json') == true) {
        final responseData = jsonDecode(response.body);
        print('Login Response: $responseData'); // Debugging line

        final user = User.fromJson(responseData['user']);
        final token = responseData['token'];

        // Save token to local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setInt('userId', user.id);
        await prefs.setString('userRole', user.userType);
        print('Token saved: $token'); // Debugging line

          // Update the UserProvider
        Provider.of<UserProvider>(context, listen: false).setUserData(
          token: token,
          userData: responseData['user'], // Pass the entire user object
          homeownerId: user.id,
          role: user.userType,
          userId: user.id.toString(),
        );

        return user;
      } else if (response.headers['content-type']?.contains('application/json') == true) {
        final error = jsonDecode(response.body);
        print('Login Error Response: $error');  // Debugging line
        throw Exception('Login failed: ${error['message']}');
      } else {
        print('Unexpected error: ${response.body}');  // Debugging line
        throw Exception('Unexpected error: ${response.statusCode}');
      }
    } catch (e) {
      print('Login Exception: $e');  // Debugging line
      rethrow;
    }
  } 

      Future<Map<int, int>> getUnreadCounts(int userId) async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('No token found. Please log in again.');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/messages/unread-counts/$userId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final counts = data['unread_counts'] as Map<String, dynamic>;
        
        // Convert string keys to integers
        return counts.map((key, value) => MapEntry(int.parse(key), value as int));
      } else {
        throw Exception('Failed to load unread counts: ${response.body}');
      }
    }

  Future<List<User>> fetchGardeners() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('No token found. Please log in again.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/api/gardeners'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = jsonDecode(response.body);
      return jsonResponse.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load gardeners: ${response.body}');
    }
  }

  Future<List<User>> fetchServiceProviders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('No token found. Please log in again.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/api/service_providers'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = jsonDecode(response.body);
      return jsonResponse.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load service providers: ${response.body}');
    }
  }

  Future<List<User>> fetchHomeowners() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('No token found. Please log in again.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/api/homeowners'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = jsonDecode(response.body);
      return jsonResponse.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load homeowners: ${response.body}');
    }
  }

  // Save token to shared preferences
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token); // Use 'token' as the key
  }

  // Get token from shared preferences
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token'); // Use 'token' as the key
  }

  // Clear token (for logout)
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token'); // Use 'token' as the key
  }

  Future<Map<String, String>> fetchProfileData(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('No token found. Please log in again.');
    }

    final url = '$baseUrl/api/profile/$userId';
    print('Request URL: $url'); // Debugging line
    print('Authorization Token: $token'); // Debugging line
    print('User ID: $userId'); // Debugging line

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );

    print('Response Status Code: ${response.statusCode}'); // Debugging line
    print('Response Body: ${response.body}'); // Debugging line

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'name': data['name'] ?? '',
        'email': data['email'] ?? '',
        'phone': data['phone'] ?? '',
        'address': data['address'] ?? '',
        'gcash_no': data['gcash_no'] ?? '',
      };
    } else if (response.statusCode == 404) {
      throw Exception('Profile not found. Please check the user ID.');
    } else {
      throw Exception('Failed to fetch profile data: ${response.body}');
    }
  }

  Future<User?> register(
    String name,
    String email,
    String password,
    String phone,
    String address,
    String userType,
    BuildContext context
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': password,
          'phone': phone,
          'address': address,
          'user_type': userType,
        }),
      );

      if (response.statusCode == 201 && response.headers['content-type']?.contains('application/json') == true) {
        final responseData = jsonDecode(response.body);
        return User.fromJson(responseData['user']);
      } else if (response.headers['content-type']?.contains('application/json') == true) {
        final error = jsonDecode(response.body);
        throw Exception('Registration failed: ${error['message']}');
      } else {
        throw Exception('Unexpected error: ${response.statusCode}');
      }
    } catch (e) {
      rethrow; // Allow the caller to handle the error
    }
  }
}