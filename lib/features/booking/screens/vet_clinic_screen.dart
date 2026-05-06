import 'package:flutter/material.dart';
import '../../../core/widgets/custom_bottom_nav_bar.dart';

void main() {
  runApp(const PetClinicApp());
}

class PetClinicApp extends StatelessWidget {
  const PetClinicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: const Color(0xFFF9F9F9),
        primaryColor: const Color(0xFFF0A500),
      ),
      home: const ClinicHomePage(),
    );
  }
}

class ClinicHomePage extends StatefulWidget {
  const ClinicHomePage({super.key});

  @override
  State<ClinicHomePage> createState() => _ClinicHomePageState();
}

class _ClinicHomePageState extends State<ClinicHomePage> {
  int _currentIndex = 3; // Mặc định chọn 'Khám bệnh' theo CustomBottomNavBar

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderSection(),
            const SizedBox(height: 16),
            _buildFilterChips(),
            const SizedBox(height: 24),
            _buildFeaturedServices(),
            const SizedBox(height: 24),
            _buildNearbyClinics(),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  // 1. Phần Header (Gradient & Tìm kiếm)
  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFC97A00), Color(0xFFF0A500), Color(0xFFFB923C)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Xin chào,',
                    style: TextStyle(color: Color(0xFFFEF9C3), fontSize: 14),
                  ),
                  Text(
                    'An Nguyễn 👋',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Stack(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: const Icon(Icons.notifications, color: Colors.white),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Tìm phòng khám thú y',
            style: TextStyle(
                color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Chăm sóc tốt nhất cho người bạn nhỏ của bạn',
            style: TextStyle(color: Color(0xFFFEF9C3), fontSize: 14),
          ),
          const SizedBox(height: 20),
          // Thanh tìm kiếm
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.grey),
                const SizedBox(width: 10),
                const Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Tìm phòng khám, bác sĩ...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC97A00),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.tune, color: Colors.white, size: 16),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2. Danh sách Filter (Gần nhất, Đang mở...)
  Widget _buildFilterChips() {
    final filters = ['Gần nhất', 'Đang mở', 'Đánh giá cao', 'Cấp cứu 24/7'];
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          bool isSelected = index == 0;
          return Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFF0A500) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: isSelected ? const Color(0xFFF0A500) : Colors.grey.shade300),
            ),
            child: Center(
              child: Text(
                filters[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // 3. Dịch vụ nổi bật (Grid)
  Widget _buildFeaturedServices() {
    final services = [
      {'title': 'Khám tổng quát', 'color': 0xFFDCFCE7, 'icon': Icons.medical_services},
      {'title': 'Tiêm phòng', 'color': 0xFFDBEAFE, 'icon': Icons.vaccines},
      {'title': 'Phẫu thuật', 'color': 0xFFFCE7F3, 'icon': Icons.content_cut},
      {'title': 'Cấp cứu', 'color': 0xFFFEE2E2, 'icon': Icons.local_hospital},
      {'title': 'Xét nghiệm', 'color': 0xFFFEF3C7, 'icon': Icons.science},
      {'title': 'Truyền dịch', 'color': 0xFFEDE9FE, 'icon': Icons.bloodtype},
    ];

    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          const Text(
          'Dịch vụ nổi bật',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemCount: services.length,
            itemBuilder: (context, index) {
              return Container(
                  decoration: BoxDecoration(
                    color: Color(services[index]['color'] as int),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                  Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                    child: Icon(
                      services[index]['icon'] as IconData,
                      color: Colors.black87,
                      size: 24,
                    ),
                  ),
                        const SizedBox(height: 8),
                        Text(
                          services[index]['title'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                  ),
              );
            },
        ),
          ],
        ),
    );
  }

  // 4. Danh sách phòng khám gần đây
  Widget _buildNearbyClinics() {
    // Dữ liệu mẫu
    final clinics = [
      {
        'name': 'Phòng khám Thú y PetCare',
        'address': '123 Đường ABC, Quận 1, TP.HCM',
        'distance': '1.2 km',
        'rating': 4.8,
        'isOpen': true,
        'image': 'https://images.unsplash.com/photo-1596272875729-41918a7c293a?auto=format&fit=crop&w=200&q=80'
      },
      {
        'name': 'Bệnh viện Thú y Quốc tế',
        'address': '456 Đường XYZ, Quận 3, TP.HCM',
        'distance': '2.5 km',
        'rating': 4.5,
        'isOpen': false,
        'image': 'https://images.unsplash.com/photo-1583337130417-3346a1be7dee?auto=format&fit=crop&w=200&q=80'
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Phòng khám gần bạn',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'Xem tất cả',
                  style: TextStyle(color: Color(0xFFC97A00), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Danh sách sử dụng Widget dùng chung ClinicCard
          ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: clinics.length,
            itemBuilder: (context, index) {
              final clinic = clinics[index];
              return ClinicCard(
                name: clinic['name'] as String,
                address: clinic['address'] as String,
                distance: clinic['distance'] as String,
                rating: clinic['rating'] as double,
                isOpen: clinic['isOpen'] as bool,
                imageUrl: clinic['image'] as String,
              );
            },
          ),
          const SizedBox(height: 20), // Padding đáy
        ],
      ),
    );
  }
}

// ============================================================================
// WIDGET DÙNG CHUNG (REUSABLE COMPONENTS)
// ============================================================================

/// Card hiển thị thông tin Phòng khám, có thể tái sử dụng ở trang Tìm kiếm, Yêu thích...
class ClinicCard extends StatelessWidget {
  final String name;
  final String address;
  final String distance;
  final double rating;
  final bool isOpen;
  final String imageUrl;

  const ClinicCard({
    super.key,
    required this.name,
    required this.address,
    required this.distance,
    required this.rating,
    required this.isOpen,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ảnh phòng khám
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              imageUrl,
              width: 90,
              height: 90,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 90,
                height: 90,
                color: Colors.grey.shade200,
                child: const Icon(Icons.local_hospital, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Thông tin phòng khám (Responsive với Expanded)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 2, // UX: Cho phép rớt dòng nếu tên quá dài
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 14),
                          const SizedBox(width: 2),
                          Text(
                            rating.toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  address,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Status Badge (Đang mở / Đóng cửa)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isOpen ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isOpen ? 'Đang mở' : 'Đóng cửa',
                        style: TextStyle(
                          color: isOpen ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Khoảng cách
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, color: Colors.grey.shade400, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          distance,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
