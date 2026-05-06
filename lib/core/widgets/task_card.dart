// lib/core/widgets/task_card.dart
import 'package:flutter/material.dart';
import 'package:pet_care/data/models/reminder_model.dart';

class TaskCard extends StatelessWidget {
  final ReminderModel task;
  final void Function(bool) onToggle;

  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
  });

  static const _primary       = Color(0xFF5BB8F5);
  static const _accent        = Color(0xFFFF8C42);
  static const _textPrimary   = Color(0xFF1E2D4E);
  static const _textSecondary = Color(0xFF8FA3BF);

  _TaskVisual get _visual {
    switch (task.type) {
      case ReminderType.bath:
        return const _TaskVisual(
          icon: Icons.water_drop_rounded,
          bgColor: Color(0xFFE3F4FF),
          iconColor: Color(0xFF5BB8F5),
          tagColor: Color(0xFF5BB8F5),
          tagBg: Color(0xFFE3F4FF),
        );
      case ReminderType.vaccine:
        return const _TaskVisual(
          icon: Icons.vaccines_rounded,
          bgColor: Color(0xFFFFF3E0),
          iconColor: Color(0xFFFF8C42),
          tagColor: Color(0xFFFF8C42),
          tagBg: Color(0xFFFFF3E0),
        );
      case ReminderType.feed:
        return const _TaskVisual(
          icon: Icons.restaurant_rounded,
          bgColor: Color(0xFFE8F5E9),
          iconColor: Color(0xFF66BB6A),
          tagColor: Color(0xFF66BB6A),
          tagBg: Color(0xFFE8F5E9),
        );
      case ReminderType.checkup:
        return const _TaskVisual(
          icon: Icons.local_hospital_rounded,
          bgColor: Color(0xFFFCE4EC),
          iconColor: Color(0xFFEF5350),
          tagColor: Color(0xFFEF5350),
          tagBg: Color(0xFFFCE4EC),
        );
      case ReminderType.walk:
        return const _TaskVisual(
          icon: Icons.directions_walk_rounded,
          bgColor: Color(0xFFF3E5F5),
          iconColor: Color(0xFFAB47BC),
          tagColor: Color(0xFFAB47BC),
          tagBg: Color(0xFFF3E5F5),
        );
      default:
        return const _TaskVisual(
          icon: Icons.star_rounded,
          bgColor: Color(0xFFF5F5F5),
          iconColor: Color(0xFF9E9E9E),
          tagColor: Color(0xFF9E9E9E),
          tagBg: Color(0xFFF5F5F5),
        );
    }
  }

  // Format DateTime → "HH:mm"
  String get _timeStr {
    final t = task.timestamp;
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final vis         = _visual;
    final isCompleted = task.isCompleted;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isCompleted ? 0.7 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon loại nhiệm vụ
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: vis.bgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(vis.icon, color: vis.iconColor, size: 22),
            ),
            const SizedBox(width: 12),

            // Thông tin
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: vis.tagBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          task.type.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: vis.tagColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _timeStr,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      decorationColor: _textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${task.petName} · ${task.petBreed}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: _textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Actions
            Column(
              children: [
                Icon(
                  Icons.notifications_rounded,
                  size: 18,
                  color: isCompleted
                      ? _textSecondary.withValues(alpha: 0.4)
                      : _accent,
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => onToggle(!task.isCompleted),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted ? _primary : Colors.transparent,
                      border: Border.all(
                        color: isCompleted ? _primary : const Color(0xFFD0DEEE),
                        width: 2,
                      ),
                    ),
                    child: isCompleted
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskVisual {
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final Color tagColor;
  final Color tagBg;

  const _TaskVisual({
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    required this.tagColor,
    required this.tagBg,
  });
}