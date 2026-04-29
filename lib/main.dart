import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pet_care/features/auth/screens/login_screen.dart';
import 'package:pet_care/features/home/screens/calendar_screen.dart';
import 'package:pet_care/features/home/screens/home_screen.dart';
// import 'package:pet_care/core/utils/backend_test.dart';
import 'package:pet_care/features/home/screens/reminder_tab.dart';
import 'package:pet_care/features/home/screens/setup_profile_screen.dart';
import 'package:pet_care/features/home/screens/health_care_screen.dart';
import 'package:pet_care/features/home/screens/pet_mart_screen.dart';
import 'features/home/screens/tips_screen.dart';
import 'package:pet_care/features/home/screens/profile_screen.dart';
import 'package:pet_care/features/home/screens/pet_details_screen.dart';
import 'package:pet_care/features/home/screens/add_reminder_screen.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load biến môi trường từ file .env
  await dotenv.load(fileName: ".env");
  
  await Firebase.initializeApp();

  // BackendTest.runAllTests();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pet Care App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      // Bạn có thể đổi lại thành LoginScreen() nếu muốn bắt người dùng đăng nhập trước
      home: const HomeScreen(),
    );
  }
}
