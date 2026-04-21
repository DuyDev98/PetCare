import 'package:flutter/material.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            width: 440,
            height: 937,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(color: const Color(0xE0EFBF73)),
            child: Stack(
              children: [
                Positioned(
                  left: 65,
                  top: 83,
                  child: Container(
                    width: 291,
                    height: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    clipBehavior: Clip.antiAlias,
                    decoration: ShapeDecoration(
                      color: Colors.white /* Background-Default-Default */,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          width: 1,
                          strokeAlign: BorderSide.strokeAlignCenter,
                          color: const Color(0xFFD9D9D9) /* Border-Default-Default */,
                        ),
                        borderRadius: BorderRadius.circular(9999),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      spacing: 8,
                      children: [
                        SizedBox(
                          width: 235,
                          child: Text(
                            '   Search',
                            style: TextStyle(
                              color: const Color(0xFF757575) /* Text-Default-Secondary */,
                              fontSize: 16,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w400,
                              height: 1,
                            ),
                          ),
                        ),
                        Container(
                          width: 16,
                          height: 16,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(),
                          child: Stack(),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 70,
                  top: 86,
                  child: Container(width: 24, height: 24, child: Stack()),
                ),
                Positioned(
                  left: 389,
                  top: 79,
                  child: Container(
                    width: 30,
                    height: 27,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(),
                    child: Stack(),
                  ),
                ),
                Positioned(
                  left: 19,
                  top: 84,
                  child: Container(width: 24, height: 24, child: Stack()),
                ),
                Positioned(
                  left: -1,
                  top: 120,
                  child: Container(width: 440, height: 783),
                ),
                Positioned(
                  left: 1,
                  top: 171,
                  child: Container(
                    width: 438,
                    height: 732,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage("https://placehold.co/438x732"),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 438.96,
                  top: 132,
                  child: Container(
                    transform: Matrix4.identity()
                      ..translate(0.0, 0.0)
                      ..rotateZ(1.57),
                    height: 439.96,
                    decoration: ShapeDecoration(
                      image: DecorationImage(
                        image: NetworkImage("https://placehold.co/0x440"),
                        fit: BoxFit.fill,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 63,
                  top: 503,
                  child: Container(
                    width: 309,
                    height: 85,
                    decoration: ShapeDecoration(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 126,
                  top: 529,
                  child: SizedBox(
                    width: 228,
                    height: 45.63,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: ' Upcoming Reminders\n',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 13,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              height: 1.20,
                              letterSpacing: -0.26,
                            ),
                          ),
                          TextSpan(
                            text: " Today's feeding, walking, and vet visits.",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w400,
                              height: 1.20,
                              letterSpacing: -0.24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 64,
                  top: 628,
                  child: Container(
                    width: 303,
                    height: 80,
                    decoration: ShapeDecoration(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 144,
                  top: 649,
                  child: SizedBox(
                    width: 204.37,
                    height: 44.57,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(
                            text: 'Pet Health Summary\n',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 13,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              height: 1.20,
                              letterSpacing: -0.26,
                            ),
                          ),
                          const TextSpan(
                            text: 'Overview of pet wellness.',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w400,
                              height: 1.20,
                              letterSpacing: -0.24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 66,
                  top: 757,
                  child: Container(
                    width: 303,
                    height: 80,
                    decoration: ShapeDecoration(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 143.74,
                  top: 772,
                  child: SizedBox(
                    width: 198.98,
                    height: 62.31,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(
                            text: 'Pet Care Tips\n',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 13,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              height: 1.20,
                              letterSpacing: -0.26,
                            ),
                          ),
                          const TextSpan(
                            text: 'Daily advice on pet health, training, and nutrition.',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 13,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w400,
                              height: 1.20,
                              letterSpacing: -0.26,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 176,
                  top: 163,
                  child: Container(
                    width: 82,
                    height: 78,
                    decoration: const ShapeDecoration(
                      color: Colors.white,
                      shape: OvalBorder(),
                    ),
                  ),
                ),
                Positioned(
                  left: 193,
                  top: 241,
                  child: const Text(
                    'Mochi',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontFamily: 'Port Lligat Slab',
                      fontWeight: FontWeight.w400,
                      height: 1.20,
                      letterSpacing: -0.40,
                    ),
                  ),
                ),
                Positioned(
                  left: 35,
                  top: 262,
                  child: const SizedBox(
                    width: 393.18,
                    height: 188,
                    child: Text(
                      'Taking Care of Your Smart Pet with Love!',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 24,
                        fontFamily: 'Orelega One',
                        fontWeight: FontWeight.w400,
                        letterSpacing: 1.20,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 36,
                  top: 327,
                  child: const SizedBox(
                    width: 314,
                    height: 58,
                    child: Text(
                      'A pet’s love is unconditional—nurture it with daily care and affection.',
                      style: TextStyle(
                        color: Color(0xFF181817),
                        fontSize: 19,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w400,
                        height: 1.38,
                        letterSpacing: 0.95,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 38,
                  top: 417,
                  child: Container(
                    width: 174.62,
                    height: 48.67,
                    decoration: ShapeDecoration(
                      color: const Color(0xFFF2781C),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                    ),
                  ),
                ),
                Positioned(
                  left: 56,
                  top: 432,
                  child: const SizedBox(
                    width: 147.97,
                    height: 9.93,
                    child: Text(
                      'Explore More',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Glades Bold',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 1,
                  top: 893,
                  child: Container(
                    width: 439,
                    height: 72,
                    decoration: const BoxDecoration(color: Color(0xFFEFA973)),
                  ),
                ),
                Positioned(
                  left: 173,
                  top: 895,
                  child: Container(
                    width: 91,
                    height: 60,
                    clipBehavior: Clip.antiAlias,
                    decoration: const BoxDecoration(),
                    child: Stack(
                      children: [
                        Positioned(
                          left: 23,
                          top: 10,
                          child: Container(width: 36, height: 35, child: Stack()),
                        ),
                        const Positioned(
                          left: 23,
                          top: 40,
                          child: Text(
                            'Service',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontFamily: 'SF Pro',
                              fontWeight: FontWeight.w600,
                              height: 1.67,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 322,
                  top: 895,
                  child: Container(
                    width: 88,
                    height: 60,
                    clipBehavior: Clip.antiAlias,
                    decoration: const BoxDecoration(),
                    child: Stack(
                      children: [
                        Positioned(
                          left: 24,
                          top: 8,
                          child: Container(width: 40, height: 37, child: Stack()),
                        ),
                        const Positioned(
                          left: 34,
                          top: 39,
                          child: Text(
                            'Pet',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontFamily: 'SF Pro',
                              fontWeight: FontWeight.w600,
                              height: 1.67,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  top: 898,
                  child: Container(
                    width: 92,
                    height: 57,
                    clipBehavior: Clip.antiAlias,
                    decoration: const BoxDecoration(),
                    child: Stack(
                      children: [
                        Positioned(
                          left: 26,
                          top: 5,
                          child: Container(
                            width: 39,
                            height: 38,
                            clipBehavior: Clip.antiAlias,
                            decoration: const BoxDecoration(),
                            child: Stack(),
                          ),
                        ),
                        const Positioned(
                          left: 29,
                          top: 37,
                          child: Text(
                            'Home',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontFamily: 'SF Pro',
                              fontWeight: FontWeight.w600,
                              height: 1.67,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 186,
                  top: 172,
                  child: Container(
                    width: 62,
                    height: 62,
                    decoration: const ShapeDecoration(
                      color: Color(0xFF090909),
                      shape: OvalBorder(),
                    ),
                  ),
                ),
                Positioned(
                  left: 196,
                  top: 181,
                  child: Container(width: 45, height: 43, child: Stack()),
                ),
                Positioned(
                  left: 0,
                  top: 9,
                  child: Container(
                    width: 440,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      spacing: 134,
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.only(left: 16, right: 6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              spacing: 10,
                              children: const [
                                Text(
                                  '9:41',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontFamily: 'SF Pro',
                                    fontWeight: FontWeight.w600,
                                    height: 1.29,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(width: 124, height: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.only(left: 6, right: 16),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              spacing: 7,
                              children: [
                                Opacity(
                                  opacity: 0.35,
                                  child: Container(
                                    width: 25,
                                    height: 13,
                                    decoration: ShapeDecoration(
                                      shape: RoundedRectangleBorder(
                                        side: const BorderSide(width: 1, color: Colors.white),
                                        borderRadius: BorderRadius.circular(4.30),
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 21,
                                  height: 9,
                                  decoration: ShapeDecoration(
                                    color: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(2.50),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}