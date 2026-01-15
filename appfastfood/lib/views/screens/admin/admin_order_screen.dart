import 'package:flutter/material.dart';
import 'package:appfastfood/service/api_service.dart'; // Đảm bảo đúng đường dẫn
import 'package:intl/intl.dart';
import '../../screens/admin/admin_order_detail_screen.dart';
class AdminOrderScreen extends StatefulWidget {
  const AdminOrderScreen({super.key});

  @override
  State<AdminOrderScreen> createState() => _AdminOrderScreenState();
}

class _AdminOrderScreenState extends State<AdminOrderScreen>
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;
  String _currentStatus = 'PENDING';
  final List<String> _quickTabs = ['PENDING', 'DELIVERED', 'CANCELLED'];
  
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
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentStatus = _quickTabs[index];
    });
    print("👉 Chuyển Tab: $_currentStatus");
  }

  void _updateStatusFromFilter(String status) {
    setState(() {
      _currentStatus = status;
    });

    int index = _quickTabs.indexOf(status);
    if (index != -1) {
      _tabController.animateTo(index);
    }
    print("👉 Chọn Filter: $_currentStatus");
  }

  String _getTitleByStatus(String status) {
    switch(status) {
      case 'PENDING': return 'Đơn mới đặt';
      case 'PROCESSING': return 'Đang chế biến';
      case 'SHIPPED': return 'Đang giao hàng';
      case 'DELIVERED': return 'Đơn thành công';
      case 'CANCELLED': return 'Đơn đã hủy';
      default: return 'Danh sách đơn hàng';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _getTitleByStatus(_currentStatus), 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
        ),
        backgroundColor: const Color(0xFFFFC529),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: _updateStatusFromFilter,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'PENDING', child: Text("Mới đặt")),
              const PopupMenuItem(value: 'PROCESSING', child: Text("Đang xử lý")),
              const PopupMenuItem(value: 'SHIPPED', child: Text("Đang giao hàng")),
              const PopupMenuItem(value: 'DELIVERED', child: Text("Hoàn thành")),
              const PopupMenuItem(value: 'CANCELLED', child: Text("Đã hủy")),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 4,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          onTap: _onTabTapped,
          tabs: const [
            Tab(text: "Mới đặt", icon: Icon(Icons.new_releases_outlined)),
            Tab(text: "Thành công", icon: Icon(Icons.check_circle_outline)),
            Tab(text: "Đã hủy", icon: Icon(Icons.cancel_outlined)),
          ],
        ),
      ),
      body: OrderListByStatus(
        key: ValueKey(_currentStatus),
        status: _currentStatus,
      ),
    );
  }
}

class OrderListByStatus extends StatefulWidget {
  final String status;
  const OrderListByStatus({super.key, required this.status});

  @override
  State<OrderListByStatus> createState() => _OrderListByStatusState();
}

class _OrderListByStatusState extends State<OrderListByStatus> {
  final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: ApiService().getAdminOrders(widget.status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Lỗi kết nối: ${snapshot.error}"));
        }

        final orders = snapshot.data ?? [];
        
        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_outlined, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 10),
                Text("Không có đơn hàng '${widget.status}'", style: const TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 80),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final o = orders[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: _buildStatusIcon(widget.status),
                title: Text(
                  "Đơn #${o['order_id']} - ${o['fullname']}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fmt.format(safeParseDouble(o['total_amount'])),
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    Text(
                      o['created_at'] ?? '',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminOrderDetailScreen(
                        order: o,
                        onStatusUpdated: () {
                          setState(() {});
                        },
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Icon _buildStatusIcon(String status) {
     switch(status) {
       case 'PENDING': return const Icon(Icons.new_releases, color: Colors.orange);
       case 'PROCESSING': return const Icon(Icons.soup_kitchen, color: Colors.amber);
       case 'SHIPPED': return const Icon(Icons.local_shipping, color: Colors.blue);
       case 'DELIVERED': return const Icon(Icons.check_circle, color: Colors.green);
       case 'CANCELLED': return const Icon(Icons.cancel, color: Colors.red);
       default: return const Icon(Icons.error);
     }
  }
}
