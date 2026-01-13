import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Nhớ thêm intl vào pubspec.yaml để format tiền/ngày
// import file order_helper.dart ở trên
import '../../utils/order_helper.dart';

class OrderCard extends StatelessWidget {
  final Map<String, dynamic> order; // Dữ liệu đơn hàng truyền vào
  final VoidCallback onTap;

  const OrderCard({Key? key, required this.order, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Format tiền tệ
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    // Format ngày tháng (Giả sử created_at là String DateTime)
    final date = DateTime.parse(order['created_at']);
    final dateFormat = DateFormat('dd MMM, hh:mm a');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dòng 1: Mã đơn hàng + Tổng tiền
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order No. #${order['order_id']}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  currencyFormat.format(
                    double.parse(order['total_amount'].toString()),
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange, // Màu cam đỏ giống Figma
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Dòng 2: Ngày đặt + Số lượng món
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateFormat.format(date),
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                Text(
                  '${order['item_count'] ?? 1} món', // Cần query count items hoặc truyền vào
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Dòng 3: Tên khách hàng + Badge Trạng thái
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      order['fullname'] ?? 'Khách lẻ',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: OrderHelper.getStatusColor(order['order_status']),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    OrderHelper.getStatusText(order['order_status']),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
