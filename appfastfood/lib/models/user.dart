import 'dart:convert';

class User {
  final int accountId;
  final String username;
  final String role;
  final int status;
  final int userId;
  final String fullname;
  final String email;
  final String phone;
  final String? birthday;
  final String? image;

  User({
    required this.accountId,
    required this.username,
    required this.role,
    required this.status,
    required this.userId,
    required this.fullname,
    required this.email,
    required this.phone,
    this.birthday,
    this.image,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      accountId: json['account_id'] ?? 0,
      username: json['Username'] ?? '', 
      role: json['role'] ?? 'CUSTOMER',
      status: json['status'] ?? 0,
      userId: json['user_id'] ?? 0,
      fullname: json['fullname'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      birthday: json['BirthDay'],
      image: json['Image'], 
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'account_id': accountId,
      'Username': username,
      'role': role,
      'status': status,
      'user_id': userId,
      'fullname': fullname,
      'email': email,
      'phone': phone,
      'birthday': birthday,
      'Image': image,
    };
  }

  @override
  String toString() => jsonEncode(toJson());
}