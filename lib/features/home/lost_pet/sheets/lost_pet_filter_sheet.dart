part of '../../screens/lost_pet_screen.dart';

class _FilterSheet extends StatefulWidget {
  final String initialKind;
  final RangeValues initialWeight;
  final bool initialUrgentOnly;
  final LostPetStatus? initialPostType;
  final void Function(
    String kind,
    RangeValues weight,
    bool urgentOnly,
    LostPetStatus? postType,
  )
  onApply;

  const _FilterSheet({
    required this.initialKind,
    required this.initialWeight,
    required this.initialUrgentOnly,
    required this.initialPostType,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String _kind;
  late RangeValues _weight;
  late bool _urgentOnly;
  late LostPetStatus? _postType;

  static const _orange = Color(0xFFE07B2B);

  @override
  void initState() {
    super.initState();
    _kind = widget.initialKind;
    _weight = widget.initialWeight;
    _urgentOnly = widget.initialUrgentOnly;
    _postType = widget.initialPostType;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bộ lọc',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Lọc loại tin
          const Text('Loại tin', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _postTypeChip('Tất cả', null, null),
              _postTypeChip(
                'Đang lạc',
                LostPetStatus.lost,
                const Color(0xFFE07B2B),
              ),
              _postTypeChip(
                'Tìm thấy',
                LostPetStatus.found,
                const Color(0xFF4CAF50),
              ),
              _postTypeChip(
                'Bị thương',
                LostPetStatus.injured,
                const Color(0xFFF9A825),
              ),
            ],
          ),
          const SizedBox(height: 14),

          const Text('Loài', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [_allKindsFilter, _dogKind, _catKind, _otherKindFilter]
                .map((k) {
                  final selected = _kind == k;
                  return ChoiceChip(
                    label: Text(k),
                    selected: selected,
                    selectedColor: const Color(0xFFFFE0C0),
                    onSelected: (_) => setState(() => _kind = k),
                    labelStyle: TextStyle(
                      color: selected ? _orange : Colors.black54,
                    ),
                  );
                })
                .toList(),
          ),
          const SizedBox(height: 14),
          Text(
            'Cân nặng: ${_weight.start.toInt()}kg – ${_weight.end.toInt()}kg',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          RangeSlider(
            values: _weight,
            min: 0,
            max: 50,
            divisions: 10,
            activeColor: _orange,
            onChanged: (v) => setState(() => _weight = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Chỉ hiện khẩn cấp',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            value: _urgentOnly,
            activeThumbColor: _orange,
            onChanged: (v) => setState(() => _urgentOnly = v),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                widget.onApply(_kind, _weight, _urgentOnly, _postType);
                Navigator.pop(context);
              },
              child: const Text(
                'Áp dụng',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _postTypeChip(String label, LostPetStatus? status, Color? color) {
    final selected = _postType == status;
    final chipColor = color ?? _orange;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: color != null
          ? color.withValues(alpha: 0.18)
          : const Color(0xFFFFE0C0),
      onSelected: (_) => setState(() => _postType = status),
      labelStyle: TextStyle(
        color: selected ? (color ?? _orange) : Colors.black54,
        fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
      ),
      side: selected
          ? BorderSide(color: chipColor, width: 1.5)
          : BorderSide(color: Colors.grey.shade300),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CREATE POST SHEET
// ─────────────────────────────────────────────────────────────────────────────
