import 'package:flutter/material.dart';

class BannerWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Find the Best Gardening and Landscaping Services',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Book top-rated gardeners and landscapers near you with ease!',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          Icon(
            Icons.local_florist,
            size: 60,
            color: Colors.green[700],
          ),
        ],
      ),
    );
  }
}
