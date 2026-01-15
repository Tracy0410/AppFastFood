class OrderItem {
  final int productId;
  final String foodName;
  final String image;
  final double price;
  final int quantity;
  final bool isRated;

  OrderItem({
    required this.productId,
    required this.foodName,
    required this.image,
    required this.price,
    required this.quantity,
    this.isRated = false,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['product_id'] ?? 0,
      foodName: json['food_name'] ?? '',
      image: json['image_url'] ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      quantity: json['quantity'] ?? 1,
      isRated: (json['is_rated'] == 1 || json['is_rated'] == true),
    );
  }
}
