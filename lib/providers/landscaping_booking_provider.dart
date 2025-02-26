import 'package:flutter/material.dart';

class LandscapingBooking {
  final String provider;
  String date;
  final String time;
  final String address;
  final String budget;
  final String projectDetails;
  final List<String> selectedServices;
  final double totalPrice;
  String status; // ✅ Added status field

  LandscapingBooking({
    required this.provider,
    required this.date,
    required this.time,
    required this.address,
    required this.budget,
    required this.projectDetails,
    required this.selectedServices,
    required this.totalPrice,
    this.status = 'Pending', // ✅ Default status is Pending
  });
}

class LandscapingBookingProvider extends ChangeNotifier {
  final List<LandscapingBooking> _bookings = [];

  List<LandscapingBooking> get landscapingBookings => _bookings;

  void addBooking({
    required String provider,
    required String date,
    required String time,
    required double totalPrice, 
    required String address,
    required String budget,
    required String projectDetails,
    required List<String> selectedServices,
  }) {
    final newBooking = LandscapingBooking(
      provider: provider,
      date: date,
      time: time,
      address: address,
      budget: budget,
      projectDetails: projectDetails,
      selectedServices: selectedServices,
      totalPrice: totalPrice,
    );

    _bookings.add(newBooking);
    notifyListeners();
  }
   void updateLandscapingTime(dynamic booking, String updatedTime) {
    // Implement the method to update the landscaping booking time
    booking.time = updatedTime;
    notifyListeners();
  }
  // ✅ Update status method
  void updateLandscapingStatus(LandscapingBooking booking, String newStatus) {
    final index = _bookings.indexOf(booking);
    if (index != -1) {
      _bookings[index].status = newStatus;
      notifyListeners();
    }
  }

  // ✅ Added method to update booking date
  void updateLandscapingDate(LandscapingBooking booking, String newDate) {
    final index = _bookings.indexOf(booking);
    if (index != -1) {
      _bookings[index].date = newDate;
      notifyListeners();
    }
  }
}
