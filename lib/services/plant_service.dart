import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/plant.dart';

class PlantService {
  static final String baseUrl = dotenv.get('BASE_URL');

  static Future<List<Plant>> getPlants() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/api/plants'),
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((plantJson) => Plant.fromJson(plantJson)).toList();
    } else {
      throw Exception('Failed to load plants');
    }
  }
}