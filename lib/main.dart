import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pet_care/features/auth/screens/login_screen.dart';
import 'package:pet_care/features/home/screens/calendar_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_care/data/services/pet_service.dart';
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
import 'package:pet_care/features/booking/screens/vet_clinic_screen.dart';
import 'package:pet_care/features/auth/screens/login_screen.dart';
import 'package:pet_care/features/home/screens/home_screen.dart';
import 'package:pet_care/features/home/screens/setup_profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp();
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
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // 1. Nếu chưa đăng nhập -> Màn hình Login
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        // 2. Nếu đã đăng nhập -> Kiểm tra xem đã tạo thú cưng chưa (Bỏ qua chọn vai trò)
        return FutureBuilder<bool>(
          future: PetService().checkUserProfileExists(),
          builder: (context, petSnapshot) {
            if (petSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            if (petSnapshot.data == true) {
              return const HomeScreen();
            } else {
              // Nếu chưa có pet -> Vào thẳng trang tạo hồ sơ
              return const CalendarScreen();
            }
          },
        );
      },
    );
  }
}
