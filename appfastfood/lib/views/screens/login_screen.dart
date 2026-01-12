import 'dart:convert';
import 'package:appfastfood/service/api_service.dart';
import 'package:appfastfood/views/screens/users/info/forgot_pass_screen.dart';
import 'package:appfastfood/views/screens/users/info/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user.dart';
import 'users/home_screen.dart';
import 'package:appfastfood/views/screens/admin/admin_home_screen.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  // Hàm xử lý Đăng Nhập
  Future<void> _handleLogin() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập Username và Password"), 
        backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {    // 1. Gọi API kiểm tra đúng sai
      final result = await _apiService.login(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );
      // 2. Nếu đăng nhập thành công (API trả về success: true)
      if (result['success'] == true) {
        User user = User.fromJson(result['user']);
        String token = result['token'];

        // Lưu vào SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', token);
        await prefs.setString('user_data', jsonEncode(user.toJson()));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Đăng nhập thành công!"),
                backgroundColor: Colors.green),
          );

          // --- ĐOẠN LOGIC PHÂN QUYỀN Ở ĐÂY ---
          // Kiểm tra nếu username nhập vào là 'admin' thì chuyển sang trang Admin
          if (_usernameController.text.trim() == 'admin') {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const AdminHomePageScreen()),
              (route) => false,
            );
          } else {
            // Ngược lại (User thường) thì chuyển sang trang Home
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomePageScreen()),
              (route) => false,
            );
          }
          // ------------------------------------
        }
      } else {
        // Trường hợp API trả về success: false (sai pass hoặc user không tồn tại)
         if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? "Đăng nhập thất bại"), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString().replaceAll("Exception: ", "");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color yellowHeader = Color(0xFFFCD057);
    const Color inputBg = Color(0xFFFEF5D3);
    const Color primaryOrange = Color(0xFFE95322);
    const Color textDark = Color(0xFF4A3B2C);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // PHẦN HEADER
            Container(
              height: 150,
              decoration: const BoxDecoration(
                color: yellowHeader,
              ),
              child: SafeArea(
                child: Stack(
                  children: [
                    Positioned(
                      left: 10,
                      top: 10,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),

                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 20),
                        child: Text(
                          "Log In",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // PHẦN BODY
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Welcome",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Chào mừng bạn đến với thế giới đồ ăn nhanh! Đăng nhập ngay để không bỏ lỡ những ưu đãi cực 'hời' dành riêng cho bạn hôm nay.",
                    style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
                  ),
                  const SizedBox(height: 30),

                  // INPUT USERNAME
                  const Text("Username", style: TextStyle(fontWeight: FontWeight.bold, color: textDark)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      hintText: "Nhập username",
                      filled: true,
                      fillColor: inputBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // INPUT PASSWORD
                  const Text("Password", style: TextStyle(fontWeight: FontWeight.bold, color: textDark)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: "Nhập password",
                      filled: true,
                      fillColor: inputBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: primaryOrange,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),

                  // FORGOT PASSWORD
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotPassScreen()));
                      },
                      child: const Text(
                        "Forget Password",
                        style: TextStyle(color: primaryOrange, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  const SizedBox(height: 50),

                  // BUTTON ĐĂNG NHẬP
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryOrange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 5,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Đăng Nhập",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // SIGN UP LINK
                  const Center(child: Text("or sign up with", style: TextStyle(color: Colors.grey))),
                  const SizedBox(height: 10),
                  
                  // Social Icons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSocialButton("assets/google_Icon.jpg", Colors.white),
                      const SizedBox(width: 20),
                      _buildSocialButton("assets/facebook_Icon.jpg", Colors.white),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // LINK ĐĂNG KÝ
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account? ", style: TextStyle(color: Colors.grey)),
                      GestureDetector(
                        onTap: () {
                          // Điều hướng sang màn hình Đăng ký
                          Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterScreen()));
                        },
                        child: const Text(
                          "Sign Up",
                          style: TextStyle(color: primaryOrange, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton(String assetName, Color bgColor) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Padding(padding: EdgeInsets.all(10), child: Image.asset(assetName)),
    );
  }
}