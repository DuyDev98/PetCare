import 'package:flutter/material.dart';
import 'package:pet_care/data/models/models.dart';

class PetAvatarSelector extends StatelessWidget {
  final List<Pet> pets;
  final String? selectedPetId;
  final void Function(String? petId) onSelected;

  const PetAvatarSelector({
    super.key,
    required this.pets,
    required this.selectedPetId,
    required this.onSelected,
  });

  static const _primary = Color(0xFF5BB8F5);
  static const _accent = Color(0xFFFF8C42);
  static const _bg = Color(0xFFF0F6FF);
  static const _textSecondary = Color(0xFF8FA3BF);

  // Pet type emoji fallbacks when no avatar URL
  static const _petEmojis = ['🐕', '🐈', '🐩', '🦜', '🐇'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // "Tất cả" item
          _buildAvatarItem(
            id: null,
            label: 'Tất cả',
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _primary.withOpacity(0.8),
                    _primary,
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.pets_rounded, color: Colors.white, size: 24),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Pet items
          ...pets.asMap().entries.map((entry) {
            final index = entry.key;
            final pet = entry.value;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _buildAvatarItem(
                id: pet.id,
                label: pet.name,
                child: pet.avatarUrl.isNotEmpty
                    ? ClipOval(
                  child: Image.network(
                    pet.avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _buildEmojiAvatar(index),
                  ),
                )
                    : _buildEmojiAvatar(index),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmojiAvatar(int index) {
    final colors = [
      [const Color(0xFFFFE0B2), const Color(0xFFFF8C42)],
      [const Color(0xFFE3F2FD), const Color(0xFF5BB8F5)],
      [const Color(0xFFF3E5F5), const Color(0xFFCE93D8)],
      [const Color(0xFFE8F5E9), const Color(0xFF81C784)],
    ];
    final colorPair = colors[index % colors.length];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colorPair,
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _petEmojis[index % _petEmojis.length],
          style: const TextStyle(fontSize: 26),
        ),
      ),
    );
  }

  Widget _buildAvatarItem({
    required String? id,
    required String label,
    required Widget child,
  }) {
    final isSelected = id == selectedPetId;

    return GestureDetector(
      onTap: () => onSelected(id),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? _primary : Colors.transparent,
                width: 2.5,
              ),
              boxShadow: isSelected
                  ? [
                BoxShadow(
                  color: _primary.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
                  : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(child: child),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight:
              isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? _primary : _textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}