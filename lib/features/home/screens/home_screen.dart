import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

import 'package:pet_care/data/services/pet_service.dart';
import 'package:pet_care/data/services/pet_photo_service.dart';
import 'package:pet_care/data/models/pet_photo_model.dart';
import 'package:pet_care/core/constants/app_colors.dart';
import 'package:pet_care/features/calendar/models/reminder_model.dart';
import 'package:pet_care/features/calendar/services/reminder_service.dart';
import 'package:pet_care/features/calendar/screens/calendar_screen.dart';
import 'package:pet_care/features/medical/screens/so_y_ba_screen.dart';
import 'package:pet_care/features/lost_and_found/screens/lost_pet_screen.dart';
import 'package:pet_care/features/photo_history/screens/photo_detail_screen.dart';

import 'setup_profile_screen.dart';
import 'settings_screen.dart';
import 'community_screen.dart';
import 'notification_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ROOT SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PetService _petService = PetService();

  int _currentIndex = 0;
  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> _pets = [];
  bool _isLoading = true;

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
          _userData  = results[0] as Map<String, dynamic>?;
          _pets      = results[1] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final pages = <Widget>[
      _HomeTab(                                    // 0 – Trang chủ
        userData: _userData,
        pets: _pets,
        onRefresh: _loadData,
        onTabSwitch: (i) => setState(() => _currentIndex = i),
        onPetsChanged: _loadData,
      ),
      const NotificationScreen(),                  // 1 – Thông báo
      const CalendarScreen(),                      // 2 – Lịch (FAB giữa)
      const SoYBaScreen(showBottomNav: false),     // 3 – Sổ y bạ
      const CommunityScreen(),                     // 4 – Cứu trợ
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HOME TAB
// ─────────────────────────────────────────────────────────────────────────────
class _HomeTab extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final List<Map<String, dynamic>> pets;
  final Future<void> Function() onRefresh;
  final void Function(int) onTabSwitch;
  final VoidCallback onPetsChanged;

  const _HomeTab({
    required this.userData,
    required this.pets,
    required this.onRefresh,
    required this.onTabSwitch,
    required this.onPetsChanged,
  });

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final ReminderService _reminderService = ReminderService();
  final PetPhotoService _photoService    = PetPhotoService();

  int _activePet     = 0;
  int _communityTab  = 0;

  static const _communityTabs = ['Quanh bạn', 'Cách hoạt động', 'An toàn'];
  static const _gradStart = Color(0xFFFFB300);
  static const _gradEnd   = Color(0xFFFF6D00);

  static IconData _iconForType(ReminderType type) {
    switch (type) {
      case ReminderType.feed: return Icons.restaurant_outlined;
      case ReminderType.bath: return Icons.bathtub_outlined;
      case ReminderType.checkup: return Icons.medical_services_outlined;
      case ReminderType.vaccine: return Icons.vaccines_outlined;
      case ReminderType.walk: return Icons.directions_walk_outlined;
      case ReminderType.other: return Icons.event_note_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lấy petId của thú cưng đang hoạt động
    final petId = widget.pets.isNotEmpty ? widget.pets[_activePet]['id'] : '';

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: AppColors.primary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildGradientHeader()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildTodayTasksCard(petId), // Truyền petId vào logic lọc
                const SizedBox(height: 24),
                _buildPhotoGalleryPreview(petId), // Truyền petId vào logic lọc
                const SizedBox(height: 24),
                _buildCommunitySection(),
                if (_communityTab == 0) ...[
                  const SizedBox(height: 20),
                  _buildNetworkCard(),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Gradient header ───────────────────────────────────────────────────────
  Widget _buildGradientHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_gradStart, _gradEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            children: [
              _buildTopBar(),
              const SizedBox(height: 20),
              _buildPetCard(),
              const SizedBox(height: 20),
              _buildActionButtons(),
              const SizedBox(height: 20),
              _buildQuickActions(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top bar: avatar + tên + chuông ────────────────────────────────────────
  Widget _buildTopBar() {
    final name     = widget.userData?['displayName'] ?? 'Bạn';
    final photoUrl = widget.userData?['photoURL'] ?? '';

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white70,
            backgroundImage: photoUrl.isNotEmpty
                ? CachedNetworkImageProvider(photoUrl) as ImageProvider
                : null,
            child: photoUrl.isEmpty
                ? const Icon(Icons.person, color: Color(0xFFFF9800))
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Xin chào,',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
              Text(name,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => widget.onTabSwitch(1),
          child: Stack(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications_outlined,
                    color: Colors.white, size: 24),
              ),
              StreamBuilder<List<ReminderModel>>(
                stream: _reminderService.getRemindersByDate(DateTime.now(), petId: null),
                builder: (_, snap) {
                  final pending = (snap.data ?? []).where((r) => !r.isCompleted).length;
                  if (pending == 0) return const SizedBox.shrink();
                  return Positioned(
                    right: 2, top: 2,
                    child: Container(
                      width: 17, height: 17,
                      decoration: BoxDecoration(
                        color: Colors.red.shade600,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Center(
                        child: Text('$pending',
                            style: const TextStyle(color: Colors.white,
                                fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.settings_outlined,
                color: Colors.white, size: 24),
          ),
        ),
      ],
    );
  }

  // ── Card thú cưng ─────────────────────────────────────────────────────────
  Widget _buildPetCard() {
    if (widget.pets.isEmpty) return _buildAddFirstPetCard();
    if (_activePet >= widget.pets.length) _activePet = 0;
    final pet = widget.pets[_activePet];

    return GestureDetector(
      onHorizontalDragEnd: (d) {
        if (d.primaryVelocity == null) return;
        setState(() {
          if (d.primaryVelocity! < 0 && _activePet < widget.pets.length - 1) {
            _activePet++;
          } else if (d.primaryVelocity! > 0 && _activePet > 0) {
            _activePet--;
          }
        });
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        child: _buildSinglePetCard(pet, key: ValueKey(pet['id'])),
      ),
    );
  }

  Widget _buildSinglePetCard(Map<String, dynamic> pet, {Key? key}) {
    final avatarUrl = pet['avatarUrl'] ?? '';
    final petId = (pet['id'] ?? '') as String;
    final shortId = petId.length > 13
        ? 'PET-${petId.substring(0, 8).toUpperCase()}'
        : 'ID: $petId';

    return Container(
      key: key,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.3),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: ClipOval(
              child: avatarUrl.isNotEmpty
                  ? CachedNetworkImage(
                imageUrl: avatarUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => const Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                ),
                errorWidget: (_, __, ___) =>
                const Icon(Icons.pets, color: Colors.white, size: 32),
              )
                  : const Icon(Icons.pets, color: Colors.white, size: 32),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(shortId,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
                const SizedBox(height: 4),
                Text(pet['name'] ?? 'Pet',
                    style: const TextStyle(color: Colors.white,
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(
                  '${pet['type'] ?? pet['kind'] ?? 'Thú cưng'} · ${pet['age'] ?? '?'} tuổi',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                ),
              ],
            ),
          ),
          if (widget.pets.length > 1)
            Column(
              children: List.generate(widget.pets.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  width: 6,
                  height: i == _activePet ? 18 : 6,
                  decoration: BoxDecoration(
                    color: i == _activePet
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }

  Widget _buildAddFirstPetCard() {
    return GestureDetector(
      onTap: _navigateAddPet,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, color: Colors.white, size: 28),
            SizedBox(width: 12),
            Text('Thêm thú cưng đầu tiên',
                style: TextStyle(color: Colors.white, fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // ── 3 nút hành động ───────────────────────────────────────────────────────
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _ActionBtn(
            label: 'Chi tiết',
            color: Colors.black.withValues(alpha: 0.5),
            onTap: () {
              if (widget.pets.isEmpty) { _navigateAddPet(); return; }
              final pet = widget.pets[_activePet];
              Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => SetupProfileScreen(petData: pet)),
              ).then((updated) { if (updated == true) widget.onPetsChanged(); });
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionBtn(
            label: 'Báo thất lạc',
            color: Colors.white.withValues(alpha: 0.25),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => const LostPetScreen(showBackButton: true))),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionBtn(
            label: 'Thêm mới',
            color: const Color(0xFF00C853).withValues(alpha: 0.85),
            onTap: _navigateAddPet,
          ),
        ),
      ],
    );
  }

  // ── 4 Quick Actions ───────────────────────────────────────────────────────
  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _QuickActionBtn(
          icon: Icons.search,
          label: 'Tìm thú\ncưng lạc',
          color: const Color(0xFFFF9800),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(
                  builder: (_) => const LostPetScreen(showBackButton: true))),
        ),
        _QuickActionBtn(
          icon: Icons.person_search_outlined,
          label: 'Tìm chủ\nlạc',
          color: const Color(0xFFE53935),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(
                  builder: (_) => const LostPetScreen(showBackButton: true))),
        ),
        _QuickActionBtn(
          icon: Icons.group_outlined,
          label: 'Tìm bạn\nbè',
          color: const Color(0xFFFF9800),
          onTap: () => widget.onTabSwitch(4),
        ),
        _QuickActionBtn(
          icon: Icons.location_on_outlined,
          label: 'Địa điểm',
          color: const Color(0xFF43A047),
          onTap: () {},
        ),
      ],
    );
  }

  // ── Thư viện ảnh (Ràng buộc theo petId) ───────────────────────────────────
  Widget _buildPhotoGalleryPreview(String petId) {
    if (petId.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Thư viện ảnh kỷ niệm',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937))),
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sẽ mở màn hình Gallery ảnh toàn màn hình')),
                );
              },
              child: const Text('Xem tất cả',
                  style: TextStyle(fontSize: 13, color: AppColors.primary,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: StreamBuilder<List<PetPhotoModel>>(
            // Sử dụng hàm chuyên biệt để lấy ảnh của đúng petId
            stream: _photoService.getPhotosByPet(petId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(strokeWidth: 2));
              }

              if (snapshot.hasError) {
                return Center(child: Text('Lỗi: ${snapshot.error}', style: const TextStyle(fontSize: 10)));
              }

              final petPhotos = snapshot.data ?? [];

              if (petPhotos.isEmpty) {
                return _buildEmptyGalleryState();
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: petPhotos.length + 1,
                itemBuilder: (context, i) {
                  if (i == 0) return _buildAddPhotoButton();

                  final photo = petPhotos[i - 1];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PhotoDetailScreen(photo: photo),
                        ),
                      );
                    },
                    child: Hero(
                      tag: photo.id,
                      child: Container(
                        width: 120,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 2))
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CachedNetworkImage(
                            imageUrl: photo.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[200],
                              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            ),
                            errorWidget: (context, url, error) => const Icon(Icons.error),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAddPhotoButton() {
    return GestureDetector(
      onTap: () {
        // TODO: Mở picker chọn ảnh từ Camera/Gallery
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), style: BorderStyle.solid),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, color: AppColors.primary, size: 28),
            SizedBox(height: 8),
            Text('Thêm ảnh', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyGalleryState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          _buildAddPhotoButton(),
          const Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Thú cưng chưa có ảnh kỷ niệm nào từ lịch chăm sóc. Hãy thêm hoạt động để lưu giữ khoảnh khắc!',
                style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
                textAlign: TextAlign.left,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Lịch hôm nay (Ràng buộc theo petId) ──────────────────────────────────
  Widget _buildTodayTasksCard(String petId) {
    if (petId.isEmpty) return const SizedBox.shrink();
    final today = DateTime.now();

    return StreamBuilder<List<ReminderModel>>(
      // Truyền petId vào service để lọc nhiệm vụ của riêng pet này
      stream: _reminderService.getRemindersByDate(today, petId: petId),
      builder: (context, snap) {
        final loading   = snap.connectionState == ConnectionState.waiting;
        final reminders = snap.data ?? [];
        final done      = reminders.where((r) => r.isCompleted).length;
        final total     = reminders.length;

        return GestureDetector(
          onTap: () => widget.onTabSwitch(2),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Lịch chăm sóc hôm nay',
                        style: TextStyle(fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937))),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(children: [
                        Text('Xem lịch',
                            style: TextStyle(color: AppColors.primary,
                                fontSize: 12, fontWeight: FontWeight.bold)),
                        SizedBox(width: 2),
                        Icon(Icons.chevron_right,
                            color: AppColors.primary, size: 16),
                      ]),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 12),
                  child: loading
                      ? const Text('Đang tải lịch...',
                      style: TextStyle(fontSize: 12, color: Colors.grey))
                      : Text(
                      total == 0
                          ? 'Không có nhiệm vụ nào hôm nay'
                          : '$done/$total nhiệm vụ hoàn thành',
                      style: TextStyle(fontSize: 12,
                          color: Colors.grey.shade500)),
                ),
                const Divider(height: 1),
                const SizedBox(height: 12),
                if (loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: CircularProgressIndicator(
                          color: AppColors.primary, strokeWidth: 2),
                    ),
                  )
                else if (reminders.isEmpty)
                  _emptyTaskState()
                else
                  ...reminders.take(3).map((r) => _realTaskRow(r)).toList(),
                if (!loading && total > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('+ ${total - 3} nhiệm vụ khác...',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.primary,
                            fontWeight: FontWeight.w500)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _realTaskRow(ReminderModel r) {
    String timeStr = '';
    try { timeStr = DateFormat('HH:mm').format(r.timestamp); } catch (_) {}
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            r.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: r.isCompleted ? const Color(0xFF6BBFA3) : Colors.grey.shade300,
            size: 20,
          ),
          const SizedBox(width: 10),
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_iconForType(r.type),
                color: AppColors.primary, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.title,
                    style: TextStyle(
                      fontSize: 13,
                      color: r.isCompleted ? Colors.grey.shade400 : const Color(0xFF374151),
                      decoration: r.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                if (timeStr.isNotEmpty)
                  Text(timeStr, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyTaskState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(Icons.event_available_outlined,
              color: Colors.grey.shade300, size: 28),
          const SizedBox(width: 10),
          Text('Nhấn + trong tab Lịch để thêm nhiệm vụ',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildCommunitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Cộng đồng quanh bạn',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937))),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(_communityTabs.length, (i) {
              final sel = i == _communityTab;
              return GestureDetector(
                onTap: () => setState(() => _communityTab = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                  decoration: BoxDecoration(
                    color: sel ? const Color(0xFFFF9800) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: Text(_communityTabs[i],
                      style: TextStyle(
                        color: sel ? Colors.white : const Color(0xFF6B7280),
                        fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      )),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 16),
        if (_communityTab == 1) _buildHowItWorksTab(),
        if (_communityTab == 2) _buildSafetyTab(),
      ],
    );
  }

  Widget _buildHowItWorksTab() {
    const purple = Color(0xFFFF9800);
    const rows = [
      ['Ai nhìn thấy bài viết', 'Người quen, người theo dõi', 'Người ở gần khu vực thú cưng bị lạc'],
      ['Hiển thị bài viết', 'Dễ trôi, phụ thuộc thuật toán', 'Ưu tiên theo vị trí, bán kính'],
      ['Kết nối trường hợp lạc', 'Chờ người chia sẻ bài viết', 'Người ở gần chủ động báo lại'],
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Text('Tin hiển thị ưu tiên theo vị trí và khoảng cách.',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
          ),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(1.4), 1: FlexColumnWidth(1.6), 2: FlexColumnWidth(1.6),
            },
            border: TableBorder(
              horizontalInside: BorderSide(color: Colors.grey.shade200),
              verticalInside:   BorderSide(color: Colors.grey.shade200),
            ),
            children: [
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade50),
                children: [
                  const SizedBox(height: 40),
                  Padding(padding: const EdgeInsets.all(10), child: Text('Mạng xã hội', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700))),
                  Container(padding: const EdgeInsets.all(10), decoration: const BoxDecoration(color: purple), child: const Text('Happy Paws', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white))),
                ],
              ),
              ...rows.map((r) => TableRow(
                children: [
                  Padding(padding: const EdgeInsets.all(10), child: Text(r[0], style: const TextStyle(fontSize: 12, color: Color(0xFF374151)))),
                  Padding(padding: const EdgeInsets.all(10), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('✗ ', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)), Expanded(child: Text(r[1], style: TextStyle(fontSize: 11, color: Colors.grey.shade600)))])),
                  Container(color: const Color(0xFFFFF3E0), padding: const EdgeInsets.all(10), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('✔ ', style: TextStyle(color: purple, fontSize: 12, fontWeight: FontWeight.bold)), Expanded(child: Text(r[2], style: const TextStyle(fontSize: 11, color: Color(0xFF374151))))])),
                ],
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyTab() {
    const items = [
      _SafetyItem(title: 'Người xung quanh khu vực thấy trước', desc: 'Tin hiển thị cho người ở gần tăng cơ hội tìm kiếm.', color: Color(0xFFE8F5F0)),
      _SafetyItem(title: 'Tin không bị trôi', desc: 'Hiển thị theo khu vực và khoảng cách.', color: Colors.white),
      _SafetyItem(title: 'Ẩn vị trí chính xác', desc: 'Bảo vệ an toàn cho thú cưng và chủ nuôi.', color: Color(0xFFFFF3E0)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Cộng đồng hoạt động hiệu quả khi có nhiều người tham gia.',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
        const SizedBox(height: 12),
        ...items.map((item) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: item.color, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
              const SizedBox(height: 6),
              Text(item.desc, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildNetworkCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Mạng lưới bảo vệ của bạn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1F2937))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(12)),
                  child: const Text('Cấp độ 3', style: TextStyle(color: Color(0xFFFF9800), fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Thành viên trong mạng lưới', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                RichText(text: TextSpan(children: [
                  const TextSpan(text: '61', style: TextStyle(color: Color(0xFFFF9800), fontWeight: FontWeight.bold, fontSize: 14)),
                  TextSpan(text: '/100', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ])),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: const LinearProgressIndicator(value: 0.61, minHeight: 8, backgroundColor: Color(0xFFEEEEEE), valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF9800))),
            ),
          ),
          GestureDetector(
            onTap: () => widget.onTabSwitch(4),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
              child: SizedBox(height: 175, width: double.infinity, child: CustomPaint(painter: _MockMapPainter())),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateAddPet() async {
    final result = await Navigator.push<bool>(context,
        MaterialPageRoute(builder: (_) => const SetupProfileScreen()));
    if (result == true) widget.onPetsChanged();
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  static const int _centerIndex = 2;

  static const _items = [
    _NavItem(icon: Icons.home_outlined,               activeIcon: Icons.home,                label: 'Trang chủ'),
    _NavItem(icon: Icons.notifications_outlined,      activeIcon: Icons.notifications,       label: 'Thông báo'),
    _NavItem(icon: Icons.calendar_today_outlined,     activeIcon: Icons.calendar_today,      label: 'Lịch'),
    _NavItem(icon: Icons.medical_information_outlined,activeIcon: Icons.medical_information, label: 'Sổ y bạ'),
    _NavItem(icon: Icons.volunteer_activism_outlined, activeIcon: Icons.volunteer_activism,  label: 'Cứu trợ'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 72,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, -2))],
                ),
              ),
            ),
            Positioned.fill(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: List.generate(_items.length, (i) {
                  if (i == _centerIndex) return const SizedBox(width: 72);
                  final item = _items[i];
                  final sel  = currentIndex == i;
                  return GestureDetector(
                    onTap: () => onTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: 64,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(sel ? item.activeIcon : item.icon,
                            color: sel ? AppColors.primary : const Color(0xFF9CA3AF), size: 24),
                          const SizedBox(height: 4),
                          Text(item.label,
                            style: TextStyle(fontSize: 10,
                              color: sel ? AppColors.primary : const Color(0xFF9CA3AF),
                              fontWeight: sel ? FontWeight.bold : FontWeight.normal),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
            Positioned(
              top: -22, left: 0, right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () => onTap(_centerIndex),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 68, height: 68,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(colors: [Color(0xFFFFB300), Color(0xFFFF6D00)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                              boxShadow: [BoxShadow(color: const Color(0xFFFF9800).withValues(alpha: 0.45), blurRadius: 14, offset: const Offset(0, 6))],
                            ),
                            child: Icon(currentIndex == _centerIndex ? Icons.calendar_today : Icons.calendar_today_outlined, color: Colors.white, size: 28),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Lịch',
                        style: TextStyle(fontSize: 10,
                          fontWeight: currentIndex == _centerIndex ? FontWeight.bold : FontWeight.normal,
                          color: currentIndex == _centerIndex ? AppColors.primary : const Color(0xFF9CA3AF))),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(22)),
        alignment: Alignment.center,
        child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
      ),
    );
  }
}

class _QuickActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickActionBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Container(
          width: 58, height: 58,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(18)),
          child: Icon(icon, color: Colors.white, size: 26),
        ),
        const SizedBox(height: 8),
        Text(label, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontSize: 11, fontWeight: FontWeight.w500), maxLines: 2),
      ]),
    );
  }
}

