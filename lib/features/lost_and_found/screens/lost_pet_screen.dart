import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

import '../models/lost_pet_model.dart';
import '../services/lost_pet_service.dart';
import 'package:pet_care/data/services/local_notification_service.dart';
import 'package:pet_care/services/location_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class LostPetScreen extends StatefulWidget {
  final bool showBackButton;

  const LostPetScreen({super.key, this.showBackButton = true});

  @override
  State<LostPetScreen> createState() => _LostPetScreenState();
}

class _LostPetScreenState extends State<LostPetScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    'Tất cả',
    'Tin báo tìm thấy',
    'Tin báo đang lạc',
    'Thú bị thương',
  ];

  String _searchQuery = '';
  bool _isGridView = true;

  String _filterKind = 'Tất cả';
  RangeValues _filterWeight = const RangeValues(0, 50);
  bool _filterUrgentOnly = false;
  String _filterPostType = 'Tất cả';

  static const _orange = Color(0xFFE07B2B);
  static const _orangeL = Color(0xFFFFF3E6);
  static const _grey = Color(0xFF9E9E9E);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  LostPetStatus? _filterForTab(int index) {
    if (index == 1) return LostPetStatus.found;
    if (index == 2) return LostPetStatus.lost;
    if (index == 3) return LostPetStatus.injured;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F4),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTabBar(),
          _buildSearchBar(),
          Expanded(child: _buildTabBarView()),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFFAF7F4),
      elevation: 0,
      leading: widget.showBackButton
          ? const BackButton(color: Colors.black87)
          : null,
      title: const Text(
        'Tìm thất lạc',
        style: TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.tune_rounded, color: Colors.black87),
          onPressed: () => _showFilterSheet(),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: const Color(0xFFFAF7F4),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: _orange,
        indicatorWeight: 3,
        labelColor: _orange,
        unselectedLabelColor: _grey,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 13,
        ),
        tabs: _tabs.map((t) => Tab(text: t)).toList(),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _orange, width: 1.5),
              ),
              child: TextField(
                onChanged: (v) =>
                    setState(() => _searchQuery = v.toLowerCase()),
                decoration: const InputDecoration(
                  hintText: 'Báo tìm kiếm',
                  hintStyle: TextStyle(color: _grey),
                  prefixIcon: Icon(Icons.search_rounded, color: _orange),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _isGridView = !_isGridView),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _orangeL,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _isGridView ? Icons.list_rounded : Icons.grid_view_rounded,
                color: _orange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: List.generate(4, (i) {
        return StreamBuilder<List<LostPetPost>>(
          stream: LostPetService.postsStream(filter: _filterForTab(i)),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(child: Text('Lỗi: ${snap.error}'));
            }
            final posts = (snap.data ?? []).where((p) {
              if (p.isClosed) return false;
              if (_searchQuery.isNotEmpty) {
                final q = _searchQuery;
                if (!p.name.toLowerCase().contains(q) &&
                    !p.breed.toLowerCase().contains(q) &&
                    !p.locationName.toLowerCase().contains(q)) {
                  return false;
                }
              }
              if (_filterKind != 'Tất cả') {
                if (_filterKind == 'Khác') {
                  if (p.kind == 'Chó' || p.kind == 'Mèo') return false;
                } else {
                  if (p.kind != _filterKind) return false;
                }
              }
              if (p.weight < _filterWeight.start ||
                  p.weight > _filterWeight.end) {
                return false;
              }
              if (_filterUrgentOnly && !p.isUrgent) {
                return false;
              }
              if (_filterPostType != 'Tất cả') {
                final match =
                    (_filterPostType == 'Đang lạc' &&
                        p.status == LostPetStatus.lost) ||
                    (_filterPostType == 'Tìm thấy' &&
                        p.status == LostPetStatus.found) ||
                    (_filterPostType == 'Bị thương' &&
                        p.status == LostPetStatus.injured);
                if (!match) return false;
              }
              return true;
            }).toList();

            if (posts.isEmpty) return _buildEmptyState();
            return _isGridView ? _buildGrid(posts) : _buildList(posts);
          },
        );
      }),
    );
  }

  Widget _buildGrid(List<LostPetPost> posts) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.52,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: posts.length,
      itemBuilder: (ctx, i) => _GridCard(post: posts[i]),
    );
  }

  Widget _buildList(List<LostPetPost> posts) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      itemCount: posts.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) => _ListCard(post: posts[i]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.pets_rounded, size: 72, color: Colors.orange.shade200),
          const SizedBox(height: 12),
          const Text(
            'Chưa có bài đăng nào',
            style: TextStyle(color: Colors.grey, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      heroTag: 'lost_pet_fab',
      onPressed: () => _showCreatePostSheet(),
      backgroundColor: _orange,
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text('Đăng bài', style: TextStyle(color: Colors.white)),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FilterSheet(
        initialKind: _filterKind,
        initialWeight: _filterWeight,
        initialUrgentOnly: _filterUrgentOnly,
        initialPostType: _filterPostType,
        onApply: (kind, weight, urgentOnly, postType) {
          setState(() {
            _filterKind = kind;
            _filterWeight = weight;
            _filterUrgentOnly = urgentOnly;
            _filterPostType = postType;
          });
        },
      ),
    );
  }

  void _showCreatePostSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _CreatePostSheet(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CARDS & WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _GridCard extends StatelessWidget {
  final LostPetPost post;
  const _GridCard({required this.post});

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    return '${diff.inDays} ngày trước';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => _LostPetDetailScreen(post: post)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1.05,
                    child: post.imageUrl.isNotEmpty
                        ? Image.network(
                            post.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _placeholderImage(),
                          )
                        : _placeholderImage(),
                  ),
                  if (post.isUrgent)
                    const Positioned(top: 6, left: 6, child: _UrgentBadge()),
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: _StatusChip(status: post.status),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(9, 7, 9, 7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tên: ${post.name}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Giống: ${post.breed}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      post.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black45,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Cân nặng: ${post.weight.toStringAsFixed(1)}kg',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd/MM/yyyy').format(post.createdAt),
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 11,
                          color: Color(0xFFE07B2B),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            post.locationName,
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFFE07B2B),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _relativeTime(post.createdAt),
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholderImage() => Container(
    color: const Color(0xFFF5E6D3),
    child: const Center(
      child: Icon(Icons.pets_rounded, size: 48, color: Color(0xFFE07B2B)),
    ),
  );
}

