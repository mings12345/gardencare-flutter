import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  String? _token;
  Map<String, dynamic>? _user;
  int? _homeownerId;
  String? _role;
  String? _userId;
  String? _account;
  String? _address;
  String? _phone;
  String? _name;
  String? _email;

  // Getters
  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  int? get homeownerId => _homeownerId;
  String? get role => _role;
  String? get userId => _userId;
  String? get account => _account;
  String? get address => _address;
  String? get phone => _phone; 
  String? get name => _name;
  String? get email => _email;
  
  // Combined status check
  bool get isLoggedIn => _token != null;

  // Main method to set all user data
   void setUserData({
    required String token,
    required Map<String, dynamic> userData,
    int? homeownerId,
    String? account,
    String? role,
    String? userId,
    String? name,
    String? email,
    String? address,
    String? phone,
  }) {
    _token = token;
    _user = userData;
    _homeownerId = homeownerId;
    _role = role;
    _userId = userId;
    _account = account;
    _name = name ?? userData['name'];
    _email = email ?? userData['email'];
    _address = address ?? userData['address'];
    _phone = phone ?? userData['phone'];
    notifyListeners();
  }


   // Add these setters
  void setName(String name) {
    _name = name;
    notifyListeners();
  }

  void setEmail(String email) {
    _email = email;
    notifyListeners();
  }

  void setAddress(String address) {
    _address = address;
    notifyListeners();
  }

  void setPhone(String phone) {
    _phone = phone;
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
  void updateAccountNo(String account) {
  _account = account;
  notifyListeners();
}

    String? get userName => _user?['name'];
  String? get userEmail => _user?['email'];
  String? get userAddress => _user?['address'];
  String? get userPhone => _user?['phone'];
 
}