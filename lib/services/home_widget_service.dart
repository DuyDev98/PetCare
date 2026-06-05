import 'package:home_widget/home_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:pet_care/features/calendar/models/reminder_model.dart';

/// Service để quản lý Pet Reminder Widget trên Home Screen
class HomeWidgetService {
  /// Hàm cập nhật widget nhắc nhở thú cưng
  ///
  /// [petName]: Tên của thú cưng (VD: Mèo Miu, Chó Bím)
  /// [reminderTitle]: Nội dung nhắc nhở (VD: Tiêm phòng dại, Khám sức khỏe)
  /// [time]: Thời gian nhắc nhở (VD: Hôm nay, 14:00)
  static Future<void> updateReminderWidget({
    required String petName,
    required String reminderTitle,
    required String time,
  }) async {
    try {
      // Lưu dữ liệu vào SharedPreferences thông qua home_widget plugin
      await HomeWidget.saveWidgetData<String>('petName', petName);
      await HomeWidget.saveWidgetData<String>('reminderTitle', reminderTitle);
      await HomeWidget.saveWidgetData<String>('time', time);

      // Gọi update widget với tên provider là 'PetReminderWidgetProvider'
      // Tên này phải trùng với tên class trong Android
      await HomeWidget.updateWidget(
        name: 'PetReminderWidgetProvider',
        iOSName: 'PetReminderWidgetProvider',
      );
    } catch (e) {
      print('Lỗi cập nhật widget: $e');
    }
  }

  /// Hàm xóa dữ liệu widget khi không còn nhắc nhở
  static Future<void> clearReminderWidget() async {
    try {
      await HomeWidget.saveWidgetData<String>('petName', 'Pet Care');
      await HomeWidget.saveWidgetData<String>('reminderTitle', 'Không có lịch nhắc sắp tới');
      await HomeWidget.saveWidgetData<String>('time', '--:--');

      await HomeWidget.updateWidget(
        name: 'PetReminderWidgetProvider',
        iOSName: 'PetReminderWidgetProvider',
      );
    } catch (e) {
      print('Lỗi xóa widget: $e');
    }
  }

  /// Tự động lấy lịch nhắc sắp tới nhất từ Firestore và cập nhật Widget
  static Future<void> refreshWidget() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('HomeWidget: User not logged in');
        await clearReminderWidget();
        return;
      }

      print('HomeWidget: Refreshing for user ${user.uid}');

      // Lấy tất cả nhắc nhở 'pending' của user này
      // Không dùng orderBy để tránh yêu cầu Composite Index phức tạp ban đầu
      final snapshot = await FirebaseFirestore.instance
          .collection('reminders')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'pending')
          .get();

      if (snapshot.docs.isEmpty) {
        print('HomeWidget: No pending reminders found for UID: ${user.uid}');
        await clearReminderWidget();
      } else {
        print('HomeWidget: Found ${snapshot.docs.length} pending items. Sorting in Dart...');

        // Chuyển sang model và lọc bỏ Template, sau đó sắp xếp theo thời gian
        List<ReminderModel> reminders = snapshot.docs
            .map((doc) => ReminderModel.fromMap(doc.data(), doc.id))
            .where((r) => !r.isTemplate) // Bỏ qua các bản mẫu lặp lại
            .toList();

        if (reminders.isEmpty) {
          print('HomeWidget: All pending items are templates. Clearing widget.');
          await clearReminderWidget();
          return;
        }

        // Sắp xếp: Ưu tiên lịch sắp tới (gần nhất), sau đó đến lịch quá hạn
        reminders.sort((a, b) => a.timestamp.compareTo(b.timestamp));

        final nearest = reminders.first;
        final String petName = nearest.petName;
        final String title = nearest.title;
        final DateTime dateTime = nearest.timestamp;
        final now = DateTime.now();

        print('HomeWidget: Nearest reminder: $title for $petName at $dateTime');

        // Định dạng thời gian
        String timeStr = '';
        if (dateTime.day == now.day &&
            dateTime.month == now.month &&
            dateTime.year == now.year) {
          timeStr = 'Hôm nay, ${DateFormat('HH:mm').format(dateTime)}';
        } else if (dateTime.isBefore(now)) {
          timeStr = 'Quá hạn: ${DateFormat('dd/MM, HH:mm').format(dateTime)}';
        } else {
          timeStr = DateFormat('dd/MM, HH:mm').format(dateTime);
        }

        await updateReminderWidget(
          petName: petName,
          reminderTitle: title,
          time: timeStr,
        );
      }
    } catch (e) {
      print('Lỗi refresh widget: $e');
    }
  }
}
