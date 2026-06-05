// lib/features/lost_pet/screens/lost_pet_screen.dart
// Màn hình "Tìm thất lạc" – Flutter động, tích hợp Firestore
// Deps: cloud_firestore, firebase_auth, cached_network_image, intl, image_picker

import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

part '../lost_pet/models/lost_pet_post.dart';
part '../lost_pet/services/lost_pet_service.dart';
part '../lost_pet/widgets/lost_pet_cards.dart';
part '../lost_pet/screens/lost_pet_detail_screen.dart';
part '../lost_pet/widgets/lost_pet_shared_widgets.dart';
part '../lost_pet/sheets/lost_pet_filter_sheet.dart';
part '../lost_pet/sheets/lost_pet_create_post_sheet.dart';

class LostPetScreen extends StatefulWidget {
  final bool showBackButton;

  const LostPetScreen({super.key, this.showBackButton = true});

  @override
  State<LostPetScreen> createState() => _LostPetScreenState();
}

class _LostPetScreenState extends State<LostPetScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Tab index: 0 = tất cả, 1 = tin báo tìm thấy, 2 = tin báo đang lạc
  static const _tabs = [
    'Tất cả',
    'Tin báo tìm thấy',
    'Tin báo đang lạc',
    'Thú bị thương',
  ];

  String _searchQuery = '';
  bool _isGridView = true;

  // ── Active filter state ───────────────────────────────────
  String _filterKind = _allKindsFilter;
  RangeValues _filterWeight = const RangeValues(0, 50);
  bool _filterUrgentOnly = false;
  LostPetStatus? _filterPostType;

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

  // ── AppBar ────────────────────────────────────────────────
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

  // ── Tab bar ───────────────────────────────────────────────
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

  // ── Search bar ────────────────────────────────────────────
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
          // Toggle grid / list view
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

  // ── TabBarView ────────────────────────────────────────────
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
              if (p.isClosed) {
                return false;
              }
              // search query
              if (_searchQuery.isNotEmpty) {
                final q = _searchQuery;
                if (!p.name.toLowerCase().contains(q) &&
                    !p.breed.toLowerCase().contains(q) &&
                    !p.locationName.toLowerCase().contains(q)) {
                  return false;
                }
              }
              // kind filter
              if (_filterKind != _allKindsFilter) {
                if (_filterKind == _otherKindFilter) {
                  if (p.kind == _dogKind || p.kind == _catKind) {
                    return false;
                  }
                } else {
                  if (p.kind != _filterKind) {
                    return false;
                  }
                }
              }
              // weight filter
              if (p.weight < _filterWeight.start ||
                  p.weight > _filterWeight.end) {
                return false;
              }
              // urgent filter
              if (_filterUrgentOnly && !p.isUrgent) {
                return false;
              }
              // post type filter
              if (_filterPostType != null && p.status != _filterPostType) {
                return false;
              }
              return true;
            }).toList();

            if (posts.isEmpty) {
              return _buildEmptyState();
            }

            return _isGridView ? _buildGrid(posts) : _buildList(posts);
          },
        );
      }),
    );
  }

  // ── Grid ──────────────────────────────────────────────────
  Widget _buildGrid(List<LostPetPost> posts) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 96),
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

  // ── List ──────────────────────────────────────────────────
  Widget _buildList(List<LostPetPost> posts) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 96),
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

  // ── FAB ───────────────────────────────────────────────────
  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () => _showCreatePostSheet(),
      backgroundColor: _orange,
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text('Đăng bài', style: TextStyle(color: Colors.white)),
    );
  }

  // ── Filter bottom sheet ───────────────────────────────────
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

  // ── Create post bottom sheet ──────────────────────────────
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
// GRID CARD
// ─────────────────────────────────────────────────────────────────────────────
