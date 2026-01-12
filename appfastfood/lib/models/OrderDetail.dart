class OrderDetail {
  final int detailId;
  final int orderId;
  final int productId;
  final String productName; // Lấy từ bảng Products (JOIN)
  final String? productImage; // Lấy từ bảng Products (JOIN)
  final int quantity;
  final double unitPrice;
  final double finalLinePrice;

  OrderDetail({
    required this.detailId,
    required this.orderId,
    required this.productId,
    required this.productName,
    this.productImage,
    required this.quantity,
    required this.unitPrice,
    required this.finalLinePrice,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    return OrderDetail(
      detailId: json['detail_id'] ?? 0,
      orderId: json['order_id'] ?? 0,
      productId: json['product_id'] ?? 0,
      // API cần trả về tên và ảnh sản phẩm trong object này
      productName: json['product_name'] ?? 'Sản phẩm không xác định',
      productImage: json['product_image'], 
      quantity: json['quantity'] ?? 0,
      // Dùng num.toDouble() để an toàn nếu JSON trả về số nguyên
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      finalLinePrice: (json['final_line_price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'detail_id': detailId,
      'order_id': orderId,
      'product_id': productId,
      'product_name': productName,
      'product_image': productImage,
      'quantity': quantity,
      'unit_price': unitPrice,
      'final_line_price': finalLinePrice,
    };
  }
}
