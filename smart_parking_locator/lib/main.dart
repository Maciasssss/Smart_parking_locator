// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/map_screen.dart'; // Import MapScreen
import 'screens/login_screen.dart';
import 'screens/admin_panel.dart';
import 'services/auth_service.dart';
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';
import 'providers/parking_spot_provider.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider(_authService)),
        ChangeNotifierProvider(create: (_) => ParkingSpotProvider()),
      ],
      child: MaterialApp(
        title: 'Smart Parking Locator',
        home: MapScreen(), // Start with MapScreen
        routes: {
          '/login': (context) => LoginScreen(),
          '/admin': (context) => AdminPanel(),
        },
      ),
    );
  }
}
