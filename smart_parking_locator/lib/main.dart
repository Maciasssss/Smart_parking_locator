import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:provider/provider.dart';
import 'screens/map_screen.dart'; 
import 'screens/login_screen.dart';
import 'screens/admin_panel.dart';
import 'providers/user_provider.dart';
import 'providers/parking_spot_provider.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await FMTCObjectBoxBackend().initialise();
    const FMTCStore newStore = FMTCStore('mapStore');
    await newStore.manage.create(); 
  } catch (e) {
    print('FMTC initialization failed: $e');
  }

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
        home: MapScreen(), 
        routes: {
          '/login': (context) => LoginScreen(),
          '/admin': (context) => AdminPanel(),
        },
      ),
    );
  }
}
