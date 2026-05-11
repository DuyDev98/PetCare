// lib/core/widgets/add_task_bottom_sheet.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pet_care/data/models/pet_model.dart';
import 'package:pet_care/data/models/reminder_model.dart';
import 'package:pet_care/data/services/pet_service.dart';
import '../../data/services/firebase_service.dart';

// ── Data class trả về khi save ────────────────────────────
class TaskFormData {
  final String title;
  final ReminderType type;
  final String petId;
  final String petName;
  final String petBreed;
  final DateTime dateTime;
  final String? imageUrl;

  const TaskFormData({
    required this.title,
    required this.type,
    required this.petId,
    required this.petName,
    required this.petBreed,
    required this.dateTime,
    this.imageUrl,
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
  final _firebaseService  = FirebaseService();
  final _petService       = PetService();
  final _picker           = ImagePicker();

  ReminderType _selectedType = ReminderType.feed;
  String?      _selectedPetId;
  String       _selectedPetName  = '';
  String       _selectedPetBreed = '';
  TimeOfDay    _selectedTime     = TimeOfDay.now();
  File?        _imageFile;
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source, imageQuality: 70);
      if (pickedFile != null) {
        setState(() => _imageFile = File(pickedFile.path));
      }
    } catch (e) {
      debugPrint("Lỗi chọn ảnh: $e");
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: _primary),
              title: const Text('Chụp ảnh mới'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: _primary),
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

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) return;
    if (_selectedPetId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn thú cưng')),
      );
      return;
    }

    setState(() => _isSaving = true);
    
    try {
      String? imageUrl;
      if (_imageFile != null) {
        imageUrl = await _petService.uploadToCloudinary(_imageFile!);
      }

      final taskDate = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      await widget.onSave(TaskFormData(
        title:    _titleController.text.trim(),
        type:     _selectedType,
        petId:    _selectedPetId!,
        petName:  _selectedPetName,
        petBreed: _selectedPetBreed,
        dateTime: taskDate,
        imageUrl: imageUrl,
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
                decoration: BoxDecoration(color: const Color(0xFFE0E9F5), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Thêm nhiệm vụ mới',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _textPrimary),
            ),
            const SizedBox(height: 20),
            _buildLabel('Hình ảnh kỷ niệm'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _showImageSourceDialog,
              child: Container(
                width: double.infinity,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F8FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _primary.withOpacity(0.1)),
                ),
                child: _imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(_imageFile!, fit: BoxFit.cover),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_rounded, color: _primary, size: 28),
                          SizedBox(height: 4),
                          Text('Chụp ảnh kỷ niệm', style: TextStyle(fontSize: 12, color: _textSecondary)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            _buildLabel('Tiêu đề'),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Ví dụ: Tắm cho Bella...',
                filled: true,
                fillColor: const Color(0xFFF5F8FF),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),
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
                        child: Text(
                          type.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : _textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            _buildLabel('Thú cưng'),
            const SizedBox(height: 8),
            StreamBuilder<List<PetModel>>(
              stream: _firebaseService.petsStream(),
              builder: (context, snapshot) {
                final pets = snapshot.data ?? [];
                return DropdownButtonFormField<String>(
                  value: _selectedPetId,
                  hint: const Text('Chọn thú cưng'),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF5F8FF),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                  items: pets.map<DropdownMenuItem<String>>((p) => DropdownMenuItem<String>(
                    value: p.id,
                    child: Text('${p.name} · ${p.kind}'),
                  )).toList(),
                  onChanged: (id) {
                    if (id == null) return;
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
            _buildLabel('Thời gian'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final time = await showTimePicker(context: context, initialTime: _selectedTime);
                if (time != null) setState(() => _selectedTime = time);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(color: const Color(0xFFF5F8FF), borderRadius: BorderRadius.circular(14)),
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
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSaving
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Lưu nhiệm vụ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textSecondary, letterSpacing: 0.3),
    );
  }
}
