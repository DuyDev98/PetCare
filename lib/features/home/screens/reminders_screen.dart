import 'package:flutter/material.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Màu nền gốc
      body: Stack(
        children: [
          _buildBackgroundDecor(), // Vẽ các vòng tròn trang trí ở góc
          SafeArea(
            child: Column(
              children: [
                _buildHeader(), // Thanh tiêu đề và chuông thông báo
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildPetSelector(), // Hàng avatar thú cưng[cite: 1]
                        _buildCalendarSection(), // Khu vực lịch tháng 3[cite: 1]
                        _buildTaskSection(), // Danh sách nhiệm vụ hôm nay[cite: 1]
                        const SizedBox(height: 100), // Khoảng trống cuộn[cite: 1]
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildBottomNav(), // Thanh điều hướng dưới cùng[cite: 1]
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(), // Nút thêm mới[cite: 1]
    );
  }

  // 1. Vẽ các khối trang trí ở góc (Giống 100% bản gốc)
  Widget _buildBackgroundDecor() {
    return Stack(
      children: [
        Positioned(
          right: 0, top: 0,
          child: Opacity(
            opacity: 0.5,
            child: Container(
              width: 128, height: 128,
              decoration: const BoxDecoration(
                color: Color(0xFFFFD6B8),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(9999)),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0, bottom: 100,
          child: Opacity(
            opacity: 0.4,
            child: Container(
              width: 112, height: 112,
              decoration: const BoxDecoration(
                color: Color(0xFFC8F0E0),
                borderRadius: BorderRadius.only(topRight: Radius.circular(9999)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 2. Thanh tiêu đề
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildCircularIcon(Icons.calendar_today, 36),
              const SizedBox(width: 12),
              const Text('Lịch chăm sóc & Nhắc nhở',
                  style: TextStyle(color: Color(0xFF1F2937), fontSize: 20, fontWeight: FontWeight.w700)),
            ],
          ),
          _buildNotificationBadge(3), // Số 3 màu đỏ[cite: 1]
        ],
      ),
    );
  }

  // 3. Chọn thú cưng (Sử dụng ListView để Responsive)
  Widget _buildPetSelector() {
    return SizedBox(
      height: 90,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _buildPetAvatar('Tất cả', isSelected: true),
          _buildPetAvatar('Milo'),
          _buildPetAvatar('Bella'),
          _buildPetAvatar('Coco'),
          _buildPetAvatar('Max'),
        ],
      ),
    );
  }

  // 4. Khu vực Lịch (Thay thế đống Row/Column thủ công)
  Widget _buildCalendarSection() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('March', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          const Text('2025', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: const Text("Phần lịch sẽ hiển thị tại đây (Giữ nguyên UI cũ của Duy)"), // Tối ưu sau[cite: 1]
          ),
        ],
      ),
    );
  }

  // 5. Danh sách nhiệm vụ
  Widget _buildTaskSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildTaskHeader("Nhiệm vụ hôm nay", "2/8 hoàn thành"),
          const SizedBox(height: 10),
          _buildTaskCard("Tắm cho chó Bella", "08:30", "Bella - Golden Retriever", "Tắm", const Color(0xFF60A5FA)),
          _buildTaskCard("Tiêm vaccine phòng dại cho Max", "10:00", "Max - Beagle", "Tiêm vaccine", const Color(0xFFF87171)),
          _buildTaskCard("Cho Bella ăn trưa", "12:00", "Bella - Golden Retriever", "Cho ăn", const Color(0xFFF4A261), isDone: true),
        ],
      ),
    );
  }

  // --- CÁC HÀM BỔ TRỢ (HELPERS) ---

  Widget _buildCircularIcon(IconData icon, double size) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2)],
      ),
      child: Icon(icon, size: size * 0.5),
    );
  }

  Widget _buildNotificationBadge(int count) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _buildCircularIcon(Icons.notifications_none, 40),
        Positioned(
          right: -2, top: -2,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: const Color(0xFFEF4444), shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2)),
            child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildPetAvatar(String name, {bool isSelected = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: isSelected ? const Color(0xFFF4A261) : Colors.transparent, width: 2),
            ),
            child: const CircleAvatar(radius: 26, backgroundImage: NetworkImage("https://placehold.co/52x52")),
          ),
          Text(name, style: TextStyle(color: isSelected ? const Color(0xFFF4A261) : const Color(0xFF9CA3AF), fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildTaskHeader(String title, String status) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: Color(0xFF1F2937), fontSize: 16, fontWeight: FontWeight.w700)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: const Color(0xFFFFF3E8), borderRadius: BorderRadius.circular(9999)),
          child: Text(status, style: const TextStyle(color: Color(0xFFF4A261), fontSize: 11)),
        ),
      ],
    );
  }

  Widget _buildTaskCard(String title, String time, String pet, String tag, Color color, {bool isDone = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDone ? const Color(0xFFF9F9F9) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: const Color(0xFFFFF8F0), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.pets, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFFFFF8F0), borderRadius: BorderRadius.circular(99)),
                      child: Text(tag, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 8),
                    Text(time, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11)),
                  ],
                ),
                Text(title, style: TextStyle(fontSize: 13, decoration: isDone ? TextDecoration.lineThrough : null)),
                Text(pet, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11)),
              ],
            ),
          ),
          Icon(isDone ? Icons.check_circle : Icons.radio_button_unchecked, color: isDone ? Colors.green : Colors.grey),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        height: 80,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Icon(Icons.home_outlined, color: Colors.grey),
            Icon(Icons.medical_services_outlined, color: Colors.grey),
            Icon(Icons.calendar_month, color: Color(0xFFF4A261)), // Đang ở màn hình lịch[cite: 1]
            Icon(Icons.people_outline, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
      width: 56, height: 56,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [Color(0xFFF4A261), Color(0xFFFBBF24)]),
      ),
      child: const Icon(Icons.add, color: Colors.white),
    );
  }
}