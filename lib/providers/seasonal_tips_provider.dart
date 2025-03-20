import 'package:flutter/material.dart';
import '../models/seasonal_tip.dart';
import '../services/seasonal_tips_service.dart';

class SeasonalTipsProvider with ChangeNotifier {
  final SeasonalTipsService _apiService = SeasonalTipsService();
  List<SeasonalTip> _tips = [];
  bool _isLoading = false;

  List<SeasonalTip> get tips => _tips;
  bool get isLoading => _isLoading;

  Future<void> fetchSeasonalTips(int plantId, String region, String season) async {
    _isLoading = true;
    notifyListeners();

    try {
      _tips = await _apiService.getSeasonalTips(plantId, region, season);
    } catch (e) {
      print('Error fetching tips: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}