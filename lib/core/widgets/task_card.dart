import 'package:flutter/material.dart';
import 'package:pet_care/data/models/reminder_model.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class TaskCard extends StatelessWidget {
  final ReminderModel task;
  final Function(bool) onToggle;

  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    bool isDone = task.isCompleted;
    String timeStr = DateFormat('HH:mm').format(task.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: GestureDetector(
              onTap: () => onToggle(!isDone),
              child: Icon(
                isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: isDone ? Colors.green : Colors.grey[300],
                size: 28,
              ),
            ),
            title: Text(
              task.title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                decoration: isDone ? TextDecoration.lineThrough : null,
                color: isDone ? Colors.grey : const Color(0xFF1E2D4E),
              ),
            ),
            subtitle: Text(
              '$timeStr • ${task.petName}',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            trailing: _getIconForType(task.type),
          ),
          
          // HIỂN THỊ KỶ NIỆM (ẢNH)
          if (task.imageUrl != null && task.imageUrl!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome, size: 14, color: Colors.orangeAccent),
                      SizedBox(width: 4),
                      Text('Kỷ niệm ghi lại', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _showFullImage(context, task.imageUrl!),
                    child: Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey[100]!),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: CachedNetworkImage(
                          imageUrl: task.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
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
              child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: CircleAvatar(
                backgroundColor: Colors.white24,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getIconForType(ReminderType type) {
    IconData icon;
    Color color;
    switch (type) {
      case ReminderType.bath: icon = Icons.bathtub_rounded; color = Colors.blue; break;
      case ReminderType.vaccine: icon = Icons.medical_services_rounded; color = Colors.redAccent; break;
      case ReminderType.feed: icon = Icons.restaurant_rounded; color = Colors.orange; break;
      case ReminderType.checkup: icon = Icons.local_hospital_rounded; color = Colors.teal; break;
      case ReminderType.walk: icon = Icons.directions_walk_rounded; color = Colors.green; break;
      default: icon = Icons.notifications_rounded; color = Colors.blueGrey;
    }
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: color, size: 18),
    );
  }
}