class _ListCard extends StatelessWidget {
  final LostPetPost post;
  const _ListCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => _LostPetDetailScreen(post: post)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(14),
              ),
              child: SizedBox(
                width: 110,
                height: 110,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    post.imageUrl.isNotEmpty
                        ? Image.network(
                            post.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _placeholder(),
                          )
                        : _placeholder(),
                    if (post.isUrgent)
                      const Positioned(top: 6, left: 6, child: _UrgentBadge()),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _StatusChip(status: post.status),
                        const Spacer(),
                        Text(
                          DateFormat('dd/MM/yyyy').format(post.createdAt),
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Tên: ${post.name}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'Giống: ${post.breed}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      post.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black45,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 12,
                          color: Color(0xFFE07B2B),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            post.locationName,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFFE07B2B),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Cân nặng: ${post.weight.toStringAsFixed(1)}kg',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: const Color(0xFFF5E6D3),
    child: const Center(
      child: Icon(Icons.pets_rounded, size: 36, color: Color(0xFFE07B2B)),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// DETAIL SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class _LostPetDetailScreen extends StatefulWidget {
  final LostPetPost post;
  const _LostPetDetailScreen({required this.post});
  @override
  State<_LostPetDetailScreen> createState() => _LostPetDetailScreenState();
}

class _LostPetDetailScreenState extends State<_LostPetDetailScreen> {
  static const _orange = Color(0xFFE07B2B);
  static const _green = Color(0xFF4CAF50);

  bool _isUpdating = false;
  late LostPetStatus _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.post.status;
  }

  bool get _isOwner =>
      FirebaseAuth.instance.currentUser?.uid == widget.post.userId;

  String get _viewerId => FirebaseAuth.instance.currentUser?.uid ?? '';

  String _normalizedPhone(String phone) =>
      phone.replaceAll(RegExp(r'[\s.-]'), '');

  Future<void> _launchPhone(String phone) async {
    final normalized = _normalizedPhone(phone);
    if (normalized.isEmpty) {
      _showSnack('Bài đăng chưa có số điện thoại liên hệ.');
      return;
    }
    final uri = Uri(scheme: 'tel', path: normalized);
    if (!await launchUrl(uri)) {
      _showSnack('Không mở được trình gọi điện trên thiết bị này.');
    }
  }

  Future<void> _sendSms(String phone, LostPetPost post) async {
    final normalized = _normalizedPhone(phone);
    if (normalized.isEmpty) {
      _showSnack('Bài đăng chưa có số điện thoại liên hệ.');
      return;
    }
    final uri = Uri(
      scheme: 'sms',
      path: normalized,
      queryParameters: {
        'body':
            'Chào bạn, mình thấy tin "${post.name}" trên PetCare. Mình muốn trao đổi thêm thông tin.',
      },
    );
    if (!await launchUrl(uri)) {
      _showSnack('Không mở được ứng dụng nhắn tin trên thiết bị này.');
    }
  }

  Future<void> _copyShareText(LostPetPost post) async {
    final text = [
      'PetCare - ${_statusLabel(post.status)}: ${post.name}',
      if (post.breed.isNotEmpty) 'Giống: ${post.breed}',
      if (post.locationName.isNotEmpty) 'Vị trí: ${post.locationName}',
      if (post.phone.isNotEmpty) 'Liên hệ: ${post.phone}',
      if (post.description.isNotEmpty) 'Mô tả: ${post.description}',
    ].join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    _showSnack('Đã sao chép nội dung bài đăng để chia sẻ.');
  }

  Future<void> _reportPost(LostPetPost post) async {
    final reporterId = _viewerId;
    if (reporterId.isEmpty) {
      _showSnack('Bạn cần đăng nhập để báo cáo bài đăng.');
      return;
    }

    final reason = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Báo cáo bài đăng',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _reportTile('Thông tin sai hoặc gây hiểu nhầm'),
              _reportTile('Không liên hệ được chủ bài'),
              _reportTile('Nội dung spam / không phù hợp'),
            ],
          ),
        ),
      ),
    );
    if (reason == null) return;

    setState(() => _isUpdating = true);
    try {
      await LostPetService.reportPost(
        post: post,
        reason: reason,
        reporterId: reporterId,
      );
      _showSnack('Đã gửi báo cáo. PetCare sẽ kiểm tra bài đăng này.');
    } catch (e) {
      _showSnack('Lỗi khi gửi báo cáo: $e');
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Widget _reportTile(String reason) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: const Icon(Icons.flag_outlined, color: _orange),
    title: Text(reason),
    onTap: () => Navigator.pop(context, reason),
  );

  Future<void> _toggleClosed(LostPetPost post) async {
    final willClose = !post.isClosed;
    final confirm = await _confirm(
      title: willClose ? 'Đóng bài đăng?' : 'Mở lại bài đăng?',
      content: willClose
          ? 'Bài đăng sẽ ẩn khỏi danh sách công khai nhưng bạn vẫn có thể mở lại.'
          : 'Bài đăng sẽ hiển thị lại trong danh sách tìm kiếm.',
      actionLabel: willClose ? 'Đóng bài' : 'Mở lại',
      actionColor: willClose ? Colors.black87 : _green,
    );
    if (!confirm) return;
    await _runOwnerAction(
      () => LostPetService.setClosed(post.id, willClose),
      willClose ? 'Đã đóng bài đăng.' : 'Đã mở lại bài đăng.',
    );
  }

  Future<void> _deletePost(LostPetPost post) async {
    final confirm = await _confirm(
      title: 'Xoá bài đăng?',
      content: 'Thao tác này không thể hoàn tác.',
      actionLabel: 'Xoá',
      actionColor: const Color(0xFFE53935),
    );
    if (!confirm) return;
    await _runOwnerAction(
      () => LostPetService.deletePost(post.id),
      'Đã xoá bài đăng.',
    );
    if (mounted) Navigator.pop(context);
  }

  Future<void> _runOwnerAction(
    Future<void> Function() action,
    String successMessage,
  ) async {
    setState(() => _isUpdating = true);
    try {
      await action();
      _showSnack(successMessage);
    } catch (e) {
      _showSnack('Lỗi: $e');
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<bool> _confirm({
    required String title,
    required String content,
    required String actionLabel,
    required Color actionColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: actionColor),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              actionLabel,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    return result == true;
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _statusLabel(LostPetStatus status) {
    switch (status) {
      case LostPetStatus.found:
        return 'Tìm thấy';
      case LostPetStatus.injured:
        return 'Bị thương';
      case LostPetStatus.lost:
        return 'Đang lạc';
    }
  }

  Future<void> _markAsFound() async {
    await _changeStatus(
      LostPetStatus.found,
      dialogTitle: 'Xác nhận tìm thấy',
      dialogContent:
          'Bạn xác nhận đã tìm thấy "${widget.post.name}"?\nBài đăng sẽ chuyển sang "Đã tìm thấy".',
      snackMsg: '🎉 Đã cập nhật: Tìm thấy thú cưng!',
      snackColor: const Color(0xFF4CAF50),
    );
  }

  Future<void> _markAsRescued() async {
    await _changeStatus(
      LostPetStatus.found,
      dialogTitle: 'Xác nhận đã cứu trợ',
      dialogContent:
          'Bạn xác nhận thú cưng bị thương "${widget.post.name}" đã được cứu trợ / chữa trị xong?',
      snackMsg: '💚 Đã cập nhật: Thú cưng đã được cứu trợ!',
      snackColor: const Color(0xFF4CAF50),
    );
  }

  Future<void> _changeStatus(
    LostPetStatus newStatus, {
    required String dialogTitle,
    required String dialogContent,
    required String snackMsg,
    required Color snackColor,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(dialogTitle),
        content: Text(dialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Xác nhận',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isUpdating = true);
    try {
      await LostPetService.updateStatus(widget.post.id, newStatus);
      setState(() => _currentStatus = newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(snackMsg), backgroundColor: snackColor),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F4),
      body: StreamBuilder<LostPetPost?>(
        stream: LostPetService.postStream(widget.post.id),
        builder: (context, snapshot) {
          final post = snapshot.data ?? widget.post;
          if (!_isUpdating) _currentStatus = post.status;
          final isResolved = _currentStatus == LostPetStatus.found;
          final isInjured = _currentStatus == LostPetStatus.injured;

          if (snapshot.connectionState != ConnectionState.waiting &&
              snapshot.data == null) {
            return const Center(child: Text('Bài đăng không còn tồn tại.'));
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: const Color(0xFFFAF7F4),
                leading: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: Colors.black87,
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      post.imageUrl.isNotEmpty
                          ? Image.network(
                              post.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _imagePlaceholder(),
                            )
                          : _imagePlaceholder(),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.45),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (post.isUrgent)
                        const Positioned(
                          top: 16,
                          right: 16,
                          child: _UrgentBadge(),
                        ),
                      Positioned(
                        bottom: 12,
                        left: 16,
                        child: _StatusChip(status: _currentStatus),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              post.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Text(
                              DateFormat('dd/MM/yyyy').format(post.createdAt),
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _infoGrid(post),
                      const SizedBox(height: 20),
                      _sectionTitle('Vị trí thất lạc'),
                      const SizedBox(height: 8),
                      _infoRow(
                        Icons.location_on_rounded,
                        post.locationName.isNotEmpty
                            ? post.locationName
                            : 'Chưa cung cấp',
                        color: _orange,
                      ),
                      const SizedBox(height: 20),
                      if (post.description.isNotEmpty) ...[
                        _sectionTitle('Mô tả đặc điểm'),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade100),
                          ),
                          child: Text(
                            post.description,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      _sectionTitle('Thông tin liên hệ'),
                      const SizedBox(height: 8),
                      _contactBox(post),
                      const SizedBox(height: 14),
                      if (!_isOwner) _buildViewerActions(post),
                      if (post.isClosed) ...[
                        const SizedBox(height: 16),
                        _closedBanner(),
                      ],
                      const SizedBox(height: 20),
                      if (_isOwner)
                        _buildOwnerPanel(post, isResolved, isInjured),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _contactBox(LostPetPost post) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.phone_rounded, color: _orange, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              post.phone.isNotEmpty ? post.phone : 'Chưa cung cấp',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: post.phone.isNotEmpty ? Colors.black87 : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewerActions(LostPetPost post) {
    final hasPhone = post.phone.trim().isNotEmpty;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _detailActionButton(
                icon: Icons.call_rounded,
                label: 'Gọi ngay',
                color: _green,
                enabled: hasPhone && !post.isClosed,
                onTap: () => _launchPhone(post.phone),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _detailActionButton(
                icon: Icons.sms_rounded,
                label: 'Nhắn tin',
                color: _orange,
                enabled: hasPhone && !post.isClosed,
                onTap: () => _sendSms(post.phone, post),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _secondaryActionButton(
                icon: Icons.ios_share_rounded,
                label: 'Sao chép tin',
                onTap: () => _copyShareText(post),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _secondaryActionButton(
                icon: Icons.flag_outlined,
                label: 'Báo cáo',
                onTap: _isUpdating ? null : () => _reportPost(post),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _closedBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Row(
        children: [
          Icon(Icons.lock_outline_rounded, color: Colors.black54),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Bài đăng đã đóng. Thông tin chỉ còn để đối chiếu.',
              style: TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerPanel(LostPetPost post, bool isResolved, bool isInjured) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quản lý bài đăng',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildOwnerButton(isResolved, isInjured),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _secondaryActionButton(
                  icon: Icons.edit_location_alt_rounded,
                  label: 'Sửa tin',
                  onTap: _isUpdating ? null : () => _showEditSheet(post),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _secondaryActionButton(
                  icon: post.isClosed
                      ? Icons.lock_open_rounded
                      : Icons.lock_outline_rounded,
                  label: post.isClosed ? 'Mở lại' : 'Đóng bài',
                  onTap: _isUpdating ? null : () => _toggleClosed(post),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _secondaryActionButton(
            icon: Icons.delete_outline_rounded,
            label: 'Xoá bài đăng',
            color: const Color(0xFFE53935),
            onTap: _isUpdating ? null : () => _deletePost(post),
          ),
        ],
      ),
    );
  }

  Widget _detailActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? color : Colors.grey.shade300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: enabled ? onTap : null,
        icon: Icon(icon, color: Colors.white, size: 19),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _secondaryActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    Color color = Colors.black87,
  }) {
    return SizedBox(
      height: 46,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.22)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: color.withValues(alpha: 0.04),
        ),
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
    );
  }

  void _showEditSheet(LostPetPost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditPostSheet(
        post: post,
        onSaved: () => _showSnack('Đã cập nhật bài đăng.'),
      ),
    );
  }

  Widget _buildOwnerButton(bool isResolved, bool isInjured) {
    if (isResolved) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _green),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded, color: _green, size: 22),
            SizedBox(width: 8),
            Text(
              'Đã xử lý xong 🎉',
              style: TextStyle(
                color: _green,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }
    if (isInjured) {
      return SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF9A825),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: _isUpdating ? null : _markAsRescued,
          icon: _isUpdating
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.healing_rounded, color: Colors.white),
          label: Text(
            _isUpdating ? 'Đang cập nhật...' : 'Đánh dấu đã cứu trợ xong',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: _green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: _isUpdating ? null : _markAsFound,
        icon: _isUpdating
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.pets_rounded, color: Colors.white),
        label: Text(
          _isUpdating ? 'Đang cập nhật...' : 'Đánh dấu đã tìm thấy',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: Colors.black87,
    ),
  );
  Widget _infoRow(IconData icon, String text, {Color color = Colors.black87}) =>
      Row(
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 14, color: color)),
          ),
        ],
      );
  Widget _infoGrid(LostPetPost post) {
    final items = [
      _InfoItem(icon: Icons.category_rounded, label: 'Loại', value: post.kind),
      _InfoItem(
        icon: Icons.pets_rounded,
        label: 'Giống',
        value: post.breed.isNotEmpty ? post.breed : '–',
      ),
      _InfoItem(
        icon: Icons.monitor_weight_rounded,
        label: 'Cân nặng',
        value: post.weight > 0 ? '${post.weight.toStringAsFixed(1)} kg' : '–',
      ),
      _InfoItem(
        icon: Icons.access_time_rounded,
        label: 'Đăng lúc',
        value: DateFormat('HH:mm – dd/MM/yyyy').format(post.createdAt),
      ),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.6,
      children: items
          .map(
            (item) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Row(
                children: [
                  Icon(item.icon, size: 18, color: _orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.label,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          item.value,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _imagePlaceholder() => Container(
    color: const Color(0xFFF5E6D3),
    child: const Center(
      child: Icon(Icons.pets_rounded, size: 72, color: Color(0xFFE07B2B)),
    ),
  );
}

class _EditPostSheet extends StatefulWidget {
  final LostPetPost post;
  final VoidCallback onSaved;

  const _EditPostSheet({required this.post, required this.onSaved});

  @override
  State<_EditPostSheet> createState() => _EditPostSheetState();
}

class _EditPostSheetState extends State<_EditPostSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _breedCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _weightCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _locCtrl;
  late final TextEditingController _otherKindCtrl;
  late String _kind;
  late LostPetStatus _status;
  late bool _isUrgent;
  bool _isSaving = false;

  final FocusNode _locFocusNode = FocusNode();
  bool _isLocAutoFilled = false;

  static const _orange = Color(0xFFE07B2B);

  @override
  void initState() {
    super.initState();
    final post = widget.post;
    _nameCtrl = TextEditingController(text: post.name);
    _breedCtrl = TextEditingController(text: post.breed);
    _descCtrl = TextEditingController(text: post.description);
    _weightCtrl = TextEditingController(
      text: post.weight > 0 ? post.weight.toStringAsFixed(1) : '',
    );
    _phoneCtrl = TextEditingController(text: post.phone);
    _locCtrl = TextEditingController(text: post.locationName);
    _kind = post.kind == 'Chó' || post.kind == 'Mèo' ? post.kind : 'Khác';
    _otherKindCtrl = TextEditingController(
      text: _kind == 'Khác' ? post.kind : '',
    );
    _status = post.status;
    _isUrgent = post.isUrgent;

    // FIX: Lắng nghe sự kiện focus (chỉ khai báo 1 lần initState)
    _locFocusNode.addListener(_handleLocFocusChange);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _breedCtrl.dispose();
    _descCtrl.dispose();
    _weightCtrl.dispose();
    _phoneCtrl.dispose();
    _locCtrl.dispose();
    _otherKindCtrl.dispose();
    // FIX: Giải phóng bộ nhớ
    _locFocusNode.removeListener(_handleLocFocusChange);
    _locFocusNode.dispose();
    super.dispose();
  }

  /// Tự động lấy vị trí khi focus vào trường nhập lần đầu
  Future<void> _handleLocFocusChange() async {
    if (_locFocusNode.hasFocus && !_isLocAutoFilled) {
      // Đánh dấu đã tự động điền để không lặp lại
      _isLocAutoFilled = true;

      try {
        final position = await LocationService().getCurrentPosition();
        // Điền tọa độ vào ô nhập liệu (Người dùng vẫn có thể xóa/sửa)
        if (mounted) {
          _locCtrl.text = '${position.latitude}, ${position.longitude}';
        }
      } catch (e) {
        // Bỏ qua nếu lỗi (ví dụ người dùng từ chối quyền)
        debugPrint('Lỗi tự động lấy vị trí: $e');
      }
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);
    try {
      final kindValue = _kind == 'Khác' ? _otherKindCtrl.text.trim() : _kind;
      await LostPetService.updatePost(
        widget.post.id,
        name: _nameCtrl.text.trim(),
        kind: kindValue,
        breed: _breedCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        weight: double.parse(_weightCtrl.text.trim().replaceAll(',', '.')),
        locationName: _locCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        status: _status,
        isUrgent: _isUrgent,
      );
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi cập nhật: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          18,
          18,
          MediaQuery.of(context).viewInsets.bottom + 18,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Sửa bài đăng',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _statusSelector(),
                const SizedBox(height: 14),
                _kindSelector(),
                const SizedBox(height: 12),
                _field(_nameCtrl, 'Tên thú cưng', required: true),
                _field(_breedCtrl, 'Giống', required: true),
                _field(_locCtrl, 'Vị trí', required: true),
                _field(_descCtrl, 'Mô tả', maxLines: 3),
                _field(
                  _weightCtrl,
                  'Cân nặng (kg)',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _validateWeight,
                ),
                _field(
                  _phoneCtrl,
                  'Số điện thoại',
                  keyboardType: TextInputType.phone,
                  validator: _validatePhone,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _isUrgent,
                  activeThumbColor: const Color(0xFFE53935),
                  title: const Text(
                    'Ưu tiên khẩn cấp',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  onChanged: (value) => setState(() => _isUrgent = value),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isSaving ? null : _save,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_rounded, color: Colors.white),
                    label: Text(
                      _isSaving ? 'Đang lưu...' : 'Lưu thay đổi',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _statusChip('Đang lạc', LostPetStatus.lost, _orange),
        _statusChip('Tìm thấy', LostPetStatus.found, const Color(0xFF4CAF50)),
        _statusChip(
          'Bị thương',
          LostPetStatus.injured,
          const Color(0xFFF9A825),
        ),
      ],
    );
  }

  Widget _statusChip(String label, LostPetStatus status, Color color) {
    final selected = _status == status;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: color.withValues(alpha: 0.16),
      side: BorderSide(color: selected ? color : Colors.grey.shade300),
      labelStyle: TextStyle(
        color: selected ? color : Colors.black54,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
      onSelected: (_) => setState(() => _status = status),
    );
  }

  Widget _kindSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _kind,
          decoration: _inputDecoration('Loài'),
          items: const [
            DropdownMenuItem(value: 'Chó', child: Text('Chó')),
            DropdownMenuItem(value: 'Mèo', child: Text('Mèo')),
            DropdownMenuItem(value: 'Khác', child: Text('Khác')),
          ],
          onChanged: (value) => setState(() => _kind = value ?? 'Chó'),
        ),
        if (_kind == 'Khác') ...[
          const SizedBox(height: 10),
          _field(_otherKindCtrl, 'Tên loài khác', required: true),
        ],
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: _inputDecoration(label),
        validator:
            validator ??
            (required
                ? (value) => (value == null || value.trim().isEmpty)
                      ? 'Vui lòng nhập $label'
                      : null
                : null),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF7F3EF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  String? _validateWeight(String? value) {
    final raw = value?.trim().replaceAll(',', '.') ?? '';
    if (raw.isEmpty) return 'Vui lòng nhập cân nặng';
    final weight = double.tryParse(raw);
    if (weight == null || weight <= 0 || weight > 100) {
      return 'Cân nặng phải là số từ 0 đến 100kg';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return 'Vui lòng nhập số điện thoại';
    final compact = raw.replaceAll(RegExp(r'[\s.-]'), '');
    if (!RegExp(r'^(0|\+84)\d{9,10}$').hasMatch(compact)) {
      return 'Số điện thoại không hợp lệ';
    }
    return null;
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _PostTypeOption {
  final LostPetStatus status;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String label;
  final String desc;
  const _PostTypeOption({
    required this.status,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.label,
    required this.desc,
  });
}

class _UrgentBadge extends StatelessWidget {
  const _UrgentBadge();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFE53935),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, size: 11, color: Colors.white),
          SizedBox(width: 2),
          Text(
            'Khẩn cấp',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final LostPetStatus status;
  const _StatusChip({required this.status});
  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    IconData icon;
    switch (status) {
      case LostPetStatus.found:
        color = const Color(0xFF4CAF50);
        label = 'Tìm thấy';
        icon = Icons.check_circle_outline_rounded;
        break;
      case LostPetStatus.injured:
        color = const Color(0xFFF9A825);
        label = 'Bị thương';
        icon = Icons.healing_rounded;
        break;
      case LostPetStatus.lost:
        color = const Color(0xFFE07B2B);
        label = 'Đang lạc';
        icon = Icons.location_searching_rounded;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: Colors.white),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final String initialKind;
  final RangeValues initialWeight;
  final bool initialUrgentOnly;
  final String initialPostType;
  final void Function(
    String kind,
    RangeValues weight,
    bool urgentOnly,
    String postType,
  )
  onApply;
  const _FilterSheet({
    required this.initialKind,
    required this.initialWeight,
    required this.initialUrgentOnly,
    required this.initialPostType,
    required this.onApply,
  });
  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String _kind;
  late RangeValues _weight;
  late bool _urgentOnly;
  late String _postType;
  static const _orange = Color(0xFFE07B2B);

  @override
  void initState() {
    super.initState();
    _kind = widget.initialKind;
    _weight = widget.initialWeight;
    _urgentOnly = widget.initialUrgentOnly;
    _postType = widget.initialPostType;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bộ lọc',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text('Loại tin', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _postTypeChip('Tất cả', null),
              _postTypeChip('Đang lạc', const Color(0xFFE07B2B)),
              _postTypeChip('Tìm thấy', const Color(0xFF4CAF50)),
              _postTypeChip('Bị thương', const Color(0xFFF9A825)),
            ],
          ),
          const SizedBox(height: 14),
          const Text('Loài', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['Tất cả', 'Chó', 'Mèo', 'Khác'].map((k) {
              final selected = _kind == k;
              return ChoiceChip(
                label: Text(k),
                selected: selected,
                selectedColor: const Color(0xFFFFE0C0),
                onSelected: (_) => setState(() => _kind = k),
                labelStyle: TextStyle(
                  color: selected ? _orange : Colors.black54,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Text(
            'Cân nặng: ${_weight.start.toInt()}kg – ${_weight.end.toInt()}kg',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          RangeSlider(
            values: _weight,
            min: 0,
            max: 50,
            divisions: 10,
            activeColor: _orange,
            onChanged: (v) => setState(() => _weight = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Chỉ hiện khẩn cấp',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            value: _urgentOnly,
            activeThumbColor: _orange,
            onChanged: (v) => setState(() => _urgentOnly = v),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                widget.onApply(_kind, _weight, _urgentOnly, _postType);
                Navigator.pop(context);
              },
              child: const Text(
                'Áp dụng',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _postTypeChip(String label, Color? color) {
    final selected = _postType == label;
    final chipColor = color ?? _orange;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: color != null
          ? color.withValues(alpha: 0.18)
          : const Color(0xFFFFE0C0),
      onSelected: (_) => setState(() => _postType = label),
      labelStyle: TextStyle(
        color: selected ? (color ?? _orange) : Colors.black54,
        fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
      ),
      side: selected
          ? BorderSide(color: chipColor, width: 1.5)
          : BorderSide(color: Colors.grey.shade300),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CREATE POST SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _CreatePostSheet extends StatefulWidget {
  const _CreatePostSheet();
  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _breedCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _locCtrl = TextEditingController();
  final _otherKindCtrl = TextEditingController();

  // THÊM: FocusNode cho trường nhập Vị trí
  final FocusNode _locFocusNode = FocusNode();
  bool _isLocAutoFilled = false; // Đánh dấu đã tự động điền hay chưa

  String _kind = 'Chó';
  LostPetStatus _postStatus = LostPetStatus.lost;
  bool _isUrgent = false;
  bool _isSaving = false;
  XFile? _pickedImage;

  static const _orange = Color(0xFFE07B2B);

  @override
  void initState() {
    super.initState();
    // THÊM: Lắng nghe sự kiện focus để tự động điền vị trí
    _locFocusNode.addListener(_handleLocFocusChange);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _breedCtrl.dispose();
    _descCtrl.dispose();
    _weightCtrl.dispose();
    _phoneCtrl.dispose();
    _locCtrl.dispose();
    _otherKindCtrl.dispose();
    _locFocusNode.removeListener(_handleLocFocusChange);
    _locFocusNode.dispose();
    super.dispose();
  }

  /// Tự động lấy vị trí khi focus vào trường nhập lần đầu
  Future<void> _handleLocFocusChange() async {
    if (_locFocusNode.hasFocus && !_isLocAutoFilled) {
      // Đánh dấu đã tự động điền để không lặp lại
      _isLocAutoFilled = true;

      try {
        final position = await LocationService().getCurrentPosition();
        // Điền tọa độ vào ô nhập liệu (Người dùng vẫn có thể xóa/sửa)
        if (mounted) {
          _locCtrl.text = '${position.latitude}, ${position.longitude}';
        }
      } catch (e) {
        // Bỏ qua nếu lỗi (ví dụ người dùng từ chối quyền)
        debugPrint('Lỗi tự động lấy vị trí: $e');
      }
    }
  }

  Future<String> _uploadToCloudinary(File file) async {
    final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
    final uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';

    if (cloudName.isEmpty || uploadPreset.isEmpty) {
      throw Exception('Chưa cấu hình Cloudinary trong file .env');
    }

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();
    final responseData = await response.stream.toBytes();
    final responseString = String.fromCharCodes(responseData);
    final jsonMap = jsonDecode(responseString);

    if (response.statusCode == 200) {
      return jsonMap['secure_url'] ?? '';
    } else {
      throw Exception('Lỗi upload Cloudinary: ${jsonMap['error']['message']}');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ảnh thú cưng')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      String imageUrl = '';
      if (_pickedImage != null) {
        imageUrl = await _uploadToCloudinary(File(_pickedImage!.path));
      }

      final kindValue = _kind == 'Khác'
          ? (_otherKindCtrl.text.trim().isNotEmpty
                ? _otherKindCtrl.text.trim()
                : 'Khác')
          : _kind;

      final post = LostPetPost(
        id: '',
        userId: uid,
        name: _nameCtrl.text.trim(),
        kind: kindValue,
        breed: _breedCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        weight: double.tryParse(_weightCtrl.text) ?? 0,
        imageUrl: imageUrl,
        status: _postStatus,
        isUrgent: _isUrgent,
        isClosed: false,
        location: const GeoPoint(10.776889, 106.700806),
        locationName: _locCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        createdAt: DateTime.now(),
      );

      await LostPetService.createPost(post);

      // Show notification
      final statusText = _postStatus == LostPetStatus.lost
          ? 'đang lạc'
          : _postStatus == LostPetStatus.found
          ? 'tìm thấy'
          : 'bị thương';

      LocalNotificationService().showNotification(
        id: DateTime.now().microsecond,
        title: 'Bài đăng đã được chia sẻ',
        body:
            'Thú cưng $statusText của bạn đã được đăng và chia sẻ với cộng đồng',
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: source, imageQuality: 80);
    if (img != null) setState(() => _pickedImage = img);
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFFE07B2B)),
              title: const Text('Chụp ảnh'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: Color(0xFFE07B2B),
              ),
              title: const Text('Chọn từ thư viện'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5EFE6),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios),
                      ),
                      const Expanded(
                        child: Text(
                          'Đăng tin mới',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    'Loại tin cứu trợ',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  _dropdownBox(),
                  const SizedBox(height: 18),
                  const Text(
                    'Loại thú cưng',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  _petTypeBox(),
                  const SizedBox(height: 18),
                  const Text(
                    'Tên thú cưng',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  _field(
                    _nameCtrl,
                    'VD: Mochi, Cục Bông, Lucky...',
                    required: true,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Giống',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  _field(
                    _breedCtrl,
                    'VD: Corgi, Poodle, Mèo Anh lông ngắn...',
                    required: true,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Vị trí',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  _field(
                    _locCtrl,
                    'VD: 55 Giải Phóng, Hà Nội',
                    focusNode: _locFocusNode, // Gán FocusNode
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Ảnh thú cưng',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _showImageSourceDialog,
                    child: Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _pickedImage != null
                              ? _orange
                              : Colors.grey.shade400,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFFF7F3EF),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: _pickedImage != null
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(
                                  File(_pickedImage!.path),
                                  fit: BoxFit.cover,
                                ),
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() => _pickedImage = null),
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 26,
                                  backgroundColor: Colors.orange.shade100,
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.orange,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Chụp/Tải ảnh thú cưng',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Mô tả',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  _field(
                    _descCtrl,
                    'Mô tả đặc điểm nhận dạng thú cưng...',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Cân nặng (kg)',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  _field(
                    _weightCtrl,
                    'VD: 4.5',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Số điện thoại liên hệ',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  _field(
                    _phoneCtrl,
                    '09xx xxx xxx',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 18),
                  GestureDetector(
                    onTap: () => setState(() => _isUrgent = !_isUrgent),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: _isUrgent
                            ? const Color(0xFFFFEBEB)
                            : const Color(0xFFF7F3EF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isUrgent
                              ? const Color(0xFFE53935)
                              : Colors.grey.shade300,
                          width: _isUrgent ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _isUrgent
                                  ? const Color(0xFFE53935)
                                  : Colors.grey.shade200,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.warning_amber_rounded,
                              color: _isUrgent ? Colors.white : Colors.grey,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Đánh dấu khẩn cấp',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: _isUrgent
                                        ? const Color(0xFFE53935)
                                        : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Bài đăng sẽ được ưu tiên hiển thị lên đầu',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: _isUrgent
                                        ? const Color(
                                            0xFFE53935,
                                          ).withValues(alpha: 0.8)
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isUrgent,
                            activeThumbColor: const Color(0xFFE53935),
                            onChanged: (v) => setState(() => _isUrgent = v),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _isSaving ? null : _submit,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send, color: Colors.white),
                      label: Text(
                        _isSaving ? 'Đang đăng...' : 'Đăng bài',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _dropdownBox() {
    final options = [
      const _PostTypeOption(
        status: LostPetStatus.lost,
        icon: Icons.location_searching_rounded,
        color: Color(0xFFE07B2B),
        bgColor: Color(0xFFFFF3E6),
        label: 'Thú cưng đang lạc',
        desc: 'Thú cưng của bạn bị mất tích',
      ),
      const _PostTypeOption(
        status: LostPetStatus.found,
        icon: Icons.search_rounded,
        color: Color(0xFF4CAF50),
        bgColor: Color(0xFFE8F5E9),
        label: 'Tìm thấy thú lạc',
        desc: 'Bạn nhặt/thấy thú cưng thất lạc',
      ),
      const _PostTypeOption(
        status: LostPetStatus.injured,
        icon: Icons.healing_rounded,
        color: Color(0xFFF9A825),
        bgColor: Color(0xFFFFF8E1),
        label: 'Thú cưng bị thương',
        desc: 'Thú cưng cần được cứu trợ, chữa trị',
      ),
    ];
    return Column(
      children: options.map((opt) {
        final selected = _postStatus == opt.status;
        return GestureDetector(
          onTap: () => setState(() => _postStatus = opt.status),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: selected ? opt.bgColor : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? opt.color : Colors.grey.shade300,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: selected ? opt.color : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    opt.icon,
                    color: selected ? Colors.white : Colors.grey,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        opt.label,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: selected ? opt.color : Colors.black87,
                        ),
                      ),
                      Text(
                        opt.desc,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: selected
                              ? opt.color.withValues(alpha: 0.75)
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Icon(Icons.check_circle_rounded, color: opt.color, size: 20),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _petTypeBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _kind,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'Chó', child: Text('Chó')),
                DropdownMenuItem(value: 'Mèo', child: Text('Mèo')),
                DropdownMenuItem(value: 'Khác', child: Text('Khác')),
              ],
              onChanged: (v) => setState(() => _kind = v!),
            ),
          ),
        ),
        if (_kind == 'Khác') ...[
          const SizedBox(height: 10),
          _field(_otherKindCtrl, 'VD: Thỏ, Hamster, Chim...', required: true),
        ],
      ],
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String hint, {
    bool required = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    FocusNode? focusNode, // Thêm tham số focusNode
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        focusNode: focusNode, // Gán focusNode cho TextFormField
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black38),
          filled: true,
          fillColor: const Color(0xFFF7F3EF),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty)
                  ? 'Vui lòng nhập trường này'
                  : null
            : null,
      ),
    );
  }
}
