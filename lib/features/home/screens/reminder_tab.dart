import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class ReminderTab extends StatefulWidget {
  const ReminderTab({super.key});

  @override
  State<ReminderTab> createState() => _ReminderTabState();
}

class _ReminderTabState extends State<ReminderTab> {
  bool isCalendarSelected = false; // Mặc định hiển thị Overdue
  DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDE9C9),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header: Nút Back và Tiêu đề
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF5D4037)),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const Text(
                    'Reminders',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5D4037)
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // 2. Tab Switcher (Calendar & Overdue)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    _buildTabItem("Calendar", isCalendarSelected, () {
                      setState(() => isCalendarSelected = true);
                    }),
                    _buildTabItem("Overdue", !isCalendarSelected, () {
                      setState(() => isCalendarSelected = false);
                    }),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 3. Nội dung chính: Lịch hoặc Danh sách (RecyclerView)
            Expanded(
              child: isCalendarSelected ? _buildCalendarView() : _buildOverdueView(),
            ),

            const SizedBox(height: 10),

            // 4. Nút Add Reminders
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: ElevatedButton(
                onPressed: () {
                  // Điều hướng sang trang AddReminderScreen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEFA973),
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                child: const Text(
                  'Add Reminders',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // 5. Thanh Navbar Mini (Quick Actions) ở dưới cùng

          ],
        ),
      ),
    );
  }

  // --- Widget: Danh sách Overdue (Cơ chế giống RecyclerView) ---
  Widget _buildOverdueView() {
    final List<Map<String, String>> overdueItems = [
      {"time": "09:00 AM", "title": "Ăn sáng", "desc": "Cho chó ăn"},
      {"time": "10:30 AM", "title": "Tắm rửa", "desc": "Tắm cho chó"},
      {"time": "02:00 PM", "title": "Cho ăn", "desc": "Cho chó ăn đêm"},
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: overdueItems.length,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(overdueItems[index]['time']!,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEFA973))),
                  const Text("Today", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              const SizedBox(width: 20),
              Container(width: 1, height: 35, color: Colors.grey[200]),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(overdueItems[index]['title']!,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(overdueItems[index]['desc']!,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Widget: View Lịch ---
  Widget _buildCalendarView() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
      child: TableCalendar(
        firstDay: DateTime.utc(2020),
        lastDay: DateTime.utc(2030),
        focusedDay: _focusedDay,
        headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
        calendarStyle: const CalendarStyle(
          todayDecoration: BoxDecoration(color: Color(0xFFFFE0B2), shape: BoxShape.circle),
          selectedDecoration: BoxDecoration(color: Color(0xFFEFA973), shape: BoxShape.circle),
        ),
      ),
    );
  }

  // --- Widget: Quick Actions Grid ---


  Widget _buildQuickBtn(IconData icon, String label, Color bg, Color iconCol, {int? badge}) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(backgroundColor: bg, radius: 22, child: Icon(icon, color: iconCol, size: 20)),
            if (badge != null)
              Positioned(
                right: -2, top: -2,
                child: CircleAvatar(radius: 8, backgroundColor: Colors.red, child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 10))),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildTabItem(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFEFA973) : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Center(
            child: Text(label, style: TextStyle(color: active ? Colors.white : Colors.grey[600], fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}