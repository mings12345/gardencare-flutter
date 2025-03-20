import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/seasonal_tips_provider.dart';

class SeasonalTipsScreen extends StatelessWidget {
  final int plantId;
  final String region;
  final String season;

  SeasonalTipsScreen({required this.plantId, required this.region, required this.season});

  @override
  Widget build(BuildContext context) {
    final tipsProvider = Provider.of<SeasonalTipsProvider>(context);

    // Fetch tips when the screen is first loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      tipsProvider.fetchSeasonalTips(plantId, region, season);
    });

    return Scaffold(
      appBar: AppBar(title: Text('Seasonal Tips')),
      body: tipsProvider.isLoading
          ? Center(child: CircularProgressIndicator())
          : tipsProvider.tips.isEmpty
              ? Center(child: Text('No tips available.'))
              : ListView.builder(
                  itemCount: tipsProvider.tips.length,
                  itemBuilder: (context, index) {
                    final tip = tipsProvider.tips[index];
                    return ListTile(
                      title: Text(tip.plantName),
                      subtitle: Text(tip.tip),
                    );
                  },
                ),
    );
  }
}