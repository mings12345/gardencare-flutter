import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  int? _homeownerId;
  String? _role; // Add role
  String? _userId; // Add userId

  int? get homeownerId => _homeownerId;
  String? get role => _role; // Getter for role
  String? get userId => _userId; // Getter for userId

  // Add an isLoggedIn getter
  bool get isLoggedIn => _homeownerId != null;

  void setHomeownerId(int id) {
    _homeownerId = id;
    notifyListeners();
  }

  void setUserDetails(String userId, String role) {
    _userId = userId;
    _role = role;
    notifyListeners();
  }

  void logout() {
    _homeownerId = null;
    _userId = null;
    _role = null;
    notifyListeners();
  }
}