import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart'; // 1. BẮT BUỘC THÊM THƯ VIỆN NÀY

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF0A973), // Màu nền vàng đồng bộ
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
  // Controller để lấy dữ liệu
  final _emailController = TextEditingController();
  final _userNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Biến trạng thái
  bool _isLoading = false;
  bool _isPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;
  bool _isGoogleInit = false; // Biến trạng thái cho Google (Giống hệt trang Login)

  // Hàm xử lý đăng ký bằng Email
  Future<void> _signUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty || confirm.isEmpty) {
      _showSnackBar("Vui lòng nhập đầy đủ thông tin!", Colors.red);
      return;
    }
    if (password != confirm) {
      _showSnackBar("Mật khẩu nhập lại không khớp!", Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (mounted) {
        _showSnackBar("Đăng ký thành công!", Colors.green);
        Navigator.pop(context); // Chuyển về màn hình đăng nhập
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
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 2. THÊM HÀM ĐĂNG KÝ BẰNG GOOGLE (Copy logic từ Login sang)
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      if (!_isGoogleInit) {
        await GoogleSignIn.instance.initialize(
          // 👉 DUY NHỚ COPY MÃ TỪ LOGIN_SCREEN.DART DÁN VÀO ĐÂY NHÉ:
          serverClientId: '668771715108-t2c483ohn8dqnj9h3k189a5ee22b5cn3.apps.googleusercontent.com',
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

      _showSnackBar("Đăng nhập Google thành công!", Colors.green);
      // Chuyển về màn hình Login hoặc thẳng vào HomeScreen tùy bạn
      if (mounted) Navigator.pop(context);

    } catch (e) {
      _showSnackBar("Lỗi Google: Kiểm tra lại cấu hình Client ID.", Colors.red);
      print("Error chi tiết: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Hàm hiển thị thông báo dùng chung
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
        // Hình ảnh Logo
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

        // Thẻ trắng chứa Form
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: const ShapeDecoration(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(45),
                  topRight: Radius.circular(45),
                ),
              ),
              shadows: [BoxShadow(color: Color(0x3F000000), blurRadius: 10, offset: Offset(0, 5))],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tiêu đề
                  const Center(
                    child: Column(
                      children: [
                        Text('Welcome !', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
                        SizedBox(height: 8),
                        Text('Sign up', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: Color(0xFFDF5110))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Các ô nhập liệu
                  _buildInputField("Email", "Enter your email", _emailController, TextInputType.emailAddress),
                  const SizedBox(height: 18),

                  _buildInputField("User name", "Enter your user name", _userNameController, TextInputType.text),
                  const SizedBox(height: 18),

                  _buildInputField(
                      "Password", "Enter your password", _passwordController, TextInputType.visiblePassword,
                      isPassword: true,
                      obscureText: _isPasswordObscured,
                      onToggleVisibility: () => setState(() => _isPasswordObscured = !_isPasswordObscured)
                  ),
                  const SizedBox(height: 18),

                  _buildInputField(
                      "Confirm Password", "Confirm your password", _confirmPasswordController, TextInputType.visiblePassword,
                      isPassword: true,
                      obscureText: _isConfirmPasswordObscured,
                      onToggleVisibility: () => setState(() => _isConfirmPasswordObscured = !_isConfirmPasswordObscured)
                  ),
                  const SizedBox(height: 40),

                  // Nút Register
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDF5110),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(55),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 25, height: 25, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                        : const Text('Register', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 20),

                  // 3. THÊM NÚT GOOGLE Ở ĐÂY
                  const Center(
                    child: Text("OR", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const SizedBox(height: 20),

                  OutlinedButton(
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(55),
                      side: const BorderSide(color: Color(0xFFDF5110), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('G', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.blue)),
                        SizedBox(width: 12),
                        Text('Sign up with Google', style: TextStyle(fontSize: 20, color: Colors.black87, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Nút quay lại trang Đăng Nhập
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text("Already have an Account ?", style: TextStyle(color: Colors.black54, fontSize: 16)),
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

  // Hàm phụ trợ tạo ô nhập liệu (Giữ nguyên của bạn)
  Widget _buildInputField(String label, String hintText, TextEditingController controller, TextInputType keyboardType, {bool isPassword = false, bool obscureText = false, VoidCallback? onToggleVisibility}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 6),
          child: Text(label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87)),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(width: 1.5, color: const Color(0xFFDF5110)),
            borderRadius: BorderRadius.circular(15),
            color: Colors.white,
          ),
          padding: const EdgeInsets.only(left: 15, right: 5),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hintText,
              hintStyle: const TextStyle(color: Colors.black38, fontSize: 18),
              suffixIcon: isPassword
                  ? IconButton(icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, color: Colors.grey), onPressed: onToggleVisibility)
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}