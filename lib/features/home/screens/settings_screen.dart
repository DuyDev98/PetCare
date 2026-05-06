import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isFeedReminderOn = true;
  bool _isShowerReminderOn = true;
  bool _isVaccineReminderOn = false;
  bool _isDarkModeOn = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7ED),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildProfileSection(),
                  const SizedBox(height: 32),
                  _buildSectionTitle('TÀI KHOẢN'),
                  _buildMenuCard(
                    children: [
                      _buildActionTile(Icons.favorite_border, 'Quản lý thú cưng', const Color(0xFFFFE8D6), const Color(0xFFF4A261), () {}),
                      _buildActionTile(Icons.person_outline, 'Thông tin cá nhân', const Color(0xFFEFEFEF), Colors.grey, () {}),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('THÔNG BÁO'),
                  _buildMenuCard(
                    children: [
                      _buildSwitchTile(Icons.restaurant, 'Nhắc lịch cho ăn', _isFeedReminderOn, (v) => setState(() => _isFeedReminderOn = v)),
                      _buildSwitchTile(Icons.water_drop_outlined, 'Nhắc lịch tắm', _isShowerReminderOn, (v) => setState(() => _isShowerReminderOn = v)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildLogoutButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, color: Color(0xFFF4A261), size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        const Text('Cài đặt', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
        const SizedBox(width: 48),
      ],
    );
  }

  Widget _buildProfileSection() {
    return Column(
      children: [
        const CircleAvatar(radius: 40, backgroundImage: NetworkImage('https://placehold.co/100x100/png')),
        const SizedBox(height: 12),
        const Text('An Nguyễn', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Text('an.nguyen@email.com', style: TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 8, bottom: 12),
        child: Text(title, style: const TextStyle(color: Color(0xFFF4A261), fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildMenuCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(children: children),
    );
  }

  Widget _buildActionTile(IconData icon, String title, Color bg, Color icColor, VoidCallback onTap) {
    return ListTile(
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: icColor, size: 20)),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(IconData icon, String title, bool val, ValueChanged<bool> onChanged) {
    return ListTile(
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: Colors.grey, size: 20)),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: Switch(value: val, onChanged: onChanged, activeColor: const Color(0xFFF4A261)),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
        onPressed: () {},
        child: const Text('Đăng xuất', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
