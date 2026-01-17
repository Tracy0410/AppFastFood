import 'package:appfastfood/service/api_service.dart';
import 'package:appfastfood/utils/notification_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationSide extends StatefulWidget {
  final Function(int promotionId, String code)? onUsePromo;
  final VoidCallback? onNotificationChanged;

  const NotificationSide({
    Key? key, 
    this.onUsePromo, 
    this.onNotificationChanged
  }) : super(key: key);

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
    final deletedIds = await NotificationHelper().getDeletedIds();
    
    if (!mounted) return;

    List<Map<String, dynamic>> tempList = [];

    if (data['orders'] != null) {
      for (var order in data['orders']) {
        int id = order['order_id'];
        String status = order['order_status'];
        String uniqueId = NotificationHelper.generateId('ORDER', id, status: status);
        if (deletedIds.contains(uniqueId)) continue;

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
          'uniqueId': uniqueId,
          'type': 'ORDER',
          'id': id,
          'title': title,
          'message': statusMsg,
          'detail': order['items_summary'] ?? "Chi tiết đơn hàng...",
          'time': order['created_at'],
          'color': statusColor,
          'code': '',
        });
      }
    }

    if (data['promotions'] != null) {
      for (var promo in data['promotions']) {
        int id = promo['promotion_id'];
        String uniqueId = NotificationHelper.generateId('PROMO', id);

        tempList.add({
          'uniqueId': uniqueId,
          'type': 'PROMOTION',
          'id': id,
          'title': "HOT: ${promo['name']}",
          'message': "Giảm ${promo['discount_percent']}%",
          'code': promo['code'],
          'detail': promo['description'] ?? "Mô tả...",
          'time': promo['start_date'],
          'color': Colors.redAccent,
        });
      }
    }

    tempList.sort((a, b) {
      DateTime t1 = DateTime.tryParse(a['time'].toString()) ?? DateTime(2000);
      DateTime t2 = DateTime.tryParse(b['time'].toString()) ?? DateTime(2000);
      return t2.compareTo(t1);
    });
    
    setState(() {
      _notifications = tempList;
      _isLoading = false;
    });
  }

  void _removeNotification(int index) async {
    final item = _notifications[index];
    if (item['type'] == 'PROMOTION') return;

    final String uniqueId = item['uniqueId'];

    await NotificationHelper().markAsDeleted(uniqueId);

    setState(() {
      _notifications.removeAt(index);
    });

    if (widget.onNotificationChanged != null) {
      widget.onNotificationChanged!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 40, left: 20, bottom: 20),
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
    bool isPromo = item['type'] == 'PROMOTION';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Stack(
        children: [
          ExpansionTile(
            leading: Icon(
              isPromo ? Icons.local_offer : Icons.fastfood,
              color: item['color'],
            ),
            title: Text(
              item['title'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['message']),
                Text(
                  _formatDate(item['time']),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Chi tiết: ${item['detail']}"),
                    if (item['code'] != null && item['code'] != '') 
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          "Mã Code: ${item['code']}",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                      ),
                    
                    // --- NÚT DÙNG NGAY (GIỮ NGUYÊN) ---
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
          // Nút Xóa (X)
          if (!isPromo) 
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