import 'package:appfastfood/views/screens/admin/admin_product_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:appfastfood/service/api_service.dart';
import 'package:appfastfood/models/products.dart';
import '../../widget/admin_side_menu.dart';

class AdminProductScreen extends StatefulWidget {
  const AdminProductScreen({super.key});

  @override
  State<AdminProductScreen> createState() => _AdminProductScreenState();
}

class _AdminProductScreenState extends State<AdminProductScreen> {
  final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  List<Product> _products = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _statusFilter = 'all'; // 'all', 'active', 'inactive'

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  // Hàm load sản phẩm từ API (Dùng hàm getAdminProducts để lấy cả sản phẩm ẩn)
  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await ApiService().getAdminProducts();
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      print("❌ Lỗi load sản phẩm: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteProduct(int productId) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: const Text("Bạn có chắc muốn xóa sản phẩm này?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Xóa", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      bool success = await ApiService().deleteProduct(productId);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Đã xóa sản phẩm"), backgroundColor: Colors.green),
          );
        }
        await _loadProducts(); // Load lại danh sách sau khi xóa
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Lỗi khi xóa sản phẩm"), backgroundColor: Colors.red),
          );
        }
        setState(() => _isLoading = false);
      }
    }
  }

  List<Product> get _filteredProducts {
    List<Product> result = _products;
    
    // 1. Lọc theo tìm kiếm
    if (_searchQuery.isNotEmpty) {
      result = result.where((product) {
        return product.name.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    // 2. Lọc theo trạng thái
    if (_statusFilter == 'active') {
      result = result.where((product) => product.status == 1).toList();
    } else if (_statusFilter == 'inactive') {
      result = result.where((product) => product.status == 0).toList();
    }
    
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      endDrawer: const AdminSideMenu(),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCD057),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Quản lý sản phẩm",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.white, size: 30),
            onPressed: () {
              // TODO: Thêm chức năng thêm sản phẩm
            },
          ),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white, size: 30),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProducts,
        child: Column(
          children: [
            // Tìm kiếm và bộ lọc
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Ô tìm kiếm
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm sản phẩm...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Bộ lọc trạng thái
                  Row(
                    children: [
                      const Text(
                        'Lọc theo:',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 12),
                      DropdownButton<String>(
                        value: _statusFilter,
                        items: const [
                          DropdownMenuItem(
                            value: 'all',
                            child: Text('Tất cả trạng thái'),
                          ),
                          DropdownMenuItem(
                            value: 'active',
                            child: Text('Đang hiển thị'),
                          ),
                          DropdownMenuItem(
                            value: 'inactive',
                            child: Text('Đã ẩn'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _statusFilter = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Thống kê
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard(
                    'Tổng sản phẩm',
                    _products.length.toString(),
                    Colors.blue,
                  ),
                  _buildStatCard(
                    'Đang hiển thị',
                    _products.where((p) => p.status == 1).length.toString(),
                    Colors.green,
                  ),
                  _buildStatCard(
                    'Đã ẩn',
                    _products.where((p) => p.status == 0).length.toString(),
                    Colors.grey,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Danh sách sản phẩm
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredProducts.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.fastfood_outlined,
                                size: 60,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 12),
                              Text(
                                "Không tìm thấy sản phẩm",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 20),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = _filteredProducts[index];
                            final bool isHidden = product.status == 0;

                            // Bọc trong Opacity để làm mờ nếu sản phẩm bị ẩn
                            return Opacity(
                              opacity: isHidden ? 0.6 : 1.0, 
                              child: Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    radius: 30,
                                    backgroundColor: Colors.grey[200],
                                    backgroundImage: product.imageUrl.isNotEmpty
                                        ? NetworkImage(product.imageUrl)
                                        : null,
                                    child: product.imageUrl.isEmpty
                                        ? const Icon(Icons.fastfood,
                                            color: Colors.grey)
                                        : null,
                                  ),
                                  title: Text(
                                    product.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 6),
                                      // Mô tả
                                      Text(
                                        product.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      // Giá và Trạng thái
                                      Row(
                                        children: [
                                          Text(
                                            fmt.format(product.price),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const Spacer(),
                                          // Badge hiển thị trạng thái
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: product.status == 1
                                                  ? Colors.green.withOpacity(0.1)
                                                  : Colors.grey.withOpacity(0.2), // Màu nền badge
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: product.status == 1
                                                    ? Colors.green
                                                    : Colors.grey,
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  product.status == 1
                                                      ? Icons.visibility
                                                      : Icons.visibility_off,
                                                  size: 12,
                                                  color: product.status == 1
                                                      ? Colors.green
                                                      : Colors.grey,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  product.status == 1
                                                      ? 'Hiển thị'
                                                      : 'Đã ẩn',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: product.status == 1
                                                        ? Colors.green
                                                        : Colors.grey, // Chữ xám đậm
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Danh mục: ${product.categoryName}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Nút Chỉnh sửa
                                      IconButton(
                                        icon: Icon(
                                          Icons.edit,
                                          color: Colors.blue[700],
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  AdminProductDetailScreen(
                                                product: product,
                                                onUpdated: _loadProducts, // Quan trọng: Load lại khi quay về
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      // Nút Xóa
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () =>
                                            _deleteProduct(product.id),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget để tạo thẻ thống kê
  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}