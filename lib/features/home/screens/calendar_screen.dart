import 'package:flutter/material.dart';
import 'package:pet_care/data/models/models.dart';
import '../../../data/services/firebase_service.dart';
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
  final _service = FirebaseService();

  DateTime _selectedDate = DateTime.now();
  String? _selectedPetId; // null = "All"
  int _currentNavIndex = 2; // Lịch is index 2

  // ─── Colors ────────────────────────────────────────────────────────────────
  static const Color _primary = Color(0xFF5BB8F5);
  static const Color _accent = Color(0xFFFF8C42);
  static const Color _bg = Color(0xFFF0F6FF);
  static const Color _cardBg = Colors.white;
  static const Color _textPrimary = Color(0xFF1E2D4E);
  static const Color _textSecondary = Color(0xFF8FA3BF);

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
                    // Pet selector
                    _buildPetSelector(),
                    const SizedBox(height: 16),
                    // Calendar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: CalendarWidget(
                        selectedDate: _selectedDate,
                        onDateSelected: (date) =>
                            setState(() => _selectedDate = date),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Task list
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
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: _textPrimary,
          ),
          const Expanded(
            child: Text(
              'Lịch chăm sóc & Nhắc nhở',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ),
          // Notification bell with badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF5FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: _primary,
                  size: 22,
                ),
              ),
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: _accent,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Center(
                    child: Text(
                      '3',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
    return StreamBuilder<List<Pet>>(
      stream: _service.petsStream(),
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

  // ─── Task Section ──────────────────────────────────────────────────────────

  Widget _buildTaskSection() {
    return StreamBuilder<List<PetTask>>(
      stream: _service.tasksStream(
        date: _selectedDate,
        petId: _selectedPetId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: _primary),
            ),
          );
        }

        final tasks = snapshot.data ?? [];
        final completed = tasks.where((t) => t.isCompleted).length;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Nhiệm vụ hôm nay',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF5FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$completed/${tasks.length} hoàn thành',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              if (tasks.isEmpty)
                _buildEmptyState()
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tasks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final task = tasks[i];
                    return TaskCard(
                      task: task,
                      onToggle: (value) =>
                          _service.toggleTask(task.id, value),
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
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF5FF),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.event_available_rounded,
                size: 40,
                color: _primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Không có nhiệm vụ nào',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Nhấn + để thêm nhiệm vụ mới',
              style: TextStyle(
                fontSize: 13,
                color: _textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── FAB ───────────────────────────────────────────────────────────────────

  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: () => _showAddTaskSheet(),
      backgroundColor: _accent,
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
        onSave: (task) => _service.addTask(task),
      ),
    );
  }

  // ─── Bottom Nav ────────────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    const items = [
      {'icon': Icons.home_rounded, 'label': 'Trang chủ'},
      {'icon': Icons.medical_services_rounded, 'label': 'Dịch vụ'},
      {'icon': Icons.calendar_month_rounded, 'label': 'Lịch'},
      {'icon': Icons.local_hospital_rounded, 'label': 'Khám bệnh'},
      {'icon': Icons.people_alt_rounded, 'label': 'Cộng đồng'},
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(items.length, (i) {
              final isActive = i == _currentNavIndex;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _currentNavIndex = i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        items[i]['icon'] as IconData,
                        size: 24,
                        color: isActive ? _primary : _textSecondary,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        items[i]['label'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: isActive ? _primary : _textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}