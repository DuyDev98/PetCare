import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../data/services/pet_service.dart';

class AddMedicalRecordScreen extends StatefulWidget {
  final String petId;

  const AddMedicalRecordScreen({super.key, required this.petId});

  @override
  State<AddMedicalRecordScreen> createState() => _AddMedicalRecordScreenState();
}

class _AddMedicalRecordScreenState extends State<AddMedicalRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final PetService _petService = PetService();
  final Color primaryColor = const Color(0xFFD97706);

  // Form Fields
  String _selectedType = 'Tiêm phòng';
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _clinicController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  
  File? _imageFile;
  bool _isLoading = false;

  final List<String> _recordTypes = ['Tiêm phòng', 'Khám bệnh', 'Xét nghiệm'];

  @override
  void dispose() {
    _titleController.dispose();
    _clinicController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: primaryColor),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? imageUrl;
      if (_imageFile != null) {
        imageUrl = await _petService.uploadToCloudinary(_imageFile!);
      }

      bool success = await _petService.addMedicalRecord(
        petId: widget.petId,
        recordType: _selectedType,
        date: _selectedDate,
        title: _titleController.text.trim(),
        clinicName: _clinicController.text.trim(),
        note: _noteController.text.trim(),
        imageUrl: imageUrl,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lưu hồ sơ thành công!')),
          );
          Navigator.pop(context);
        }
      } else {
        throw Exception("Failed to save to Firestore");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm hồ sơ y tế'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Loại hồ sơ', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    items: _recordTypes.map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedType = val!),
                  ),
                  const SizedBox(height: 20),
                  
                  _buildTextField(_titleController, 'Tiêu đề (Vắc-xin, tên bệnh...)', 'Vui lòng nhập tiêu đề'),
                  const SizedBox(height: 16),
                  
                  _buildTextField(_clinicController, 'Tên phòng khám / Bác sĩ', 'Vui lòng nhập tên phòng khám'),
                  const SizedBox(height: 16),

                  const Text('Ngày thực hiện', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                          Icon(Icons.calendar_today, color: primaryColor),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildTextField(_noteController, 'Ghi chú / Đơn thuốc', null, maxLines: 4),
                  const SizedBox(height: 20),

                  const Text('Hình ảnh đính kèm', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: _imageFile != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(_imageFile!, fit: BoxFit.cover),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, color: primaryColor, size: 40),
                                const Text('Chọn ảnh từ thư viện'),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveRecord,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('LƯU HỒ SƠ', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator(color: Color(0xFFD97706))),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String? errorText, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: 'Nhập $label...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          validator: (value) => (errorText != null && (value == null || value.isEmpty)) ? errorText : null,
        ),
      ],
    );
  }
}
