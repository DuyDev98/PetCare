import 'package:flutter/material.dart';

class CalendarWidget extends StatefulWidget {
  final DateTime selectedDate;
  final void Function(DateTime) onDateSelected;

  const CalendarWidget({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  late DateTime _displayMonth;

  static const _primary = Color(0xFF5BB8F5);
  static const _accent = Color(0xFFFF8C42);
  static const _textPrimary = Color(0xFF1E2D4E);
  static const _textSecondary = Color(0xFF8FA3BF);

  static const _weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
  static const _months = [
    'Tháng 1', 'Tháng 2', 'Tháng 3', 'Tháng 4',
    'Tháng 5', 'Tháng 6', 'Tháng 7', 'Tháng 8',
    'Tháng 9', 'Tháng 10', 'Tháng 11', 'Tháng 12',
  ];

  @override
  void initState() {
    super.initState();
    _displayMonth = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
    );
  }

  void _previousMonth() {
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5BB8F5).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMonthHeader(),
          const SizedBox(height: 16),
          _buildWeekdayRow(),
          const SizedBox(height: 8),
          _buildDaysGrid(),
        ],
      ),
    );
  }

  Widget _buildMonthHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: _previousMonth,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF5FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.chevron_left_rounded,
              color: _primary,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${_months[_displayMonth.month - 1]}  ',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
                TextSpan(
                  text: '${_displayMonth.year}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: _nextMonth,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF5FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.chevron_right_rounded,
              color: _primary,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekdayRow() {
    return Row(
      children: _weekdays.map((day) {
        return Expanded(
          child: Center(
            child: Text(
              day,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDaysGrid() {
    final firstDay = DateTime(_displayMonth.year, _displayMonth.month, 1);
    // 0=Mon, 6=Sun in our layout (Monday first)
    int startWeekday = firstDay.weekday - 1; // 0=Mon

    final daysInMonth =
        DateTime(_displayMonth.year, _displayMonth.month + 1, 0).day;
    // Prev month days to show
    final daysInPrevMonth =
        DateTime(_displayMonth.year, _displayMonth.month, 0).day;

    final today = DateTime.now();
    final cells = <_CalendarCell>[];

    // Previous month tail
    for (int i = startWeekday - 1; i >= 0; i--) {
      cells.add(_CalendarCell(
        day: daysInPrevMonth - i,
        isCurrentMonth: false,
        date: DateTime(
            _displayMonth.year, _displayMonth.month - 1, daysInPrevMonth - i),
      ));
    }

    // Current month
    for (int d = 1; d <= daysInMonth; d++) {
      cells.add(_CalendarCell(
        day: d,
        isCurrentMonth: true,
        date: DateTime(_displayMonth.year, _displayMonth.month, d),
      ));
    }

    // Next month head
    while (cells.length % 7 != 0) {
      final nextDay = cells.length - startWeekday - daysInMonth + 1;
      cells.add(_CalendarCell(
        day: nextDay,
        isCurrentMonth: false,
        date: DateTime(_displayMonth.year, _displayMonth.month + 1, nextDay),
      ));
    }

    final rows = cells.length ~/ 7;

    return Column(
      children: List.generate(rows, (row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: List.generate(7, (col) {
              final cell = cells[row * 7 + col];
              final isToday = cell.date.year == today.year &&
                  cell.date.month == today.month &&
                  cell.date.day == today.day;
              final isSelected =
                  cell.date.year == widget.selectedDate.year &&
                      cell.date.month == widget.selectedDate.month &&
                      cell.date.day == widget.selectedDate.day;

              return Expanded(
                child: GestureDetector(
                  onTap: () => widget.onDateSelected(cell.date),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 36,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _primary
                          : isToday
                          ? _primary.withOpacity(0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '${cell.day}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected || isToday
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : cell.isCurrentMonth
                              ? isToday
                              ? _primary
                              : _textPrimary
                              : _textSecondary.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}

class _CalendarCell {
  final int day;
  final bool isCurrentMonth;
  final DateTime date;
  const _CalendarCell(
      {required this.day,
        required this.isCurrentMonth,
        required this.date});
}