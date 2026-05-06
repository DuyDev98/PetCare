import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../data/services/pet_service.dart';

class AuthController extends ChangeNotifier {
  final PetService _petService = PetService();
  bool _isLoading = false;
  bool _isGoogleInit = false;

  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Logic Đăng nhập Email
  Future<String?> signIn(String email, String password) async {
    _setLoading(true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null; 
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-credential') return "Email hoặc mật khẩu không đúng.";
      return "Lỗi đăng nhập: ${e.message}";
    } finally {
      _setLoading(false);
    }
  }

  // Logic Đăng ký Email
  Future<String?> signUp(String email, String password, String username, {String role = 'user'}) async {
    _setLoading(true);
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(username);
        // FIX: Đã đổi sang named parameters trong PetService
        await _petService.saveUserInfo(
          role: role, 
          displayName: username,
        );
      }
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') return "Email này đã được đăng ký!";
      return e.message;
    } finally {
      _setLoading(false);
    }
  }

  // Logic Đăng nhập Google
  Future<String?> signInWithGoogle() async {
    _setLoading(true);
    try {
      if (!_isGoogleInit) {
        await GoogleSignIn.instance.initialize(
          serverClientId: dotenv.env['GOOGLE_SERVER_CLIENT_ID'],
        );
        _isGoogleInit = true;
      }

      final GoogleSignInAccount? googleUser = await GoogleSignIn.instance.authenticate();
      if (googleUser == null) {
        _setLoading(false);
        return "Hủy đăng nhập";
      }

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(idToken: googleAuth.idToken);

      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      if (userCredential.user != null) {
        final existingRole = await _petService.getUserRole();
        if (existingRole == null) {
          // FIX: Đã đổi sang named parameters
          await _petService.saveUserInfo(role: 'user');
        }
      }
      return null;
    } catch (e) {
      return "Lỗi Google: Kiểm tra cấu hình Client ID.";
    } finally {
      _setLoading(false);
    }
  }
}
