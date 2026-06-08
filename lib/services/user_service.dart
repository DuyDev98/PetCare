import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Lấy stream số lượng người dùng trong bán kính cho trước (km)
  Stream<int> getNearbyUserCountStream({required double radiusInKm}) {
    // Chúng ta lắng nghe toàn bộ collection users để cập nhật thời gian thực
    return _db.collection('users').snapshots().asyncMap((snapshot) async {
      try {
        // 1. Lấy vị trí hiện tại của thiết bị
        Position currentPos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
        );

        int count = 0;
        for (var doc in snapshot.docs) {
          final data = doc.data();
          // Giả định users có trường 'location' kiểu GeoPoint
          if (data['location'] != null && data['location'] is GeoPoint) {
            GeoPoint targetGP = data['location'];

            // 2. Tính khoảng cách giữa vị trí hiện tại và từng user (mét)
            double distanceInMeters = Geolocator.distanceBetween(
              currentPos.latitude,
              currentPos.longitude,
              targetGP.latitude,
              targetGP.longitude,
            );

            // 3. Đếm nếu nằm trong bán kính radiusInKm
            if (distanceInMeters <= radiusInKm * 1000) {
              count++;
            }
          }
        }
        return count;
      } catch (e) {
        return 0;
      }
    });
  }
}
