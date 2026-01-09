import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../service/api_service.dart';
import '../../../models/checkout.dart'; // Import Model Preview

class CheckoutScreen extends StatefulWidget {
  final List<OrderItemReq> inputItems; // Danh sách hàng cần mua
  final bool isBuyFromCart; // Mua từ giỏ hay mua ngay

  const CheckoutScreen({
    super.key,
    required this.inputItems,
    this.isBuyFromCart = false,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _noteController =
      TextEditingController(); // Controller cho ô ghi chú

  CheckoutPreviewRes? _data; // Dữ liệu hứng từ API Preview
  bool _isLoading = true;

  // Giả định dữ liệu chọn (Sau này bạn có thể làm màn hình chọn địa chỉ riêng)
  int _addressId = 1;
  int? _promotionId;
  String _paymentMethod = "COD";

  @override
  void initState() {
    super.initState();
    _fetchPreview();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  // --- 1. Gọi API tính tiền trước (Preview) ---
  void _fetchPreview() async {
    setState(() => _isLoading = true);

    // Convert dữ liệu để gửi lên Server
    final itemsMap = widget.inputItems.map((e) => e.toJson()).toList();

    // Gọi hàm trong ApiService
    final result = await _apiService.previewOrder(
      items: itemsMap,
      promotionId: _promotionId,
      shippingAddressId: _addressId,
    );

    if (mounted) {
      setState(() {
        _data = result;
        _isLoading = false;
      });
    }
  }

  // --- 2. Gọi API đặt hàng thật (Submit) ---
  void _submitOrder() async {
    if (_data == null) return;

    // Hiện loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFFDC95F)),
      ),
    );

    final itemsMap = widget.inputItems.map((e) => e.toJson()).toList();

    try {
      final res = await _apiService.createOrder(
        items: itemsMap,
        shippingAddressId: _addressId,
        promotionId: _promotionId,
        paymentMethod: _paymentMethod,
        isBuyFromCart: widget.isBuyFromCart,
        note: _noteController.text.trim(),
      );

      // Tắt loading dialog
      if (mounted) Navigator.pop(context);

      if (res['success'] == true) {
        // Thành công -> Show thông báo và quay về trang chủ hoặc trang lịch sử đơn
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("🎉 Đặt hàng thành công!"),
            backgroundColor: Colors.green,
          ),
        );

        // Quay về màn hình gốc (xóa hết stack màn hình cũ để tránh user back lại trang checkout)
        // Navigator.of(context).pushNamedAndRemoveUntil('/home', (Route<dynamic> route) => false);
        // Hoặc đơn giản là pop:
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Thất bại: ${res['message']}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi kết nối: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9), // Màu nền xám nhạt
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDC95F), // Màu vàng chủ đạo
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.brown),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Xác Nhận Đơn Hàng",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFDC95F)),
            )
          : _data == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Lỗi tải thông tin đơn hàng"),
                  ElevatedButton(
                    onPressed: _fetchPreview,
                    child: const Text("Thử lại"),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Header trang trí màu vàng cong cong
                  Container(
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFDC95F),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- 1. ĐỊA CHỈ GIAO HÀNG ---
                        const Text(
                          "Địa Chỉ Giao Hàng",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3E2723),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E5AB), // Màu kem
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Color(0xFF5D4037),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  "778 Locust View Drive Oaklanda, CA (Hardcode)", // Sau này thay bằng biến address
                                  style: TextStyle(
                                    color: Color(0xFF5D4037),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  size: 20,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  // Mở màn hình chọn địa chỉ khác
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // --- 2. CÁC TÙY CHỌN (Phương thức thanh toán / Voucher) ---
                        _buildSelectorRow(
                          title: "Phương thức thanh toán",
                          value: _paymentMethod,
                          icon: Icons.payment,
                        ),
                        const Divider(thickness: 0.5),
                        _buildSelectorRow(
                          title: "Mã khuyến mãi",
                          value: _promotionId != null
                              ? "Đã chọn"
                              : "Chọn voucher",
                          icon: Icons.local_offer,
                          isHighlight: _promotionId != null,
                        ),

                        const SizedBox(height: 20),

                        // --- 3. DANH SÁCH MÓN ĂN ---
                        const Text(
                          "Đơn Hàng",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3E2723),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Render List Items
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _data!.items.length,
                          itemBuilder: (context, index) {
                            final item = _data!.items[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 15),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Ảnh sản phẩm
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      item.image,
                                      width: 70,
                                      height: 70,
                                      fit: BoxFit.cover,
                                      errorBuilder: (ctx, _, __) => Container(
                                        width: 70,
                                        height: 70,
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.image),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  // Thông tin tên và giá
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          currency.format(
                                            item.discountedUnitPrice,
                                          ),
                                          style: const TextStyle(
                                            color: Colors.orange,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Số lượng
                                  Text(
                                    "x${item.quantity}",
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        // --- 4. GHI CHÚ ---
                        const SizedBox(height: 10),
                        TextField(
                          controller: _noteController,
                          decoration: InputDecoration(
                            hintText: "Ghi chú cho tài xế/nhà hàng...",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 10),

                        // --- 5. TỔNG KẾT TIỀN ---
                        _buildSummaryRow(
                          "Tổng tiền hàng",
                          currency.format(_data!.subtotal),
                        ),
                        if (_data!.totalDiscount > 0)
                          _buildSummaryRow(
                            "Khuyến mãi",
                            "-${currency.format(_data!.totalDiscount)}",
                            color: Colors.green,
                          ),
                        _buildSummaryRow(
                          "Phí vận chuyển",
                          currency.format(_data!.shippingFee),
                        ),
                        _buildSummaryRow(
                          "Thuế VAT",
                          currency.format(_data!.taxFee),
                        ),

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(color: Colors.black12),
                        ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Thành Tiền",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Color(0xFF3E2723),
                              ),
                            ),
                            Text(
                              currency.format(_data!.totalAmount),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                                color: Color(0xFFD84315),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),

                        // --- 6. NÚT ĐẶT HÀNG ---
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(
                                0xFFFDC95F,
                              ), // Màu vàng
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 2,
                            ),
                            onPressed: _submitOrder,
                            child: const Text(
                              "ĐẶT HÀNG NGAY",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Widget con để hiển thị dòng text 2 bên (Trái: Tiêu đề, Phải: Giá trị)
  Widget _buildSummaryRow(
    String title,
    String value, {
    Color color = const Color(0xFF3E2723),
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Widget con để hiển thị dòng chọn (Payment, Voucher)
  Widget _buildSelectorRow({
    required String title,
    required String value,
    required IconData icon,
    bool isHighlight = false,
  }) {
    return InkWell(
      onTap: () {
        // Xử lý mở modal chọn payment hoặc voucher tại đây
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.orange, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isHighlight ? Colors.red : const Color(0xFF3E2723),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
