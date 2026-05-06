import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../logic/auth_controller.dart';
import 'package:pet_care/data/services/pet_service.dart';
import 'package:pet_care/features/auth/screens/role_selection_screen.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/utils/ui_helpers.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.secondary,
      body: SafeArea(
        child: Register(),
      ),
    );
  }
}

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final _emailController = TextEditingController();
  final _userNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  final AuthController _authController = AuthController();
  final PetService _petService = PetService();

  @override
  void initState() {
    super.initState();
    _authController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      UIHelpers.showSnackBar(context, "Không thể chọn ảnh: $e", isError: true);
    }
  }

  Future<void> _handleSignUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();
    final username = _userNameController.text.trim();

    if (email.isEmpty || password.isEmpty || confirm.isEmpty || username.isEmpty) {
      UIHelpers.showSnackBar(context, "Vui lòng nhập đầy đủ thông tin!", isError: true);
      return;
    }
    if (password != confirm) {
      UIHelpers.showSnackBar(context, "Mật khẩu nhập lại không khớp!", isError: true);
      return;
    }

    final error = await _authController.signUp(email, password, username);

    if (error == null) {
      if (_imageFile != null) {
        // Tải ảnh lên Cloudinary
        String? imageUrl = await _petService.uploadToCloudinary(_imageFile!);
        if (imageUrl != null) {
          // Lưu thông tin kèm ảnh đại diện vào Firestore (FIX: Không dùng tham số vị trí)
          await _petService.saveUserInfo(
            displayName: username,
            photoURL: imageUrl,
          );
        }
      }
      
      if (mounted) {
        UIHelpers.showSnackBar(context, "Đăng ký thành công!");
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RoleSelectionScreen()));
      }
    } else {
      if (mounted) UIHelpers.showSnackBar(context, error, isError: true);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _userNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _authController.dispose();
    super.dispose();
  }

  bool _isPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;

  @override
  Widget build(BuildContext context) {
    final isLoading = _authController.isLoading;

    return Column(
      children: [
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _pickImage,
          child: Stack(
            children: [
              CircleAvatar(
                radius: 55,
                backgroundColor: Colors.white,
                backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                child: _imageFile == null ? const Icon(Icons.add_a_photo, size: 40, color: AppColors.primary) : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.edit, color: Colors.white, size: 18),
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Text("Thêm ảnh đại diện", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(top: 20),
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(45),
                topRight: Radius.circular(45),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text('Đăng ký', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ),
                  const SizedBox(height: 30),
                  CustomTextField(
                    label: "Họ và tên",
                    hintText: "Nhập tên của bạn",
                    controller: _userNameController,
                  ),
                  const SizedBox(height: 18),
                  CustomTextField(
                    label: "Email",
                    hintText: "Nhập email",
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 18),
                  CustomTextField(
                    label: "Mật khẩu",
                    hintText: "Nhập mật khẩu",
                    controller: _passwordController,
                    isPassword: true,
                    obscureText: _isPasswordObscured,
                    onToggleVisibility: () => setState(() => _isPasswordObscured = !_isPasswordObscured),
                  ),
                  const SizedBox(height: 18),
                  CustomTextField(
                    label: "Xác nhận mật khẩu",
                    hintText: "Nhập lại mật khẩu",
                    controller: _confirmPasswordController,
                    isPassword: true,
                    obscureText: _isConfirmPasswordObscured,
                    onToggleVisibility: () => setState(() => _isConfirmPasswordObscured = !_isConfirmPasswordObscured),
                  ),
                  const SizedBox(height: 40),
                  CustomButton(
                    text: 'Tiếp tục',
                    isLoading: isLoading,
                    onPressed: _handleSignUp,
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Đã có tài khoản? Đăng nhập", style: TextStyle(color: AppColors.textGrey, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
