import 'package:appfastfood/views/screens/users/setting/setting_screen.dart';
import 'package:appfastfood/views/screens/welcome_screen.dart';
import 'package:flutter/material.dart';
import '../../views/screens/admin/admin_order_screen.dart'; // Đảm bảo đúng đường dẫn tới file AdminOrderScreen


class AdminSideMenu extends StatelessWidget {
  const AdminSideMenu({super.key});

  // Hàm hiển thị hộp thoại xác nhận đăng xuất
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text("Xác nhận đăng xuất"),
          content: const Text("Bạn có chắc chắn muốn đăng xuất khỏi hệ thống không?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Đóng dialog
              child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE95322),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                // Thoát hoàn toàn và về màn hình Login
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WelcomeScreen())
                );
              },
              child: const Text("Đăng xuất", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(40),
          bottomLeft: Radius.circular(40),
        ),
      ),
      backgroundColor: const Color(0xFFE95322),
      child: Column(
        children: [
          // Header
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Colors.transparent),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 40, color: Color(0xFFE95322)),
            ),
            accountName: const Text(
              "Admin",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            accountEmail: const Text(
              "admin@yummyquick.com",
              style: TextStyle(color: Colors.white70),
            ),
          ),
          
          // Danh sách Menu
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuItem(context, Icons.restaurant, "Sản phẩm", () {
                  Navigator.pop(context);
                }),
                _buildMenuItem(context, Icons.assignment, "Đơn hàng", () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminOrderScreen()),
                  );
                }),
                _buildMenuItem(context, Icons.person_outline, "Khách hàng", () {
                  Navigator.pop(context);
                }),
                _buildMenuItem(context, Icons.notifications_none, "Thông báo", () {
                  Navigator.pop(context);
                }),
                _buildMenuItem(context, Icons.bar_chart, "Doanh thu", () {
                  Navigator.pop(context);
                }),
                _buildMenuItem(context, Icons.settings_outlined, "Cài đặt", () {
                  Navigator.push(context,MaterialPageRoute(builder: (context) => const SettingScreen()));
                }),
                _buildMenuItem(context, Icons.chat_bubble_outline, "Bình luận", () {
                  Navigator.pop(context);
                }),
                _buildMenuItem(context, Icons.star_border, "Đánh giá", () {
                  Navigator.pop(context);
                }),
              ],
            ),
          ),

          // Nút Đăng xuất
          _buildMenuItem(context, Icons.logout, "Đăng xuất", () {
            _showLogoutDialog(context); // Gọi hàm xác nhận thay vì chuyển trang ngay
          }),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFFE95322), size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
    );
  }
}
