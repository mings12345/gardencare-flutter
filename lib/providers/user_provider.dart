import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  int? _homeownerId;

  int? get homeownerId => _homeownerId;

  void setHomeownerId(int id) {
    _homeownerId = id;
    notifyListeners();
  }
}