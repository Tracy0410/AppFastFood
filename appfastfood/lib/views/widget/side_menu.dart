import 'dart:convert';
import 'package:appfastfood/views/screens/users/home_screen.dart';
import 'package:appfastfood/views/screens/users/info/profile_screen.dart';
import 'package:appfastfood/views/screens/users/setting_screen.dart';
import 'package:appfastfood/views/screens/welcome_screen.dart';
import 'package:appfastfood/views/screens/users/home_interface/support_screen.dart';
import 'package:appfastfood/views/screens/users/contact_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user.dart';

class SideMenu extends StatefulWidget {
  const SideMenu({super.key});

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  // Biến trạng thái
  bool _isLoggedIn = false;
  String _userName = "Khách";
  String _userEmail = "Vui lòng đăng nhập để tiếp tục";
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  //1. HÀM KIỂM TRA ĐĂNG NHẬP
  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('access_token');
    final String? userJsonString = prefs.getString('user_data');

    setState(() {
      if (token != null && token.isNotEmpty && userJsonString != null) {
        _isLoggedIn = true;
        try {
          Map<String, dynamic> userMap = jsonDecode(userJsonString);
          User currentUser = User.fromJson(userMap);

          _userName = currentUser.username;
          _userEmail = currentUser.email;
          _avatarUrl = currentUser.image; 
        } catch (e) {
          print("Lỗi parse user data: $e");
        }
      } else {
        _isLoggedIn = false;
        _userName = "Khách";
        _userEmail = "Vui lòng đăng nhập";
        _avatarUrl = null;
      }
    });
  }

  // --- 2. HÀM XỬ LÝ ĐĂNG XUẤT ---
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.clear();

    if (mounted) {
      setState(() {
        _isLoggedIn = false;
        _userName = "Khách";
        _avatarUrl = null;
      });

      Navigator.pop(context);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomePageScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? avatarImage = _isLoggedIn ? _getAvatarProvider(_avatarUrl) : null;
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.75,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          bottomLeft: Radius.circular(30),
        ),
      ),
      backgroundColor: const Color(0xFFE95322),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // A. HEADER (AVATAR + INFO)
              Row(
                children: [
                  Container(
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      backgroundImage: avatarImage,
                      child: avatarImage == null
                          ? const Icon(
                              Icons.person,
                              size: 35,
                              color: Color(0xFFE95322),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _userEmail,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),
              const Divider(color: Colors.white30, thickness: 1),
              const SizedBox(height: 10),

              // B. DANH SÁCH MENU
              if (_isLoggedIn) ...[
                
                _buildMenuItem(Icons.person_outline, "Hồ sơ của tôi", () {
                   Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen()));
                }),
                _buildMenuItem(
                  Icons.location_on_outlined,
                  "Theo Dõi Đơn Hàng",
                  () {},
                ),
                _buildMenuItem(Icons.credit_card, "Phương Thức Thanh Toán", () {}),
                _buildMenuItem(Icons.phone_in_talk_outlined, "Liên Hệ Với Cửa Hàng", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ContactScreen()),
                  );
                }),
              ] else ...[
                _buildMenuItem(Icons.login, "Đăng Nhập / Đăng Ký", () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WelcomeScreen(),
                    ),
                  );
                }),
              ],

              
              _buildMenuItem(Icons.chat_bubble_outline, "Trợ Giúp", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SupportScreen()),
                    );
                  }),
              _buildMenuItem(Icons.settings_outlined, "Cài Đặt", () {
                Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const SettingScreen())
                );
              }),
              const Spacer(),

              // C. NÚT ĐĂNG XUẤT
              if (_isLoggedIn)
                _buildMenuItem(Icons.logout, "Đăng Xuất", () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Đăng xuất"),
                      content: const Text(
                        "Bạn có chắc chắn muốn đăng xuất không?",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Hủy"),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _logout();
                          },
                          child: const Text(
                            "Đồng ý",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  // Widget hỗ trợ tạo item cho Menu để code gọn hơn
  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 5),
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        color: Colors.white30,
        size: 12,
      ),
    );
  }

  ImageProvider? _getAvatarProvider(String? imgString) {
    if (imgString == null || imgString.isEmpty) {
      return null;
    }
    try {
      if (imgString.startsWith('data:image')) {
        var parts = imgString.split(',');
        if (parts.length > 1) {
          return MemoryImage(base64Decode(parts[1]));
        }
      }
      if (imgString.startsWith('http')) {
        return NetworkImage(imgString);
      }
    } catch (e) {
      print("Lỗi hiển thị ảnh avatar: $e");
    }
    return null;
  }
}
