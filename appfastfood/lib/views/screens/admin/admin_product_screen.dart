import 'package:appfastfood/views/screens/admin/admin_home_screen.dart';
import 'package:appfastfood/views/screens/admin/admin_product_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:appfastfood/service/api_service.dart';
import 'package:appfastfood/models/products.dart';

class AdminProductScreen extends StatefulWidget {
  const AdminProductScreen({super.key});

  @override
  State<AdminProductScreen> createState() => _AdminProductScreenState();
}

class _AdminProductScreenState extends State<AdminProductScreen> {
  final ApiService _apiService = ApiService();
  final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  List<Product> _products = [];
  bool _isLoading = true;
  int _selectedCategoryId = 0;
  String _statusFilter = 'all';

  final List<Map<String, dynamic>> _categories = [
    {'id': 0, 'name': 'Tất cả'},
    {'id': 1, 'name': 'Burger'},
    {'id': 2, 'name': 'Pizza'},
    {'id': 3, 'name': 'Mì Ý'},
    {'id': 4, 'name': 'Cơm'},
    {'id': 5, 'name': 'Gà Rán'},
    {'id': 6, 'name': 'Đồ uống'},
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await _apiService.getAdminProducts(
        status: _statusFilter,
        categoryId: _selectedCategoryId,
      );
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      print("❌ Lỗi load products: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFFFCD057),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminHomePageScreen(),
                ),
              );
            }
          },
        ),
        title: const Text(
          "Quản Lý Thực Đơn",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.green, size: 30),
            onPressed: () {
              // Chuyển sang trang thêm mới (Product rỗng)
              // ĐÃ BỎ average_rating
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AdminProductDetailScreen(
                    product: Product(
                      id: 0,
                      name: '',
                      description: '',
                      price: 0,
                      imageUrl: '',
                      categoryId: 1,
                      categoryName: '',
                      status: 1,
                      // average_rating đã được bỏ
                    ),
                    onUpdated: _loadProducts,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          // 1. Danh mục ngang
          Container(
            height: 50,
            margin: const EdgeInsets.symmetric(vertical: 10),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategoryId == cat['id'];
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedCategoryId = cat['id']);
                    _loadProducts();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFFB039)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Text(
                      cat['name'],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 2. Lọc trạng thái
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text(
                  "Trạng thái: ",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                _buildStatusChip("Tất cả", "all"),
                const SizedBox(width: 8),
                _buildStatusChip("Đang bán", "active", Colors.green),
                const SizedBox(width: 8),
                _buildStatusChip("Đã ẩn", "inactive", Colors.red),
              ],
            ),
          ),

          const Divider(),

          // 3. Grid sản phẩm
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadProducts,
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.7,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                      itemCount: _products.length,
                      itemBuilder: (context, index) {
                        return _buildProductCard(_products[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(
    String label,
    String value, [
    Color color = Colors.blue,
  ]) {
    final isSelected = _statusFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() => _statusFilter = value);
        _loadProducts();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isSelected ? color : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    bool isHidden = product.status == 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ảnh sản phẩm
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(15),
                  ),
                  child: Opacity(
                    opacity: isHidden ? 0.5 : 1.0,
                    child: ColorFiltered(
                      colorFilter: isHidden
                          ? const ColorFilter.mode(
                              Colors.grey,
                              BlendMode.saturation,
                            )
                          : const ColorFilter.mode(
                              Colors.transparent,
                              BlendMode.multiply,
                            ),
                      child: Image.network(
                        product.imageUrl,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image),
                        ),
                      ),
                    ),
                  ),
                ),
                // Badge ID
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "#${product.id}",
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
                // if (isHidden)
                //   const Center(
                //     child: Container(
                //       padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                //       color: Colors.black87,
                //       child: Text("ĐÃ ẨN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                //     ),
                //   ),
              ],
            ),
          ),

          // Thông tin
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isHidden ? Colors.grey : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      fmt.format(product.price),
                      style: TextStyle(
                        color: isHidden ? Colors.grey : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    Row(
                      children: [
                        Icon(
                          isHidden ? Icons.visibility_off : Icons.visibility,
                          size: 20,
                          color: isHidden ? Colors.grey : Colors.green,
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AdminProductDetailScreen(
                                  product: product,
                                  onUpdated: _loadProducts,
                                ),
                              ),
                            );
                          },
                          child: const Icon(
                            Icons.edit,
                            size: 20,
                            color: Colors.blue,
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
