import 'package:flutter/foundation.dart';

class AuthService with ChangeNotifier {
  bool _isAdmin = false; // Default user role

  // Dummy user data for testing; replace with your actual logic.
  final List<String> _adminEmails = ['admin@example.com']; // Admin email addresses

  // Simulated login method
  Future<bool> login(String email, String password) async {
    await Future.delayed(Duration(seconds: 1)); // Simulate network delay

    // Replace this with your actual authentication logic
    if (_adminEmails.contains(email) && password == 'adminpassword') {
      _isAdmin = true; // Set admin if the email matches
      notifyListeners(); // Notify listeners about the change
      return true; // Login successful
    }
    return false; // Login failed
  }

  // Simulated logout method
  Future<void> logout() async {
    await Future.delayed(Duration(seconds: 1)); // Simulate network delay
    _isAdmin = false; // Reset admin status
    notifyListeners(); // Notify listeners about the change
  }

  // Example method to check admin status asynchronously
  Future<bool> isAdminUser() async {
    await Future.delayed(Duration(seconds: 1)); // Simulate network delay
    return _isAdmin; // Return admin status
  }
}
