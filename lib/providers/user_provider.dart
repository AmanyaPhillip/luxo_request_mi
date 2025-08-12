import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class UserProvider with ChangeNotifier {
  UserData? _userData;
  bool _isSetupComplete = false;

  UserData? get userData => _userData;
  bool get isSetupComplete => _isSetupComplete;

  // Load user data from SharedPreferences
  Future<void> loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('userData');
      final setupComplete = prefs.getBool('setupComplete') ?? false;
      
      if (userDataString != null) {
        final userDataMap = jsonDecode(userDataString);
        _userData = UserData.fromJson(userDataMap);
      }
      
      _isSetupComplete = setupComplete;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  // Save user data to SharedPreferences
  Future<void> saveUserData(UserData userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = jsonEncode(userData.toJson());
      
      await prefs.setString('userData', userDataString);
      await prefs.setBool('setupComplete', true);
      
      _userData = userData;
      _isSetupComplete = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving user data: $e');
    }
  }

  // Update user data
  Future<void> updateUserData(UserData userData) async {
    await saveUserData(userData);
  }

  // Get current language
  String getCurrentLanguage() {
    return _userData?.language ?? 'English';
  }

  // Get request URL based on current language
  String getRequestUrl() {
    return Constants.getRequestUrl(getCurrentLanguage());
  }

  // Get user's full name
  String getFullName() {
    if (_userData == null) return 'User';
    return '${_userData!.firstName} ${_userData!.lastName}';
  }

  // Clear user data (for testing purposes)
  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userData');
    await prefs.setBool('setupComplete', false);
    
    _userData = null;
    _isSetupComplete = false;
    notifyListeners();
  }
}