import 'package:flutter/foundation.dart';
import '../../data/services/reminder_service.dart';
import '../../data/models/reminder_model.dart';

class BackendTest {
  static Future<void> runAllTests() async {
    final service = ReminderService();
    print("🚀 --- BẮT ĐẦU TEST LOGIC REMINDER ---");

    try {
      // 1. TEST: TẠO NHẮC NHỞ MỚI (Trang 2)
      print("1. Đang tạo nhắc nhở mẫu...");
      await service.createReminder(
        title: "Tắm cho mèo (Test)",
        dateTime: DateTime.now().add(const Duration(hours: 1)), // 1 tiếng nữa
        type: "bath",
        notes: "Ghi chú test logic",
      );
      print("✅ Tạo thành công!");

      // 2. TEST: TẠO NHẮC NHỞ QUÁ HẠN (Để test Trang 3)
      print("2. Đang tạo nhắc nhở quá hạn mẫu...");
      await service.createReminder(
        title: "Đi dạo (Quá hạn)",
        dateTime: DateTime.now().subtract(const Duration(days: 1)), // Hôm qua
        type: "walk",
        status: "pending", // Nhớ sửa hàm createReminder để cho phép truyền status nếu cần
      );

      // 3. TEST: LẤY DANH SÁCH NGÀY HÔM NAY (Trang 1)
      print("3. Kiểm tra danh sách ngày hôm nay:");
      service.getRemindersByDate(DateTime.now()).listen((list) {
        print("📋 Số lượng nhắc nhở hôm nay: ${list.length}");
        for (var item in list) {
          print("   - [${item.status}] ${item.title} lúc ${item.timestamp}");
        }
      });

      // 4. TEST: LẤY DANH SÁCH QUÁ HẠN (Trang 3)
      print("4. Kiểm tra danh sách quá hạn:");
      service.getOverdueReminders().listen((list) {
        print("⚠️ Số lượng quá hạn: ${list.length}");
        for (var item in list) {
          print("   - OVERDUE: ${item.title}");
        }
      });

    } catch (e) {
      print("❌ LỖI KHI TEST: $e");
    }
  }
}