// lib/core/widgets/task_card.dart
import 'package:flutter/material.dart';
import 'package:pet_care/data/models/reminder_model.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/app_colors.dart';

class TaskCard extends StatelessWidget {
  final ReminderModel task;
  final Function(bool) onToggle;

  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
  });

  static const _textPrimary = AppColors.textBlack;
  static const _textSecondary = AppColors.textGrey;

  _TaskVisual get _visual {
    switch (task.type) {
      case ReminderType.bath:
        return _TaskVisual(
          icon: Icons.water_drop_rounded,
          bgColor: AppColors.primary.withOpacity(0.1),
          iconColor: AppColors.primary,
          tagColor: AppColors.primary,
          tagBg: AppColors.primary.withOpacity(0.1),
        );
      case ReminderType.vaccine:
        return const _TaskVisual(
          icon: Icons.vaccines_rounded,
          bgColor: Color(0xFFFFF3E0),
          iconColor: AppColors.secondary,
          tagColor: AppColors.secondary,
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

  @override
  Widget build(BuildContext context) {
    final vis = _visual;
    final isDone = task.isCompleted;
    final timeStr = DateFormat('HH:mm').format(task.timestamp);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isDone ? 0.7 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: vis.bgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(vis.icon, color: vis.iconColor, size: 22),
              ),
              title: Text(
                task.title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  decoration: isDone ? TextDecoration.lineThrough : null,
                  color: isDone ? _textSecondary : _textPrimary,
                ),
              ),
              subtitle: Text(
                '$timeStr • ${task.petName}',
                style: const TextStyle(fontSize: 12, color: _textSecondary),
              ),
              trailing: GestureDetector(
                onTap: () => onToggle(!isDone),
                child: Icon(
                  isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: isDone ? Colors.green : Colors.grey[300],
                  size: 28,
                ),
              ),
            ),
            if (task.imageUrl != null && task.imageUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, size: 14, color: Colors.orangeAccent),
                        const SizedBox(width: 4),
                        const Text(
                          'Kỷ niệm ghi lại',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.orangeAccent,
                          ),
                        ),
                        const Spacer(),
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
                      ],
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _showFullImage(context, task.imageUrl!),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: CachedNetworkImage(
                          imageUrl: task.imageUrl!,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 160,
                            color: Colors.grey[50],
                            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 160,
                            color: Colors.grey[50],
                            child: const Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.contain,
                placeholder: (context, url) => const CircularProgressIndicator(),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
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
