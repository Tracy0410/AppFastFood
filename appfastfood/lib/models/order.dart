import 'package:flutter/material.dart';

class OrderModel {
  final int id; // Mã đơn hàng
  final DateTime date; // Ngày giờ đặt
  final String status;
  final String paymentStatus;
  final String paymentMethod;
  final double subTotal;
  final double discount;
  final double tax;
  final double totalAmount;
  final String itemsSummary;
  final String thumbnail;

  OrderModel({
    required this.id,
    required this.date, // <--- Quan trọng
    required this.status,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.subTotal,
    required this.discount,
    required this.tax,
    required this.totalAmount,
    required this.itemsSummary,
    required this.thumbnail,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['order_id'],
      date: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),

      status: json['order_status'],
      paymentStatus: json['payment_status'],
      paymentMethod: json['payment_method'] ?? 'COD',
      subTotal: double.tryParse(json['subtotal'].toString()) ?? 0.0,
      discount: double.tryParse(json['discount_amount'].toString()) ?? 0.0,
      tax: double.tryParse(json['tax_fee'].toString()) ?? 0.0,
      totalAmount: double.tryParse(json['total_amount'].toString()) ?? 0.0,
      itemsSummary: json['items_summary'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
    );
  }

  // Helper check trạng thái
  bool get isUnpaidVNPay =>
      paymentMethod == 'VNPAY' &&
      paymentStatus == 'UNPAID' &&
      status != 'CANCELLED';

  // Helper lấy màu trạng thái
  Color get statusColor {
    if (status == 'CANCELLED') return Colors.red;
    if (status == 'COMPLETED' || status == 'DELIVERED') return Colors.green;
    return Colors.blue;
  }

  // Helper text trạng thái
  String get statusText {
    if (status == 'CANCELLED') return "Đã hủy";
    if (status == 'COMPLETED' || status == 'DELIVERED') return "Hoàn thành";
    if (status == 'PENDING') return "Chờ xác nhận";
    if (status == 'SHIPPED') return "Đang giao";
    return "Đang xử lý";
  }
}
