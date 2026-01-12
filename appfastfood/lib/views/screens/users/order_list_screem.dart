import 'package:appfastfood/models/order.dart';
import 'package:appfastfood/service/api_service.dart';
import 'package:appfastfood/views/screens/users/order_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen>
    with AutomaticKeepAliveClientMixin {
  // Giữ trạng thái khi chuyển tab chính

  // Biến lưu TOÀN BỘ đơn hàng lấy từ API
  List<OrderModel> _allOrders = [];
  bool isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  // Hàm gọi API lấy tất cả đơn
  Future<void> _fetchOrders() async {
    if (_allOrders.isEmpty) {
      setState(() => isLoading = true);
    }
    try {
      // Giả sử API trả về tất cả đơn hàng
      List<OrderModel> data = await ApiService().getOrderYourUserId();
      if (mounted) {
        setState(() {
          _allOrders = data;
        });
      }
    } catch (e) {
      print("Lỗi fetch orders: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // --- HÀM LỌC ĐƠN HÀNG THEO TRẠNG THÁI ---
  List<OrderModel> _filterOrders(List<String> statuses) {
    return _allOrders.where((order) {
      // Kiểm tra xem status của đơn hàng có nằm trong danh sách cần lấy không
      return statuses.contains(order.status.toUpperCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Tạo 3 danh sách riêng biệt
    // Bạn nhớ kiểm tra các chữ 'PENDING', 'SHIPPED' này có khớp với Database của bạn không nhé
    final listProcessing = _filterOrders([
      'PENDING',
      'CONFIRMED',
      'SHIPPED',
      'PROCESSING',
      'UNPAID',
    ]);
    final listCompleted = _filterOrders([
      'COMPLETED',
      'DELIVERED',
      'PAID',
      'SUCCESS',
    ]);
    final listCancelled = _filterOrders(['CANCELLED', 'FAILED']);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Transform.translate(
            offset: Offset(0, -10),
            child: Text(
              "Đơn hàng của tôi",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          backgroundColor: Color(0xFFFFC529),
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false,
          bottom: const TabBar(
            labelColor: Color(0xFFE95322), // Màu chữ khi chọn
            unselectedLabelColor: Color.fromARGB(
              255,
              255,
              255,
              255,
            ), // Màu chữ khi không chọn
            indicatorColor: Color(0xFFE95322), // Màu gạch dưới
            tabs: [
              Tab(text: "Đang xử lý"),
              Tab(text: "Hoàn thành"),
              Tab(text: "Đã hủy"),
            ],
          ),
        ),
        backgroundColor: Colors.grey[100],

        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  // Tab 1: Đang xử lý
                  _buildListTab(listProcessing),

                  // Tab 2: Hoàn thành
                  _buildListTab(listCompleted),

                  // Tab 3: Đã hủy
                  _buildListTab(listCancelled),
                ],
              ),
      ),
    );
  }

  // Widget dùng chung để vẽ danh sách cho từng Tab
  Widget _buildListTab(List<OrderModel> orders) {
    return RefreshIndicator(
      onRefresh: _fetchOrders, // Kéo tab nào cũng refresh lại toàn bộ
      child: orders.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              physics:
                  const AlwaysScrollableScrollPhysics(), // Để list rỗng vẫn kéo refresh được
              itemCount: orders.length,
              itemBuilder: (context, index) {
                return _buildOrderItem(orders[index]);
              },
            ),
    );
  }

  // Widget hiển thị khi tab trống
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 70, color: Colors.grey[300]),
          const SizedBox(height: 10),
          const Text(
            "Không có đơn hàng nào",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // Widget hiển thị từng thẻ đơn hàng (Code cũ giữ nguyên)
  Widget _buildOrderItem(OrderModel order) {
    final currency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(order.date);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  OrderDetailScreen(orderId: order.id), // Truyền ID sang Detail
            ),
          ).then(
            (_) => _fetchOrders(),
          ); // Khi quay lại thì reload để cập nhật trạng thái mới
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      order.thumbnail.isNotEmpty
                          ? order.thumbnail
                          : 'https://via.placeholder.com/150',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Đơn #${order.id}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              dateStr,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          order.itemsSummary,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Tổng tiền",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        currency.format(order.totalAmount),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE95322),
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: order.statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: order.statusColor.withOpacity(0.5),
                      ),
                    ),
                    child: Text(
                      order.statusText,
                      style: TextStyle(
                        color: order.statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
