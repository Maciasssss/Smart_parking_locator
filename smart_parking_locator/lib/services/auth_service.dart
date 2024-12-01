import 'package:flutter/foundation.dart';

class AuthService with ChangeNotifier {
  bool _isAdmin = false; 

  final List<String> _adminEmails = ['admin']; 

  Future<bool> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1)); 

    if (_adminEmails.contains(email) && password == 'admin') {
      _isAdmin = true; 
      notifyListeners(); 
      return true; 
    }
    return false; 
  }

  Future<void> logout() async {
    await Future.delayed(const Duration(seconds: 1)); 
    _isAdmin = false; 
    notifyListeners(); 
  }
  
  Future<bool> isAdminUser() async {
    await Future.delayed(const Duration(seconds: 1)); 
    return _isAdmin;
  }
}
