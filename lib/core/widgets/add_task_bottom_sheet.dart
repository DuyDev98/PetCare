// lib/core/widgets/add_task_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:pet_care/data/models/pet_model.dart';
import 'package:pet_care/data/models/reminder_model.dart';
import '../../data/services/firebase_service.dart';

class TaskFormData {
  final String title;
  final ReminderType type;
  final String petId;
  final String petName;
  final String petBreed;
  final DateTime dateTime;
  final RepeatType repeatType;
  final List<int> repeatDays;
  final DateTime? repeatUntil;

  const TaskFormData({
    required this.title,
    required this.type,
    required this.petId,
    required this.petName,
    required this.petBreed,
    required this.dateTime,
    this.repeatType  = RepeatType.none,
    this.repeatDays  = const [],
    this.repeatUntil,
  });
}

class AddTaskBottomSheet extends StatefulWidget {
  final DateTime selectedDate;
  final Future<void> Function(TaskFormData) onSave;

  const AddTaskBottomSheet({
    super.key,
    required this.selectedDate,
    required this.onSave,
  });

  @override
  State<AddTaskBottomSheet> createState() => _AddTaskBottomSheetState();
}

class _AddTaskBottomSheetState extends State<AddTaskBottomSheet> {
  final _titleController = TextEditingController();
  final _service         = FirebaseService();

  ReminderType _selectedType     = ReminderType.feed;
  String?      _selectedPetId;
  String       _selectedPetName  = '';
  String       _selectedPetBreed = '';
  TimeOfDay    _selectedTime     = TimeOfDay.now();

  // Repeat state
  RepeatType   _repeatType       = RepeatType.none;
  List<int>    _repeatDays       = [];   // custom weekdays
  DateTime?    _repeatUntil;

  bool         _isSaving         = false;

  static const _primary       = Color(0xFF5BB8F5);
  static const _accent        = Color(0xFFFF8C42);
  static const _textPrimary   = Color(0xFF1E2D4E);
  static const _textSecondary = Color(0xFF8FA3BF);

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) return;
    if (_selectedPetId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn thú cưng')),
      );
      return;
    }
    // Nếu chọn lặp nhưng chưa chọn ngày kết thúc
    if (_repeatType != RepeatType.none && _repeatUntil == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ngày kết thúc lặp lại')),
      );
      return;
    }
    // Nếu custom nhưng chưa chọn ngày nào
    if (_repeatType == RepeatType.custom && _repeatDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất 1 ngày trong tuần')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final taskDate = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
      await widget.onSave(TaskFormData(
        title:       _titleController.text.trim(),
        type:        _selectedType,
        petId:       _selectedPetId!,
        petName:     _selectedPetName,
        petBreed:    _selectedPetBreed,
        dateTime:    taskDate,
        repeatType:  _repeatType,
        repeatDays:  _repeatDays,
        repeatUntil: _repeatUntil,
      ));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPadding),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E9F5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Thêm nhiệm vụ mới',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _textPrimary)),
            const SizedBox(height: 20),

            // ── Tiêu đề ──────────────────────────────────
            _buildLabel('Tiêu đề'),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Ví dụ: Tắm cho Bella...',
                hintStyle: TextStyle(color: _textSecondary.withValues(alpha: 0.7)),
                filled: true,
                fillColor: const Color(0xFFF5F8FF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),

            // ── Loại nhiệm vụ ─────────────────────────────
            _buildLabel('Loại nhiệm vụ'),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ReminderType.values.map((type) {
                  final isSelected = type == _selectedType;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedType = type),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? _primary : const Color(0xFFF5F8FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(type.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : _textSecondary,
                            )),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // ── Thú cưng ──────────────────────────────────
            _buildLabel('Thú cưng'),
            const SizedBox(height: 8),
            StreamBuilder<List<PetModel>>(
              stream: _service.petsStream(),
              builder: (context, snapshot) {
                final pets = snapshot.data ?? [];
                return DropdownButtonFormField<String>(
                  value: _selectedPetId,
                  hint: const Text('Chọn thú cưng'),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF5F8FF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  items: pets.map((p) => DropdownMenuItem(
                    value: p.id,
                    child: Text('${p.name} · ${p.breed}'),
                  )).toList(),
                  onChanged: (id) {
                    final pet = pets.firstWhere((p) => p.id == id);
                    setState(() {
                      _selectedPetId    = id;
                      _selectedPetName  = pet.name;
                      _selectedPetBreed = pet.breed;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            // ── Thời gian ─────────────────────────────────
            _buildLabel('Thời gian'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _selectedTime,
                );
                if (time != null) setState(() => _selectedTime = time);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F8FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time_rounded, color: _primary, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _textPrimary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Lặp lại ───────────────────────────────────
            _buildLabel('Lặp lại'),
            const SizedBox(height: 8),
            _buildRepeatTypeSelector(),
            if (_repeatType == RepeatType.custom) ...[
              const SizedBox(height: 12),
              _buildWeekdayPicker(),
            ],
            if (_repeatType != RepeatType.none) ...[
              const SizedBox(height: 12),
              _buildRepeatUntilPicker(),
            ],
            const SizedBox(height: 24),

            // ── Nút lưu ───────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSaving
                    ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Lưu nhiệm vụ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Repeat type chips ─────────────────────────────────────
  Widget _buildRepeatTypeSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: RepeatType.values.map((type) {
          final isSelected = type == _repeatType;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() {
                _repeatType = type;
                if (type != RepeatType.custom) _repeatDays = [];
                if (type == RepeatType.none) _repeatUntil = null;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? _accent : const Color(0xFFF5F8FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? _accent : Colors.transparent,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected) ...[
                      const Icon(Icons.repeat_rounded, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                    ],
                    Text(type.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : _textSecondary,
                        )),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Weekday picker (custom) ───────────────────────────────
  Widget _buildWeekdayPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Chọn ngày trong tuần',
            style: TextStyle(fontSize: 12, color: _textSecondary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: weekdayLabels.entries.map((e) {
            final isSelected = _repeatDays.contains(e.key);
            return GestureDetector(
              onTap: () => setState(() {
                if (isSelected) {
                  _repeatDays = List.from(_repeatDays)..remove(e.key);
                } else {
                  _repeatDays = List.from(_repeatDays)..add(e.key);
                }
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: isSelected ? _primary : const Color(0xFFF5F8FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(e.value,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : _textSecondary,
                      )),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Repeat until date picker ──────────────────────────────
  Widget _buildRepeatUntilPicker() {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _repeatUntil ?? widget.selectedDate.add(const Duration(days: 30)),
          firstDate: widget.selectedDate.add(const Duration(days: 1)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) setState(() => _repeatUntil = date);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F8FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _repeatUntil == null ? Colors.orange.withValues(alpha: 0.5) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.event_rounded,
                color: _repeatUntil == null ? Colors.orange : _primary, size: 20),
            const SizedBox(width: 12),
            Text(
              _repeatUntil == null
                  ? 'Chọn ngày kết thúc *'
                  : 'Kết thúc: ${_repeatUntil!.day}/${_repeatUntil!.month}/${_repeatUntil!.year}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _repeatUntil == null ? Colors.orange : _textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: _textSecondary,
          letterSpacing: 0.3,
        ));
  }
}