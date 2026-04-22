import 'package:flutter/material.dart';

class TipsScreen extends StatefulWidget {
  const TipsScreen({super.key});

  @override
  State<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends State<TipsScreen> {
  // Danh sách dữ liệu mẫu cho các Tips
  final List<Map<String, String>> _allTips = [
    {"title": "Basic Commands", "image": "assets/images/commands.png"},
    {"title": "Choosing Pet Food", "image": "assets/images/food.png"},
    {"title": "Pet-Proofing", "image": "assets/images/proofing.png"},
    {"title": "Exercise Needs", "image": "assets/images/exercise.png"},
    {"title": "Stress Signs", "image": "assets/images/stress.png"},
    {"title": "Vet Visits", "image": "assets/images/vet.png"},
    {"title": "Common Allergies", "image": "assets/images/allergies.png"},
    {"title": "Best Treats", "image": "assets/images/treats.png"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDE9C9),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Tiêu đề và Nút Back
            _buildHeader(context),

            // 2. Thanh tìm kiếm (Search Bar)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: "Search",
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    suffixIcon: Icon(Icons.close, color: Colors.grey, size: 20),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 25),
              child: Text(
                "Daily tips to improve your pet's well-being!",
                style: TextStyle(fontSize: 14, color: Color(0xFF5D4037)),
              ),
            ),
            const SizedBox(height: 20),

            // 3. Grid hiển thị Tips (Ấn vào để xem chi tiết)
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 cột
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 0.85, // Tỷ lệ ô (chiều cao > chiều rộng)
                ),
                itemCount: _allTips.length,
                itemBuilder: (context, index) {
                  return _buildTipCard(
                    context,
                    _allTips[index]['title']!,
                    _allTips[index]['image']!,
                  );
                },
              ),
            ),

            // 4. Navbar Mini
            _buildBottomNavbar(),
          ],
        ),
      ),
    );
  }

  // --- Widget: Header ---
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF5D4037)),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const Text(
            'Tips',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF5D4037)),
          ),
        ],
      ),
    );
  }

  // --- Widget: Ô Tip Card ---
  Widget _buildTipCard(BuildContext context, String title, String imagePath) {
    return GestureDetector(
      onTap: () {
        // Chuyển sang trang chi tiết (Bạn có thể tạo file mới tên TipDetailScreen)
        print("Mở chi tiết: $title");
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFF9F0),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5D4037),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Image.asset(imagePath),
                  // Lộc hãy thay Icon bằng Image.asset(imagePath) khi đã có ảnh nhé
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Widget: Navbar (Đồng bộ với các trang trước) ---
  Widget _buildBottomNavbar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 0, 15, 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavIcon(Icons.home_outlined, "Home", Colors.orange),
            _buildNavIcon(Icons.pets, "My Pet", Colors.orange),
            _buildNavIcon(Icons.lightbulb, "Tips", Colors.orange, isActive: true),
          ],
        ),
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, String label, Color color, {bool isActive = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: isActive ? color : Colors.grey[400]),
        Text(label, style: TextStyle(fontSize: 10, color: isActive ? color : Colors.grey[400])),
      ],
    );
  }
}