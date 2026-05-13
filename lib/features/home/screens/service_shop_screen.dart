import 'package:flutter/material.dart';
import 'package:pet_care/data/mock_data.dart';
import 'package:pet_care/data/models/models.dart';
import 'package:pet_care/core/widgets/product_card.dart';
import 'package:pet_care/data/models/product_model.dart';
class ServiceShopScreen extends StatefulWidget {
  const ServiceShopScreen({super.key});

  @override
  State<ServiceShopScreen> createState() => _ServiceShopScreenState();
}

class _ServiceShopScreenState extends State<ServiceShopScreen> {
  String selectedCategory = 'Tất cả';
  int cartCount = 0;
  List<Product> filteredProducts = mockProducts;

  void filterCategory(String category) {
    setState(() {
      selectedCategory = category;
      if (category == 'Tất cả') {
        filteredProducts = mockProducts;
      } else {
        filteredProducts = mockProducts.where((p) => p.category == category).toList();
      }
    });
  }

  void addToCart() {
    setState(() => cartCount++);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Icon(Icons.arrow_back_ios, color: Colors.black),
        title: const Text("Dịch vụ & Mua sắm", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black)),
              if (cartCount > 0)
                Positioned(
                  right: 8, top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    // Thay BoxBoxShape thành BoxShape
                    decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                    child: Text("$cartCount", style: const TextStyle(color: Colors.white, fontSize: 10)),
                  ),
                )
            ],
          )
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Tìm kiếm sản phẩm...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
            ),
          ),
          // Categories
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: ['Tất cả', 'Thức ăn', 'Đồ chơi', 'Phụ kiện'].map((cat) {
                bool isSelected = selectedCategory == cat;
                return GestureDetector(
                  onTap: () => filterCategory(cat),
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.orangeAccent : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Text(cat, style: TextStyle(color: isSelected ? Colors.white : Colors.black54, fontWeight: FontWeight.bold)),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          // Product Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.7,
              ),
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) => ProductCard(
                product: filteredProducts[index],
                onAddToCart: addToCart,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 1,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "Trang chủ"),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: "Dịch vụ"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: "Lịch"),
          BottomNavigationBarItem(icon: Icon(Icons.medical_services_outlined), label: "Khám bệnh"),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: "Cộng đồng"),
        ],
      ),
    );
  }
}

