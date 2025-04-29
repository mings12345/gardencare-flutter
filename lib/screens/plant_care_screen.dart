import 'package:flutter/material.dart';
import 'package:gardencare_app/services/notification_service.dart';
import '../models/plant.dart';
import '../services/plant_service.dart';

class PlantCareScreen extends StatefulWidget {
  @override
  _PlantCareScreenState createState() => _PlantCareScreenState();
}

class _PlantCareScreenState extends State<PlantCareScreen> {
  int _extractDaysFromFrequency(String frequency) {
    final match = RegExp(r'(\d+)').firstMatch(frequency);
    return match != null ? int.parse(match.group(1)!) : 3; // default to 3 days
  }

  late Future<List<Plant>> _futurePlants;
  List<Plant> _allPlants = [];
  List<Plant> _filteredPlants = [];

  @override
  void initState() {
    super.initState();
    _futurePlants = PlantService.getPlants();
    _futurePlants.then((plants) {
      setState(() {
        _allPlants = plants;
        _filteredPlants = plants;
      });
    });
  }

  void _filterPlants(String query) {
    setState(() {
      _filteredPlants = _allPlants
          .where((plant) => plant.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Plant Care Tips')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search plant name',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _filterPlants,
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Plant>>(
              future: _futurePlants,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return _filteredPlants.isEmpty
                      ? Center(child: Text("No plants found."))
                      : ListView.builder(
                          itemCount: _filteredPlants.length,
                          itemBuilder: (context, index) {
                            final plant = _filteredPlants[index];
                            return Card(
                              margin: EdgeInsets.all(8),
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      plant.name, 
                                      style: TextStyle(
                                        fontSize: 18, 
                                        fontWeight: FontWeight.bold
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    _buildInfoRow('💧 Water', plant.wateringFrequency),
                                    _buildInfoRow('☀️ Sunlight', plant.sunlight),
                                    _buildInfoRow('🌱 Soil', plant.soil),
                                    _buildInfoRow('🧪 Fertilizer', plant.fertilizer),
                                    _buildInfoRow('🐛 Problems', plant.commonProblems),
                                    SizedBox(height: 10),
                                    ElevatedButton.icon(
                                    onPressed: () async {
                                      try {
                                        // Make sure notifications are initialized first
                                        await NotificationService.initialize();
                                        
                                        int days = _extractDaysFromFrequency(plant.wateringFrequency);
                                        await NotificationService.scheduleWaterReminder(
                                          id: plant.id,
                                          plantName: plant.name,
                                          repeatDays: days,
                                        );
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Reminder set to water ${plant.name} 🌿'),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Failed to set reminder: ${e.toString()}'),
                                            behavior: SnackBarBehavior.floating,
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    },
                                    icon: Icon(Icons.notifications_active),
                                    label: Text("Set Reminder"),
                                  ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                return Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label + ': ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}