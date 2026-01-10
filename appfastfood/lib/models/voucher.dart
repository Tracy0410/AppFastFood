class Voucher {
  final int id; // promotion_id
  final String title; // name
  final double discountPercent; // discount_percent
  final DateTime expiryDate; // end_date

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
      // DB trả về decimal/string nên cần parse kỹ
      discountPercent:
          double.tryParse(json['discount_percent'].toString()) ?? 0.0,
      expiryDate: DateTime.parse(json['end_date']),
    );
  }
}
