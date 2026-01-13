import 'package:appfastfood/models/reviews.dart';

class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final int categoryId;
  final String categoryName;
  final double averageRating;
  final int reviewCount;
  final int status;
  final List<Reviews> reviews;

  final double? finalPrice;
  final double? discountPercent;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.categoryId,
    required this.categoryName,
    this.averageRating = 0.0,
    this.reviewCount = 0,
    this.status = 1,
    this.reviews = const [],
    this.finalPrice,
    this.discountPercent,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: int.tryParse(json['product_id'].toString()) ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      imageUrl: json['image_url'] ?? '',
      categoryId: int.tryParse(json['category_id'].toString()) ?? 0,
      categoryName: json['category_name'] ?? '',
      averageRating: double.tryParse(json['average_rating'].toString()) ?? 0.0,
      reviewCount: int.tryParse(json['review_count'].toString()) ?? 0,
      status: int.tryParse(json['status'].toString()) ?? 1,
      
      finalPrice: json['final_price'] != null 
          ? double.tryParse(json['final_price'].toString()) 
          : null,
      
      discountPercent: json['discount_percent'] != null 
          ? double.tryParse(json['discount_percent'].toString()) 
          : null,

      reviews: (json['reviews'] as List?)
              ?.map((item) => Reviews.fromJson(item))
              .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': id,
      'name': name,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'category_id': categoryId,
      'category_name': categoryName,
      'status': status,
      'final_price': finalPrice,
      'discount_percent': discountPercent,
    };
  }
}