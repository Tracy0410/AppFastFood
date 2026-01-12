import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../service/api_service.dart';

// Hàm helper để parse giá trị an toàn từ String/num sang double
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

class AdminOrderDetailScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  final Function() onStatusUpdated;

  const AdminOrderDetailScreen({
    super.key,
    required this.order,
    required this.onStatusUpdated,
  });

  @override
  State<AdminOrderDetailScreen> createState() => _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends State<AdminOrderDetailScreen> {
  final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  bool _isLoading = false;
  List<dynamic> _orderDetails = [];

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    try {
      // Gọi API lấy chi tiết đơn hàng
      // Note: Bạn cần tạo API mới hoặc dùng API hiện có
      // Tạm thời lấy từ order['order_details'] nếu có
      if (widget.order['order_details'] != null) {
        setState(() {
          _orderDetails = widget.order['order_details'];
        });
      }
    } catch (e) {
      print("❌ Lỗi load order details: $e");
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isLoading = true);
    try {
      bool success = await ApiService().updateOrderStatus(
        widget.order['order_id'],
        newStatus,
      );
      
      if (success) {
        widget.onStatusUpdated();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Đã cập nhật trạng thái thành: $newStatus")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lỗi cập nhật trạng thái")),
        );
      }
    } catch (e) {
      print("❌ Lỗi khi cập nhật: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final status = order['order_status'];
    final date = DateTime.parse(order['created_at']);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text("Chi tiết đơn #${order['order_id']}"),
        backgroundColor: Colors.amber,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Thông tin cơ bản
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Mã đơn: #${order['order_id']}",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(status),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _getStatusText(status),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text("Ngày đặt: ${dateFormat.format(date)}"),
                          Text("Khách hàng: ${order['fullname']}"),
                          Text("SĐT: ${order['phone'] ?? 'N/A'}"),
                          Text("Email: ${order['email'] ?? 'N/A'}"),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Địa chỉ giao hàng
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "📦 Địa chỉ giao hàng",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "${order['recipient_name'] ?? order['fullname']}",
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(order['street_address'] ?? ''),
                          Text("${order['district']}, ${order['city']}"),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Thanh toán & Ghi chú
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "💳 Thanh toán",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            order['payment_status'] == 'PAID'
                                ? "✅ Đã thanh toán"
                                : "⏳ Chờ thanh toán (COD)",
                            style: TextStyle(
                              color: order['payment_status'] == 'PAID'
                                  ? Colors.green
                                  : Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (order['note'] != null &&
                              order['note'].toString().isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const Text(
                              "📝 Ghi chú",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(order['note'].toString()),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Danh sách sản phẩm
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "🍔 Sản phẩm",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._orderDetails.map((item) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    // Ảnh sản phẩm
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(8),
                                        image: item['image_url'] != null
                                            ? DecorationImage(
                                                image: NetworkImage(
                                                    item['image_url']),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                      ),
                                      child: item['image_url'] == null
                                          ? const Icon(Icons.fastfood,
                                              color: Colors.grey)
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    // Thông tin
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item['product_name'] ?? 'Sản phẩm',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            fmt.format(safeParseDouble(item['price'])),
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Số lượng
                                    Text(
                                      "x${item['quantity']}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tổng tiền
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildTotalRow("Tạm tính", safeParseDouble(order['subtotal'])),
                          _buildTotalRow("Giảm giá",
                              safeParseDouble(order['discount_amount'] ?? 0)),
                          _buildTotalRow("Phí vận chuyển", 15000),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "TỔNG CỘNG",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                fmt.format(safeParseDouble(order['total_amount'])),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Nút hành động
                  if (status == 'PENDING')
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _updateStatus('CANCELLED'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              "Hủy đơn",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _updateStatus('PROCESSING'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              "Xác nhận đơn",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (status == 'PROCESSING')
                    ElevatedButton(
                      onPressed: () => _updateStatus('SHIPPED'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text(
                        "Giao cho shipper",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  if (status == 'SHIPPED')
                    ElevatedButton(
                      onPressed: () => _updateStatus('DELIVERED'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text(
                        "Xác nhận đã giao",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildTotalRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(fmt.format(amount)),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'PENDING':
        return 'Chờ xác nhận';
      case 'PROCESSING':
        return 'Đang xử lý';
      case 'SHIPPED':
        return 'Đang giao';
      case 'DELIVERED':
        return 'Đã giao';
      case 'CANCELLED':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.orange;
      case 'PROCESSING':
        return Colors.blue;
      case 'SHIPPED':
        return Colors.purple;
      case 'DELIVERED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}