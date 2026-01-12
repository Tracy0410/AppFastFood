import 'dart:convert';
import 'package:appfastfood/models/user.dart';
import 'package:appfastfood/service/api_service.dart';
import 'package:appfastfood/utils/app_colors.dart';
import 'package:appfastfood/utils/storage_helper.dart';
import 'package:appfastfood/views/screens/admin/admin_home_screen.dart';
import 'package:appfastfood/views/screens/users/home_screen.dart';
import 'package:appfastfood/views/screens/users/info/forgot_pass_screen.dart';
import 'package:appfastfood/views/screens/users/info/register_screen.dart';
import 'package:appfastfood/views/widget/auth_widgets.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Future<void> _handleLogin() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập Username và Password"), backgroundColor: Colors.orange),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await _apiService.login(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );
      
      if (result['success'] == true) {
        // 1. Parse User từ JSON
        User user = User.fromJson(result['user']);
        String token = result['token'];
        
        // 2. Lưu vào SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await StorageHelper.saveToke(token);
        await StorageHelper.saveUserId(user.userId);
        await StorageHelper.saveRole(user.role);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đăng nhập thành công!"), backgroundColor: Colors.green));
          
          if (user.role == 'ADMIN') {
            Navigator.push(
              context, 
              MaterialPageRoute(builder: (context) => const AdminHomePageScreen()),
            );
          } else {
            Navigator.push(
              context, 
              MaterialPageRoute(builder: (context) => const HomePageScreen())
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString().replaceAll("Exception: ", "");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            AuthHeader(
              title: "Log In",
              onBackPressed: () => Navigator.pop(context),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Welcome", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  const SizedBox(height: 5),
                  const Text(
                    "Chào mừng bạn đến với thế giới đồ ăn nhanh! Đăng nhập ngay.",
                    style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    title: "Username", 
                    controller: _usernameController, hintText: "Nhập username"
                  ),
                  CustomTextField(
                    title: "Password",
                    controller: _passwordController,
                    hintText: "Nhập password",
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.primaryOrange),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword)
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ForgotPassScreen()),
                        );
                      },
                      child: const Text("Forget Password", style: TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    text: "Đăng Nhập",
                    isLoading: _isLoading,
                    onPressed: _handleLogin,
                  ),
                  const SizedBox(height: 20),
                  const SocialLoginSection(),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account? ", style: TextStyle(color: Colors.grey)),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen())),
                        child: const Text("Sign Up", style: TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}