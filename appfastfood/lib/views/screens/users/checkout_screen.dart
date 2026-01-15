import 'package:appfastfood/models/cartItem.dart';
import 'package:appfastfood/models/promotion.dart';
import 'package:appfastfood/views/screens/users/info/address/address_list.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../service/api_service.dart';
import '../../../models/checkout.dart';
import 'package:appfastfood/models/address.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:appfastfood/views/screens/users/promotion_checkout_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final List<OrderItemReq> inputItems;
  final bool isBuyFromCart;

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
  final TextEditingController _noteController = TextEditingController();

  CheckoutPreviewRes? _data;
  bool _isLoading = true;

  Address? _currentAddress;
  Promotion? _selectedPromotion;
  String _paymentMethod = "COD";

  int promotionId = 0;

  @override
  void initState() {
    super.initState();
    promotionId = 0;
    _loadDefaultAddress();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _onSelectVoucher() async {
    // 1. Chuyển đổi dữ liệu sang CartItem (Bạn đã làm đúng chỗ này)
    List<CartItem> tempCartItems = widget.inputItems.map((item) {
      return CartItem(
        cartId: 0, 
        productId: item.productId,
        categoryId: item.categoryId, 
        name: "",
        price: 0,
        imageUrl: "",
        quantity: item.quantity,
        note: item.note,
      );
    }).toList();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        // SỬA TẠI ĐÂY: Dùng tempCartItems thay vì items
        builder: (context) => PromotionCheckoutScreen(cartItems: tempCartItems), 
      ),
    );
    if (result != null && result is Promotion) {
      setState(() {
        _selectedPromotion = result; 
      });

      _fetchPreview();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Đã áp dụng mã: ${result.name}")),
      );
    }
  

