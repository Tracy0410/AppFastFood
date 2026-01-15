import 'package:appfastfood/utils/storage_helper.dart';
import 'package:appfastfood/views/screens/users/home_screen.dart';
import 'package:appfastfood/views/screens/admin/admin_home_screen.dart'; // Import Admin screen
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkRoleAndNavigate();
  }

  _checkRoleAndNavigate() async {
    // Chạy song song
    final result = await Future.wait([
      Future.delayed(const Duration(seconds: 2)),
      StorageHelper.getToken(),
      StorageHelper.getRole(),
    ]);

    if (!mounted) return;

    final String? token = result[1];
    final String? role = result[2];

    // 1. Chưa đăng nhập -> Login
    if (token == null || token.isEmpty) {
      Navigator.pushReplacement(
        // Dùng pushReplacement
        context,
        MaterialPageRoute(builder: (context) => const HomePageScreen()),
      );
      return;
    }

    // 2. Đã đăng nhập -> Kiểm tra Role
    if (role == 'ADMIN') {
      // Chỉ ADMIN mới vào đây
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminHomePageScreen()),
      );
    } else {
      // CUSTOMER hoặc bất kỳ role nào khác -> Home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePageScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... Giữ nguyên UI của bạn
    return Scaffold(
      backgroundColor: const Color(0xFFE95322),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 180,
              width: 180,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset('assets/logoApp.jpg', fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              "Fast Food App",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Đang tải món ngon...",
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
