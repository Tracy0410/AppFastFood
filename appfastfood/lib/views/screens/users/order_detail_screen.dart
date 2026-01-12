import 'package:appfastfood/models/order.dart';
import 'package:appfastfood/service/api_service.dart';
import 'package:appfastfood/views/screens/users/ai_chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late Future<OrderModel?> _orderFuture;
  final ApiService _apiService = ApiService();
  bool _isActionLoading = true;
  bool isActionCancel = true;
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Hàm load dữ liệu
  void _loadData() {
    setState(() {
      _orderFuture = _apiService.getOrderDetail(widget.orderId);
    });
  }

  // Hàm xử lý khi bấm nút Hủy
  Future<void> _handleCancelOrder() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận hủy"),
        content: const Text("Bạn có chắc chắn muốn hủy đơn hàng này không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Đóng"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Hủy đơn", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Bắt đầu Loading
    setState(() => isActionCancel = true);

    try {
      // 2. Gọi API
      bool success = await _apiService.cancelOrder(widget.orderId);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Đã hủy đơn hàng"),
              backgroundColor: Colors.green,
            ),
          );
          _loadData(); // Load lại trang
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Lỗi: Không thể hủy đơn hàng này"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Nếu có lỗi code thì in ra xem
      print("Lỗi ở UI: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Lỗi ứng dụng: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // QUAN TRỌNG NHẤT: Dù thành công hay thất bại, luôn tắt Loading ở đây
      if (mounted) {
        setState(() => isActionCancel = false);
      }
    }
  }

  // Hàm xử lý Copy mã đơn
  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã sao chép mã đơn hàng')));
  }

  Future<void> _handleRepay() async {
    setState(() => _isActionLoading = true); // Hiện vòng xoay

    // 1. Gọi API thanh toán nhanh
    bool isSuccess = await _apiService.repayOrder(widget.orderId);

    if (mounted) {
      setState(() => _isActionLoading = false); // Tắt vòng xoay

      if (isSuccess) {
        // 2. Thông báo thành công
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Thanh toán thành công!"),
            backgroundColor: Colors.green,
          ),
        );

        // 3. Tự động load lại dữ liệu để cập nhật trạng thái mới
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Thanh toán thất bại, thử lại sau"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Màu nền xám nhạt cho sang
      appBar: AppBar(
        title: const Text(
          "Chi tiết đơn hàng",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: FutureBuilder<OrderModel?>(
        future: _orderFuture,
        builder: (context, snapshot) {
          // 1. Đang tải
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Có lỗi
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 50, color: Colors.red),
                  const SizedBox(height: 10),
                  Text("Lỗi: ${snapshot.error}"),
                  TextButton(
                    onPressed: _loadData,
                    child: const Text("Thử lại"),
                  ),
                ],
              ),
            );
          }

          // 3. Không tìm thấy đơn (null)
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("Không tìm thấy đơn hàng này."));
          }

          // 4. Có dữ liệu -> Hiển thị UI
          final order = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => _loadData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildStatusHeader(order),
                  const SizedBox(height: 16),
                  _buildProductList(order),
                  const SizedBox(height: 16),
                  _buildPaymentDetails(order),
                  const SizedBox(height: 30), // Khoảng trống dưới cùng
                ],
              ),
            ),
          );
        },
      ),

      // Bottom Bar cho các nút hành động
      bottomNavigationBar: FutureBuilder<OrderModel?>(
        future: _orderFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox();
          return _buildBottomAction(snapshot.data!);
        },
      ),
    );
  }

  // --- WIDGET 1: HEADER TRẠNG THÁI ---
  Widget _buildStatusHeader(OrderModel order) {
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(order.date);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Phần màu mè trạng thái
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: order.statusColor.withOpacity(
                0.1,
              ), // Màu nền nhạt theo trạng thái
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.local_shipping_outlined,
                  size: 40,
                  color: order.statusColor,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.statusText.toUpperCase(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: order.statusColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Cập nhật: $dateStr",
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Phần Mã đơn hàng
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Mã đơn hàng",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "#${order.id}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => _copyToClipboard(order.id.toString()),
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text("Sao chép"),
                  style: TextButton.styleFrom(foregroundColor: Colors.blue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET 2: DANH SÁCH SẢN PHẨM ---
  Widget _buildProductList(OrderModel order) {
    final currency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Danh sách món ăn",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Divider(height: 24),

          // Logic parse chuỗi itemsSummary: "Tên (x2) - 100000"
          ...order.itemsSummary.split(', ').map((itemStr) {
            String name = itemStr;
            String quantity = "";
            String price = "";

            // Xử lý chuỗi phức tạp
            if (itemStr.contains('-')) {
              // Tách giá tiền ra (Lấy phần sau dấu gạch ngang cuối cùng)
              int lastDashIndex = itemStr.lastIndexOf('-');
              String infoPart = itemStr.substring(0, lastDashIndex).trim();
              String pricePart = itemStr.substring(lastDashIndex + 1).trim();
              double priceVal = double.tryParse(pricePart) ?? 0;
              price = currency.format(priceVal);

              name = infoPart;
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.fastfood,
                      size: 20,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    price,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPaymentDetails(OrderModel order) {
    final currency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Chi tiết thanh toán",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          _buildRowInfo("Phương thức", order.paymentMethod, isBold: true),
          _buildRowInfo(
            "Trạng thái",
            order.paymentStatus == 'PAID' ? "Đã thanh toán" : "Chưa thanh toán",
            valueColor: order.paymentStatus == 'PAID'
                ? Colors.green
                : Colors.orange,
          ),

          const Divider(height: 24),

          _buildRowInfo("Tạm tính", currency.format(order.subTotal)),

          if (order.tax > 0)
            _buildRowInfo("Thuế (VAT)", "+${currency.format(order.tax)}"),

          if (order.discount > 0)
            _buildRowInfo(
              "Giảm giá",
              "-${currency.format(order.discount)}",
              valueColor: Colors.green,
            ),

          const Divider(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Tổng cộng",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                currency.format(order.totalAmount),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Color(0xFFE95322),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRowInfo(
    String label,
    String value, {
    bool isBold = false,
    Color valueColor = Colors.black,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              fontSize: 15,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AIChatScreen()),
                );
              },
              icon: const Icon(Icons.headset_mic, size: 18),
              label: const Text("Hỗ trợ"),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Colors.grey),
                foregroundColor: Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 12),
          if (order.status == 'PENDING' && order.paymentStatus == 'UNPAID') ...[
            Expanded(
              child: OutlinedButton(
                onPressed: _handleCancelOrder,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Colors.red),
                  foregroundColor: Colors.red,
                ),
                child: const Text(
                  "Hủy đơn",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          if (order.isUnpaidVNPay) ...[
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () {
                  _handleRepay();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE95322),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                child: const Text(
                  "Thanh toán ngay",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ] else if (order.status == 'COMPLETED' ||
              order.status == 'CANCELLED') ...[
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE95322),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                child: const Text(
                  "Đặt lại đơn này",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(),
          ],
        ],
      ),
    );
  }
}
