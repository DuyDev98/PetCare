import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_care/data/services/pet_service.dart';
import 'package:pet_care/features/home/screens/home_screen.dart';
import 'package:pet_care/features/auth/screens/login_screen.dart';
import 'package:pet_care/features/auth/screens/role_selection_screen.dart';
import 'package:pet_care/features/partner/screens/partner_home_screen.dart';

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
        // 1. Nếu chưa đăng nhập -> Màn hình Login
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        // 2. Nếu đã đăng nhập -> Kiểm tra Role/Profile
        return FutureBuilder<Map<String, dynamic>?>(
          future: PetService().getCurrentUserData(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            final userData = userSnapshot.data;
            if (userData == null || userData['role'] == null) {
              return const RoleSelectionScreen();
            }

            if (userData['role'] == 'partner') {
              return const PartnerHomeScreen();
            }

            // Nếu là user, kiểm tra xem đã có pet chưa
            return FutureBuilder<bool>(
              future: PetService().checkUserProfileExists(),
              builder: (context, petSnapshot) {
                if (petSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(body: Center(child: CircularProgressIndicator()));
                }
                
                if (petSnapshot.data == true) {
                  return const HomeScreen();
                } else {
                  return const RoleSelectionScreen();
                }
              },
            );
          },
        );
      },
    );
  }
}
