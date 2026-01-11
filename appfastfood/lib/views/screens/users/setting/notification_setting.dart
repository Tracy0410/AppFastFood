import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingScreen extends StatefulWidget {
  const NotificationSettingScreen({super.key});

  @override
  State<NotificationSettingScreen> createState() => _NotificationSettingScreenState();
}

class _NotificationSettingScreenState extends State<NotificationSettingScreen> {
  bool _orderNotification = true;
  bool _promotionNotification = true;
  bool _paymentNotification = true;

  final String keyOrder = 'setting_order_notify';
  final String keyPromotion = 'setting_promotion_notify';
  final String keyPayment = 'setting_payment_notify';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _orderNotification = prefs.getBool(keyOrder) ?? true;
      _promotionNotification = prefs.getBool(keyPromotion) ?? true;
      _paymentNotification = prefs.getBool(keyPayment) ?? true;
    });
  }

  Future<void> _updateSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Cài Đặt Thông Báo", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    _buildSwitchItem("Đơn hàng", "Trạng thái vận chuyển", Icons.local_shipping_outlined, _orderNotification, (val) {
                      setState(() => _orderNotification = val);
                      _updateSetting(keyOrder, val);
                    }),
                    const Divider(height: 1, indent: 60),
                    _buildSwitchItem("Khuyến mãi", "Ưu đãi mới", Icons.discount_outlined, _promotionNotification, (val) {
                      setState(() => _promotionNotification = val);
                      _updateSetting(keyPromotion, val);
                    }),
                    const Divider(height: 1, indent: 60),
                    _buildSwitchItem("Thanh toán", "Biến động số dư", Icons.payment_outlined, _paymentNotification, (val) {
                      setState(() => _paymentNotification = val);
                      _updateSetting(keyPayment, val);
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchItem(String title, String sub, IconData icon, bool val, ValueChanged<bool> onChange) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: Colors.blue),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(sub),
      trailing: Switch(value: val, onChanged: onChange, activeColor: Colors.green),
    );
  }
}