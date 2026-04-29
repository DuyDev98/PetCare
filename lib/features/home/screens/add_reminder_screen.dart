import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddReminderScreen extends StatefulWidget {
  const AddReminderScreen({super.key});

  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();

}

class _AddReminderScreenState extends State<AddReminderScreen> {
  TimeOfDay _selectedTime = TimeOfDay.now();
  DateTime _selectedDate = DateTime.now();

  // Biến lưu trạng thái lặp lại
  String _selectedRepeat = "Daily";
  final List<String> _repeatOptions = ["Once", "Daily", "Weekly", "Monthly", "Yearly"];

  // Hàm chọn Giờ
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(context: context, initialTime: _selectedTime);
    if (picked != null) setState(() => _selectedTime = picked);
  }

  // Hàm chọn Ngày
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // Hàm hiển thị lựa chọn Lặp lại (Repeat)
  void _showRepeatOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _repeatOptions.map((option) {
              return ListTile(
                title: Text(option, textAlign: TextAlign.center),
                onTap: () {
                  setState(() => _selectedRepeat = option);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDE9C9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF5D4037)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Add Reminders', style: TextStyle(color: Color(0xFF5D4037), fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            _buildInputLabel("Title"),
            _buildTextField("Enter title..."),
            const SizedBox(height: 20),
            _buildInputLabel("Content"),
            _buildTextField("Enter content...", maxLines: 3),
            const SizedBox(height: 20),

            // ROW CHỌN TIME & DATE
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInputLabel("Time"),
                      GestureDetector(
                        onTap: () => _selectTime(context),
                        child: _buildSelectorField(_selectedTime.format(context), Icons.access_time),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInputLabel("Date"),
                      GestureDetector(
                        onTap: () => _selectDate(context),
                        child: _buildSelectorField(DateFormat('MMM dd, yyyy').format(_selectedDate), Icons.calendar_today),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // PHẦN CHỌN REPEAT (Đã thêm logic ấn)
            _buildInputLabel("Repeat"),
            GestureDetector(
              onTap: () => _showRepeatOptions(context),
              child: _buildSelectorField(_selectedRepeat, Icons.repeat),
            ),

            const SizedBox(height: 40),

            // Nút Save
            ElevatedButton(
              onPressed: () {
                // In ra kết quả để kiểm tra logic
                print("Lưu nhắc nhở: $_selectedRepeat lúc ${_selectedTime.format(context)} ngày ${DateFormat('dd/MM/yyyy').format(_selectedDate)}");
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEFA973),
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('Save Reminders', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET CON ---
  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, bottom: 8),
      child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF5D4037))),
    );
  }

  Widget _buildTextField(String hint, {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: TextField(
        maxLines: maxLines,
        decoration: InputDecoration(hintText: hint, border: InputBorder.none, contentPadding: const EdgeInsets.all(15)),
      ),
    );
  }

  Widget _buildSelectorField(String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(value, style: const TextStyle(fontSize: 15, color: Colors.black87)),
          Icon(icon, color: const Color(0xFFEFA973), size: 20),
        ],
      ),
    );
  }
}