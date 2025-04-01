import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/seasonal_tip.dart';

class SeasonalTipsService {
  final String baseUrl = 'http://192.168.2.34/api';

  Future<List<SeasonalTip>> getSeasonalTips(int plantId, String region, String season) async {
    try {
      // ✅ Fix: Encode parameters to avoid URL errors
      String encodedRegion = Uri.encodeComponent(region);
      String encodedSeason = Uri.encodeComponent(season);
      
      final response = await http.get(Uri.parse('$baseUrl/seasonal-tips/$plantId/$encodedRegion/$encodedSeason'));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        // ✅ Fix: Ensure the response is a list
        if (jsonData is List) {
          return jsonData.map((json) => SeasonalTip.fromJson(json)).toList();
        } else if (jsonData is Map && jsonData.containsKey('data')) {
          return (jsonData['data'] as List).map((json) => SeasonalTip.fromJson(json)).toList();
        } else {
          throw Exception('Unexpected API response format');
        }
      } else {
        throw Exception('Failed to load tips. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching tips: $e');
      return [];
    }
  }
}
