import 'package:flutter/material.dart';
import 'package:pet_care/data/services/pet_service.dart';
import 'package:pet_care/features/home/screens/setup_profile_screen.dart';
import 'package:pet_care/features/partner/screens/partner_home_screen.dart';
import '../../../core/constants/app_colors.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final PetService petService = PetService();

    return Scaffold(
      backgroundColor: AppColors.secondary,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.pets, size: 80, color: AppColors.primary),
                const SizedBox(height: 20),
                const Text(
                  'Chào mừng bạn!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Vui lòng xác nhận vai trò của bạn để chúng tôi hỗ trợ tốt nhất',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 40),
                
                // Option: Pet Owner
                _buildRoleCard(
                  context: context,
                  title: 'Tôi là Chủ nuôi',
                  description: 'Tìm kiếm dịch vụ, đặt lịch chăm sóc thú cưng',
                  icon: Icons.person,
                  onTap: () async {
                    // FIX: Chỉ truyền tham số có tên 'role'
                    await petService.saveUserInfo(role: 'user');
                    
                    if (context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const SetupProfileScreen()),
                      );
                    }
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Option: Caretaker/Partner
                _buildRoleCard(
                  context: context,
                  title: 'Tôi là Người chăm sóc',
                  description: 'Cung cấp dịch vụ Spa, Khám bệnh cho thú cưng',
                  icon: Icons.medical_services,
                  onTap: () async {
                    // FIX: Chỉ truyền tham số có tên 'role'
                    await petService.saveUserInfo(role: 'partner');
                    
                    if (context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const PartnerHomeScreen()),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 30),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(description, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
