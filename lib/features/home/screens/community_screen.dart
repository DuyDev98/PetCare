import 'package:flutter/material.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cộng đồng thú cưng'),
        backgroundColor: const Color(0xFFD97706),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 100, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('Tính năng cộng đồng đang được phát triển!',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
