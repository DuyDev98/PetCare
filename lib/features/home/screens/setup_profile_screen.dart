import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pet_care/data/services/pet_service.dart';
import '../../../core/utils/ui_helpers.dart';

class SetupProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? petData; // Thêm tham số này để nhận dữ liệu khi sửa

  const SetupProfileScreen({super.key, this.petData});

  @override
  State<SetupProfileScreen> createState() => _SetupProfileScreenState();
}

class _SetupProfileScreenState extends State<SetupProfileScreen> {
  final PetService _petService = PetService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  int? _selectedPetIndex;
  bool _isLoading = false;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  final List<Map<String, String>> pets = [
    {'emoji': '🐕', 'name': 'Chó'},
    {'emoji': '🐱', 'name': 'Mèo'},
    {'emoji': '🐭', 'name': 'Chuột'},
    {'emoji': '🦎', 'name': 'Thằn lằn'},
    {'emoji': '🐟', 'name': 'Cá'},
    {'emoji': '🦡', 'name': 'Ferret'},
    {'emoji': '🐿️', 'name': 'Chinchilla'},
    {'emoji': '🐍', 'name': 'Rắn'},
    {'emoji': '🐢', 'name': 'Rùa'},
    {'emoji': '🐰', 'name': 'Thỏ'},
    {'emoji': 'Hamster', 'name': 'Guinea'},
    {'emoji': '🐴', 'name': 'Ngựa'},
    {'emoji': '🫏', 'name': 'Lừa'},
    {'emoji': '🐷', 'name': 'Lợn'},
    {'emoji': '🐐', 'name': 'Dê'},
    {'emoji': '🐑', 'name': 'Cừu'},
    {'emoji': '🐄', 'name': 'Gia súc'},
    {'emoji': '🦜', 'name': 'Chim'},
    {'emoji': '🐔', 'name': 'Gà'},
    {'emoji': '🦆', 'name': 'Vịt'},
  ];

  @override
  void initState() {
    super.initState();
    // Nếu có petData -> Chế độ chỉnh sửa
    if (widget.petData != null) {
      _nameController.text = widget.petData!['name'] ?? '';
      _ageController.text = widget.petData!['age'] ?? '';
      String type = widget.petData!['type'] ?? '';
      _selectedPetIndex = pets.indexWhere((p) => p['name'] == type);
      if (_selectedPetIndex == -1) _selectedPetIndex = null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        UIHelpers.showSnackBar(context, "Lỗi chọn ảnh: $e", isError: true);
      }
    }
  }

  Future<void> _handleComplete() async {
    final name = _nameController.text.trim();
    final age = _ageController.text.trim();

    if (name.isEmpty || age.isEmpty || _selectedPetIndex == null) {
      UIHelpers.showSnackBar(context, "Vui lòng nhập đầy đủ thông tin!", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    String? imageUrl;
    if (_imageFile != null) {
      imageUrl = await _petService.uploadToCloudinary(_imageFile!);
    }

    bool success;
    if (widget.petData != null) {
      // Cập nhật
      success = await _petService.updatePetProfile(
        petId: widget.petData!['id'],
        name: name,
        age: age,
        type: pets[_selectedPetIndex!]['name']!,
        imageUrl: imageUrl,
      );
    } else {
      // Thêm mới
      success = await _petService.createPetProfile(
        name: name,
        age: age,
        type: pets[_selectedPetIndex!]['name']!,
        imageUrl: imageUrl,
      );
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      UIHelpers.showSnackBar(context, widget.petData != null ? "Cập nhật thành công!" : "Thêm thú cưng thành công!");
      Navigator.pop(context, true); 
    } else if (mounted) {
      UIHelpers.showSnackBar(context, "Thao tác thất bại!", isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEdit = widget.petData != null;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFD0C0B0), Color(0xFFE5D5C5)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(color: Colors.black12, shape: BoxShape.circle),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black87),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        isEdit ? 'Chỉnh sửa thú cưng' : 'Thêm thú cưng',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Avatar Section
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFD97706), width: 2),
                            image: _imageFile != null
                                ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                                : (isEdit && widget.petData!['avatarUrl'] != null && widget.petData!['avatarUrl'].isNotEmpty)
                                    ? DecorationImage(image: NetworkImage(widget.petData!['avatarUrl']), fit: BoxFit.cover)
                                    : null,
                          ),
                          child: (_imageFile == null && !(isEdit && widget.petData!['avatarUrl']?.isNotEmpty == true))
                              ? const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.camera_alt, size: 35, color: Color(0xFF7A3D00)),
                                    Text('Ảnh pet', style: TextStyle(fontSize: 10, color: Color(0xFF7A3D00), fontWeight: FontWeight.bold)),
                                  ],
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(color: Color(0xFFD97706), shape: BoxShape.circle),
                            child: const Icon(Icons.edit, color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                const Text('Thông tin cơ bản', style: TextStyle(color: Color(0xFF7A3D00), fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                _buildTextField(controller: _nameController, hintText: 'Tên thú cưng', icon: Icons.pets),
                const SizedBox(height: 12),
                _buildTextField(controller: _ageController, hintText: 'Tuổi', icon: Icons.cake, keyboardType: TextInputType.number),
                const SizedBox(height: 24),

                const Text('Chọn giống loài', style: TextStyle(color: Color(0xFF7A3D00), fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 20),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: pets.length,
                  itemBuilder: (context, index) {
                    final pet = pets[index];
                    final isSelected = _selectedPetIndex == index;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedPetIndex = index),
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isSelected
                                    ? [const Color(0xFFD97706), const Color(0xFFB45309)]
                                    : [const Color(0xFFFFA02E), const Color(0xFFF59E0B)],
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(width: isSelected ? 4 : 3, color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.6)),
                            ),
                            child: Center(child: Text(pet['emoji']!, style: const TextStyle(fontSize: 30))),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF7A3D00) : Colors.white.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              pet['name']!,
                              style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF7A3D00), fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7A3D00),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _isLoading ? null : _handleComplete,
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(isEdit ? 'Cập nhật' : 'Hoàn tất', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({TextEditingController? controller, required String hintText, required IconData icon, TextInputType keyboardType = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x2DC87800)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Color(0xFF7A3D00)),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFFFFA02E)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
