import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/services/pet_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_text_field.dart';

class SetupProfileScreen extends StatefulWidget {
  const SetupProfileScreen({super.key});

  @override
  State<SetupProfileScreen> createState() => _SetupProfileScreenState();
}

class _SetupProfileScreenState extends State<SetupProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  String? _selectedPetType;
  bool _isLoading = false;
  final PetService _petService = PetService();
  final List<Map<String, String>> _petTypes = [
    {'type': 'dog', 'icon': '🐶', 'label': 'Chó'},
    {'type': 'cat', 'icon': '🐱', 'label': 'Mèo'},
    {'type': 'bird', 'icon': '🐦', 'label': 'Chim'},
    {'type': 'hamster', 'icon': '🐹', 'label': 'Hamster'},
    {'type': 'fish', 'icon': '🐠', 'label': 'Cá'},
    {'type': 'rabbit', 'icon': '🐰', 'label': 'Thỏ'},
    {'type': 'other', 'icon': '🐾', 'label': 'Khác'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _submitData() async {
    final name = _nameController.text.trim();
    final age = _ageController.text.trim();

    if (name.isEmpty || age.isEmpty || _selectedPetType == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng điền đủ thông tin và chọn loại thú cưng'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    bool success = await _petService.createPetProfile(
      name: name,
      age: age,
      type: _selectedPetType!,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tạo hồ sơ thành công!'), backgroundColor: Colors.green),
      );
      // TODO: Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Có lỗi xảy ra, vui lòng thử lại'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                const Text(
                  'It takes 20 seconds!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          'Choose a pet type',
                          style: TextStyle(color: AppColors.textBlack, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: Wrap(
                          spacing: 20, // Khoảng cách ngang giữa các con vật
                          runSpacing: 20, // Khoảng cách dọc (khi bị rớt dòng)
                          alignment: WrapAlignment.center,
                          children: _petTypes.map((pet) {
                            return _buildPetTypeItem(pet['type']!, pet['icon']!, pet['label']!);
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 30),
                      CustomTextField(
                        label: 'Pet name',
                        hintText: 'Enter your pet name',
                        controller: _nameController,
                      ),
                      const SizedBox(height: 20),
                      CustomTextField(
                        label: 'Pet age',
                        hintText: 'Enter your pet age',
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            elevation: 3,
                          ),
                          onPressed: _isLoading ? null : _submitData,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 25,
                                  height: 25,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                                )
                              : const Text(
                                  'Continue',
                                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPetTypeItem(String type, String icon, String label) {
    bool isSelected = _selectedPetType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedPetType = type),
      child: Column(
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFDF5110).withOpacity(0.15) : Colors.grey.shade100,
              shape: BoxShape.circle,
              border: Border.all(
                  color: isSelected ? const Color(0xFFDF5110) : Colors.transparent,
                  width: 2.5
              ),
            ),
            // Hiển thị Emoji ở giữa hình tròn
            child: Center(child: Text(icon, style: const TextStyle(fontSize: 32))),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isSelected ? const Color(0xFFDF5110) : Colors.black54,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
