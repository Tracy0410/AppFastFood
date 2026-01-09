class OrderItemReq {
  final int productId;
  final int quantity;
  final String note;
  OrderItemReq({
    required this.productId,
    required this.quantity,
    this.note = '',
  });
  Map<String, dynamic> toJson() => {
    'productId': productId,
    'quantity': quantity,
    'note': note,
  };
}

// Model hứng dữ liệu Preview trả về (Backend trả gì mình hứng nấy)
class CheckoutPreviewRes {
  final double subtotal;
  final double totalDiscount;
  final double shippingFee;
  final double taxFee;
  final double totalAmount;
  final List<PreviewItem> items;

  CheckoutPreviewRes({
    required this.subtotal,
    required this.totalDiscount,
    required this.shippingFee,
    required this.taxFee,
    required this.totalAmount,
    required this.items,
  });

  factory CheckoutPreviewRes.fromJson(Map<String, dynamic> json) {
    return CheckoutPreviewRes(
      subtotal: double.tryParse(json['subtotal'].toString()) ?? 0.0,
      totalDiscount:
          double.tryParse(json['totalDiscountAmount'].toString()) ?? 0.0,
      shippingFee: double.tryParse(json['shippingFee'].toString()) ?? 0.0,
      taxFee: double.tryParse(json['taxFee'].toString()) ?? 0.0,
      totalAmount: double.tryParse(json['totalAmount'].toString()) ?? 0.0,
      items: (json['items'] as List? ?? [])
          .map((e) => PreviewItem.fromJson(e))
          .toList(),
    );
  }
}

class PreviewItem {
  final int productId;
  final String name;
  final String image;
  final int quantity;
  final double unitPrice;
  final double finalLinePrice;

  PreviewItem({
    required this.productId,
    required this.name,
    required this.image,
    required this.quantity,
    required this.unitPrice,
    required this.finalLinePrice,
  });

  // Getter tính đơn giá thực tế sau khi giảm
  double get discountedUnitPrice =>
      quantity > 0 ? finalLinePrice / quantity : 0.0;

  factory PreviewItem.fromJson(Map<String, dynamic> json) {
    return PreviewItem(
      productId: json['product_id'] ?? 0,
      name: json['name'] ?? 'Unknown',
      image: json['image'] ?? '',
      quantity: json['quantity'] ?? 0,
      unitPrice: double.tryParse(json['unit_price'].toString()) ?? 0.0,
      finalLinePrice:
          double.tryParse(json['final_line_price'].toString()) ?? 0.0,
    );
  }
}
