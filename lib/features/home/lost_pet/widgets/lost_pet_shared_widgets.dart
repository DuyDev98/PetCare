part of '../../screens/lost_pet_screen.dart';

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _PostTypeOption {
  final LostPetStatus status;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String label;
  final String desc;
  const _PostTypeOption({
    required this.status,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.label,
    required this.desc,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _UrgentBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFE53935),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, size: 11, color: Colors.white),
          SizedBox(width: 2),
          Text(
            'Khẩn cấp',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final LostPetStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    final IconData icon;
    switch (status) {
      case LostPetStatus.found:
        color = const Color(0xFF4CAF50);
        label = 'Tìm thấy';
        icon = Icons.check_circle_outline_rounded;
        break;
      case LostPetStatus.injured:
        color = const Color(0xFFF9A825);
        label = 'Bị thương';
        icon = Icons.healing_rounded;
        break;
      case LostPetStatus.lost:
        color = const Color(0xFFE07B2B);
        label = 'Đang lạc';
        icon = Icons.location_searching_rounded;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: Colors.white),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FILTER SHEET
// ─────────────────────────────────────────────────────────────────────────────
