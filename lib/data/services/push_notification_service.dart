import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pet_care/data/services/local_notification_service.dart';
import 'dart:developer';

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _localNotificationService = LocalNotificationService();

  /// Khởi tạo FCM, xin quyền và lấy token
  Future<void> initFCM() async {
    // Xin quyền thông báo (đối với iOS)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      log('User granted permission');

      // Lấy token
      String? token = await _fcm.getToken();
      if (token != null) {
        log("FCM Token: $token");
        // Tự động lưu token nếu user đã login
        await refreshUserFCM();
      }
    }

    // Lắng nghe thông báo khi app đang mở (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log("Nhận thông báo foreground: ${message.notification?.title}");

      if (message.notification != null) {
        _localNotificationService.showNotification(
          id: message.hashCode,
          title: message.notification!.title ?? 'Thông báo mới',
          body: message.notification!.body ?? '',
        );
      }
    });

    // Lắng nghe khi người dùng nhấn vào thông báo để mở app
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log("Mở app từ thông báo: ${message.notification?.title}");
    });
  }

  /// Cập nhật token và vị trí người dùng lên Firestore
  Future<void> updateUserTokenAndLocation({
    required String token,
    required double latitude,
    required double longitude,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db.collection('users').doc(user.uid).set({
      'fcmToken': token,
      'location': GeoPoint(latitude, longitude),
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    log("Đã cập nhật token và vị trí cho user ${user.uid}");
  }

  /// Hàm tiện ích để tự động cập nhật nếu đã đăng nhập
  Future<void> refreshUserFCM() async {
    final user = _auth.currentUser;
    if (user != null) {
      String? token = await _fcm.getToken();
      if (token != null) {
        // Giả sử vị trí được lấy từ một service khác hoặc truyền vào
        // Ở đây chỉ minh họa việc lưu token
        await _db.collection('users').doc(user.uid).set({
          'fcmToken': token,
        }, SetOptions(merge: true));
      }
    }
  }
}
