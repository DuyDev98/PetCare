import 'package:flutter/material.dart';

class HealthCareScreen extends StatelessWidget {
  const HealthCareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDE9C9), // Màu nền vàng nhạt đặc trưng
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header: Nút Back và Tiêu đề
            _buildHeader(context),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. Banner Tình trạng sức khỏe (BMI Pet)
                    _buildStatusBanner(),

                    const SizedBox(height: 25),
                    _buildSectionTitle("Chỉ số hôm nay"),
                    const SizedBox(height: 10),

                    // 3. Grid chỉ số nhanh (Nhịp tim, Nước, ...)
                    _buildHealthGrid(),

                    const SizedBox(height: 25),
                    _buildSectionTitle("Lịch trình y tế sắp tới"),
                    const SizedBox(height: 10),

                    // 4. Danh sách Lịch tiêm/Khám (RecyclerView)
                    _buildMedicalList(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // 5. Bottom Navbar Mini
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
            'Sức khỏe thú cưng',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF5D4037)),
          ),
        ],
      ),
    );
  }

  // --- Widget: Banner Tình trạng ---
  Widget _buildStatusBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF82), // Màu xanh lá như ảnh bạn gửi
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Tình trạng chung", style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 5),
                const Text("Sức khỏe Rất Tốt", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                  child: const Text("BMI: 21.0 (Cân đối)", style: TextStyle(color: Colors.white, fontSize: 13)),
                )
              ],
            ),
          ),
          const Icon(Icons.pets, size: 70, color: Colors.white24),
        ],
      ),
    );
  }

  // --- Widget: Grid chỉ số ---
  Widget _buildHealthGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 1.1,
      children: [
        _buildStatCard("Nhịp tim", "95 bpm", Icons.favorite, Colors.red[100]!, Colors.red),
        _buildStatCard("Nước uống", "450 ml", Icons.water_drop, Colors.blue[100]!, Colors.blue),
        _buildStatCard("Calories", "320 kcal", Icons.local_fire_department, Colors.orange[100]!, Colors.orange),
        _buildStatCard("Vận động", "1.2 km", Icons.directions_walk, Colors.green[100]!, Colors.green),
      ],
    );
  }

  // --- Widget: Danh sách Y tế (Giống RecyclerView) ---
  Widget _buildMedicalList() {
    final List<Map<String, dynamic>> medicalData = [
      {"title": "Tiêm Vaccine 7 bệnh", "date": "Ngày 25/04/2026", "icon": Icons.vaccines, "color": Colors.orange},
      {"title": "Tẩy giun định kỳ", "date": "Còn 3 ngày nữa", "icon": Icons.bug_report, "color": Colors.green},
      {"title": "Kiểm tra định kỳ", "date": "Phòng khám PetCare", "icon": Icons.medical_services, "color": Colors.blue},
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: medicalData.length,
      itemBuilder: (context, index) {
        final item = medicalData[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: item['color'].withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(item['icon'], color: item['color'], size: 24),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(item['date'], style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        );
      },
    );
  }

  // --- Các Widget bổ trợ nhỏ ---
  Widget _buildStatCard(String title, String val, IconData icon, Color bg, Color iconCol) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, color: iconCol, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              Text(val, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF5D4037)));
  }

  Widget _buildBottomNavbar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 0, 15, 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavIcon(Icons.calendar_month, "Lịch", Colors.orange),
            _buildNavIcon(Icons.edit_note, "Nhật ký", Colors.orange),
            _buildNavIcon(Icons.bar_chart, "Sức khỏe", Colors.green, isActive: true),
            _buildNavIcon(Icons.people, "Cộng đồng", Colors.blue),
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