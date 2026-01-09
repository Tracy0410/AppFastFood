import 'package:appfastfood/models/cartItem.dart';
import 'package:appfastfood/models/checkout.dart';
import 'package:appfastfood/models/products.dart';
import 'package:appfastfood/service/api_service.dart';
import 'package:appfastfood/utils/storage_helper.dart';
import 'package:appfastfood/views/screens/users/checkout_screen.dart';
import 'package:flutter/material.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;

  bool _isLoggedIn = false;
  int? _userId;

  bool isLiking = false;
  bool isFav = false;

  bool _isAddingToCart = false;

  Product? _fullProduct;
  bool isLoadingReview = true;

  @override
  void initState() {
    super.initState();
    _checkFav();
    _fechFullProductData();
  }

  void _processBuyNow() {
    if (!_isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng đăng nhập để mua hàng")),
      );
      return;
    }

    // 1. Tạo đối tượng CartItem từ sản phẩm hiện tại
    // Lưu ý: Đảm bảo các trường khớp với CartItem model của bạn
    final itemToBuy = OrderItemReq(
      productId: widget.product.id, // hoặc id
      // name: widget.product.name,
      // imageUrl: widget.product.imageUrl,
      // price: widget.product.price,
      quantity: _quantity,
      // cartId: 0, // ID giả vì chưa vào DB giỏ hàng
      note: "", // Nếu model có trường note
    );

    // 2. Chuyển sang màn hình Checkout
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(
          inputItems: [itemToBuy], // Truyền dưới dạng List
          isBuyFromCart: false, // Đánh dấu là mua ngay (không phải từ giỏ)
        ),
      ),
    );
  }

  void _fechFullProductData() async {
    var data = await ApiService().getProductById(widget.product.id);
    if (mounted) {
      setState(() {
        _fullProduct = data;
        isLoadingReview = false;
      });
    }
  }

  void _checkFav() async {
    await _checkLoginStatus();
    if (_isLoggedIn) {
      bool isLiked = await ApiService().checkFav(widget.product.id);
      if (mounted) {
        setState(() {
          isFav = isLiked;
        });
      }
    }
  }

  void _onLiked() async {
    if (isLiking) return;
    if (!_isLoggedIn) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Bạn cần đăng nhập!")));
      return;
    }
    setState(() {
      isLiking = true;
    });
    if (isFav) {
      bool success = await ApiService().removeFavorite(widget.product.id);
      if (success) {
        setState(() {
          isFav = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Bạn vừa xóa khỏi món ăn yêu thich")),
        );
      }
    } else {
      bool success = await ApiService().addFavorites(widget.product.id);
      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Đã thêm vào yêu thích!")));
        setState(() {
          isFav = true;
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Thích chưa thành công")));
      }
    }
    setState(() {
      isLiking = false;
    });
  }

  Future<void> _checkLoginStatus() async {
    final token = await StorageHelper.getToken();
    final userId = await StorageHelper.getUserId();
    if (mounted) {
      setState(() {
        _isLoggedIn = (token != null && token.isNotEmpty);
        if (userId != null) _userId = userId;
      });
    }
  }

  Future<void> _addtoCart() async {
    if (!_isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bạn cần đăng nhập để thêm sản phẩm")),
      );
      return;
    }
    setState(() {
      _isAddingToCart = true;
    });

    bool success = await ApiService().addToCart(
      widget.product.id,
      _quantity,
      'Không ghi chú',
    );
    setState(() {
      _isAddingToCart = false;
    });
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Đã thêm món vào giỏ hàng!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating, // Nổi lên cho đẹp
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sản phẩm đã có trong giỏ hàng")),
        );
      }
    }
  }

  void _incrementQuantity() {
    setState(() {
      _quantity++;
    });
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFE95322);
    final displayProduct = _fullProduct ?? widget.product;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFFFFC529),
        title: Text(
          "Chi tiết sản phẩm",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isLoggedIn)
            IconButton(
              onPressed: () => _onLiked(),
              icon: isFav
                  ? Icon(Icons.favorite, color: Colors.red)
                  : Icon(Icons.favorite_border_outlined, color: Colors.white),
            ),
        ],
      ),
      // Mở rộng body lên phần AppBar nếu muốn ảnh nền full
      extendBodyBehindAppBar: true,

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. ẢNH SẢN PHẨM
            Container(
              height: 350,
              width: double.infinity,
              color: Colors.grey[100], // Màu nền tạm khi chưa load ảnh
              child: widget.product.imageUrl.isNotEmpty
                  ? Image.network(
                      widget.product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.image_not_supported, size: 50),
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.image_not_supported, size: 50),
                    ),
            ),

            // 2. PHẦN THÔNG TIN (Bo tròn kéo lên trên ảnh một chút cho đẹp)
            Container(
              transform: Matrix4.translationValues(0.0, -30.0, 0.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thanh ngang nhỏ trang trí
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tên sản phẩm & Giá
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${widget.product.price}đ",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildQuantityButton(
                            Icons.remove,
                            _decrementQuantity,
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              "$_quantity",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _buildQuantityButton(Icons.add, _incrementQuantity),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.product.name,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Rating và Thời gian (Giả lập)
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        "${widget.product.averageRating}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 20),
                      const Icon(
                        Icons.access_time,
                        color: Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        "15-20 phút",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // Mô tả
                  const Text(
                    "Mô tả",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    width: 400,
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color.fromARGB(255, 160, 160, 160),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      widget.product.description ??
                          'Chưa có mô tả cho sản phẩm này.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Divider(),

                  const SizedBox(height: 10),

                  const Text(
                    "Đánh giá sản phẩm này",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),

                  const SizedBox(height: 5),
                  if (isLoadingReview)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (displayProduct.review.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      alignment: Alignment.center,
                      child: Column(
                        children: const [
                          Icon(
                            Icons.comment_outlined,
                            color: Colors.grey,
                            size: 40,
                          ),
                          SizedBox(height: 10),
                          Text(
                            "Chưa có đánh giá nào.",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap:
                          true, // BẮT BUỘC: Để cuộn được trong SingleChildScrollView
                      physics:
                          const NeverScrollableScrollPhysics(), // Tắt cuộn riêng của list view
                      itemCount: displayProduct.review.length,
                      itemBuilder: (context, index) {
                        final review = displayProduct.review[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 15),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Avatar và Tên
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundImage:
                                        (review.image != null &&
                                            review.image!.isNotEmpty)
                                        ? NetworkImage(review.image!)
                                        : null,
                                    child:
                                        (review.image == null ||
                                            review.image!.isEmpty)
                                        ? const Icon(
                                            Icons.person,
                                            size: 20,
                                            color: Colors.grey,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      review.fullname,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  // Hiển thị ngày (nhỏ)
                                  Text(
                                    "${review.reviewDate.day}/${review.reviewDate.month}/${review.reviewDate.year}", // Cắt chuỗi ngày cho gọn
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Số sao rating
                              Row(
                                children: List.generate(5, (starIndex) {
                                  return Icon(
                                    Icons.star,
                                    size: 14,
                                    color: starIndex < review.rating
                                        ? Colors.amber
                                        : Colors.grey[300],
                                  );
                                }),
                              ),
                              const SizedBox(height: 8),

                              // Nội dung comment
                              Text(
                                review.desciption,
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Tổng tiền: ",
                  style: TextStyle(color: const Color.fromARGB(255, 0, 0, 0)),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: AlignmentGeometry.bottomRight,
                  child: Text(
                    "${widget.product.price * _quantity} VNĐ",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
              SizedBox(width: 10),
            ],
          ),
          SizedBox(height: 10),
          Divider(),
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(onPressed: () {}, icon: Icon(Icons.chat)),
              ),
              SizedBox(
                height: 45,
                child: VerticalDivider(
                  color: primaryColor,
                  thickness: 1,
                  width: 20,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _isAddingToCart
                    ? SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(),
                      )
                    : IconButton(
                        onPressed: () {
                          _addtoCart();
                        },
                        icon: Icon(Icons.shopping_cart_checkout_outlined),
                      ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // if (_isLoggedIn) {
                    //   ScaffoldMessenger.of(context).showSnackBar(
                    //     const SnackBar(
                    //       content: Text("Mua thành công sản phẩm"),
                    //     ),
                    //   );
                    // } else {
                    //   ScaffoldMessenger.of(context).showSnackBar(
                    //     const SnackBar(
                    //       content: Text("Vui lòng đăng nhập tài khoản"),
                    //     ),
                    //   );
                    // }
                    _processBuyNow();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.all(10),
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadiusGeometry.circular(10),
                    ),
                  ),
                  child: Text("Mua với voucher"),
                ),
              ),
              SizedBox(width: 10),
            ],
          ),
        ],
      ),
    );
  }

  // Widget nút tăng giảm số lượng
  Widget _buildQuantityButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 244, 148, 3),
        borderRadius: BorderRadius.circular(50),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.black),
        // splashRadius: 20,
      ),
    );
  }
}
