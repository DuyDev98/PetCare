import 'package:flutter/material.dart';
import 'package:pet_care/data/models/pet_model.dart';
import 'package:pet_care/data/models/reminder_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pet_care/core/constants/app_colors.dart'; // Import AppColors
import '../../../data/services/firebase_service.dart';
import '../../../data/services/reminder_service.dart';
import '../../../core/widgets/pet_avatar_selector.dart';
import '../../../core/widgets/calendar_widget.dart';
import '../../../core/widgets/task_card.dart';
import '../../../core/widgets/add_task_bottom_sheet.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _petService      = FirebaseService();
  final _reminderService = ReminderService();

  DateTime _selectedDate  = DateTime.now();
  String?  _selectedPetId;

  // Sử dụng màu từ AppColors
  final Color _primary = AppColors.primary;
  final Color _bg = const Color(0xFFFAF8F5);
  final Color _textPrimary = const Color(0xFF1F2937);
  final Color _textSecondary = const Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
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
                    _buildMomentsSection(),
                    _buildTaskSection(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
      // ĐÃ XÓA bottomNavigationBar Ở ĐÂY ĐỂ DÙNG CHUNG VỚI HOMESCREEN
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Center(
        child: Text(
          'Lịch chăm sóc & Nhắc nhở',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textPrimary),
        ),
      ),
    );
  }

  Widget _buildPetSelector() {
    return StreamBuilder<List<PetModel>>(
      stream: _petService.petsStream(),
      builder: (context, snapshot) {
        final pets = snapshot.data ?? [];
        return PetAvatarSelector(
          pets: pets,
          selectedPetId: _selectedPetId,
          onSelected: (id) => setState(() => _selectedPetId = id),
        );
      },
    );
  }

  Widget _buildMomentsSection() {
    return StreamBuilder<List<ReminderModel>>(
      stream: _reminderService.getRemindersByDate(_selectedDate, petId: _selectedPetId),
      builder: (context, snapshot) {
        final reminders = snapshot.data ?? [];
        final remindersWithImages = reminders
            .where((r) => r.imageUrl != null && r.imageUrl!.isNotEmpty)
            .toList();

        if (remindersWithImages.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, color: _primary, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Khoảnh khắc kỷ niệm',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 140,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: remindersWithImages.length,
                itemBuilder: (context, index) {
                  final reminder = remindersWithImages[index];
                  return Container(
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
                        imageUrl: reminder.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _buildTaskSection() {
    return StreamBuilder<List<ReminderModel>>(
      stream: _reminderService.getRemindersByDate(_selectedDate, petId: _selectedPetId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: Padding(padding: const EdgeInsets.all(40), child: CircularProgressIndicator(color: _primary)));
        }

        final reminders = snapshot.data ?? [];
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
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                  ),
                  if (reminders.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(color: _primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        '$completed/${reminders.length} hoàn thành',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _primary),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              if (reminders.isEmpty) _buildEmptyState()
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: reminders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final reminder = reminders[i];
                    return TaskCard(
                      task: reminder,
                      onToggle: (value) => _reminderService.toggleReminder(reminder.id, value),
                    );
                  },
                ),
            ],
          ),
        );
      },
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
              decoration: BoxDecoration(color: _primary.withOpacity(0.1), borderRadius: BorderRadius.circular(40)),
              child: Icon(Icons.event_available_rounded, size: 40, color: _primary),
            ),
            const SizedBox(height: 16),
            const Text('Không có nhiệm vụ nào', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Nhấn + để thêm nhiệm vụ mới', style: TextStyle(fontSize: 13, color: _textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton(
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
        onSave: (data) => _reminderService.createReminder(
          title:    data.title,
          dateTime: data.dateTime,
          type:     data.type,
          petId:    data.petId,
          petName:  data.petName,
          petBreed: data.petBreed,
          imageUrl: data.imageUrl,
        ),
      ),
    );
  }
}
