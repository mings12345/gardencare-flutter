import 'package:flutter/material.dart';

class GenerateReportsScreen extends StatelessWidget {
  const GenerateReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Generate Reports"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select Report Type",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Generate Booking Report
                _generateReport(context, "Booking Report");
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Booking Report"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                // Generate Revenue Report
                _generateReport(context, "Revenue Report");
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Revenue Report"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                // Generate User Activity Report
                _generateReport(context, "User Activity Report");
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("User Activity Report"),
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to handle report generation
  void _generateReport(BuildContext context, String reportType) {
    // Show a dialog or navigate to a new screen for report generation
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Generate $reportType"),
          content: Text("Are you sure you want to generate the $reportType?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                // Perform report generation logic here
                Navigator.pop(context); // Close the dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("$reportType generated successfully!"),
                  ),
                );
              },
              child: const Text("Generate"),
            ),
          ],
        );
      },
    );
  }
}