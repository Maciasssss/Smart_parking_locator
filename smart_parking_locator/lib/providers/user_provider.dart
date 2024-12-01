import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

class UserProvider with ChangeNotifier {
  final AuthService _authService;

  UserProvider(this._authService);
 
  Future<bool> checkAdminStatus() async {
    return await _authService.isAdminUser(); 
  }
}
