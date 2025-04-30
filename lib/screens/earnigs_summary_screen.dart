import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gardencare_app/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class EarningsSummaryScreen extends StatefulWidget {
  const EarningsSummaryScreen({Key? key}) : super(key: key);

  @override
  _EarningsSummaryScreenState createState() => _EarningsSummaryScreenState();
}

class _EarningsSummaryScreenState extends State<EarningsSummaryScreen> {
  bool isLoading = true;
  double totalEarnings = 0.0;
  List<Map<String, dynamic>> earnings = [];
  String selectedTimeframe = 'All Time';
  List<String> timeframes = ['All Time', 'This Month', 'This Week', 'Today'];

  @override
  void initState() {
    super.initState();
    _fetchEarningsSummary();
  }

  Future<void> _fetchEarningsSummary() async {
    setState(() => isLoading = true);
    
    try {
      final token = await AuthService.getToken();
      if (token == null) return;
      
      final String baseUrl = dotenv.get('BASE_URL');
      final response = await http.get(
        Uri.parse('$baseUrl/api/earnings/summary'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          totalEarnings = (data['total_earnings'] as num?)?.toDouble() ?? 0.0;
          earnings = List<Map<String, dynamic>>.from(data['earnings'] ?? []);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load earnings data');
      }
    } catch (e) {
      print('Error fetching earnings summary: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load earnings data')),
      );
      setState(() => isLoading = false);
    }
  }

  List<Map<String, dynamic>> _getFilteredEarnings() {
    final now = DateTime.now();
    
    switch (selectedTimeframe) {
      case 'Today':
        final today = DateFormat('yyyy-MM-dd').format(now);
        return earnings.where((e) => 
          e['completed_at'] != null && 
          e['completed_at'].toString().startsWith(today)
        ).toList();
      
      case 'This Week':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        return earnings.where((e) {
          if (e['completed_at'] == null) return false;
          final completedDate = DateTime.tryParse(e['completed_at'].toString());
          if (completedDate == null) return false;
          return completedDate.isAfter(weekStart);
        }).toList();
      
      case 'This Month':
        final monthStart = DateTime(now.year, now.month, 1);
        return earnings.where((e) {
          if (e['completed_at'] == null) return false;
          final completedDate = DateTime.tryParse(e['completed_at'].toString()) ;
          if (completedDate == null) return false;
          return completedDate.isAfter(monthStart);
        }).toList();
      
      case 'All Time':
      default:
        return earnings;
    }
  }

  double _getFilteredTotal() {
    final filteredEarnings = _getFilteredEarnings();
    return filteredEarnings.fold(0.0, (sum, item) {
      final amount = (item['amount'] as num?)?.toDouble() ?? 0.0;
      return sum + amount;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredEarnings = _getFilteredEarnings();
    final filteredTotal = _getFilteredTotal();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings Summary'),
        backgroundColor: Colors.green,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchEarningsSummary,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.green.shade50,
                    child: Column(
                      children: [
                        Text(
                          'Total Earnings ($selectedTimeframe)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₱${filteredTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 40,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: timeframes.length,
                            itemBuilder: (context, index) {
                              final timeframe = timeframes[index];
                              final isSelected = timeframe == selectedTimeframe;
                              
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(timeframe),
                                  selected: isSelected,
                                  selectedColor: Colors.green,
                                  backgroundColor: Colors.grey.shade200,
                                  labelStyle: TextStyle(
                                    color: isSelected ? Colors.white : Colors.black,
                                  ),
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() {
                                        selectedTimeframe = timeframe;
                                      });
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: filteredEarnings.isEmpty
                        ? Center(
                            child: Text(
                              'No earnings data for $selectedTimeframe',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: filteredEarnings.length,
                            itemBuilder: (context, index) {
                              final earning = filteredEarnings[index];
                              final serviceName = earning['service_name'] ?? 'Service';
                              final amount = (earning['amount'] as num?)?.toDouble() ?? 0.0;
                              final completedAt = earning['completed_at'] != null
                                  ? DateFormat('MMM d, yyyy').format(DateTime.parse(earning['completed_at']))
                                  : 'Unknown date';
                              final clientName = earning['client_name'] ?? 'Client';
                              
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  title: Text(
                                    serviceName,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text('$clientName • $completedAt'),
                                  trailing: Text(
                                    '₱${amount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}