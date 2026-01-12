class OrderItem {
  final int productId;
  final String foodName;
  final String image;
  final double price;
  final int quantity;
  final bool isRated; // <--- Thêm dòng này

  OrderItem({
    required this.productId,
    required this.foodName,
    required this.image,
    required this.price,
    required this.quantity,
    this.isRated = false, // <--- Mặc định là false
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['product_id'] ?? 0,
      foodName: json['food_name'] ?? '',
      image: json['image_url'] ?? '', // Kiểm tra lại key JSON của sếp
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      quantity: json['quantity'] ?? 1,
      // API CẦN TRẢ VỀ TRƯỜNG 'is_rated' (0 hoặc 1, true hoặc false)
      // Nếu API chưa có thì sếp phải thêm vào SQL query ở backend nhé
      isRated: (json['is_rated'] == 1 || json['is_rated'] == true),
    );
  }
}
