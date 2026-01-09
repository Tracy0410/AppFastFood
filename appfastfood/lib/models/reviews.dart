class Reviews {
  final double rating;
  final String desciption;
  final DateTime reviewDate;
  final String fullname;
  final String? image;

  Reviews({
    required this.rating,
    required this.desciption,
    required this.reviewDate,
    required this.fullname,
    this.image,
  });

  factory Reviews.fromJson(Map<String, dynamic> json) {
    return Reviews(
      rating: (json['rating'] != null)
          ? double.parse(json['rating'].toString())
          : 0.0,
      desciption: json['description'] ?? '',
      reviewDate:
          DateTime.tryParse(json['review_date'].toString()) ?? DateTime.now(),
      fullname: json['fullname'] ?? 'Ẩn danh',
      image: json['image'],
    );
  }
}
