import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pet_care/data/models/product_model.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;
  final VoidCallback onAddToCart;

  const ProductDetailScreen({super.key, required this.product, required this.onAddToCart});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat("#,###", "vi_VN");

    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: Column(
        children: [
          Hero(tag: product.id, child: Image.network(product.image, height: 300, fit: BoxFit.cover)),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text("${currencyFormat.format(product.price)}đ", style: const TextStyle(fontSize: 20, color: Colors.red, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Text(product.description, style: const TextStyle(fontSize: 16, color: Colors.grey)),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
                onPressed: () {
                  onAddToCart();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã thêm vào giỏ hàng!")));
                },
                child: const Text("Thêm vào giỏ hàng", style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ),
          )
        ],
      ),
    );
  }
}