import 'package:appfastfood/models/cartItem.dart';
import 'package:appfastfood/models/promotion.dart';
import 'package:appfastfood/service/api_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Model Voucher cập nhật theo DB của bạn (dùng discount_percent)

class PromotionCheckoutScreen extends StatefulWidget {
  // Nhận danh sách món từ Checkout để lọc voucher
  final List<CartItem> cartItems; // List Model item của bạn

  const PromotionCheckoutScreen({super.key, required this.cartItems});

  @override
  State<PromotionCheckoutScreen> createState() =>
      _PromotionCheckoutScreenState();
}

class _PromotionCheckoutScreenState extends State<PromotionCheckoutScreen> {
  List<Promotion> _availableVouchers = [];
  bool _isLoading = true;
  String? _errorMessage;
  @override
  void initState() {
    super.initState();
    _loadVoucher();
  }

  // Gọi API lấy voucher phù hợp với giỏ hàng
  Future<void> _loadVoucher() async {
    try {
      final vouchers = await ApiService.checkAvailablePromotions(
        widget.cartItems,
      );
      if (mounted) {
        setState(() {
          _availableVouchers = vouchers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll(
            "Exception: ",
            "",
          ); // Xóa chữ Exception cho đẹp
        });
      }
      print("Lỗi: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chọn Mã Khuyến Mãi")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _availableVouchers.isEmpty
          ? const Center(
              child: Text("Không có mã giảm giá nào cho đơn hàng này"),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _availableVouchers.length,
              itemBuilder: (context, index) {
                final voucher = _availableVouchers[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.percent, color: Colors.red),
                    title: Text(
                      voucher.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "Giảm ${voucher.discountPercent}% - HSD: ${DateFormat('dd/MM').format(voucher.endDate)}",
                    ),
                    trailing: ElevatedButton(
                      onPressed: () {
                        // Trả voucher về cho màn hình Checkout
                        Navigator.pop(context, voucher);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      child: const Text("Dùng"),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
