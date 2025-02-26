import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TotalEarningsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Replace with actual earnings data
    final List<Map<String, String>> earnings = [
      {'date': '2025-02-01', 'amount': '\$500.00'},
      {'date': '2025-02-02', 'amount': '\$300.00'},
      {'date': '2025-02-03', 'amount': '\$200.00'},
      // Add more earnings data here
    ];

    double weeklyEarnings = 0.0;
    double monthlyEarnings = 0.0;

    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    final DateTime now = DateTime.now();
    final DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final DateTime startOfMonth = DateTime(now.year, now.month, 1);

    for (var earning in earnings) {
      final DateTime earningDate = formatter.parse(earning['date']!);
      final double amount = double.parse(earning['amount']!.replaceAll('\$', ''));

      if (earningDate.isAfter(startOfWeek) || earningDate.isAtSameMomentAs(startOfWeek)) {
        weeklyEarnings += amount;
      }

      if (earningDate.isAfter(startOfMonth) || earningDate.isAtSameMomentAs(startOfMonth)) {
        monthlyEarnings += amount;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Total Earnings'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Earnings Details',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Weekly Earnings: \$${weeklyEarnings.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Monthly Earnings: \$${monthlyEarnings.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: earnings.length,
                itemBuilder: (context, index) {
                  final earning = earnings[index];
                  return Card(
                    child: ListTile(
                      title: Text('Date: ${earning['date']}'),
                      subtitle: Text('Amount: ${earning['amount']}'),
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