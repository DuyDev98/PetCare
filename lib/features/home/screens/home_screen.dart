import 'package:flutter/material.dart';
import 'package:pet_care/data/services/pet_service.dart';
import '../../../core/constants/app_colors.dart';

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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    // Lấy dữ liệu user và pets cùng lúc
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
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7D0A8),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 30),
                _buildMyPetsSection(),
                const SizedBox(height: 30),
                _buildScheduleSection(),
                const SizedBox(height: 30),
                _buildQuickActionsGrid(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    String name = _userData?['displayName'] ?? 'User';
    String photoUrl = _userData?['photoURL'] ?? 'https://placehold.co/100x100/png';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundImage: NetworkImage(photoUrl),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Chào,', style: TextStyle(color: Color(0xFFD9501B), fontSize: 14)),
                Text('$name!', style: const TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 10)],
          ),
          child: IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black54),
            onPressed: () {},
          ),
        )
      ],
    );
  }

  Widget _buildMyPetsSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Thú cưng của tôi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
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
            itemCount: _pets.length + 1,
            itemBuilder: (context, index) {
              if (index < _pets.length) {
                final pet = _pets[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _buildPetCard(
                    name: pet['name'] ?? 'Pet',
                    breed: pet['type'] ?? 'Unknown',
                    age: '${pet['age'] ?? '0'} tuổi',
                    imageUrl: pet['type'] == 'dog' ? 'assets/images/dog.png' : 'assets/images/cat.png',
                    isGradient: index % 2 == 0,
                  ),
                );
              } else {
                return _buildAddPetCard();
              }
            },
          ),
        )
      ],
    );
  }

  Widget _buildPetCard({required String name, required String breed, required String age, required String imageUrl, required bool isGradient}) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isGradient ? null : Colors.white,
        gradient: isGradient ? const LinearGradient(colors: [Color(0xFFF6A364), Color(0xFFE98045)], begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
        borderRadius: BorderRadius.circular(24),
        border: isGradient ? null : Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 32, 
              backgroundColor: Colors.grey[200],
              backgroundImage: imageUrl.startsWith('http') ? NetworkImage(imageUrl) : AssetImage(imageUrl) as ImageProvider,
            ),
          ),
          const SizedBox(height: 12),
          Text(name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isGradient ? Colors.white : Colors.black87), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(breed, style: TextStyle(fontSize: 12, color: isGradient ? Colors.white70 : Colors.grey)),
          const SizedBox(height: 4),
          Text(age, style: TextStyle(fontSize: 11, color: isGradient ? Colors.white70 : Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildAddPetCard() {
    return Container(
      width: 110,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF4A261), width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          CircleAvatar(radius: 20, backgroundColor: Colors.white54, child: Icon(Icons.add, color: Color(0xFFF4A261))),
          SizedBox(height: 8),
          Text('Thêm thú\ncưng', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFF4A261), fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildScheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Lịch chăm sóc & Nhắc nhở', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nhiệm vụ hôm nay', style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 16),
              _buildTaskItem(time: '8:00 AM', desc: 'Cho ăn', icon: '🍖', isDone: true),
              _buildTaskItem(time: '10:30 AM', desc: 'Vệ sinh', icon: '🐱', isDone: false),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildTaskItem({required String time, required String desc, required String icon, required bool isDone}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(isDone ? Icons.check_circle : Icons.radio_button_unchecked, color: isDone ? const Color(0xFF6BBFA3) : Colors.grey.shade400, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$time: $desc',
              style: TextStyle(
                fontSize: 14, 
                color: isDone ? Colors.grey : Colors.black87, 
                decoration: isDone ? TextDecoration.lineThrough : null
              ),
            ),
          ),
          Text(icon, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildQuickActionButton(icon: Icons.calendar_month, label: 'Lịch', bgColor: const Color(0xFFFFF1E6), iconColor: const Color(0xFFF4A261)),
          _buildQuickActionButton(icon: Icons.edit_note, label: 'Nhật ký', bgColor: const Color(0xFFFFF1E6), iconColor: const Color(0xFFF4A261)),
          _buildQuickActionButton(icon: Icons.bar_chart, label: 'Sức khỏe', bgColor: const Color(0xFF4CAF82), iconColor: Colors.white, badgeCount: 1),
          _buildQuickActionButton(icon: Icons.people_alt, label: 'Cộng đồng', bgColor: const Color(0xFF5B9BD5), iconColor: Colors.white, badgeCount: 3),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({required IconData icon, required String label, required Color bgColor, required Color iconColor, int badgeCount = 0}) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            if (badgeCount > 0)
              Positioned(
                top: -6,
                right: -6,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: Text('$badgeCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              )
          ],
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w500))
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: const Color(0xFFF4A261),
        unselectedItemColor: Colors.grey.shade400,
        showUnselectedLabels: true,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        currentIndex: 2,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Lịch'),
          BottomNavigationBarItem(icon: Icon(Icons.medical_services_outlined), label: 'Dịch vụ'),
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.local_hospital_outlined), label: 'Bệnh viện'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'Cộng đồng'),
        ],
      ),
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
