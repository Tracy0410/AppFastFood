class CartItem {
  final int cartId;
  final int productId;
  final int categoryId;
  final String name;
  final double price;
  final String imageUrl;
  int quantity;
  String note;

  CartItem({
    required this.cartId,
    required this.productId,
    this.categoryId = 0,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.quantity,
    this.note = '',
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      cartId: json['cart_id'] ?? 0,
      productId: json['product_id'] ?? 0,
      categoryId: json['category_id'] ?? 0,
      name: json['name'] ?? '',
      // Xử lý giá tiền: JSON trả về String "55000.00" -> cần parse
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      imageUrl: json['image_url'] ?? '',
      quantity: json['quantity'] ?? 0,
      note: json['note'] ?? '',
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'cart_id': cartId,
      'product_id': productId, // Quan trọng: server thường dùng snake_case
      'category_id': categoryId, // Quan trọng
      'name': name,
      'price': price,
      'image_url': imageUrl,
      'quantity': quantity,
      'note': note,
    };
  }
}
