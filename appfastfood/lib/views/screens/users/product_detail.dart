import 'package:appfastfood/models/checkout.dart';
import 'package:appfastfood/models/products.dart';
import 'package:appfastfood/service/api_service.dart';
import 'package:appfastfood/utils/storage_helper.dart';
import 'package:appfastfood/views/screens/users/checkout_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // 1. Import thư viện format tiền

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  // --- State Variables ---
  int _quantity = 1;
  bool _isLoggedIn = false;
  bool _isLiking = false;
  bool _isFav = false;
  bool _isAddingToCart = false;
  bool _isLoadingReview = true;
  Product? _fullProduct;

  // --- Constants ---
  final Color primaryColor = const Color(0xFFE95322);

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _fetchFullProductData();
  }

  // --- Logic Methods (Giữ nguyên không đổi) ---

  Future<void> _checkLoginStatus() async {
    final token = await StorageHelper.getToken();
    setState(() {
      _isLoggedIn = (token != null && token.isNotEmpty);
    });
    if (_isLoggedIn) {
      _checkFav();
    }
  }

  void _fetchFullProductData() async {
    try {
      var data = await ApiService().getProductById(widget.product.id);
      if (mounted) {
        setState(() {
          _fullProduct = data;
          _isLoadingReview = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingReview = false);
    }
  }

  void _checkFav() async {
    bool isLiked = await ApiService().checkFav(widget.product.id);
    if (mounted) {
      setState(() {
        _isFav = isLiked;
      });
    }
  }

  void _toggleFavorite() async {
    if (_isLiking) return;
    if (!_isLoggedIn) {
      _showSnackBar(
        "Bạn cần đăng nhập để thực hiện chức năng này!",
        isError: true,
      );
      return;
    }

    setState(() => _isLiking = true);

    bool success;
    if (_isFav) {
      success = await ApiService().removeFavorite(widget.product.id);
      if (success) _showSnackBar("Đã xóa khỏi danh sách yêu thích");
    } else {
      success = await ApiService().addFavorites(widget.product.id);
      if (success)
        _showSnackBar("Đã thêm vào danh sách yêu thích", isError: false);
    }

    if (success && mounted) {
      setState(() => _isFav = !_isFav);
    }

    setState(() => _isLiking = false);
  }

  void _addToCart() async {
    if (!_isLoggedIn) {
      _showSnackBar("Bạn cần đăng nhập để thêm sản phẩm", isError: true);
      return;
    }

    setState(() => _isAddingToCart = true);

    bool success = await ApiService().addToCart(
      widget.product.id,
      _quantity,
      '',
    );

    setState(() => _isAddingToCart = false);

    if (mounted) {
      if (success) {
        _showSnackBar("Đã thêm món vào giỏ hàng!", isError: false);
      } else {
        _showSnackBar(
          "Sản phẩm đã có trong giỏ hàng hoặc lỗi xảy ra",
          isError: true,
        );
      }
    }
  }

  void _processBuyNow() {
    if (!_isLoggedIn) {
      _showSnackBar("Vui lòng đăng nhập để mua hàng", isError: true);
      return;
    }

    final itemToBuy = OrderItemReq(
      productId: widget.product.id,
      categoryId: widget.product.categoryId,
      quantity: _quantity,
      note: "",
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CheckoutScreen(inputItems: [itemToBuy], isBuyFromCart: false),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // --- UI Methods ---

  @override
  Widget build(BuildContext context) {
    // 2. Khai báo formatter
    final formatCurrency = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'VNĐ',
      decimalDigits: 0,
    );

    final displayProduct = _fullProduct ?? widget.product;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Container(
              transform: Matrix4.translationValues(0.0, -30.0, 0.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDragHandle(),
                  const SizedBox(height: 20),

                  // Truyền formatter vào hàm này
                  _buildPriceAndQuantity(formatCurrency),

                  const SizedBox(height: 15),
                  Text(
                    widget.product.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildRatingAndTime(displayProduct),
                  const SizedBox(height: 25),
                  const Text(
                    "Mô tả",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.product.description ??
                        'Chưa có mô tả cho sản phẩm này.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 10),
                  const Text(
                    "Đánh giá sản phẩm",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  _buildReviewSection(displayProduct),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      // Truyền formatter xuống bottom bar
      bottomNavigationBar: _buildBottomBar(formatCurrency),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      backgroundColor: const Color(0xFFFFC529),
      expandedHeight: 350.0,
      pinned: true,
      stretch: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (_isLoggedIn)
          IconButton(
            onPressed: _toggleFavorite,
            icon: Icon(
              _isFav ? Icons.favorite : Icons.favorite_border_outlined,
              color: _isFav ? Colors.red : Colors.white,
              size: 28,
            ),
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        stretchModes: const [StretchMode.zoomBackground],
        background: widget.product.imageUrl.isNotEmpty
            ? Image.network(
                widget.product.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image),
                ),
              )
            : Container(color: Colors.grey[200]),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        width: 50,
        height: 5,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // 3. Update UI: Giá tiền (Đơn giá)
  Widget _buildPriceAndQuantity(NumberFormat formatCurrency) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          formatCurrency.format(widget.product.price), // Format ở đây
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        Row(
          children: [
            _buildQuantityButton(Icons.remove, () {
              if (_quantity > 1) setState(() => _quantity--);
            }),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Text(
                "$_quantity",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildQuantityButton(Icons.add, () {
              setState(() => _quantity++);
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildQuantityButton(IconData icon, VoidCallback onTap) {
    return Container(
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 244, 148, 3),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white, size: 20),
        constraints: const BoxConstraints(),
        padding: const EdgeInsets.all(8),
      ),
    );
  }

  Widget _buildRatingAndTime(Product product) {
    return Row(
      children: [
        const Icon(Icons.star, color: Colors.amber, size: 20),
        const SizedBox(width: 4),
        Text(
          "${product.averageRating}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(width: 20),
        const Icon(Icons.access_time, color: Colors.grey, size: 20),
        const SizedBox(width: 4),
        const Text("15-20 phút", style: TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildReviewSection(Product displayProduct) {
    if (_isLoadingReview) {
      return const Center(child: CircularProgressIndicator());
    }
    if (displayProduct.reviews.isEmpty) {
      return Center(
        child: Column(
          children: const [
            Icon(Icons.comment_outlined, color: Colors.grey, size: 40),
            Text("Chưa có đánh giá nào.", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayProduct.reviews.length,
      itemBuilder: (context, index) {
        final review = displayProduct.reviews[index];
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
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage:
                        (review.image != null && review.image!.isNotEmpty)
                        ? NetworkImage(review.image!)
                        : null,
                    child: (review.image == null || review.image!.isEmpty)
                        ? const Icon(Icons.person, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review.fullname,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "${review.reviewDate.day}/${review.reviewDate.month}/${review.reviewDate.year}",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    Icons.star,
                    size: 14,
                    color: index < review.rating
                        ? Colors.amber
                        : Colors.grey[300],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(review.desciption, style: const TextStyle(height: 1.4)),
            ],
          ),
        );
      },
    );
  }

  // 4. Update UI: Tổng tiền (Bottom Bar)
  Widget _buildBottomBar(NumberFormat formatCurrency) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Tổng tiền:", style: TextStyle(color: Colors.grey)),
                Text(
                  formatCurrency.format(
                    widget.product.price * _quantity,
                  ), // Format ở đây
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Nút Giỏ hàng
            Container(
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: _isAddingToCart
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      onPressed: _addToCart,
                      icon: Icon(
                        Icons.shopping_cart_outlined,
                        color: primaryColor,
                      ),
                    ),
            ),
            // Nút Mua ngay
            ElevatedButton(
              onPressed: _processBuyNow,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Mua ngay",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