if (result != null && result is Promotion) {
  setState(() {
    _selectedPromotion = result;
  });

      _fetchPreview();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Đã áp dụng mã: ${result.name}")));
    }
  }

  Future<void> _loadDefaultAddress() async {
    try {
      final address = await _apiService.getAddress();
      if (address.isNotEmpty) {
        final defaultAddress = address.firstWhere(
          (e) => e.isDefault == true,
          orElse: () => address.first,
        );
        if (mounted) {
          setState(() {
            _currentAddress = defaultAddress;
          });
          _fetchPreview();
        }
      } else {
        if (mounted) _fetchPreview();
      }
    } catch (e) {
      print("Lỗi tải địa chỉ: $e");
      if (mounted) _fetchPreview();
    }
  }

  void _showPaymentMethodPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Chọn phương thức thanh toán",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.money, color: Colors.green),
                title: const Text("Thanh toán khi nhận hàng (COD)"),
                trailing: _paymentMethod == "COD"
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                onTap: () {
                  setState(() => _paymentMethod = "COD");
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.qr_code, color: Colors.blue),
                title: const Text("Ví VNPay / Ngân hàng"),
                trailing: _paymentMethod == "VNPAY"
                    ? const Icon(Icons.check_circle, color: Colors.blue)
                    : null,
                onTap: () {
                  setState(() => _paymentMethod = "VNPAY");
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // --- 3. SỬA LẠI HÀM PREVIEW ---
  void _fetchPreview() async {
    setState(() => _isLoading = true);

    final itemsMap = widget.inputItems.map((e) => e.toJson()).toList();

    // Sửa: Chỉ gửi ID của voucher đi, không gửi cả object
    // promotionId: _selectedPromotion?.id
    final result = await _apiService.previewOrder(
      items: itemsMap,
      promotionId: _selectedPromotion?.id,
      shippingAddressId: _currentAddress?.addressId,
    );

    if (mounted) {
      setState(() {
        _data = result;
        _isLoading = false;
      });
    }
  }

  // --- 4. SỬA LẠI HÀM SUBMIT ---
  void _submitOrder() async {
    if (_data == null) return;

    if (_currentAddress == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Vui lòng chọn địa chỉ")));
      return;
    }

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
        shippingAddressId: _currentAddress!.addressId,
        promotionId: _selectedPromotion?.id,
        paymentMethod: _paymentMethod,
        isBuyFromCart: widget.isBuyFromCart,
        note: _noteController.text.trim(),
      );

      if (mounted) Navigator.pop(context);

      if (res['success'] == true) {
        if (_paymentMethod == "VNPAY" && res['paymentUrl'] != null) {
          final String url = res['paymentUrl'];
          final Uri uri = Uri.parse(url);

          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Đang mở trang thanh toán VNPay..."),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Không thể mở liên kết thanh toán")),
            );
          }
        } else {
          // COD
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("🎉 Đặt hàng thành công!"),
              backgroundColor: Colors.green,
            ),
          );
          // TODO: Nên dùng pushAndRemoveUntil để về Home và clear giỏ hàng
          Navigator.pop(context);
        }
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
  // --- 👇 HÀM TÍNH TOÁN LOGIC 20% ---

  // 1. Tính số tiền được giảm
  double get _calculateDiscount {
    if (_data == null) return 0;

    // LOGIC CỦA BẠN: Nếu mua từ giỏ và chưa chọn mã -> Giảm 20%
    if (widget.isBuyFromCart && promotionId == 0) {
      return _data!.subtotal * 0.2;
    }

    // Ngược lại: Lấy theo API (nếu có voucher)
    return _data!.totalDiscount;
  }

  // 2. Tính tổng tiền phải thanh toán cuối cùng
  double get _calculateFinalTotal {
    if (_data == null) return 0;
    // Tổng = Tiền hàng - Giảm giá + Ship + Thuế
    return _data!.subtotal -
        _calculateDiscount +
        _data!.shippingFee +
        _data!.taxFee;
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDC95F),
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
                        // --- ĐỊA CHỈ ---
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
                            color: const Color(0xFFF3E5AB),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Color(0xFF5D4037),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _currentAddress == null
                                    ? const Text(
                                        "Vui lòng chọn địa chỉ",
                                        style: TextStyle(color: Colors.red),
                                      )
                                    : Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _currentAddress!.name,
                                            style: const TextStyle(
                                              color: Color(0xFF5D4037),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            "${_currentAddress!.streetAddress}, ${_currentAddress!.district}, ${_currentAddress!.city}",
                                            style: const TextStyle(
                                              color: Color(0xFF5D4037),
                                              fontSize: 13,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  size: 20,
                                  color: Colors.grey,
                                ),
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AddressList(
                                        isFromCheckout: true,
                                      ),
                                    ),
                                  );
                                  if (result != null && result is Address) {
                                    setState(() {
                                      _currentAddress = result;
                                    });
                                    _fetchPreview();
                                  }
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // --- 5. KẾT NỐI SỰ KIỆN CHỌN VOUCHER ---
                        _buildSelectorRow(
                          title: "Phương thức thanh toán",
                          value: _paymentMethod == "COD"
                              ? "Tiền mặt (COD)"
                              : "VNPay (Online)",
                          icon: Icons.payment,
                          opTap: _showPaymentMethodPicker,
                        ),
                        const Divider(thickness: 0.5),
                        _buildSelectorRow(
                          title: "Mã khuyến mãi",
                          // Nếu đã chọn thì hiện tên, chưa chọn thì nhắc
                          value: _selectedPromotion != null
                              ? _selectedPromotion!.name
                              : "Chọn voucher",
                          icon: Icons.local_offer,
                          isHighlight: _selectedPromotion != null,
                          opTap: _onSelectVoucher, // <--- GẮN HÀM VÀO ĐÂY
                        ),

                        const SizedBox(height: 20),

                        // --- DANH SÁCH MÓN ---
                        const Text(
                          "Đơn Hàng",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3E2723),
                          ),
                        ),
                        const SizedBox(height: 10),
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

                        // --- TỔNG KẾT TIỀN ---
                        _buildSummaryRow(
                          "Tổng tiền hàng",
                          currency.format(_data!.subtotal),
                        ),
                        if (_calculateDiscount > 0)
                          _buildSummaryRow(
                            // Kiểm tra xem đang giảm theo kiểu nào để đặt tên
                            (promotionId == 0 && widget.isBuyFromCart)
                                ? "Ưu đãi giỏ hàng (20%)"
                                : "Khuyến mãi voucher",
                            "-${currency.format(_calculateDiscount)}", // Dùng hàm tính toán ở bước 2
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
                            widget.isBuyFromCart && promotionId == 0
                                ? Text(
                                    currency.format(_calculateFinalTotal),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22,
                                      color: Color(0xFFD84315),
                                    ),
                                  )
                                : Text(
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

                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFDC95F),
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

  Widget _buildSelectorRow({
    required String title,
    required String value,
    required IconData icon,
    bool isHighlight = false,
    VoidCallback? opTap,
  }) {
    return InkWell(
      onTap: opTap,
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