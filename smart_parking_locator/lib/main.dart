import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/login_screen.dart';
import 'screens/admin_panel.dart';
import 'services/auth_service.dart';
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';
import 'providers/parking_spot_provider.dart'; // Import ParkingSpotProvider

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final AuthService _authService = AuthService(); // Ensure proper injection

  @override
  Widget build(BuildContext context) {
    return MultiProvider( // Use MultiProvider to include multiple providers
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider(_authService)),
        ChangeNotifierProvider(create: (_) => ParkingSpotProvider()), // Provide ParkingSpotProvider
      ],
      child: MaterialApp(
        title: 'Smart Parking Locator',
        home: FutureBuilder<bool>(
          future: _authService.isAdminUser(), // Check if the user is admin
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error occurred!'));
            } else {
              final isAdmin = snapshot.data ?? false;
              return isAdmin ? AdminPanel() : LoginScreen(); // Direct user to the correct screen
            }
          },
        ),
        routes: {
          '/login': (context) => LoginScreen(),
          '/admin': (context) => AdminPanel(),
        },
      ),
    );
  }
}
