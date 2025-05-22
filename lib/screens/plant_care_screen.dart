import 'package:flutter/material.dart';
import '../models/plant.dart';
import '../services/plant_service.dart';

class PlantCareScreen extends StatefulWidget {
  @override
  _PlantCareScreenState createState() => _PlantCareScreenState();
}

class _PlantCareScreenState extends State<PlantCareScreen> {
  

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
      appBar: AppBar(
            title: const Text(
              'Plant Care Tips',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.green[800],
            elevation: 10,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
            ),
            iconTheme: const IconThemeData(
              color: Colors.white, // 👈 this sets the leading icon to white
            ),
          ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
              )],
              ),
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Search plant name',
                  labelStyle: TextStyle(color: Colors.green[800]),
                  prefixIcon: Icon(Icons.search, color: Colors.green[800]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  filled: true,
                  fillColor: Colors.transparent,
                ),
                onChanged: _filterPlants,
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Plant>>(
              future: _futurePlants,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return _filteredPlants.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 50, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                "No plants found",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredPlants.length,
                          itemBuilder: (context, index) {
                            final plant = _filteredPlants[index];
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    spreadRadius: 1,
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.spa, color: Colors.green[700], size: 24),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            plant.name,
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green[900],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    _buildInfoRow(Icons.opacity, 'Water', plant.wateringFrequency),
                                    _buildInfoRow(Icons.wb_sunny, 'Sunlight', plant.sunlight),
                                    _buildInfoRow(Icons.landscape, 'Soil', plant.soil),
                                    _buildInfoRow(Icons.science, 'Fertilizer', plant.fertilizer),
                                    _buildInfoRow(Icons.bug_report, 'Problems', plant.commonProblems),
                                    const SizedBox(height: 16),
                                  
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                } else if (snapshot.hasError) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 50, color: Colors.red),
                        SizedBox(height: 16),
                        Text(
                          'Error loading plants',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green[700]!),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Loading your plants...',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.green[700]),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                width: MediaQuery.of(context).size.width - 100,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}