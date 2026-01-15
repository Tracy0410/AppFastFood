import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:appfastfood/service/api_service.dart';
import '../../widget/admin_side_menu.dart';
import 'admin_order_detail_screen.dart'; // Thêm import này

class AdminCustomerScreen extends StatefulWidget {
  const AdminCustomerScreen({super.key});

  @override
  State<AdminCustomerScreen> createState() => _AdminCustomerScreenState();
}

class _AdminCustomerScreenState extends State<AdminCustomerScreen> {
  List<dynamic> _customers = [];
  List<dynamic> _orders = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final orders = await ApiService().getAdminOrders('ALL');
      
      final Map<int, Map<String, dynamic>> customerMap = {};
      
      for (var order in orders) {
        final userId = order['user_id'];
        if (userId != null) {
          if (!customerMap.containsKey(userId)) {
            customerMap[userId] = {
              'user_id': userId,
              'fullname': order['fullname'] ?? 'Khách hàng',
              'email': order['email'] ?? 'N/A',
              'phone': order['phone'] ?? 'N/A',
              'order_count': 1,
              'total_spent': safeParseDouble(order['total_amount']),
            };
          } else {
            customerMap[userId]!['order_count']++;
            customerMap[userId]!['total_spent'] += safeParseDouble(order['total_amount']);
          }
        }
      }
      
      setState(() {
        _customers = customerMap.values.toList();
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      print("❌ Lỗi load khách hàng: $e");
      setState(() => _isLoading = false);
    }
  }

