import 'package:flutter/material.dart';

class PetMartScreen extends StatefulWidget {
  const PetMartScreen({super.key});

  @override
  State<PetMartScreen> createState() => _PetMartScreenState();
}

class _PetMartScreenState extends State<PetMartScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDE9C9),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header: Tiêu đề và Giỏ hàng
            _buildHeader(context),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. Thanh tìm kiếm
                    _buildSearchBar(),

                    const SizedBox(height: 25),
                    _buildSectionTitle("My orders", hasArrow: true),
                    const SizedBox(height: 15),

                    // 3. Trạng thái đơn hàng
                    _buildOrderStatusRow(),

                    const SizedBox(height: 25),

                    // 4. Banner Discount (50% OFF)
                    _buildDiscountBanner(),

                    const SizedBox(height: 25),
                    _buildSectionTitle("Sản phẩm gợi ý"),
                    const SizedBox(height: 15),

                    // 5. Grid Sản phẩm (RecyclerView)
                    _buildProductGrid(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),


          ],
        ),
      ),
    );
  }

  // --- Widget: Header ---
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Nút Back nằm ở phía bên trái
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new, // Icon mũi tên quay lại
                color: Color(0xFF5D4037),
                size: 24,
              ),
              onPressed: () {
                // Lệnh để quay trở lại trang trước đó
                Navigator.pop(context);
              },
            ),
          ),

          // Tiêu đề trang nằm ở chính giữa
          const Text(
            'Pet Mart',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5D4037),
            ),
          ),

          // Nút Giỏ hàng (chỉ dành cho Pet Mart) nằm ở bên phải
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(Icons.shopping_cart_outlined, color: Color(0xFF5D4037)),
              onPressed: () {
                // Logic mở giỏ hàng
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- Widget: Thanh tìm kiếm ---
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(30),
      ),
      child: const TextField(
        decoration: InputDecoration(
          hintText: "Search product...",
          border: InputBorder.none,
          suffixIcon: Icon(Icons.close, size: 20),
        ),
      ),
    );
  }

  // --- Widget: Trạng thái đơn hàng ---
  Widget _buildOrderStatusRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatusItem(Icons.account_balance_wallet_outlined, "Unpaid"),
        _buildStatusItem(Icons.inventory_2_outlined, "Processing"),
        _buildStatusItem(Icons.local_shipping_outlined, "Shipping"),
        _buildStatusItem(Icons.chat_outlined, "Review"),
        _buildStatusItem(Icons.assignment_return_outlined, "Returns"),
      ],
    );
  }

  Widget _buildStatusItem(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF5D4037), size: 26),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF5D4037))),
      ],
    );
  }

  // --- Widget: Banner Giảm giá ---
  Widget _buildDiscountBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFA64444), // Màu đỏ nâu như ảnh
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text("Discount", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              Text("Happier cats and dogs!", style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
          const Text("50%\nOFF", textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFFFD54F), fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // --- Widget: Grid Sản phẩm ---
  Widget _buildProductGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 0.65,
      ),
      itemCount: 2, // Số lượng sản phẩm
      itemBuilder: (context, index) {
        return _buildProductCard(
          index == 0 ? "Nulo | 3KG" : "Feline Delights | 1KG",
          index == 0 ? "Turkey & Cod Recipe" : "Salmon & Chicken",
          index == 0 ? "assets/nulo.png" : "assets/feline.png",
        );
      },
    );
  }

  Widget _buildProductCard(String title, String desc, String img) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Center(child: Icon(Icons.fastfood, size: 80, color: Colors.orange.shade100))), // Thay bằng Image.asset
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text(desc, maxLines: 2, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF5D4037),
                  side: const BorderSide(color: Color(0xFF5D4037)),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("Buy Now", style: TextStyle(fontSize: 12)),
              ),
              const Icon(Icons.add_shopping_cart, color: Color(0xFF5D4037), size: 20),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {bool hasArrow = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF5D4037))),
        if (hasArrow) const Icon(Icons.chevron_right, color: Color(0xFF5D4037)),
      ],
    );
  }


}