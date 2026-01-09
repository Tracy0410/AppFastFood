import 'package:appfastfood/utils/app_colors.dart';
import 'package:appfastfood/views/widget/topbar_page.dart';
import 'package:flutter/material.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 1. Header (Dùng Widget TopBarPage có sẵn của bạn)
          const TopBarPage(showBackButton: true, title: "Cài đặt"),

          // 2. Danh sách các mục cài đặt
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              children: [
                _buildSettingItem(
                  icon: Icons.notifications_none_outlined,
                  title: "Cài Đặt Thông Báo",
                  onTap: () {
                    // Xử lý chuyển trang hoặc bật tắt thông báo
                    print("Click Cài đặt thông báo");
                  },
                ),
                _buildSettingItem(
                  icon: Icons.vpn_key_outlined,
                  title: "Thay Đổi Mật Khẩu",
                  isKeyIcon: true, // Icon chìa khóa có vòng tròn bao quanh
                  onTap: () {
                     print("Click Thay đổi mật khẩu");
                  },
                ),
                _buildSettingItem(
                  icon: Icons.person_off_outlined,
                  title: "Xóa Tài Khoản",
                  onTap: () {
                     print("Click Xóa tài khoản");
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Widget tái sử dụng để vẽ từng dòng cài đặt ---
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
                          // Xử lý riêng cho icon chìa khóa (nằm trong vòng tròn)
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
                      color: Colors.black87, // Màu chữ đậm dễ đọc
                    ),
                  ),
                ),

                // Icon mũi tên bên phải
                const Icon(
                  Icons.arrow_forward_ios, 
                  color: AppColors.primaryOrange, 
                  size: 16
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}