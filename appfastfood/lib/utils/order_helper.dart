import 'package:flutter/material.dart';
class OrderHelper {
  // Map trạng thái từ Database sang Tiếng Việt hiển thị
  static String getStatusText(String status) {
    switch (status) {
      case 'PENDING':
        return 'Chờ xác nhận';
      case 'PROCESSING':
        return 'Đang thực hiện';
      case 'SHIPPED':
        return 'Đang giao';
      case 'DELIVERED':
        return 'Đã giao';
      case 'CANCELLED':
        return 'Đã hủy';
      default:
        return 'Không xác định';
    }
  }

  // Map trạng thái sang Màu sắc (giống Figma)
  static Color getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.orange; // Màu cam cho chờ đợi
      case 'PROCESSING':
        return Colors.blue;   // Màu xanh dương cho xử lý
      case 'SHIPPED':
        return Colors.purple; // Màu tím cho đang giao
      case 'DELIVERED':
        return Colors.green;  // Màu xanh lá cho thành công
      case 'CANCELLED':
        return Colors.red;    // Màu đỏ cho hủy
      default:
        return Colors.grey;
    }
  }
}
