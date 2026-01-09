import 'package:appfastfood/models/reviews.dart';

class Product {
  final int id;
  final String name;
  final String description;
  final double price;         // Giá gốc
  final String imageUrl;
  final int categoryId;
  final String categoryName;
  final double? averageRating;
  final int? reviewCount;
  final List<Reviews> review;

  // --- 1. MỚI THÊM: Hứng dữ liệu khuyến mãi từ Server ---
  final double? finalPrice;       // Giá sau khi giảm (Server đã tính sẵn)
  final double? discountPercent;  // % Giảm giá (Ví dụ: 15.0)
  // ----------------------------------------------------

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.categoryId,
    required this.categoryName,
    this.averageRating,
    this.reviewCount,
    this.review = const [],
    // --- Thêm vào Constructor ---
    this.finalPrice,
    this.discountPercent,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: int.tryParse(json['product_id'].toString()) ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0,
      imageUrl: json['image_url'] ?? '',
      averageRating: double.tryParse(json['average_rating'].toString()) ?? 0.0,
      reviewCount: int.tryParse(json['review_count'].toString()) ?? 0,
      
      categoryId: int.tryParse(json['category_id'].toString()) ?? 0,
      categoryName: json['category_name'] ?? '',

      // --- 2. MỚI THÊM: Map dữ liệu từ JSON ---
      finalPrice: json['final_price'] != null 
          ? double.tryParse(json['final_price'].toString()) 
          : null, // Nếu null thì lát nữa UI sẽ hiển thị giá gốc
      
      discountPercent: json['discount_percent'] != null 
          ? double.tryParse(json['discount_percent'].toString()) 
          : null,
      // ---------------------------------------

      review: (json['reviews'] as List?)
              ?.map((item) => Reviews.fromJson(item))
              .toList() ??
          [],
    );
  }
}