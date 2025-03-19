import 'package:flutter/material.dart';
import '../widgets/dashboard_card.dart';
import 'admin_total_bookings.dart'; // Import Total Bookings screen
import 'admin_active_users.dart'; // Import Active Users screen
import 'admin_total_services.dart'; // Import Total Services screen
import 'admin_revenue.dart'; // Import Revenue screen
import 'generate_reports.dart'; // Import Generate Reports screen
import 'admin_profile.dart'; // Import Profile screen


class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: Colors.green,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.green,
              ),
              child: Text(
                "A",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text("Dashboard"),
              onTap: () {
                // Navigate back to the Dashboard (current screen)
                Navigator.pop(context); // Close the drawer
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("Profile"),
              onTap: () {
                // Navigate to Profile screen
                Navigator.pop(context); // Close the drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminProfileScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.book),
              title: const Text("Total Bookings"),
              onTap: () {
                // Navigate to Total Bookings screen
                Navigator.pop(context); // Close the drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminTotalBookings(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text("Active Users"),
              onTap: () {
                // Navigate to Active Users screen
                Navigator.pop(context); // Close the drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminActiveUsers(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.work),
              title: const Text("Total Services"),
              onTap: () {
                // Navigate to Total Services screen
                Navigator.pop(context); // Close the drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminTotalServices(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: const Text("Revenue"),
              onTap: () {
                // Navigate to Revenue screen
                Navigator.pop(context); // Close the drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminRevenue(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment),
              title: const Text("Generate Reports"),
              onTap: () {
                // Navigate to Generate Reports screen
                Navigator.pop(context); // Close the drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GenerateReportsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return GridView.count(
              crossAxisCount: 2,  // Always 2 columns
              crossAxisSpacing: 20, // Increased spacing between columns
              mainAxisSpacing: 20,  // Increased spacing between rows
              childAspectRatio: 1.0,  // Adjusted for larger cards
              children: [
                // Total Bookings Card
                InkWell(
                  onTap: () {
                    // Navigate to Total Bookings screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminTotalBookings(),
                      ),
                    );
                  },
                  child: const SizedBox(
                    height: 150, // Fixed height for all cards
                    child: DashboardCard(title: "Total Bookings", value: "124"),
                  ),
                ),
                // Active Users Card
                InkWell(
                  onTap: () {
                    // Navigate to Active Users screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminActiveUsers(),
                      ),
                    );
                  },
                  child: const SizedBox(
                    height: 150, // Fixed height for all cards
                    child: DashboardCard(title: "Active Users", value: "58"),
                  ),
                ),
                // Total Services Card 
                InkWell(
                  onTap: () {
                    // Navigate to Total Services screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminTotalServices(),
                      ),
                    );
                  },
                  child: const SizedBox(
                    height: 150, // Fixed height for all cards
                    child: DashboardCard(title: "Total Services", value: "12"),
                  ),
                ),
                // Revenue Card
                InkWell(
                  onTap: () {
                    // Navigate to Revenue screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminRevenue(),
                      ),
                    );
                  },
                  child: const SizedBox(
                    height: 150, // Fixed height for all cards
                    child: DashboardCard(title: "Revenue", value: "\$15,230"),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}