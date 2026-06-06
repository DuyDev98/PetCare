import 'package:flutter/material.dart';

class AppColors {
  // Màu chủ đạo - Cam sáng
  static const Color primary = Color(0xFFF4A261);
  static const Color primaryLight = Color(0xFFFFE8D6);
  static const Color primaryDark = Color(0xFFE76F51);

  // Khôi phục các màu bị thiếu
  static const Color secondary = Color(0xFFE76F51); // Thường là màu tương phản hoặc đậm hơn primary
  static const Color textBlack = Color(0xFF1F2937);
  static const Color textGrey = Color(0xFF6B7280);

  // Màu nền và màu phụ
  static const Color background = Color(0xFFFAF9F6);
  static const Color grey = Color(0xFF9CA3AF);
  static const Color darkGrey = Color(0xFF4B5563);
  static const Color lightGrey = Color(0xFFF3F4F6);

  // Gradient cho Header
  static const LinearGradient orangeGradient = LinearGradient(
    colors: [Color(0xFFF4A261), Color(0xFFE8834A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
