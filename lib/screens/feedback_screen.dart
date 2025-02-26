import 'package:flutter/material.dart';

class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Example feedback data
    final feedbackList = [
      {
        'name': 'John Doe',
        'feedback': 'Great service, my garden looks amazing!',
        'rating': 5,
      },
      {
        'name': 'Jane Smith',
        'feedback': 'Quick and professional!',
        'rating': 4,
      },
      {
        'name': 'Alice Brown',
        'feedback': 'Affordable and excellent quality.',
        'rating': 5,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Feedback'),
        backgroundColor: Colors.green,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: feedbackList.length,
        itemBuilder: (context, index) {
          final feedback = feedbackList[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Client Name
                  Text(
                    feedback['name'] as String,  // Casting to String
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Feedback Text
                  Text(
                    feedback['feedback'] as String,  // Casting to String
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Rating
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        'Rating: ${feedback['rating'] as int}/5',  // Casting to int
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
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
