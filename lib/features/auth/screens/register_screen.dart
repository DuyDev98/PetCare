import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_text_field.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/user_model.dart';
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

  bool _isLoading = false;
  bool _isPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;
  bool _isGoogleInit = false;

  Future<void> _signUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();
    // Bổ sung lấy tên người dùng từ ô nhập liệu
    final userName = _userNameController.text.trim();

    if (email.isEmpty || password.isEmpty || confirm.isEmpty || userName.isEmpty) {
      _showSnackBar("Vui lòng nhập đầy đủ thông tin!", Colors.red);
      return;
    }

    if (password != confirm) {
      _showSnackBar("Mật khẩu nhập lại không khớp!", Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Tạo tài khoản ở Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Lấy UID (mã định danh duy nhất) vừa được cấp
      String uid = userCredential.user!.uid;

      // 3. Đổ dữ liệu vào Khuôn đúc UserModel
      UserModel newUser = UserModel(
        uid: uid,
        email: email,
        userName: userName,
      );

      // 4. Lưu thông tin chi tiết vào bảng 'users' trong Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set(newUser.toMap());

      // Thành công thì thông báo và quay lại trang Login
      if (mounted) {
        _showSnackBar("Đăng ký thành công!", Colors.green);
        Navigator.pop(context);
      }

    } on FirebaseAuthException catch (e) {
      String errorMessage = "Đã xảy ra lỗi. Vui lòng thử lại.";
      if (e.code == 'email-already-in-use') {
        errorMessage = "Email này đã được đăng ký!";
      } else if (e.code == 'weak-password') {
        errorMessage = "Mật khẩu quá yếu (cần ít nhất 6 ký tự).";
      } else if (e.code == 'invalid-email') {
        errorMessage = "Định dạng Email không hợp lệ.";
      }
      _showSnackBar(errorMessage, Colors.red);
    } catch (e) {
      // Bắt thêm lỗi phòng trường hợp rớt mạng khi lưu Firestore
      _showSnackBar("Lỗi hệ thống: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      if (!_isGoogleInit) {
        await GoogleSignIn.instance.initialize(
          serverClientId: dotenv.env['GOOGLE_SERVER_CLIENT_ID'],
        );
        _isGoogleInit = true;
      }

      final GoogleSignInAccount? googleUser = await GoogleSignIn.instance.authenticate();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (mounted) {
        _showSnackBar("Đăng nhập Google thành công!", Colors.green);
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnackBar("Lỗi Google: Kiểm tra lại cấu hình Client ID.", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _userNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                        Text('Welcome !', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textBlack)),
                        SizedBox(height: 8),
                        Text('Sign up', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.primary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  CustomTextField(
                    label: "Email",
                    hintText: "Enter your email",
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 18),
                  CustomTextField(
                    label: "User name",
                    hintText: "Enter your user name",
                    controller: _userNameController,
                  ),
                  const SizedBox(height: 18),
                  CustomTextField(
                    label: "Password",
                    hintText: "Enter your password",
                    controller: _passwordController,
                    isPassword: true,
                    obscureText: _isPasswordObscured,
                    onToggleVisibility: () => setState(() => _isPasswordObscured = !_isPasswordObscured),
                  ),
                  const SizedBox(height: 18),
                  CustomTextField(
                    label: "Confirm Password",
                    hintText: "Confirm your password",
                    controller: _confirmPasswordController,
                    isPassword: true,
                    obscureText: _isConfirmPasswordObscured,
                    onToggleVisibility: () => setState(() => _isConfirmPasswordObscured = !_isConfirmPasswordObscured),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(55),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 3,
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 25, height: 25, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                        : const Text('Register', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 20),
                  const Center(
                    child: Text("OR", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton(
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(55),
                      side: const BorderSide(color: AppColors.primary, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                        const Text('Sign up with Google', style: TextStyle(fontSize: 20, color: AppColors.textBlack, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text("Already have an Account ?", style: TextStyle(color: AppColors.textGrey, fontSize: 16)),
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
