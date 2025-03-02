import 'package:flutter/material.dart';

class AdminRevenue extends StatelessWidget {
  const AdminRevenue({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Revenue"),
        backgroundColor: Colors.green.shade900,
      ),
      body: const Center(
        child: Text(
          "Details about Revenue",
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}