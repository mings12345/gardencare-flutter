import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  String? _token;
  Map<String, dynamic>? _user;
  int? _homeownerId;
  String? _role;
  String? _userId;

  // Getters
  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  int? get homeownerId => _homeownerId;
  String? get role => _role;
  String? get userId => _userId;
  
  // Combined status check
  bool get isLoggedIn => _token != null;

  // Main method to set all user data
  void setUserData({
    required String token,
    required Map<String, dynamic> userData,
    int? homeownerId,
    String? role,
    String? userId,
  }) {
    _token = token;
    _user = userData;
    _homeownerId = homeownerId;
    _role = role;
    _userId = userId;
    notifyListeners();
  }

  // Individual setters for specific properties
  void setToken(String token) {
    _token = token;
    notifyListeners();
  }

  void setHomeownerId(int id) {
    _homeownerId = id;
    notifyListeners();
  }

  void setRole(String role) {
    _role = role;
    notifyListeners();
  }

  void setUserId(String userId) {
    _userId = userId;
    notifyListeners();
  }

  // Clear all user data
  void clearUserData() {
    _token = null;
    _user = null;
    _homeownerId = null;
    _role = null;
    _userId = null;
    notifyListeners();
  }

  // Helper to get user name safely
  String? get userName => _user?['name'];

  // Helper to get user email safely
  String? get userEmail => _user?['email'];
}