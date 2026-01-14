import 'package:appfastfood/service/api_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationSide extends StatefulWidget {
  final Function(int promotionId, String code)? onUsePromo;

  const NotificationSide({Key? key, this.onUsePromo}) : super(key: key);

  @override
  State<NotificationSide> createState() => _NotificationSideState();
}

class _NotificationSideState extends State<NotificationSide> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    final data = await _apiService.getNotificationSync();
    
    if (!mounted) return;

    List<Map<String, dynamic>> tempList = [];

    if (data['orders'] != null) {
      for (var order in data['orders']) {
        String title = "Đơn hàng #${order['order_id']}";
        String statusMsg = "";
        Color statusColor = Colors.blue;

        switch (order['order_status']) {
          case 'PENDING':
            statusMsg = "Đơn hàng đã được đặt thành công. Chờ xác nhận.";
            statusColor = Colors.orange;
            break;
          case 'COOKING':
            statusMsg = "Đơn hàng đang được chế biến. Vui lòng đợi nhé!";
            statusColor = Colors.blue;
            break;
          case 'DELIVERING':
            statusMsg = "Tài xế đang giao món đến bạn.";
            statusColor = Colors.purple;
            break;
          case 'COMPLETED':
            statusMsg = "Đơn hàng đã hoàn tất. Chúc ngon miệng!";
            statusColor = Colors.green;
            break;
          case 'CANCELLED':
            statusMsg = "Đơn hàng đã bị hủy.";
            statusColor = Colors.red;
            break;
          default:
            statusMsg = "Trạng thái: ${order['order_status']}";
        }

        tempList.add({
          'type': 'ORDER',
          'id': order['order_id'],
          'title': title,
          'message': statusMsg,
          'detail': order['items_summary'] ?? "Chi tiết đơn hàng...",
          'time': order['created_at'],
          'color': statusColor,
          'isNew': true,
        });
      }
    }

    if (data['promotions'] != null) {
      for (var promo in data['promotions']) {
        tempList.add({
          'type': 'PROMOTION',
          'id': promo['promotion_id'],
          'title': "HOT: ${promo['name']}",
          'message': "Nhập mã: ${promo['code']} để giảm ${promo['discount_percent']}%",
          'code': promo['code'],
          'raw_name': promo['name'],
          'detail': promo['description'] ?? "Áp dụng cho các món trong danh mục...",
          'time': promo['start_date'],
          'color': Colors.redAccent,
          'isNew': false,
        });
      }
    }
    
    setState(() {
      _notifications = tempList;
      _isLoading = false;
    });
  }

  void _removeNotification(int index) {
    setState(() {
      _notifications.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 50, left: 20, bottom: 20),
            color: Colors.redAccent,
            width: double.infinity,
            child: const Text(
              "Thông Báo",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _notifications.isEmpty
                    ? const Center(child: Text("Hiện chưa có thông báo nào"))
                    : ListView.builder(
                        padding: const EdgeInsets.all(10),
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          final item = _notifications[index];
                          return _buildNotificationCard(item, index);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> item, int index) {
    IconData iconData = item['type'] == 'ORDER' ? Icons.fastfood : Icons.local_offer;

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Stack(
        children: [
          ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: item['color'].withOpacity(0.1),
              child: Icon(iconData, color: item['color']),
            ),
            title: Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 5),
                Text(item['message'], style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                const SizedBox(height: 5),
                Text(_formatDate(item['time']), style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                width: double.infinity,
                color: Colors.grey[50],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Chi tiết:", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Text(item['detail']),
                    
                    if (item['type'] == 'PROMOTION')
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: ElevatedButton(
                          onPressed: () {
                            if (widget.onUsePromo != null) {
                                widget.onUsePromo!(
                                  item['id'] ?? 0, 
                                  item['code'] ?? ''
                                );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            minimumSize: const Size(double.infinity, 35)
                          ),
                          child: const Text("Dùng ngay", style: TextStyle(color: Colors.white)),
                        ),
                      )
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            right: 0,
            top: 0,
            child: IconButton(
              icon: const Icon(Icons.close, size: 18, color: Colors.grey),
              onPressed: () => _removeNotification(index),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic dateStr) {
    if(dateStr == null) return '';
    try {
      DateTime date = DateTime.parse(dateStr.toString());
      return DateFormat('dd/MM HH:mm').format(date);
    } catch (e) {
      return '';
    }
  }
}