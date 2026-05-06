import 'package:flutter/material.dart';
import '../logic/auth_controller.dart';
import 'register_screen.dart';
import 'role_selection_screen.dart'; // Import màn hình chọn vai trò
import 'package:pet_care/data/services/pet_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/utils/ui_helpers.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.secondary,
      body: SafeArea(
        child: Login(),
      ),
    );
  }
}

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordObscured = true;

  final AuthController _authController = AuthController();

  @override
  void initState() {
    super.initState();
    _authController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  Future<void> _handleSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      UIHelpers.showSnackBar(context, "Vui lòng nhập đầy đủ thông tin!", isError: true);
      return;
    }

    final error = await _authController.signIn(email, password);
    
    if (error == null) {
      UIHelpers.showSnackBar(context, "Đăng nhập thành công!");
      _navigateToRoleSelection();
    } else {
      UIHelpers.showSnackBar(context, error, isError: true);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final error = await _authController.signInWithGoogle();
    
    if (error == null) {
      UIHelpers.showSnackBar(context, "Đăng nhập Google thành công!");
      _navigateToRoleSelection();
    } else if (error != "Hủy đăng nhập") {
      UIHelpers.showSnackBar(context, error ?? "Lỗi đăng nhập Google", isError: true);
    }
  }

  // Luôn chuyển đến màn hình chọn vai trò sau khi đăng nhập
  void _navigateToRoleSelection() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _authController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _authController.isLoading;

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 20, bottom: 20),
          width: 140,
          height: 140,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/logo.png"),
              fit: BoxFit.contain,
            ),
          ),
        ),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(45),
                topRight: Radius.circular(45),
              ),
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Column(
                      children: [
                        Text('Welcome Back !', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textBlack)),
                        SizedBox(height: 8),
                        Text('Sign in', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: AppColors.primary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 35),
                  CustomTextField(
                    label: "Email",
                    hintText: "Enter your email",
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    label: "Password",
                    hintText: "Enter your password",
                    controller: _passwordController,
                    isPassword: true,
                    obscureText: _isPasswordObscured,
                    onToggleVisibility: () => setState(() => _isPasswordObscured = !_isPasswordObscured),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: const Text("Forgot Password?", style: TextStyle(color: AppColors.primary, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  CustomButton(
                    text: 'Login',
                    isLoading: isLoading,
                    onPressed: _handleSignIn,
                  ),
                  const SizedBox(height: 25),
                  const Center(child: Text("OR", style: TextStyle(color: Colors.black38, fontWeight: FontWeight.bold))),
                  const SizedBox(height: 25),
                  OutlinedButton(
                    onPressed: isLoading ? null : _handleGoogleSignIn,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(55),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      side: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.network(
                          'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
                          width: 22,
                          height: 22,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata, size: 30, color: Colors.blue),
                        ),
                        const SizedBox(width: 12),
                        const Text('Sign in with Google', style: TextStyle(fontSize: 18, color: AppColors.textBlack, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
                      },
                      child: const Text("Don't have an Account ? Sign up", style: TextStyle(color: AppColors.textGrey, fontSize: 16)),
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
