import 'package:flutter/material.dart';

class AdminActiveUsers extends StatelessWidget {
  const AdminActiveUsers({super.key});

  // Dummy data for demonstration
  final List<Map<String, dynamic>> activeUsers = const [
    {
      "userId": "001",
      "userName": "John Doe",
      "email": "john.doe@example.com",
      "registrationDate": "2023-09-01",
      "status": "Active",
    },
    {
      "userId": "002",
      "userName": "Jane Smith",
      "email": "jane.smith@example.com",
      "registrationDate": "2023-09-05",
      "status": "Active",
    },
    {
      "userId": "003",
      "userName": "Alice Johnson",
      "email": "alice.johnson@example.com",
      "registrationDate": "2023-09-10",
      "status": "Inactive",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Active Users"),
        backgroundColor: Colors.green,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: activeUsers.length,
        itemBuilder: (context, index) {
          final user = activeUsers[index];
          return Card(
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "User ID: ${user["userId"]}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text("Name: ${user["userName"]}"),
                  const SizedBox(height: 8),
                  Text("Email: ${user["email"]}"),
                  const SizedBox(height: 8),
                  Text("Registration Date: ${user["registrationDate"]}"),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        "Status: ${user["status"]}",
                        style: TextStyle(
                          color: user["status"] == "Active" ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (user["status"] == "Active")
                        ElevatedButton(
                          onPressed: () {
                            // Handle deactivate action
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          child: const Text("Deactivate"),
                        ),
                      if (user["status"] == "Inactive")
                        ElevatedButton(
                          onPressed: () {
                            // Handle activate action
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          child: const Text("Activate"),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}