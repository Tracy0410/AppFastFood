
import 'dart:convert';
import 'package:intl/intl.dart'; // Import intl để format ngày tháng nếu cần
import 'Address.dart';
import 'OrderDetail.dart';
class Order {
  final int orderId;
  final int userId;
  final int shippingAddressId;
  final Address? shippingAddress; // Để hứng thông tin địa chỉ chi tiết nếu API trả về nested object
  final double subtotal;
  final double taxFee;
  final double totalAmount;
  final DateTime createdAt;
  final String orderStatus; // PENDING, PROCESSING, etc.
  final String paymentStatus; // UNPAID, PAID
  final String? note;
  final List<OrderDetail> details; // Danh sách món ăn trong đơn

  Order({
    required this.orderId,
    required this.userId,
    required this.shippingAddressId,
    this.shippingAddress,
    required this.subtotal,
    required this.taxFee,
    required this.totalAmount,
    required this.createdAt,
    required this.orderStatus,
    required this.paymentStatus,
    this.note,
    required this.details,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    var list = json['order_details'] as List? ?? []; // Key này do API trả về quy định
    List<OrderDetail> detailsList = list.map((i) => OrderDetail.fromJson(i)).toList();

    return Order(
      orderId: json['order_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      shippingAddressId: json['shipping_address_id'] ?? 0,
      // Nếu API trả về nguyên cục address
      shippingAddress: json['address'] != null ? Address.fromJson(json['address']) : null,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      taxFee: (json['tax_fee'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      orderStatus: json['order_status'] ?? 'PENDING',
      paymentStatus: json['payment_status'] ?? 'UNPAID',
      note: json['note'],
      details: detailsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'user_id': userId,
      'shipping_address_id': shippingAddressId,
      'subtotal': subtotal,
      'tax_fee': taxFee,
      'total_amount': totalAmount,
      'created_at': createdAt.toIso8601String(),
      'order_status': orderStatus,
      'payment_status': paymentStatus,
      'note': note,
      'order_details': details.map((e) => e.toJson()).toList(),
    };
  }

  // Helper: Format tiền tệ VND
  String get formattedTotal {
    final formatCurrency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return formatCurrency.format(totalAmount);
  }

  // Helper: Format ngày tạo đơn
  String get formattedDate {
    return DateFormat('dd/MM/yyyy HH:mm').format(createdAt);
  }
  
  @override
  String toString() => jsonEncode(toJson());
}
