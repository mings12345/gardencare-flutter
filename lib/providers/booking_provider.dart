import 'package:flutter/material.dart';

class BookingProvider with ChangeNotifier {
  List<Map<String, dynamic>> _bookings = [];

  List<Map<String, dynamic>> get bookings => _bookings;

  void addBooking(Map<String, dynamic> booking) {
    _bookings.add(booking);
    notifyListeners();
  }

  void clearBookings() {
    _bookings.clear();
    notifyListeners();
  }
}