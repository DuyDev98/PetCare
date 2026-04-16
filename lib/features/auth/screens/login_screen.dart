import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'register_screen.dart'; // Đảm bảo Duy đã có file này trong cùng thư mục

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      // Màu cam chủ đạo của PetCare
      backgroundColor: Color(0xFFF0A973),
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
  // 1. Khởi tạo Controller và Biến trạng thái
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordObscured = true;

  // 2. Hàm xử lý Đăng nhập bằng Email/Mật khẩu
  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar("Vui lòng nhập đầy đủ thông tin!", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _showSnackBar("Đăng nhập thành công!", Colors.green);
      // TODO: Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
    } on FirebaseAuthException catch (e) {
      String msg = "Lỗi đăng nhập!";
      if (e.code == 'invalid-credential') msg = "Email hoặc mật khẩu không đúng.";
      _showSnackBar(msg, Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 3. Hàm xử lý Đăng nhập bằng Google
  // Biến cờ để đảm bảo GoogleSignIn chỉ khởi tạo 1 lần
  bool _isGoogleInit = false;

  // 3. Hàm xử lý Đăng nhập bằng Google (Bản cập nhật v7.x)
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      // 1. Ở bản v7, bắt buộc phải initialize() trước khi gọi các hàm khác
      if (!_isGoogleInit) {
        await GoogleSignIn.instance.initialize();
        _isGoogleInit = true;
      }

      // 2. Dùng authenticate() thay vì signIn()
      final GoogleSignInAccount? googleUser = await GoogleSignIn.instance.authenticate();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      // 3. Lấy thông tin xác thực (Ở bản v7, thuộc tính này không cần chữ 'await' nữa)
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // 4. Tạo Credential cho Firebase (Giờ chỉ cần truyền idToken là đủ)
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // 5. Đăng nhập vào Firebase
      await FirebaseAuth.instance.signInWithCredential(credential);

      _showSnackBar("Đăng nhập Google thành công!", Colors.green);
      // TODO: Nhảy sang trang HomeScreen tại đây

    } catch (e) {
      _showSnackBar("Lỗi Google: Kiểm tra lại mạng hoặc mã SHA-1.", Colors.red);
      print("Error chi tiết: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  // Hàm hiển thị thông báo nhanh
  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // --- LOGO ---
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

        // --- PHẦN THÔNG TIN TRẮNG ---
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
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
                        Text('Welcome Back !', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87)),
                        SizedBox(height: 8),
                        Text('Sign in', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: Color(0xFFDF5110))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 35),

                  // Ô nhập Email
                  _buildInputField("Email", "Enter your email", _emailController, TextInputType.emailAddress),
                  const SizedBox(height: 20),

                  // Ô nhập Password
                  _buildInputField(
                      "Password", "Enter your password", _passwordController, TextInputType.visiblePassword,
                      isPassword: true,
                      obscureText: _isPasswordObscured,
                      onToggleVisibility: () => setState(() => _isPasswordObscured = !_isPasswordObscured)
                  ),

                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: const Text("Forgot Password?", style: TextStyle(color: Color(0xFFDF5110), fontSize: 16)),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // NÚT LOGIN CHÍNH
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDF5110),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(55),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 3,
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 25, height: 25, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                        : const Text('Login', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ),

                  const SizedBox(height: 25),
                  const Center(child: Text("OR", style: TextStyle(color: Colors.black38, fontWeight: FontWeight.bold))),
                  const SizedBox(height: 25),

                  // NÚT GOOGLE (Cái chúng ta vừa cấu hình SHA-1)
                  OutlinedButton(
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(55),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      side: const BorderSide(color: Color(0xFFDF5110), width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon Google lấy từ mạng để không cần thêm vào assets
                        Image.network(
                          'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
                          width: 22,
                          height: 22,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata, size: 30, color: Colors.blue),
                        ),
                        const SizedBox(width: 12),
                        const Text('Sign in with Google', style: TextStyle(fontSize: 18, color: Colors.black87, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
                      },
                      child: const Text("Don't have an Account ? Sign up", style: TextStyle(color: Colors.black54, fontSize: 16)),
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

  // Widget con để tạo ô nhập liệu cho đồng bộ
  Widget _buildInputField(String label, String hintText, TextEditingController controller, TextInputType keyboardType, {bool isPassword = false, bool obscureText = false, VoidCallback? onToggleVisibility}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 6),
          child: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87)),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(width: 1.5, color: const Color(0xFFDF5110)),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 18),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hintText,
              hintStyle: const TextStyle(color: Colors.black26),
              suffixIcon: isPassword
                  ? IconButton(
                icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                onPressed: onToggleVisibility,
              )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}