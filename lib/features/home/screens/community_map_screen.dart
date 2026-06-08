import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pet_care/core/constants/app_colors.dart';

class CommunityMapScreen extends StatefulWidget {
  const CommunityMapScreen({super.key});

  @override
  State<CommunityMapScreen> createState() => _CommunityMapScreenState();
}

class _CommunityMapScreenState extends State<CommunityMapScreen> {
  // MapController dùng để điều khiển bản đồ chương trình (zoom, move, rotate)
  final MapController _mapController = MapController();

  // LỖI 1: Tạo biến tọa độ mặc định (Hà Nội) làm fallback để tránh NaN
  LatLng _currentPosition = const LatLng(21.0285, 105.8542);
  bool _isAnonymous = false;
  bool _isLoading = true; // Biến quản lý trạng thái tải vị trí
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  /// Lấy vị trí hiện tại của thiết bị
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng bật định vị trên thiết bị.')),
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _isLoading = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // FIX LỖI: Hiển thị SnackBar khi bị từ chối quyền vĩnh viễn
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bạn cần cấp quyền vị trí để xem cộng đồng quanh mình')),
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Lấy GPS chính xác
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _isLoading = false;
        });

        // FIX LỖI: Lập tức "bay" về vị trí thực tế của người dùng (ví dụ Hà Nội)
        _mapController.move(_currentPosition, 17.5);

        // Cập nhật vị trí lên Firestore nếu không ở chế độ ẩn danh
        _updateUserLocation(_currentPosition);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi định vị: $e')),
        );
      }
    }
  }

  Future<void> _updateUserLocation(LatLng position) async {
    if (_userId.isEmpty || _isAnonymous) return;
    await FirebaseFirestore.instance.collection('user_locations').doc(_userId).set({
      'userId': _userId,
      'location': GeoPoint(position.latitude, position.longitude),
      'isAnonymous': _isAnonymous,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  void _goToMyLocation() {
    // MapController.move(center, zoom) cho phép di chuyển bản đồ đến tọa độ mong muốn
    _mapController.move(_currentPosition, 15.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cộng đồng quanh bạn', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        actions: [
          Row(
            children: [
              const Text('Ẩn danh', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Switch(
                value: _isAnonymous,
                activeColor: AppColors.primary,
                onChanged: (val) {
                  setState(() => _isAnonymous = val);
                  if (val) {
                    // Xóa vị trí nếu bật ẩn danh
                    FirebaseFirestore.instance.collection('user_locations').doc(_userId).delete();
                  } else if (_currentPosition != null) {
                    _updateUserLocation(_currentPosition!);
                  }
                },
              ),
            ],
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentPosition,
                    initialZoom: 14.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.petcare.app',
                    ),
                    _buildUserMarkersStream(),
                  ],
                ),
                Positioned(
                  bottom: 20,
                  right: 16,
                  child: FloatingActionButton(
                    onPressed: _goToMyLocation,
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.my_location, color: AppColors.primary),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildUserMarkersStream() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('user_locations').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const MarkerLayer(markers: []);

        List<Marker> markers = [];

        // Marker của chính mình (màu xanh)
        if (!_isAnonymous) {
          markers.add(
            Marker(
              point: _currentPosition,
              width: 50,
              height: 50,
              child: const Icon(Icons.location_on, color: Colors.blue, size: 40),
            ),
          );
        }

        // Markers của người dùng khác
        for (var doc in snapshot.data!.docs) {
          if (doc.id == _userId) continue;
          final data = doc.data() as Map<String, dynamic>;
          final GeoPoint gp = data['location'];
          final LatLng pos = LatLng(gp.latitude, gp.longitude);

          markers.add(
            Marker(
              point: pos,
              width: 50,
              height: 50,
              child: GestureDetector(
                onTap: () => _showUserDetail(data),
                child: const Icon(Icons.pets, color: AppColors.primary, size: 35),
              ),
            ),
          );
        }

        return MarkerLayer(markers: markers);
      },
    );
  }

  void _showUserDetail(Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primaryLight,
              child: Icon(Icons.person, size: 50, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            const Text('Thành viên PetCare', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Đang ở gần bạn!', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Nhắn tin làm quen', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
