import 'package:flutter/material.dart';

class AdminTotalServices extends StatelessWidget {
  const AdminTotalServices({super.key});

  // Dummy data for demonstration
  final List<Map<String, dynamic>> services = const [
    {
      "serviceId": "001",
      "serviceName": "Lawn Mowing",
      "serviceDescription": "Regular lawn mowing service",
      "servicePrice": "\$50",
      "status": "Active",
    },
    {
      "serviceId": "002",
      "serviceName": "Tree Trimming",
      "serviceDescription": "Tree trimming and pruning",
      "servicePrice": "\$100",
      "status": "Active",
    },
    {
      "serviceId": "003",
      "serviceName": "Pest Control",
      "serviceDescription": "Pest control and extermination",
      "servicePrice": "\$150",
      "status": "Inactive",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Total Services"),
        backgroundColor: Colors.green,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];
          return Card(
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Service ID: ${service["serviceId"]}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text("Service Name: ${service["serviceName"]}"),
                  const SizedBox(height: 8),
                  Text("Description: ${service["serviceDescription"]}"),
                  const SizedBox(height: 8),
                  Text("Price: ${service["servicePrice"]}"),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        "Status: ${service["status"]}",
                        style: TextStyle(
                          color: service["status"] == "Active" ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (service["status"] == "Active")
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
                      if (service["status"] == "Inactive")
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