class Promotion {
  final int id;
  final String name;
  final double discountPercent;
  final DateTime startDate;
  final DateTime endDate;

  Promotion({
    required this.id,
    required this.name,
    required this.discountPercent,
    required this.startDate,
    required this.endDate,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) {
    return Promotion(
      id: json['promotion_id'] ?? 0,
      name: json['name'] ?? '',
      discountPercent: double.tryParse(json['discount_percent'].toString()) ?? 0.0,
      startDate: DateTime.tryParse(json['start_date'].toString()) ?? DateTime.now(),
      endDate: DateTime.tryParse(json['end_date'].toString()) ?? DateTime.now(),
    );
  }
}