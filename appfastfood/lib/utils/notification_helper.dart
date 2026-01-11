import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationHelper {
  static final NotificationHelper _instance = NotificationHelper._internal();
  factory NotificationHelper() => _instance;
  NotificationHelper._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> requestPermission() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // Hàm hiển thị thông báo có check setting
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    required String type, // 'order', 'promotion', 'payment'
  }) async {
    
    final prefs = await SharedPreferences.getInstance();
    
    // Mapping key
    String settingKey = '';
    if (type == 'order') settingKey = 'setting_order_notify';
    else if (type == 'promotion') settingKey = 'setting_promotion_notify';
    else if (type == 'payment') settingKey = 'setting_payment_notify';

    // Check quyền: Nếu false thì return luôn
    bool isAllowed = prefs.getBool(settingKey) ?? true; 
    if (!isAllowed) return; 

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'fastfood_notification_channel',
      'Thông báo Yummy Quick',
      channelDescription: 'Thông báo về đơn hàng, khuyến mãi và thanh toán',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
    );
  }
}