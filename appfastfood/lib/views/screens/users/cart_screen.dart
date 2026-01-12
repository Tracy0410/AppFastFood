import 'package:appfastfood/models/cartItem.dart';
import 'package:appfastfood/models/checkout.dart';
import 'package:appfastfood/service/api_service.dart';
import 'package:appfastfood/views/screens/users/checkout_screen.dart';
import 'package:appfastfood/views/widget/product_card_cart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<CartItem> _cartItem = [];
  bool _isLoading = true;
  double _subTotal = 0.0;
  final currentFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  final Set<int> _selecteItem = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      var items = await ApiService().getCartList();
      if (mounted) {
        setState(() {
          _cartItem = items;
          _selecteItem.clear();
          for (var item in items) {
            _selecteItem.add(item.cartId);
          }
          _calculateTotal();
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Lỗi $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _processCheckout() async {
    // 1. Kiểm tra xem có chọn món nào chưa
    if (_selecteItem.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ít nhất 1 món để thanh toán'),
        ),
      );
      return;
    }

    // 2. Lọc ra các món đã tích chọn (Checkbox)
    final selectedCartItems = _cartItem
        .where((item) => _selecteItem.contains(item.cartId))
        .toList();

    // 3. Chuyển đổi từ CartItem (model giỏ hàng) sang OrderItemReq (model gửi lên API đặt hàng)
    // Lưu ý: Đảm bảo class OrderItemReq có constructor nhận productId, quantity, note
    List<OrderItemReq> itemsToCheckout = selectedCartItems.map((item) {
      return OrderItemReq(
        productId: item.productId,
        categoryId: item.categoryId,
        quantity: item.quantity,
        note: item.note ?? "", // Nếu note null thì để rỗng
      );
    }).toList();

    // 4. Chuyển sang màn hình Checkout
    // Dùng await Navigator.push để khi user quay lại (back), ta load lại giỏ hàng
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(
          inputItems: itemsToCheckout, // Truyền danh sách món
          isBuyFromCart:
              true, // Đánh dấu là mua từ giỏ (để server biết đường xóa giỏ hàng sau khi mua)
        ),
      ),
    );

    // 5. Sau khi quay lại từ trang Checkout (dù mua thành công hay chưa), load lại giỏ hàng
    _fetchData();
  }

  double _calculateTotal() {
    double temp = 0;
    for (var item in _cartItem) {
      if (_selecteItem.contains(item.cartId)) {
        temp += item.price * item.quantity;
      }
    }
    setState(() {
      _subTotal = temp;
    });
    return _subTotal;
  }

  void _choseItem(int cartId) {
    setState(() {
      if (_selecteItem.contains(cartId)) {
        _selecteItem.remove(cartId);
      } else {
        _selecteItem.add(cartId);
      }
      _calculateTotal();
    });
  }

  void _choseAll(bool? value) {
    setState(() {
      if (value == true) {
        for (var item in _cartItem) {
          _selecteItem.add(item.cartId);
        }
      } else {
        _selecteItem.clear();
      }
      _calculateTotal();
    });
  }

  Future<void> _deleteItem(int index) async {
    final item = _cartItem[index];
    bool success = await ApiService().removeCart(item.cartId);
    if (success) {
      setState(() {
        _cartItem.removeAt(index);
        _calculateTotal();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Đã xóa khỏi giỏ hàng")));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Thực hiện đã bị lỗi")));
    }
  }

  Future<void> _updateItem(int index, int newQuantity, String newNote) async {
    final item = _cartItem[index];
    int oldQuantity = item.quantity;
    setState(() {
      item.quantity = newQuantity;
      _calculateTotal();
    });

    try {
      bool success = await ApiService().updateCart(
        item.cartId,
        newQuantity,
        newNote,
      );
      if (!success) {
        setState(() {
          item.quantity = oldQuantity;
          _calculateTotal();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Lỗi kết nối, không cập nhật được giỏ hàng"),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        item.quantity = oldQuantity;
        _calculateTotal();
      });
      print("Lỗi update: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    double finalTotal = _calculateTotal();
    bool isAllSelected =
        _cartItem.isNotEmpty && _selecteItem.length == _cartItem.length;

    return Scaffold(
      backgroundColor: Colors.grey[50], // Thêm màu nền nhẹ cho đẹp
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFC529),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Giỏ Hàng",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: isAllSelected,
                          activeColor: const Color(0xFFE95322),
                          onChanged: (value) => _choseAll(value),
                        ),
                        const Text(
                          "Chọn tất cả",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          "Đã chọn: ${_selecteItem.length}",
                          style: const TextStyle(
                            color: Color(0xFFE95322),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _cartItem.isEmpty
                        ? const Center(child: Text("Giỏ hàng trống"))
                        : ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: _cartItem.length,
                            itemBuilder: (context, index) {
                              final item = _cartItem[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 15),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: _selecteItem.contains(item.cartId),
                                      activeColor: const Color(0xFFE95322),
                                      onChanged: (value) =>
                                          _choseItem(item.cartId),
                                    ),
                                    Expanded(
                                      child: CardProductCart(
                                        item: item,
                                        onIncrease: () => _updateItem(
                                          index,
                                          item.quantity + 1,
                                          item.note ?? "",
                                        ),
                                        onDecrease: () {
                                          if (item.quantity > 1) {
                                            _updateItem(
                                              index,
                                              item.quantity - 1,
                                              item.note ?? "",
                                            );
                                          }
                                        },
                                        onDelete: () => _deleteItem(index),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Tổng Cộng",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              currentFormat.format(finalTotal),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE95322),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _selecteItem.isEmpty
                                ? null
                                : () {
                                    _processCheckout();
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFC529),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: Text(
                              "Đến thanh toán ${_selecteItem.length} món hàng",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE95322),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