  double safeParseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      String cleaned = value.replaceAll(RegExp(r'[^0-9.-]'), '');
      return double.tryParse(cleaned) ?? 0.0;
    }
    return 0.0;
  }

  List<dynamic> get _filteredCustomers {
    if (_searchQuery.isEmpty) return _customers;
    return _customers.where((customer) {
      final name = customer['fullname']?.toString().toLowerCase() ?? '';
      final email = customer['email']?.toString().toLowerCase() ?? '';
      final phone = customer['phone']?.toString().toLowerCase() ?? '';
      return name.contains(_searchQuery.toLowerCase()) ||
          email.contains(_searchQuery.toLowerCase()) ||
          phone.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  List<dynamic> _getCustomerOrders(int userId) {
    // Sắp xếp đơn hàng theo thời gian mới nhất
    final customerOrders = _orders.where((order) => order['user_id'] == userId).toList();
    customerOrders.sort((a, b) {
      final dateA = DateTime.parse(a['created_at'] ?? '1970-01-01');
      final dateB = DateTime.parse(b['created_at'] ?? '1970-01-01');
      return dateB.compareTo(dateA); // Sắp xếp giảm dần (mới nhất lên đầu)
    });
    return customerOrders;
  }

  void _viewOrderDetails(Map<String, dynamic> order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminOrderDetailScreen(
          order: order,
          onStatusUpdated: () {
            // Khi trạng thái đơn hàng thay đổi, load lại dữ liệu
            _loadData();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    
    return Scaffold(
      backgroundColor: Colors.white,
      endDrawer: const AdminSideMenu(),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCD057),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Quản lý khách hàng",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
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
        child: Column(
          children: [
            // Tìm kiếm
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm khách hàng...',
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
            ),

            // Thống kê
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(
                    label: Text('Tổng: ${_customers.length} KH'),
                    backgroundColor: Colors.blue[50],
                  ),
                  Chip(
                    label: Text('${_orders.length} đơn hàng'),
                    backgroundColor: Colors.green[50],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Danh sách khách hàng
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredCustomers.isEmpty
                      ? const Center(
                          child: Text("Không tìm thấy khách hàng"),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 20),
                          itemCount: _filteredCustomers.length,
                          itemBuilder: (context, index) {
                            final customer = _filteredCustomers[index];
                            final customerOrders = _getCustomerOrders(customer['user_id']);
                            
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              elevation: 2,
                              child: ExpansionTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.amber[100],
                                  child: Text(
                                    customer['fullname'][0],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  customer['fullname'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(customer['email']),
                                    Text(customer['phone']),
                                  ],
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "📊 Thống kê mua hàng",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            _buildStatItem(
                                              "Số đơn",
                                              "${customer['order_count']}",
                                              Icons.shopping_bag,
                                              Colors.blue,
                                            ),
                                            _buildStatItem(
                                              "Tổng chi",
                                              fmt.format(safeParseDouble(customer['total_spent'])),
                                              Icons.attach_money,
                                              Colors.green,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 15),
                                        if (customerOrders.isNotEmpty) ...[
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                "📋 Tất cả đơn hàng",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                "(${customerOrders.length} đơn)",
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          // Container với chiều cao cố định để cuộn
                                          Container(
                                            height: customerOrders.length <= 3 
                                                ? customerOrders.length * 60.0 // Chiều cao tự động nếu ít
                                                : 200.0, // Chiều cao cố định nếu nhiều
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.grey.shade200),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: ListView.builder(
                                              physics: const AlwaysScrollableScrollPhysics(),
                                              shrinkWrap: true,
                                              itemCount: customerOrders.length,
                                              itemBuilder: (context, orderIndex) {
                                                final order = customerOrders[orderIndex];
                                                final orderDate = DateTime.parse(order['created_at'] ?? DateTime.now().toString());
                                                final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
                                                
                                                return InkWell(
                                                  onTap: () {
                                                    _viewOrderDetails(order);
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      border: orderIndex < customerOrders.length - 1
                                                          ?  Border(bottom: BorderSide(color: Colors.grey.shade200))
                                                          : null,
                                                    ),
                                                    child: ListTile(
                                                      dense: true,
                                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                                      leading: Container(
                                                        width: 30,
                                                        height: 30,
                                                        decoration: BoxDecoration(
                                                          color: _getStatusColor(order['order_status']).withOpacity(0.1),
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        alignment: Alignment.center,
                                                        child: Icon(
                                                          _getStatusIcon(order['order_status']),
                                                          size: 16,
                                                          color: _getStatusColor(order['order_status']),
                                                        ),
                                                      ),
                                                      title: Text(
                                                        "Đơn #${order['order_id']}",
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                      subtitle: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            dateFormat.format(orderDate),
                                                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                                                          ),
                                                          const SizedBox(height: 2),
                                                          Text(
                                                            fmt.format(safeParseDouble(order['total_amount'])),
                                                            style: const TextStyle(
                                                              fontSize: 13,
                                                              fontWeight: FontWeight.bold,
                                                              color: Colors.red,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      trailing: Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: _getStatusColor(order['order_status']).withOpacity(0.1),
                                                          borderRadius: BorderRadius.circular(12),
                                                        ),
                                                        child: Text(
                                                          _getStatusText(order['order_status']),
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.bold,
                                                            color: _getStatusColor(order['order_status']),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ] else ...[
                                          const Padding(
                                            padding: EdgeInsets.symmetric(vertical: 16),
                                            child: Text(
                                              "Khách hàng chưa có đơn hàng nào",
                                              style: TextStyle(
                                                color: Colors.grey,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 15),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                icon: const Icon(Icons.email, size: 18),
                                                label: const Text("Gửi email"),
                                                onPressed: () {
                                                  _sendEmail(customer['email']);
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                icon: const Icon(Icons.phone, size: 18),
                                                label: const Text("Gọi điện"),
                                                onPressed: () {
                                                  _makePhoneCall(customer['phone']);
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
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

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'PENDING': return 'Chờ xác nhận';
      case 'PROCESSING': return 'Đang xử lý';
      case 'SHIPPED': return 'Đang giao';
      case 'DELIVERED': return 'Đã giao';
      case 'CANCELLED': return 'Đã hủy';
      default: return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING': return Colors.orange;
      case 'PROCESSING': return Colors.blue;
      case 'SHIPPED': return Colors.purple;
      case 'DELIVERED': return Colors.green;
      case 'CANCELLED': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'PENDING': return Icons.pending;
      case 'PROCESSING': return Icons.local_shipping;
      case 'SHIPPED': return Icons.delivery_dining;
      case 'DELIVERED': return Icons.check_circle;
      case 'CANCELLED': return Icons.cancel;
      default: return Icons.question_mark;
    }
  }

  void _sendEmail(String email) {
    // TODO: Triển khai chức năng gửi email
    print("Gửi email đến: $email");
  }

  void _makePhoneCall(String phone) {
    // TODO: Triển khai chức năng gọi điện
    print("Gọi điện đến: $phone");
  }
}