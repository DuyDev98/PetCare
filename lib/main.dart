import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// 1. Đổi import từ register_screen.dart sang login_screen.dart
import 'package:pet_care/features/auth/screens/login_screen.dart';

void main() async {
  // 3. Phải gọi dòng này đầu tiên để Flutter chuẩn bị sẵn sàng
  WidgetsFlutterBinding.ensureInitialized();

  // 4. Bật công tắc khởi động Firebase
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
      ),
      // 2. Gọi giao diện Đăng nhập làm màn hình khởi động
      home: const LoginScreen(),
    );
  }
}