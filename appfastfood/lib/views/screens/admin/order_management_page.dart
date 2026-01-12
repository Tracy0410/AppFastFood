import 'package:flutter/material.dart';
import '../../widget/order_card.dart';
import 'order_detail_page.dart';
class OrderManagementPage extends StatefulWidget {
  const OrderManagementPage({Key? key}) : super(key: key);

  @override
  State<OrderManagementPage> createState() => _OrderManagementPageState();
}

class _OrderManagementPageState extends State<OrderManagementPage> {
  // Danh sách trạng thái để làm bộ lọc
  final List<String> _filters = [
    'ALL', 
    'PENDING', 
    'PROCESSING', 
    'SHIPPED', 
    'DELIVERED', 
    'CANCELLED'
  ];
  
  // Tên hiển thị trên nút lọc
  final Map<String, String> _filterNames = {
    'ALL': 'Tất cả',
    'PENDING': 'Đang chờ',
    'PROCESSING': 'Đang làm',
    'SHIPPED': 'Đang giao',
    'DELIVERED': 'Hoàn tất',
    'CANCELLED': 'Đã hủy',
  };

  String _selectedFilter = 'ALL';

  // Dữ liệu giả lập (Bạn sẽ thay bằng API call ở đây)
  // Dữ liệu này khớp với SQL bạn cung cấp
  final List<Map<String, dynamic>> _allOrders = [
    {
      'order_id': 6,
      'created_at': '2026-01-08 15:30:53',
      'fullname': 'Nguyễn Văn Khách',
      'total_amount': 263500,
      'order_status': 'PROCESSING',
      'item_count': 3
    },
    {
      'order_id': 4,
      'created_at': '2023-11-05 11:30:00',
      'fullname': 'Lê Văn Mới',
      'total_amount': 104300,
      'order_status': 'DELIVERED',
      'item_count': 1
    },
    {
      'order_id': 3,
      'created_at': '2026-01-08 10:30:00',
      'fullname': 'Nguyễn Văn Khách',
      'total_amount': 72000,
      'order_status': 'PENDING',
      'item_count': 1
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Logic lọc danh sách
    List<Map<String, dynamic>> displayedOrders = _selectedFilter == 'ALL'
        ? _allOrders
        : _allOrders.where((o) => o['order_status'] == _selectedFilter).toList();

    return Scaffold(
      backgroundColor: Colors.grey[50], // Màu nền nhẹ
      appBar: AppBar(
        backgroundColor: Colors.amber, // Màu vàng thương hiệu
        title: const Text('Quản lý đơn hàng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // 1. Bộ lọc (Filter) dạng Chips nằm ngang
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _filters.map((filter) {
                  bool isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ChoiceChip(
                      label: Text(_filterNames[filter]!),
                      selected: isSelected,
                      selectedColor: Colors.amber,
                      backgroundColor: Colors.grey[200],
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (bool selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // 2. Danh sách đơn hàng
          Expanded(
            child: displayedOrders.isEmpty
                ? const Center(child: Text("Không có đơn hàng nào"))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: displayedOrders.length,
                    itemBuilder: (context, index) {
                      return OrderCard(
                        order: displayedOrders[index],
                        onTap: () {
                          // Chuyển sang trang chi tiết
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrderDetailPage(
                                orderId: displayedOrders[index]['order_id'],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
