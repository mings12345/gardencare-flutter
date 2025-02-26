/*import 'package:flutter/material.dart';
import 'package:gardencare_app/screens/booking_success_screen.dart';
import '../models/booking.dart'; // Assuming you have a Booking model

class ConfirmBookingScreen extends StatefulWidget {
  final String serviceName;
  final String gardenerName;
  final String date;
  final String time;
  final String address;
  final String specialInstructions;

  const ConfirmBookingScreen({
    Key? key,
    required this.serviceName,
    required this.gardenerName,
    required this.date,
    required this.time,
    required this.address,
    required this.specialInstructions, required String serviceProvider, String? budget, String? projectDetails,
  }) : super(key: key);

  @override
  _ConfirmBookingScreenState createState() => _ConfirmBookingScreenState();
}

class _ConfirmBookingScreenState extends State<ConfirmBookingScreen> {
  // List to store confirmed bookings
  List<Booking> bookings = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Booking'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Service: ${widget.serviceName}', style: const TextStyle(fontSize: 18)),
            Text('Gardener: ${widget.gardenerName}', style: const TextStyle(fontSize: 18)),
            Text('Date: ${widget.date}', style: const TextStyle(fontSize: 18)),
            Text('Time: ${widget.time}', style: const TextStyle(fontSize: 18)),
            Text('Address: ${widget.address}', style: const TextStyle(fontSize: 18)),
            Text('Special Instructions: ${widget.specialInstructions}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Create a new booking
                final newBooking = Booking(
                  serviceName: widget.serviceName,
                  gardenerName: widget.gardenerName,
                  date: widget.date,
                  time: widget.time,
                  address: widget.address,
                  specialInstructions: widget.specialInstructions,
                );

                // Add the new booking to the list
                setState(() {
                  bookings.add(newBooking);
                });

                // Navigate to the Success Screen and pass the bookings list
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookingSuccessScreen(bookings: bookings),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Confirm Booking'),
            ),
          ],
        ),
      ),
    );
  }
}
*/