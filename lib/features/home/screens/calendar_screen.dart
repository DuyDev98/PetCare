import 'package:flutter/material.dart';
import 'package:pet_care/data/models/pet_model.dart';
import 'package:pet_care/data/models/reminder_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pet_care/core/constants/app_colors.dart';
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

  // Colors - Using unified AppColors
  static const Color _primary       = AppColors.primary;
  static const Color _accent        = AppColors.secondary;
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
                        _buildMomentsSection(reminders),
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
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: _primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.notifications_none_rounded, color: _primary, size: 22),
              ),
              Positioned(
                top: -2, right: -2,
                child: Container(
                  width: 18, height: 18,
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Center(
                    child: Text('3', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
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
          onSelected: (id) => setState(() => _selectedPetId = id),
        );
      },
    );
  }

  // ─── Moments Section ───────────────────────────────────────────────────────

  Widget _buildMomentsSection(List<ReminderModel> reminders) {
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
              const Icon(Icons.auto_awesome, color: _primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Khoảnh khắc kỷ niệm',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _textPrimary),
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
                    errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
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
                    color: _primary.withOpacity(0.1),
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
                color: _primary.withOpacity(0.1),
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
              type:     data.type,
              petId:    data.petId,
              petName:  data.petName,
              petBreed: data.petBreed,
              imageUrl: data.imageUrl,
            );
          } else {
            await _reminderService.createRepeatingReminder(
              title:         data.title,
              startDateTime: data.dateTime,
              type:          data.type,
              petId:         data.petId,
              petName:       data.petName,
              petBreed:      data.petBreed,
              repeatType:    data.repeatType,
              repeatUntil:   data.repeatUntil!,
              repeatDays:    data.repeatDays,
              imageUrl:      data.imageUrl,
            );
          }
        },
      ),
    );
  }
}
