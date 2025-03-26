import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/seasonal_tips_provider.dart';

class SeasonalTipsScreen extends StatefulWidget {
  @override
  _SeasonalTipsScreenState createState() => _SeasonalTipsScreenState();
}

class _SeasonalTipsScreenState extends State<SeasonalTipsScreen> {
  bool _isFetched = false; // Prevent multiple API calls

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isFetched) {
        Provider.of<SeasonalTipsProvider>(context, listen: false)
            .fetchSeasonalTips(1, 'Philippines', 'Dry Season');
        _isFetched = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Seasonal Tips'),
        backgroundColor: Colors.green,
      ),
      body: Consumer<SeasonalTipsProvider>(
        builder: (context, tipsProvider, child) {
          if (tipsProvider.isLoading) {
            return Center(child: CircularProgressIndicator());
          } else if (tipsProvider.tips.isEmpty) {
            return Center(child: Text('No tips available.'));
          } else {
            return ListView.builder(
              padding: EdgeInsets.all(16.0),
              itemCount: tipsProvider.tips.length,
              itemBuilder: (context, index) {
                final tip = tipsProvider.tips[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: Icon(Icons.eco, color: Colors.green),
                    title: Text(tip.plantName),
                    subtitle: Text(tip.tip),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
