import 'package:appfastfood/models/Order.dart';
import 'package:appfastfood/service/api_service.dart';
import 'package:appfastfood/views/screens/users/home_interface/order_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderListScreen extends StatefulWidget {
  final Future<void> Function() onRefresh;
  const OrderListScreen({super.key, required this.onRefresh});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen>
    with AutomaticKeepAliveClientMixin {
  List<OrderModel> _orders = [];
  bool isLoading = true;
  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  @override
  bool get wantKeepAlive => true;

  Future<void> _fetchOrders() async {
    if (_orders.isEmpty) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      List<OrderModel> data = await ApiService().getOrderYourUserId();
      if (mounted) {
        setState(() {
          _orders = data;
        });
      }
    } catch (e) {
      print("Lỗi fetch orders: $e");
    } finally {
      if (mounted) {
        isLoading = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Đơn hàng của tôi",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.grey[100], // Màu nền xám nhẹ
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchOrders, // Kéo để refresh
              child: _orders.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _orders.length,
                      itemBuilder: (context, index) {
                        return _buildOrderItem(_orders[index]);
                      },
                    ),
            ),
    );
  }

  // Widget hiển thị khi không có đơn nào
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            "Bạn chưa có đơn hàng nào",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // Widget hiển thị từng thẻ đơn hàng
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
          // Chuyển sang màn hình chi tiết
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailScreen(orderId: order.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Ảnh Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      order.thumbnail.isNotEmpty
                          ? order.thumbnail
                          : 'https://via.placeholder.com/150', // Ảnh mặc định nếu null
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

                  // 2. Thông tin chính
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
                        // Hiển thị tóm tắt món ăn (cắt bớt nếu dài quá)
                        Text(
                          order.itemsSummary,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(),
              // 3. Tổng tiền và Trạng thái
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Tổng thanh toán",
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
