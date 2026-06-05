import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pet_care/data/models/pet_photo_model.dart';
import 'package:pet_care/data/services/pet_photo_service.dart';
import 'package:pet_care/data/services/cloudinary_service.dart';

class PhotoDetailScreen extends StatelessWidget {
  final PetPhotoModel photo;
  final PetPhotoService _photoService = PetPhotoService();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  PhotoDetailScreen({super.key, required this.photo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 28),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: Center(
        child: Hero(
          tag: photo.id,
          child: CachedNetworkImage(
            imageUrl: photo.imageUrl,
            placeholder: (context, url) => const CircularProgressIndicator(color: Colors.white),
            errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa ảnh này khỏi nhật ký?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx); // Đóng dialog
              _handleDelete(context);
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDelete(BuildContext context) async {
    try {
      // Hiển thị loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      // Bước 1: Xóa ảnh trên Cloudinary
      await _cloudinaryService.deleteImage(photo.imageUrl);

      // Bước 2: Xóa document trên Firestore
      await _photoService.deletePetPhoto(photo.id);

      // Đóng loading
      if (context.mounted) Navigator.pop(context);

      // Quay lại màn hình trước và thông báo
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa ảnh thành công')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Đóng loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi xóa ảnh: $e')),
        );
      }
    }
  }
}
