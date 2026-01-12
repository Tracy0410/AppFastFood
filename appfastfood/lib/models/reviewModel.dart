class ReviewModel {
  final int orderId; // Thêm cái này để backend biết review của đơn nào
  final int productId;
  final double rating;
  final String comment;

  ReviewModel({
    required this.orderId,
    required this.productId,
    required this.rating,
    required this.comment,
  });

  // Hàm chuyển đổi sang JSON để gửi đi
  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'product_id': productId,
      'rating': rating,
      'comment': comment,
    };
  }
}
