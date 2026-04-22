import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDE9C9),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header với nút Back
            _buildHeader(context),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. Ảnh đại diện (Avatar) với nút Edit nhỏ
                    Center(child: _buildAvatarSection()),

                    const SizedBox(height: 20),

                    // 3. Thông tin cá nhân (Name, Gender)
                    _buildSectionTitle("Owner"),
                    _buildInfoRow("Name", "Senoda Thihansi"),
                    _buildInfoRow("Gender", "Woman"),

                    const SizedBox(height:10),

                    // 4. Liên hệ (Email, Phone)
                    _buildSectionTitle("Owner's contacts"),
                    _buildInfoRow("Email", "Senoda@gmail.com"),
                    _buildInfoRow("Phone", "+9471456465"),

                    const SizedBox(height: 10),

                    // 5. Địa chỉ (Country, City, Address)
                    _buildSectionTitle("City of residence"),
                    _buildInfoRow("Country", "Sri Lanka"),
                    _buildInfoRow("City", "Malabe"),
                    const SizedBox(height: 10),
                    _buildSectionTitle("Address"),
                    _buildInfoRow("Address", "Your full address here", isFullWidth: true),

                    const SizedBox(height: 30),

                    // 6. Nút chức năng (Edit & Log out)
                    _buildActionButtons(),

                    const SizedBox(height: 15),
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

  // --- Widget: Avatar Section ---
  Widget _buildAvatarSection() {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: const CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey,
            backgroundImage: NetworkImage('https://via.placeholder.com/150'), // Thay bằng ảnh thật
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(color: Color(0xFFEFA973), shape: BoxShape.circle),
            child: const Icon(Icons.edit, color: Colors.white, size: 18),
          ),
        ),
      ],
    );
  }

  // --- Widget: Hàng thông tin (Info Row) ---
  Widget _buildInfoRow(String label, String value, {bool isFullWidth = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          // Phần Label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            width: isFullWidth ? null : 100,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1E6),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                bottomLeft: Radius.circular(10),
              ),
            ),
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5D4037)),
            ),
          ),
          // Phần Giá trị
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Text(
                value,
                style: const TextStyle(color: Color(0xFF5D4037)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Widget: Nút chức năng ---
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEFA973),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: const Text("Edit", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: const Text("Log out", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 5),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF5D4037)),
      ),
    );
  }


}