import 'package:appfastfood/models/orderItem.dart';
import 'package:flutter/material.dart';

// --- 1. OrderItem class (Viết chung vào đây cho gọn) ---

// --- 2. OrderModel (Đã fix để không phải sửa code chỗ khác) ---
class OrderModel {
  final int id;
  final DateTime date;
  final String status;
  final String paymentStatus;
  final String paymentMethod;
  final double subTotal;
  final double discount;
  final double tax;
  final double totalAmount;
  final String itemsSummary;
  final String thumbnail;

  // Danh sách chi tiết (Để mặc định là rỗng để không bị lỗi code cũ)
  final List<OrderItem> items;

  OrderModel({
    required this.id,
    required this.date,
    required this.status,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.subTotal,
    required this.discount,
    required this.tax,
    required this.totalAmount,
    required this.itemsSummary,
    required this.thumbnail,

    // --- QUAN TRỌNG: Bỏ 'required', thêm '= const []' ---
    this.items = const [],
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // Logic an toàn: Nếu JSON không có 'items', tự động lấy mảng rỗng
    var list = json['items'] as List? ?? [];
    List<OrderItem> itemsList = list.map((i) => OrderItem.fromJson(i)).toList();

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

      // Nếu API trả về list thì có dữ liệu, không thì lấy rỗng từ biến itemsList ở trên
      items: itemsList,
    );
  }

  // --- Giữ nguyên các hàm helper cũ ---
  bool get isUnpaidVNPay =>
      paymentMethod == 'VNPAY' &&
      paymentStatus == 'UNPAID' &&
      status != 'CANCELLED';

  Color get statusColor {
    if (status == 'CANCELLED') return Colors.red;
    if (['COMPLETED', 'DELIVERED', 'SUCCESS'].contains(status))
      return Colors.green;
    return Colors.blue;
  }

  String get statusText {
    if (status == 'CANCELLED') return "Đã hủy";
    if (['COMPLETED', 'DELIVERED', 'SUCCESS'].contains(status))
      return "Hoàn thành";
    if (status == 'PENDING') return "Chờ xác nhận";
    if (status == 'SHIPPED') return "Đang giao";
    return "Đang xử lý";
  }
}