import 'package:flutter/material.dart';

class PetDetailsScreen extends StatelessWidget {
  const PetDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDE9C9),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header có nút Back
            _buildHeader(context),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. Ảnh thú cưng (Avatar) với icon Edit
                    Center(child: _buildPetAvatar()),

                    const SizedBox(height: 30),

                    // 3. Thông tin cơ bản
                    _buildSectionTitle("Pet"),
                    _buildInfoRow("Name", "Mochi"),
                    _buildInfoRow("Gender", "Female"),

                    const SizedBox(height: 20),

                    // 4. Chi tiết sức khỏe (Weight, Age)
                    _buildSectionTitle("Pet Details"),
                    _buildInfoRow("Weight", "20 lb"),
                    _buildInfoRow("Age", "6 month"),

                    const SizedBox(height: 50),

                    // 5. Nút Edit chính giữa
                    Center(
                      child: SizedBox(
                        width: 200,
                        child: ElevatedButton(
                          onPressed: () {
                            // Chuyển sang màn hình chỉnh sửa
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEFA973),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            "Edit",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Widget: Header ---
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF5D4037)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  // --- Widget: Pet Avatar ---
  Widget _buildPetAvatar() {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: const CircleAvatar(
            radius: 70,
            backgroundColor: Colors.grey,
            backgroundImage: NetworkImage('https://via.placeholder.com/150'), // Thay bằng ảnh mèo thật
          ),
        ),
        Positioned(
          bottom: 5,
          right: 5,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFEFA973),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.edit, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  // --- Widget: Hàng thông tin (Info Row) ---
  Widget _buildInfoRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            width: 110,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF1E6),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF5D4037),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Text(
                value,
                style: const TextStyle(color: Color(0xFF5D4037), fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 5),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF5D4037),
        ),
      ),
    );
  }


}