import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'package:appfastfood/service/api_service.dart';
import '../../widget/admin_side_menu.dart';
import 'admin_order_screen.dart';

class AdminHomePageScreen extends StatefulWidget {
  const AdminHomePageScreen({super.key});

  @override
  State<AdminHomePageScreen> createState() => _AdminHomePageScreenState();
}

class _AdminHomePageScreenState extends State<AdminHomePageScreen> {
  double safeParseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      // Xử lý nếu có dấu chấm/thập phân
      String cleaned = value.replaceAll(RegExp(r'[^0-9.-]'), '');
      return double.tryParse(cleaned) ?? 0.0;
    }
    return 0.0;
  }
  // Biến state để lưu thống kê
  Map<String, dynamic> stats = {'revenue': 0, 'total_orders': 0};
  
  List<dynamic> recentOrders = []; 
  
  bool isLoading = true;

  // Định dạng tiền tệ VNĐ
  final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Hàm tải cả thống kê và đơn hàng gần nhất
  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final orders = await ApiService().getAdminOrders('ALL'); 
      
      // Tính toán thống kê từ danh sách đơn hàng
      double totalRevenue = 0;
      int totalOrders = orders.length;
      
      // Tính tổng doanh thu từ tất cả đơn hàng (chỉ tính đơn đã giao DELIVERED)
      for (var order in orders) {
        if (order['order_status'] == 'DELIVERED') {
          totalRevenue += safeParseDouble(order['total_amount']);
        }
      }
      
      setState(() {
        stats = {
          'revenue': totalRevenue,
          'total_orders': totalOrders
        };
        recentOrders = orders;
        isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
      print("Lỗi tải dữ liệu Dashboard: $e");
    }
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
          "Yummy Quick Admin",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white, size: 30),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // PHẦN THỐNG KÊ TỔNG QUAN
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatCard(
                    "Doanh thu", 
                    "Tổng doanh thu", 
                    fmt.format(safeParseDouble(stats['revenue'])), 
                    Icons.attach_money, 
                    Colors.green
                  ),
                  _buildStatCard(
                    "Số đơn", 
                    "Tổng số đơn", 
                    stats['total_orders'].toString(), 
                    Icons.shopping_bag, 
                    Colors.blue
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // PHẦN TIÊU ĐỀ DANH SÁCH
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Các đơn gần nhất",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminOrderScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        "Xem tất cả →",
                        style: TextStyle(
                          color: Colors.redAccent, 
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // DANH SÁCH ĐƠN HÀNG
              isLoading 
                ? const Center(child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ))
                : recentOrders.isEmpty 
                  ? const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text("Chưa có đơn hàng nào"),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      // Chỉ lấy tối đa 5 đơn
                      itemCount: recentOrders.length > 5 ? 5 : recentOrders.length, 
                      itemBuilder: (context, index) {
                        final order = recentOrders[index];
                        return _buildOrderItem(
                          "#${order['order_id']}", 
                          order['fullname'] ?? "Khách hàng", 
                          fmt.format(safeParseDouble(order['total_amount'])), 
                          _getStatusText(order['order_status']), 
                          _getStatusColor(order['order_status'])
                        );
                      },
                    ),
                const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Hàm hỗ trợ lấy text trạng thái tiếng Việt
  String _getStatusText(String? status) {
    // Thêm dấu ? và check null để an toàn
    switch (status) {
      case 'PENDING': return "Mới đặt";
      case 'PROCESSING': return "Đang làm";
      case 'SHIPPED': return "Đang giao";
      case 'DELIVERED': return "Thành công";
      case 'CANCELLED': return "Đã hủy";
      default: return status ?? "Chờ xử lý";
    }
  }

  // Hàm hỗ trợ lấy màu trạng thái
  Color _getStatusColor(String? status) {
    switch (status) {
      case 'PENDING': return Colors.blue;
      case 'PROCESSING': return Colors.orange;
      case 'SHIPPED': return Colors.indigo;
      case 'DELIVERED': return Colors.green;
      case 'CANCELLED': return Colors.red;
      default: return Colors.grey;
    }
  }

  Widget _buildStatCard(String topTitle, String subTitle, String value, IconData icon, Color color) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.42,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05), 
            blurRadius: 10,
            offset: const Offset(0, 5)
          )
        ],
      ),
      child: Column(
        children: [
          Text(topTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 5),
          Text(subTitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 5),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildOrderItem(String id, String name, String price, String status, Color statusColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
             color: Colors.grey.withOpacity(0.1),
             blurRadius: 4,
             offset: const Offset(0, 2)
          )
        ]
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(name, style: const TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(price, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  status,
                  style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
