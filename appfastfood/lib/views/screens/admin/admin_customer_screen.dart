import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:appfastfood/service/api_service.dart';
import '../../widget/admin_side_menu.dart';

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
      // Lấy tất cả đơn hàng để trích xuất thông tin khách hàng
      final orders = await ApiService().getAdminOrders('ALL');
      
      // Trích xuất thông tin khách hàng từ danh sách đơn
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
    return _orders.where((order) => order['user_id'] == userId).toList();
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
                                          const Text(
                                            "📋 Đơn hàng gần nhất",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          ...customerOrders.take(3).map((order) => ListTile(
                                            dense: true,
                                            contentPadding: EdgeInsets.zero,
                                            leading: const Icon(Icons.receipt, size: 16),
                                            title: Text(
                                              "Đơn #${order['order_id']}",
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                            subtitle: Text(
                                              fmt.format(safeParseDouble(order['total_amount'])),
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                            trailing: Chip(
                                              label: Text(
                                                _getStatusText(order['order_status']),
                                                style: const TextStyle(fontSize: 10),
                                              ),
                                              backgroundColor: _getStatusColor(order['order_status'])
                                                  .withOpacity(0.1),
                                            ),
                                          )),
                                        ],
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                icon: const Icon(Icons.email, size: 18),
                                                label: const Text("Gửi email"),
                                                onPressed: () {
                                                  // TODO: Gửi email cho khách
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                icon: const Icon(Icons.phone, size: 18),
                                                label: const Text("Gọi điện"),
                                                onPressed: () {
                                                  // TODO: Gọi điện cho khách
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
}