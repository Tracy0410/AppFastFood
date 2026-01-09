class Promotion {
  final int id;
  final String name;
  final double discountPercent;
  final DateTime endDate;

  Promotion({
    required this.id,
    required this.name,
    required this.discountPercent,
    required this.endDate,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) {
    return Promotion(
      id: json['promotion_id'] ?? 0,
      name: json['name'] ?? '',
      // Ép kiểu sang double cẩn thận
      discountPercent: double.tryParse(json['discount_percent'].toString()) ?? 0.0,
      endDate: DateTime.tryParse(json['end_date'].toString()) ?? DateTime.now(),
    );
  }
}