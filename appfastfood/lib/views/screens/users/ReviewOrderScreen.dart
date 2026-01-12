import 'package:appfastfood/models/Order.dart';
import 'package:appfastfood/models/orderItem.dart';
import 'package:appfastfood/models/reviewModel.dart';
import 'package:appfastfood/service/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class ReviewOrderScreen extends StatefulWidget {
  final OrderModel order;

  const ReviewOrderScreen({super.key, required this.order});

  @override
  State<ReviewOrderScreen> createState() => _ReviewOrderScreenState();
}

class _ReviewOrderScreenState extends State<ReviewOrderScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  // Map lưu trữ đánh giá
  final Map<int, double> _ratings = {};
  final Map<int, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    // Khởi tạo controller cho tất cả các món
    for (var item in widget.order.items) {
      _ratings[item.productId] = 5.0;
      _controllers[item.productId] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final itemsToReview = widget.order.items
        .where((item) => !item.isRated)
        .toList();
    if (itemsToReview.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tất cả món ăn đã được đánh giá!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    List<ReviewModel> reviewsToSend = [];

    for (var item in itemsToReview) {
      reviewsToSend.add(
        ReviewModel(
          orderId: widget.order.id,
          productId: item.productId,
          rating: _ratings[item.productId] ?? 5.0,
          comment: _controllers[item.productId]?.text.trim() ?? '',
        ),
      );
    }
    bool success = await _apiService.submitReviews(reviewsToSend);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text("Thành công!"),
            content: const Text("Cảm ơn bạn đã đánh giá."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context, true);
                },
                child: const Text("Đóng"),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Gửi đánh giá thất bại! Vui lòng thử lại."),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.order.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Đánh giá")),
        body: const Center(child: Text("Không tải được danh sách món ăn.")),
      );
    }

    // Kiểm tra xem còn món nào CHƯA đánh giá không
    bool hasPendingReviews = widget.order.items.any((item) => !item.isRated);

    return Scaffold(
      appBar: AppBar(title: const Text("Đánh giá đơn hàng"), centerTitle: true),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: widget.order.items.length,
              separatorBuilder: (_, __) => const Divider(height: 30),
              itemBuilder: (context, index) {
                final item = widget.order.items[index];
                return _buildReviewItem(item);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 5,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                // Disable nút nếu đang loading HOẶC không còn món nào để đánh giá
                onPressed: (_isLoading || !hasPendingReviews)
                    ? null
                    : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE95322),
                  disabledBackgroundColor:
                      Colors.grey, // Màu khi nút bị disable
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : Text(
                        hasPendingReviews
                            ? "Gửi đánh giá"
                            : "Đã hoàn tất đánh giá",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget hiển thị từng món (Đã cập nhật logic khóa giao diện)
  Widget _buildReviewItem(OrderItem item) {
    // Biến kiểm tra xem món này đã được đánh giá từ trước chưa
    // (Được truyền từ API thông qua Model)
    bool isRated = item.isRated;

    return Opacity(
      // Làm mờ nếu đã đánh giá
      opacity: isRated ? 0.6 : 1.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  image: item.image.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(item.image),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: item.image.isEmpty
                    ? const Icon(Icons.fastfood, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.foodName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    // Hiển thị dòng thông báo nếu đã đánh giá
                    if (isRated)
                      const Padding(
                        padding: EdgeInsets.only(top: 4.0),
                        child: Text(
                          "(Đã gửi đánh giá)",
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // --- THANH ĐÁNH GIÁ SAO ---
          Center(
            child: RatingBar.builder(
              initialRating:
                  5, // Nếu sếp có lưu số sao cũ thì điền vào đây: isRated ? item.oldRating : 5
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: false,
              itemCount: 5,
              // KHÓA thao tác vuốt nếu đã đánh giá
              ignoreGestures: isRated,
              itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
              itemBuilder: (context, _) => Icon(
                Icons.star,
                // Đổi màu xám nếu đã khóa
                color: isRated ? Colors.grey : Colors.amber,
              ),
              onRatingUpdate: (rating) {
                if (!isRated) {
                  _ratings[item.productId] = rating;
                }
              },
            ),
          ),
          const SizedBox(height: 12),

          // --- Ô NHẬP COMMENT ---
          TextField(
            controller: _controllers[item.productId],
            // KHÓA ô nhập liệu (Read Only)
            readOnly: isRated,
            decoration: InputDecoration(
              // Đổi text gợi ý
              hintText: isRated
                  ? "Bạn đã đánh giá món này rồi"
                  : "Món ăn thế nào? (Tùy chọn)",
              filled: true,
              // Đổi màu nền xám nếu đã khóa
              fillColor: isRated ? Colors.grey[200] : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}
