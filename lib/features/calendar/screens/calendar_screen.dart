import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pet_care/data/models/pet_model.dart';
import 'package:pet_care/data/models/pet_photo_model.dart';
import 'package:pet_care/data/services/notification_service.dart';
import 'package:pet_care/data/services/local_notification_service.dart';
import 'package:pet_care/features/calendar/models/reminder_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pet_care/core/constants/app_colors.dart';
import 'package:pet_care/data/services/pet_photo_service.dart';
import 'package:pet_care/data/services/pet_service.dart';
import 'package:pet_care/data/services/firebase_service.dart';
import 'package:pet_care/features/calendar/services/reminder_service.dart';
import 'package:pet_care/features/home/screens/notification_screen.dart';
import 'package:pet_care/features/photo_history/screens/photo_history_screen.dart';
import 'package:pet_care/features/photo_history/screens/photo_detail_screen.dart';
import '../widgets/pet_avatar_selector.dart';
import '../widgets/calendar_widget.dart';
import '../widgets/task_card.dart';
import '../widgets/add_task_bottom_sheet.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _petService      = FirebaseService();
  final _reminderService = ReminderService();
  final _petPhotoService = PetPhotoService();
  final _uploadService   = PetService();
  final _notificationService = NotificationService();
  final _picker          = ImagePicker();

  DateTime _selectedDate  = DateTime.now();
  String?  _selectedPetId;
  String   _selectedPetName = '';
  bool     _isSavingPhoto = false;

  // Colors - Using unified AppColors
  static const Color _primary       = AppColors.primary;
  static const Color _bg            = Color(0xFFF8F9FA);
  static const Color _textPrimary   = AppColors.textBlack;
  static const Color _textSecondary = AppColors.textGrey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: StreamBuilder<List<ReminderModel>>(
                stream: _reminderService.getRemindersByDate(_selectedDate, petId: _selectedPetId),
                builder: (context, snapshot) {
                  final reminders = snapshot.data ?? [];
                  
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        _buildPetSelector(),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: CalendarWidget(
                            selectedDate: _selectedDate,
                            onDateSelected: (date) =>
                                setState(() => _selectedDate = date),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildPetPhotosSection(),
                        _buildTaskSection(reminders, snapshot.connectionState),
                        const SizedBox(height: 100),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Lịch chăm sóc & Nhắc nhở',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textPrimary),
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationScreen()),
              );
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: _primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.notifications_none_rounded, color: _primary, size: 22),
                ),
                StreamBuilder<int>(
                  stream: _notificationService.getUnreadCountStream(),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    if (count == 0) return const SizedBox.shrink();

                    return Positioned(
                      top: -2, right: -2,
                      child: Container(
                        width: 18, height: 18,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            '$count',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Pet Selector ──────────────────────────────────────────────────────────

  Widget _buildPetSelector() {
    return StreamBuilder<List<PetModel>>(
      stream: _petService.petsStream(),
      builder: (context, snapshot) {
        final pets = snapshot.data ?? [];
        return PetAvatarSelector(
          pets: pets,
          selectedPetId: _selectedPetId,
          onSelected: (id) => setState(() {
            _selectedPetId = id;
            final selected = pets.where((pet) => pet.id == id);
            _selectedPetName = selected.isEmpty ? '' : selected.first.name;
          }),
        );
      },
    );
  }

  // ─── Pet Photos Section ────────────────────────────────────────────────────

  Widget _buildPetPhotosSection() {
    return StreamBuilder<List<PetPhotoModel>>(
      stream: _petPhotoService.getPhotosByDate(_selectedDate, petId: _selectedPetId),
      builder: (context, snapshot) {
        final photos = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.photo_camera_rounded, color: _primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => PhotoHistoryScreen()),
                        );
                      },
                      child: const Text(
                        'Ảnh kỷ niệm',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _textPrimary),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Lưu ảnh kỷ niệm',
                    onPressed: _isSavingPhoto ? null : _showPetPhotoSourceDialog,
                    icon: _isSavingPhoto
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_a_photo_rounded, color: _primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (photos.isNotEmpty)
              SizedBox(
                height: 140,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: photos.length,
                  itemBuilder: (context, index) => _buildPetPhotoItem(photos[index]),
                ),
              ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _buildPetPhotoItem(PetPhotoModel photo) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PhotoDetailScreen(photo: photo)),
        );
      },
      child: Hero(
        tag: photo.id,
        child: Container(
          margin: const EdgeInsets.only(right: 12),
          width: 110,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CachedNetworkImage(
              imageUrl: photo.imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) =>
                  const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              errorWidget: (context, url, error) =>
                  const Icon(Icons.broken_image, color: Colors.grey),
              imageBuilder: (context, imageProvider) => Stack(
                fit: StackFit.expand,
                children: [
                  Image(image: imageProvider, fit: BoxFit.cover),
                  // Nút xóa ở góc phải ảnh
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _confirmDeletePhoto(photo),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                  if (photo.title.isNotEmpty)
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        color: Colors.black.withValues(alpha: 0.45),
                        child: Text(
                          photo.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
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

  Future<void> _confirmDeletePhoto(PetPhotoModel photo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa ảnh kỷ niệm?'),
        content: const Text('Bạn có chắc chắn muốn xóa ảnh này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Gọi service xóa
      await PetPhotoService().deletePetPhoto(photo.id);
      // Có thể thêm xóa trên Cloudinary nếu cần
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa ảnh kỷ niệm')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể xóa ảnh: $e')),
      );
    }
  }

  void _showPetPhotoSourceDialog() {
    if (_selectedPetId == null || _selectedPetId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn thú cưng trước khi lưu ảnh')),
      );
      return;
    }

    final titleController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ảnh kỷ niệm',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _textPrimary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleController,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: 'Tiêu đề kỷ niệm',
                filled: true,
                fillColor: const Color(0xFFF5F8FF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: _primary),
              title: const Text('Chụp ảnh'),
              onTap: () {
                Navigator.pop(context);
                _savePetPhoto(ImageSource.camera, titleController.text.trim());
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: _primary),
              title: const Text('Chọn ảnh từ thư viện'),
              onTap: () {
                Navigator.pop(context);
                _savePetPhoto(ImageSource.gallery, titleController.text.trim());
              },
            ),
          ],
          ),
        ),
      ),
    );
  }

  Future<void> _savePetPhoto(ImageSource source, String title) async {
    final petId = _selectedPetId;
    if (petId == null || petId.isEmpty) return;

    try {
      final pickedFile = await _picker.pickImage(source: source, imageQuality: 75);
      if (pickedFile == null) return;

      setState(() => _isSavingPhoto = true);
      final imageUrl = await _uploadService.uploadToCloudinary(File(pickedFile.path));
      if (!mounted) return;

      if (imageUrl == null || imageUrl.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể tải ảnh lên')),
        );
        return;
      }

      await _petPhotoService.addPetPhoto(
        petId: petId,
        petName: _selectedPetName,
        title: title,
        imageUrl: imageUrl,
        timestamp: DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          DateTime.now().hour,
          DateTime.now().minute,
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu ảnh kỷ niệm')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể lưu ảnh: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSavingPhoto = false);
    }
  }

  // ─── Task Section ──────────────────────────────────────────────────────────

  Widget _buildTaskSection(List<ReminderModel> reminders, ConnectionState connectionState) {
    if (connectionState == ConnectionState.waiting) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: _primary),
        ),
      );
    }

    final completed = reminders.where((r) => r.isCompleted).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Nhiệm vụ trong ngày',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _textPrimary),
              ),
              if (reminders.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$completed/${reminders.length} hoàn thành',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _primary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (reminders.isEmpty)
            _buildEmptyState()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reminders.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final reminder = reminders[i];
                return TaskCard(
                  task: reminder,
                  onToggle: (value) => _reminderService.toggleReminder(reminder.id, value),
                  onDelete: () => _confirmDeleteReminder(reminder),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(Icons.event_available_rounded, size: 40, color: _primary),
            ),
            const SizedBox(height: 16),
            const Text(
              'Không có nhiệm vụ nào',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Nhấn + để thêm nhiệm vụ mới',
              style: TextStyle(fontSize: 13, color: _textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  // ─── FAB ───────────────────────────────────────────────────────────────────

  Widget _buildFAB() {
    return FloatingActionButton(
      heroTag: 'calendar_fab',
      onPressed: _showAddTaskSheet,
      backgroundColor: _primary,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
    );
  }

  void _showAddTaskSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTaskBottomSheet(
        selectedDate: _selectedDate,
        onSave: (data) async {
          if (data.repeatType == RepeatType.none) {
            await _reminderService.createReminder(
              title:    data.title,
              dateTime: data.dateTime,
              petId:    data.petId,
              petName:  data.petName,
              petBreed: data.petBreed,
              type:     ReminderType.other,
              imageUrl: data.imageUrl,
            );

            // Schedule notification
            LocalNotificationService().scheduleNotification(
              id: data.dateTime.millisecondsSinceEpoch ~/ 1000,
              title: data.title,
              body: '${data.petName} - ${data.petBreed}',
              scheduledDate: data.dateTime,
            );
          } else {
            await _reminderService.createRepeatingReminder(
              title:         data.title,
              startDateTime: data.dateTime,
              petId:         data.petId,
              petName:       data.petName,
              petBreed:      data.petBreed,
              repeatType:    data.repeatType,
              repeatUntil:   data.repeatUntil!,
              repeatDays:    data.repeatDays,
              type:          ReminderType.other,
              imageUrl:      data.imageUrl,
            );

            // Schedule first notification
            LocalNotificationService().scheduleNotification(
              id: data.dateTime.millisecondsSinceEpoch ~/ 1000,
              title: data.title,
              body: '${data.petName} - ${data.petBreed}',
              scheduledDate: data.dateTime,
            );
          }
        },
      ),
    );
  }

  Future<void> _confirmDeleteReminder(ReminderModel reminder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa nhiệm vụ?'),
        content: Text('Bạn có chắc muốn xóa "${reminder.title}" khỏi lịch không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _reminderService.deleteReminder(reminder.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa nhiệm vụ')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể xóa nhiệm vụ: $e')),
      );
    }
  }
}
