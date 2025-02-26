import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gardencare_app/providers/booking_provider.dart'; // Import the BookingProvider

class BookingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Fetch the bookings from the provider
    final bookingProvider = Provider.of<BookingProvider>(context);
    final bookings = bookingProvider.bookings;

    // If no bookings are found, show a message
    if (bookings.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Booking Details"),
          backgroundColor: Colors.green,
        ),
        body: Center(
          child: Text("No bookings found.", style: TextStyle(fontSize: 18)),
        ),
      );
    }

    // Display the list of bookings
    return Scaffold(
      appBar: AppBar(
        title: Text("Booking Details"),
        backgroundColor: Colors.green,
      ),
      body: ListView.builder(
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return Card(
            margin: EdgeInsets.all(10),
            child: ListTile(
              title: Text("Service Type: ${booking['type']}"),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Address: ${booking['address']}"),
                  Text("Date: ${booking['date']}"),
                  Text("Time: ${booking['time']}"),
                  Text("Total Price: ₱${booking['total_price'].toStringAsFixed(2)}"),
                  if (booking['special_instructions'] != null)
                    Text("Special Instructions: ${booking['special_instructions']}"),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}