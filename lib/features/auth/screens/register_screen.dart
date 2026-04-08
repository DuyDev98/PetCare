import 'package:flutter/material.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0x7FFFC83E), // Màu nền vàng nhạt giống Figma của bạn
      body: SingleChildScrollView(
        child: Center(
          // FittedBox sẽ giúp cái khung 586px tự co lại cho vừa khít màn hình điện thoại
          child: FittedBox(
            fit: BoxFit.contain,
            child: const Register(),
          ),
        ),
      ),
    );
  }
}

class Register extends StatelessWidget {
  const Register({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 586,
      height: 829,
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1),
          borderRadius: BorderRadius.circular(45),
        ),
        shadows: const [
          BoxShadow(
            color: Color(0x3F000000),
            blurRadius: 4,
            offset: Offset(4, 4),
            spreadRadius: 0,
          )
        ],
      ),
      child: Stack(
        children: [
          // Phần nền vàng phía trên
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: 586,
              height: 275,
              decoration: const BoxDecoration(color: Color(0x7FFFC83E)),
            ),
          ),
          // Khung trắng bo góc xanh phía dưới
          Positioned(
            left: 0,
            top: 240,
            child: Container(
              width: 586,
              height: 589,
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(width: 2.50, color: Color(0xFF006DFF)),
                  borderRadius: BorderRadius.circular(45),
                ),
              ),
            ),
          ),
          // Ảnh Logo (Đang dùng ảnh tạm)
          Positioned(
            left: 152,
            top: 43,
            child: Container(
              width: 285,
              height: 157,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage("https://placehold.co/285x157"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          // Ô nhập Tên tài khoản
          buildInputBox(top: 347),
          // Ô nhập Mật khẩu
          buildInputBox(top: 468),
          // Ô nhập Lại mật khẩu
          buildInputBox(top: 593),

          // Nút Đăng ký
          Positioned(
            left: 166,
            top: 718,
            child: Container(
              width: 254,
              height: 52,
              decoration: ShapeDecoration(
                color: const Color(0xFFFA9200),
                shape: RoundedRectangleBorder(
                  side: const BorderSide(width: 2, strokeAlign: BorderSide.strokeAlignOutside),
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Center(
                child: Text(
                  'Đăng Ký',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 25,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          // Các nhãn chữ (Labels)
          buildLabel('Tên tài khoản:', 305, 100),
          buildLabel('Mật khẩu:', 433, 94),
          buildLabel('Nhập lại mật khẩu:', 553, 101),

          // Tiêu đề chính
          const Positioned(
            left: 128,
            top: 212,
            child: Text(
              'Đăng Ký Tài Khoản',
              style: TextStyle(
                color: Colors.black,
                fontSize: 36,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // Hai cái đường kẻ trang trí ở giữa
          buildDivider(left: 422, top: 268, width: 140),
          buildDivider(left: 24, top: 268, width: 127),
        ],
      ),
    );
  }

  // Hàm bổ trợ để code ngắn gọn hơn
  Widget buildInputBox({required double top}) {
    return Positioned(
      left: 95,
      top: top,
      child: Container(
        width: 371,
        height: 52,
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            side: const BorderSide(width: 1, color: Color(0xFF906C12)),
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  Widget buildLabel(String text, double top, double left) {
    return Positioned(
      left: left,
      top: top,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 25,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget buildDivider({required double left, required double top, required double width}) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: width,
        decoration: const ShapeDecoration(
          shape: RoundedRectangleBorder(
            side: BorderSide(width: 1, strokeAlign: BorderSide.strokeAlignCenter),
          ),
        ),
      ),
    );
  }
}