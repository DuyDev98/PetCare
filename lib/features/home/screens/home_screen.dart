import 'package:flutter/material.dart';
import 'package:pet_care/data/services/pet_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_bottom_nav_bar.dart';
import 'setup_profile_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PetService _petService = PetService();

  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> _pets = [];
  bool _isLoading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _petService.getCurrentUserData(),
        _petService.getMyPets(),
      ]);

      if (mounted) {
        setState(() {
          _userData = results[0] as Map<String, dynamic>?;
          _pets = results[1] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      print("Lỗi loadData HomeScreen: $e");
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Stack(
              children: [
                Positioned(
                  right: -screenWidth * 0.2,
                  top: -screenWidth * 0.2,
                  child: Container(
                    width: screenWidth * 0.5,
                    height: screenWidth * 0.5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 25),
                      _buildMyPetsSection(screenWidth),
                      const SizedBox(height: 25),
                      _buildScheduleSection(),
                      const SizedBox(height: 25),
                      _buildQuickActionsGrid(),
                      const SizedBox(height: 25),
                      _buildLatestNotesSection(screenWidth),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }

  Widget _buildHeader() {
    String name = _userData?['displayName'] ?? 'Bạn';
    String photoUrl = _userData?['photoURL'] ?? '';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.secondary,
                  backgroundImage: photoUrl.isNotEmpty ? CachedNetworkImageProvider(photoUrl) : null,
                  child: photoUrl.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Chào,', style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
                    Text(
                      '$name!',
                      style: const TextStyle(color: Color(0xFF1F2937), fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _buildNotificationButton(),
      ],
    );
  }

  Widget _buildNotificationButton() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
          ),
          child: IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF1F2937)),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
            },
          ),
        ),
        Positioned(
          right: 8,
          top: 8,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildMyPetsSection(double screenWidth) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Thú cưng của tôi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
            Row(
              children: [
                _buildSmallCircleButton(Icons.chevron_left),
                const SizedBox(width: 8),
                _buildSmallCircleButton(Icons.chevron_right),
              ],
            )
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            // Nếu list trống, chỉ hiện nút Add. Nếu có list, hiện list + nút Add ở cuối.
            itemCount: _pets.length + 1,
            itemBuilder: (context, index) {
              if (index < _pets.length) {
                final pet = _pets[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _buildPetCard(
                    width: screenWidth * 0.38,
                    name: pet['name'] ?? 'Pet',
                    breed: pet['type'] ?? 'Unknown',
                    age: '${pet['age'] ?? '0'} tuổi',
                    imageUrl: pet['avatarUrl'] ?? '', // FIX: Dùng avatarUrl từ Database
                    isGradient: index % 2 == 0,
                  ),
                );
              } else {
                return _buildAddPetCard(screenWidth * 0.3);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPetCard({required double width, required String name, required String breed, required String age, required String imageUrl, required bool isGradient}) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isGradient ? null : Colors.white,
        gradient: isGradient ? const LinearGradient(colors: [Color(0xFFF4A261), Color(0xFFE8834A)], begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white,
            child: ClipOval(
              child: imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const CircularProgressIndicator(strokeWidth: 2),
                    errorWidget: (context, url, error) => const Icon(Icons.pets, color: Colors.grey),
                  )
                : const Icon(Icons.pets, size: 30, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isGradient ? Colors.white : const Color(0xFF374151)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            breed,
            style: TextStyle(fontSize: 12, color: isGradient ? Colors.white70 : Colors.black54),
            maxLines: 1,
          ),
          Text(
            age,
            style: TextStyle(fontSize: 11, color: isGradient ? Colors.white.withValues(alpha: 0.7) : Colors.black45),
          ),
        ],
      ),
    );
  }

  Widget _buildAddPetCard(double width) {
    return GestureDetector(
      onTap: () async {
        // Sau khi quay lại từ trang Setup, tải lại data
        await Navigator.push(context, MaterialPageRoute(builder: (context) => const SetupProfileScreen()));
        _loadData(); 
      },
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary, width: 1.5, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.add, color: AppColors.primary, size: 24),
            ),
            const SizedBox(height: 8),
            const Text('Thêm mới', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // ... (Giữ nguyên các hàm UI khác: _buildScheduleSection, _buildQuickActionsGrid, v.v.)
  Widget _buildScheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Lịch chăm sóc & Nhắc nhở', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nhiệm vụ hôm nay', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
              const SizedBox(height: 16),
              _buildTaskItem(time: '8:00 AM', desc: 'Cho thú cưng ăn', icon: '🍖', isDone: true),
              _buildTaskItem(time: '10:30 AM', desc: 'Tắm rửa', icon: '🛁', isDone: false),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildTaskItem({required String time, required String desc, required String icon, required bool isDone}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(isDone ? Icons.check_circle : Icons.radio_button_unchecked, color: isDone ? const Color(0xFF6BBFA3) : Colors.grey.shade300, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$time: $desc',
              style: TextStyle(
                fontSize: 13,
                color: isDone ? const Color(0xFF9CA3AF) : const Color(0xFF374151),
                decoration: isDone ? TextDecoration.lineThrough : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(icon, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildQuickActionButton(icon: Icons.calendar_month, label: 'Lịch', bgColor: const Color(0xFFFFF1E6), iconColor: const Color(0xFFF4A261)),
          _buildQuickActionButton(icon: Icons.medical_services_outlined, label: 'Y tế', bgColor: AppColors.primary, iconColor: Colors.white),
          _buildQuickActionButton(icon: Icons.shopping_bag_outlined, label: 'Shop', bgColor: const Color(0xFF4CAF82), iconColor: Colors.white),
          _buildQuickActionButton(icon: Icons.people_alt_outlined, label: 'Cộng đồng', bgColor: const Color(0xFF5B9BD5), iconColor: Colors.white, badgeCount: 3),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({required IconData icon, required String label, required Color bgColor, required Color iconColor, int badgeCount = 0}) {
    return Expanded(
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16)),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              if (badgeCount > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                    child: Text('$badgeCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                )
            ],
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF374151), fontWeight: FontWeight.w500))
        ],
      ),
    );
  }

  Widget _buildLatestNotesSection(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ghi chú mới nhất', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildNavArrow(Icons.chevron_left),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildNoteCard(screenWidth, 'Luna', 'Khám định kỳ', 'assets/images/dog.png')),
                  const SizedBox(width: 12),
                  Expanded(child: _buildNoteCard(screenWidth, 'Milo', 'Tắm rửa', 'assets/images/cat.png')),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _buildNavArrow(Icons.chevron_right),
          ],
        )
      ],
    );
  }

  Widget _buildNoteCard(double screenWidth, String name, String note, String imgPath) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.asset(imgPath, height: 80, width: double.infinity, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(height: 80, color: Colors.grey[200])),
          ),
          const SizedBox(height: 10),
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text(note, style: const TextStyle(fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildNavArrow(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[200]!)),
      child: Icon(icon, size: 20, color: Colors.grey),
    );
  }

  Widget _buildSmallCircleButton(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: Icon(icon, size: 20, color: Colors.black54),
    );
  }
}
