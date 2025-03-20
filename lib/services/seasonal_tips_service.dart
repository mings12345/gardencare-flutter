import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/seasonal_tip.dart';

class SeasonalTipsService {
  final String baseUrl = 'http://gardencare.test/api';

  Future<List<SeasonalTip>> getSeasonalTips(int plantId, String region, String season) async {
    final response = await http.get(Uri.parse('$baseUrl/seasonal-tips/$plantId/$region/$season'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => SeasonalTip.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load tips');
    }
  }
}