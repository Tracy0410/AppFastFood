class Voucher {
  final int id;
  final String title;
  final double discountPercent;
  final DateTime expiryDate;

  Voucher({
    required this.id,
    required this.title,
    required this.discountPercent,
    required this.expiryDate,
  });

  factory Voucher.fromJson(Map<String, dynamic> json) {
    return Voucher(
      id: json['promotion_id'],
      title: json['name'],
      discountPercent:
          double.tryParse(json['discount_percent'].toString()) ?? 0.0,
      expiryDate: DateTime.parse(json['end_date']),
    );
  }
}
