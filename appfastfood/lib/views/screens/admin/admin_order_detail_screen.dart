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

  // Hàm riêng để cập nhật trạng thái thanh toán - ĐÃ SỬA
  Future<bool> _updatePaymentStatus(String newPaymentStatus) async {
    try {
      final api = ApiService();
      bool success = await api.updatePaymentStatus(
        widget.order['order_id'],
        newPaymentStatus,
      );
      
      if (success) {
        print("✅ Payment status updated to $newPaymentStatus");
        // Cập nhật UI local
        setState(() {
          widget.order['payment_status'] = newPaymentStatus;
        });
      } else {
        print("❌ Failed to update payment status");
      }
      
      return success;
    } catch (e) {
      print("❌ Lỗi cập nhật thanh toán: $e");
      return false;
    }
  }

  // Hàm xử lý logic khi bấm "Giao cho shipper" - ĐÃ SỬA
Future<void> _handleShipAndPay() async {
  if (_isLoading) return;
  
  setState(() => _isLoading = true);
  
  try {
    final orderId = widget.order['order_id'];
    final api = ApiService();

    print("🔄 [1/2] Đang cập nhật trạng thái giao hàng...");
    
    // 1. Cập nhật trạng thái đơn hàng -> SHIPPED
    bool orderSuccess = await api.updateOrderStatus(orderId, 'SHIPPED');

    if (!orderSuccess) {
      throw Exception("Không thể cập nhật trạng thái giao hàng");
    }

    print("✅ [1/2] Đã cập nhật trạng thái giao hàng thành công");
    print("🔄 [2/2] Đang cập nhật trạng thái thanh toán...");
    
    // 2. Cập nhật trạng thái thanh toán -> PAID
    bool paymentSuccess = await api.updatePaymentStatus(orderId, 'PAID');

    if (!paymentSuccess) {
      // Hiển thị cảnh báo nhưng không throw exception
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.orange,
          content: Text("Đã chuyển sang trạng thái SHIPPED nhưng chưa cập nhật được thanh toán!"),
          duration: Duration(seconds: 4),
        ),
      );
      
      // Cập nhật UI local
      setState(() {
        widget.order['order_status'] = 'SHIPPED';
        widget.order['payment_status'] = 'UNPAID'; // Giữ nguyên hoặc để UNPAID
      });
    } else {
      // Cập nhật UI local
      setState(() {
        widget.order['order_status'] = 'SHIPPED';
        widget.order['payment_status'] = 'PAID';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text("✅ Đã giao cho Shipper và cập nhật Đã thanh toán!"),
          duration: Duration(seconds: 2),
        ),
      );
    }

    // 3. Cập nhật callback
    widget.onStatusUpdated();
    
    // Đợi 1 chút để người dùng thấy thông báo
    await Future.delayed(const Duration(seconds: 1));
    
    // Quay lại màn hình danh sách
    if (mounted) {
      Navigator.pop(context);
    }

  } catch (e) {
    print("❌ Exception in _handleShipAndPay: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("❌ Lỗi: ${e.toString()}"),
        duration: const Duration(seconds: 3),
      ),
    );
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

  Future<void> _updateStatus(String newStatus) async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    try {
      final api = ApiService();
      bool success = await api.updateOrderStatus(
        widget.order['order_id'],
        newStatus,
      );
      
      if (success) {
        widget.onStatusUpdated();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ Đã cập nhật trạng thái thành: $newStatus"),
            duration: const Duration(seconds: 2),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ Lỗi cập nhật trạng thái"),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print("❌ Lỗi khi cập nhật: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Lỗi: $e"),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Hàm cập nhật chỉ trạng thái thanh toán
  Future<void> _updatePaymentOnly(String newPaymentStatus) async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    try {
      bool success = await _updatePaymentStatus(newPaymentStatus);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ Đã cập nhật trạng thái thanh toán thành: $newPaymentStatus"),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ Lỗi cập nhật trạng thái thanh toán"),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print("❌ Lỗi khi cập nhật thanh toán: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Lỗi: $e"),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final status = order['order_status'];
    final paymentStatus = order['payment_status'];
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "💳 Thanh toán",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            paymentStatus == 'PAID'
                                ? "✅ Đã thanh toán"
                                : paymentStatus == 'UNPAID'
                                    ? "⏳ Chờ thanh toán (COD)"
                                    : paymentStatus == 'PENDING'
                                        ? "⏳ Đang chờ thanh toán"
                                        : "❌ Đã hoàn tiền",
                            style: TextStyle(
                              color: paymentStatus == 'PAID'
                                  ? Colors.green
                                  : paymentStatus == 'UNPAID' || paymentStatus == 'PENDING'
                                      ? Colors.orange
                                      : Colors.red,
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
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
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                order['note'].toString(),
                                style: TextStyle(
                                  color: Colors.grey[800],
                                  fontSize: 14,
                                ),
                              ),
                            ),
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
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
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
                                    // Số lượng và tổng
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          "x${item['quantity']}",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          fmt.format(safeParseDouble(item['price']) * (item['quantity'] ?? 1)),
                                          style: TextStyle(
                                            color: Colors.green[700],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
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
                          _buildTotalRow("Phí vận chuyển", 0),
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
                            onPressed: _isLoading ? null : () => _updateStatus('CANCELLED'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    "Hủy đơn",
                                    style: TextStyle(color: Colors.white),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : () => _updateStatus('PROCESSING'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    "Xác nhận đơn",
                                    style: TextStyle(color: Colors.white),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  if (status == 'PROCESSING')
                    ElevatedButton(
                      onPressed: _isLoading ? null : () => _handleShipAndPay(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Giao cho shipper",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "(Tự động cập nhật Đã thanh toán)",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  if (status == 'SHIPPED')
                    ElevatedButton(
                      onPressed: _isLoading ? null : () => _updateStatus('DELIVERED'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              "Xác nhận đã giao",
                              style: TextStyle(color: Colors.white),
                            ),
                    ),
                  const SizedBox(height: 16),
                  
                  // Nút quay lại
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      side: const BorderSide(color: Colors.grey),
                    ),
                    child: const Text(
                      "Quay lại",
                      style: TextStyle(color: Colors.grey),
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
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            fmt.format(amount),
            style: TextStyle(
              fontSize: 14,
              fontWeight: label == "TỔNG CỘNG" ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'PENDING':
        return 'Chờ xác nhận';
      case 'PROCESSING':
        return 'Đã xác nhận';
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