class _SafetyItem {
  final String title;
  final String desc;
  final Color color;
  const _SafetyItem({required this.title, required this.desc, required this.color});
}

class _MockMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = const Color(0xFFE8F5E9));
    final road = Paint()..color = const Color(0xFFB2DFDB).withValues(alpha: 0.7)..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 28) canvas.drawLine(Offset(0, y), Offset(size.width, y), road);
    for (double x = 0; x < size.width; x += 36) canvas.drawLine(Offset(x, 0), Offset(x, size.height), road);
    final block = Paint()..color = const Color(0xFFA5D6A7).withValues(alpha: 0.55);
    for (final r in [
      const Rect.fromLTWH(40, 35, 55, 35), const Rect.fromLTWH(190, 55, 70, 28),
      const Rect.fromLTWH(110, 95, 45, 45), const Rect.fromLTWH(260, 100, 55, 40),
      const Rect.fromLTWH(60, 110, 38, 28),
    ]) canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(4)), block);

    final tp = TextPainter(text: const TextSpan(text: 'ĐÔNG LƯ', style: TextStyle(color: Color(0xFF546E7A), fontSize: 11, fontWeight: FontWeight.bold)), textDirection: ui.TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(size.width - tp.width - 14, size.height - tp.height - 12));

    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, 48, Paint()..color = const Color(0xFFFF9800).withValues(alpha: 0.15));
    canvas.drawCircle(center, 48, Paint()..color = const Color(0xFFFF9800).withValues(alpha: 0.4)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    canvas.drawCircle(center, 9, Paint()..color = const Color(0xFFFF9800));
    canvas.drawCircle(center, 9, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
