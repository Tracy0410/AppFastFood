import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../utils/order_helper.dart';
class OrderDetailPage extends StatefulWidget {
  final int orderId;
  const OrderDetailPage({Key? key, required this.orderId}) : super(key: key);

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  // Mock data chi tiết (Thực tế bạn sẽ gọi API getDetailsByOrderId)
  final Map<String, dynamic> _orderDetail = {
    'order_id': 3,
    'created_at': '2026-01-08 10:30:00',
    'fullname': 'Nguyễn Văn Khách',
    'status': 'PENDING',
    'address': '123 Đường Láng, Đống Đa, Hà Nội',
    'payment_method': 'COD (Chưa thanh toán)',
    'note': 'Giao giờ hành chính nha shop',
    'subtotal': 72000,
    'shipping_fee': 15000,
    'discount': 0,
    'total': 87000,
    'items': [
      {
        'name': 'Gà rán truyền thống',
        'image': 'img/chicken_original.jpg', // Cần xử lý đường dẫn ảnh từ server
        'quantity': 2,
        'price': 36000,
      }
    ]
  };

  void _updateStatus(String newStatus) {
    // TODO: Gọi API cập nhật trạng thái đơn hàng lên Server
    setState(() {
      _orderDetail['status'] = newStatus;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã cập nhật trạng thái: $newStatus')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    String status = _orderDetail['status'];
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.amber,
        title: const Text('Chi tiết đơn hàng', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        leading: const BackButton(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. Header: Mã đơn + Trạng thái
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order No. #${_orderDetail['order_id']}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: OrderHelper.getStatusColor(status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    OrderHelper.getStatusText(status),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(_orderDetail['created_at'], style: TextStyle(color: Colors.grey[600])),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(_orderDetail['fullname'], style: TextStyle(color: Colors.grey[600])),
            ),
            const SizedBox(height: 20),

            // 2. Địa chỉ (Màu vàng nhạt giống Figma)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1), // Màu vàng nhạt
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Địa chỉ nhận hàng:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
                  const SizedBox(height: 4),
                  Text(_orderDetail['address'], style: const TextStyle(fontSize: 15)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Thông tin thanh toán & Ghi chú
            _buildInfoRow("Thanh toán:", _orderDetail['payment_method'], isRed: true),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text("Ghi chú: ${_orderDetail['note'] ?? 'Không có'}"),
            ),
            const SizedBox(height: 20),

            // 4. Danh sách món ăn
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _orderDetail['items'].length,
              itemBuilder: (context, index) {
                final item = _orderDetail['items'][index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      // Ảnh sản phẩm
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 60, height: 60,
                          color: Colors.grey[300],
                          // child: Image.network(item['image'], fit: BoxFit.cover), // Uncomment khi có link ảnh thật
                          child: const Icon(Icons.fastfood, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Tên và giá
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 4),
                            Text(currencyFormat.format(item['price']), style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      ),
                      // Số lượng
                      Text("x${item['quantity']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              },
            ),
            const Divider(thickness: 1),

            // 5. Tổng tiền
            _buildSummaryRow("Tạm tính", _orderDetail['subtotal'], currencyFormat),
            _buildSummaryRow("Phí giao hàng", _orderDetail['shipping_fee'], currencyFormat),
            _buildSummaryRow("Giảm giá", _orderDetail['discount'], currencyFormat),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Tổng cộng", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(
                  currencyFormat.format(_orderDetail['total']),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // 6. Nút hành động (Logic Duyệt đơn)
            // Chỉ hiện nút Duyệt/Hủy khi đơn đang ở trạng thái PENDING
            if (status == 'PENDING') 
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateStatus('CANCELLED'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFE0E0), // Đỏ nhạt
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text("Hủy đơn"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateStatus('PROCESSING'), // Duyệt -> Chuyển sang đang làm
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber, // Vàng
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text("Xác nhận"),
                    ),
                  ),
                ],
              ),
              
            // Nút chuyển trạng thái giao hàng (cho Staff/Admin)
            if (status == 'PROCESSING')
               SizedBox(
                width: double.infinity,
                 child: ElevatedButton(
                    onPressed: () => _updateStatus('SHIPPED'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text("Giao cho Shipper", style: TextStyle(color: Colors.white)),
                  ),
               ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isRed = false}) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value, 
            style: TextStyle(
              color: isRed ? Colors.red : Colors.black87,
              fontWeight: isRed ? FontWeight.bold : FontWeight.normal
            ),
            overflow: TextOverflow.ellipsis
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, int amount, NumberFormat format) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700])),
          Text(format.format(amount), style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
