import 'package:appfastfood/service/api_service.dart';
import 'package:appfastfood/utils/app_colors.dart';
import 'package:appfastfood/utils/storage_helper.dart';
import 'package:appfastfood/views/screens/users/home_screen.dart';
import 'package:appfastfood/views/screens/users/setting/change_pass.dart';
import 'package:appfastfood/views/screens/users/setting/notification_setting.dart';
import 'package:appfastfood/views/widget/topbar_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  final ApiService _apiService = ApiService();

  Future<void> _confirmDeleteAccount() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Xóa tài khoản?"),
          content: const Text(
            "Tài khoản của bạn sẽ bị vô hiệu hóa và bạn sẽ không thể đăng nhập lại. Bạn có chắc chắn muốn tiếp tục?",
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Đồng ý", style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteAccount();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAccount() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Lấy ID user từ StorageHelper
      final int? userId = await StorageHelper.getUserId();
      
      if (userId != null) {
        // Gọi API xóa (Backend sẽ update status = 0)
        final bool success = await _apiService.deleteAccount(userId); 

        // Tắt loading
        if (mounted) Navigator.pop(context);

        if (success) {
          // Xóa thành công: Xóa dữ liệu local và logout
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear(); // Xóa sạch Token và Info

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Tài khoản đã được xóa thành công.")),
            );

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomePageScreen()), 
              (route) => false,
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Có lỗi xảy ra, vui lòng thử lại sau.")),
            );
          }
        }
      } else {
        if (mounted) Navigator.pop(context);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Lỗi: Không tìm thấy thông tin người dùng.")),
          );
        }
      }
    } catch (e) {
      // Lỗi kết nối hoặc code
      if (mounted) Navigator.pop(context);
      print("Lỗi xóa tài khoản: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header
          const TopBarPage(showBackButton: true, title: "Cài đặt"),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              children: [
                _buildSettingItem(
                  icon: Icons.notifications_none_outlined,
                  title: "Cài Đặt Thông Báo",
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationSettingScreen()));
                  },
                ),
                _buildSettingItem(
                  icon: Icons.vpn_key_outlined,
                  title: "Thay Đổi Mật Khẩu",
                  isKeyIcon: true,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePass()));
                  },
                ),
                _buildSettingItem(
                  icon: Icons.person_off_outlined,
                  title: "Xóa Tài Khoản",
                  onTap: () {
                    _confirmDeleteAccount();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isKeyIcon = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          splashColor: AppColors.primaryOrange.withOpacity(0.1),
          highlightColor: AppColors.primaryOrange.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                // Phần Icon bên trái
                Container(
                  width: 45,
                  height: 45,
                  alignment: Alignment.centerLeft,
                  child: isKeyIcon
                      ? Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.primaryOrange, width: 2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.vpn_key, color: AppColors.primaryOrange, size: 20),
                        )
                      : Icon(icon, color: AppColors.primaryOrange, size: 40),
                ),
                const SizedBox(width: 15),

                // Phần Text tiêu đề
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),

                const Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.primaryOrange,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}