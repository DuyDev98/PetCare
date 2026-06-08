import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pet_care/services/photo_service.dart';

/// Màn hình xem ảnh toàn màn hình nâng cao:
/// - Sử dụng [PhotoViewGallery] để xử lý vuốt/zoom mượt mà.
/// - Hiển thị thông tin thời gian realtime của từng bức ảnh.
/// - Header có hiệu ứng Gradient mờ ảo giúp tăng khả năng đọc.
class FullScreenGalleryScreen extends StatefulWidget {
  final List<Map<String, dynamic>> photos; // Dữ liệu gồm {'url': String, 'date': DateTime}
  final int initialIndex;

  const FullScreenGalleryScreen({
    super.key,
    required this.photos,
    required this.initialIndex,
  });

  @override
  State<FullScreenGalleryScreen> createState() => _FullScreenGalleryScreenState();
}

class _FullScreenGalleryScreenState extends State<FullScreenGalleryScreen> {
  late PageController _pageController;
  late int _currentIndex;
  final PhotoService _photoService = PhotoService(); // Thêm service để gọi lệnh xóa

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Format ngày tháng theo chuẩn Việt Nam
  String _formatDate(DateTime date) => DateFormat('dd/MM/yyyy').format(date);
  String _formatTime(DateTime date) => DateFormat('HH:mm').format(date);

  /// Hộp thoại xác nhận xóa ảnh và thực hiện xóa trên Firestore
  Future<void> _handleDelete() async {
    final String docId = widget.photos[_currentIndex]['id'] ?? '';
    if (docId.isEmpty) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa ảnh?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'Bạn có chắc chắn muốn xóa bức ảnh kỷ niệm này không?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa', style: TextStyle(color: Color(0xFFFF5252), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;

      // Bước 1: Hiển thị loading overlay
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator(color: Colors.orange)),
      );

      try {
        // Bước 2: Gọi lệnh xóa trên Firestore (Hàm deletePhoto đã bao gồm xóa cả Cloudinary)
        // LỖI 2: Thực hiện lệnh xóa trực tiếp thông qua Service
        await _photoService.deletePhoto(docId);

        if (mounted) {
          Navigator.pop(context); // Đóng loading dialog
          Navigator.pop(context); // Quay lại màn hình chính
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã xóa ảnh kỷ niệm thành công'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Đóng loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi khi xóa ảnh: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── LỚP 1: GALLERY HIỂN THỊ ẢNH ─────────────────────────────────────
          PhotoViewGallery.builder(
            scrollPhysics: const BouncingScrollPhysics(),
            builder: (BuildContext context, int index) {
              final photo = widget.photos[index];
              return PhotoViewGalleryPageOptions(
                imageProvider: CachedNetworkImageProvider(photo['url']),
                initialScale: PhotoViewComputedScale.contained,
                minScale: PhotoViewComputedScale.contained * 1.0,
                maxScale: PhotoViewComputedScale.covered * 4.0,
                heroAttributes: PhotoViewHeroAttributes(
                  tag: 'gallery_photo_${photo['url']}', // Tag phải khớp với HomeScreen
                ),
              );
            },
            itemCount: widget.photos.length,
            loadingBuilder: (context, event) => const Center(
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            ),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            pageController: _pageController,
            onPageChanged: (index) => setState(() => _currentIndex = index),
          ),

          // ── LỚP 2: HEADER OVERLAY (GRADIENT + INFO + BUTTONS) ───────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.75),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      // Nút Đóng (Góc trái)
                      _buildIconButton(
                        icon: Icons.close_rounded,
                        onTap: () => Navigator.pop(context),
                      ),

                      // Thông tin thời gian (Chính giữa)
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatDate(widget.photos[_currentIndex]['date']),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              _formatTime(widget.photos[_currentIndex]['date']),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Nút Xóa (Góc phải)
                      _buildIconButton(
                        icon: Icons.delete_outline_rounded,
                        color: const Color(0xFFFF5252),
                        onTap: _handleDelete,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── LỚP 3: PAGE INDICATOR (BOTTOM) ──────────────────────────────────
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentIndex + 1} / ${widget.photos.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Nút bấm tròn phong cách kính mờ
  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}
