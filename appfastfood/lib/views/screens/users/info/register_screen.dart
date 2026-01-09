import 'package:appfastfood/service/api_service.dart';
import 'package:appfastfood/views/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../utils/app_colors.dart';
import '../../../widget/auth_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _fullnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  Future<void> _register() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty ||
        _fullnameController.text.isEmpty || _emailController.text.isEmpty ||
        _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin')));
      return;
    }
    setState(() { _isLoading = true; });
    try {
      final response = await _apiService.register(
        _usernameController.text, _passwordController.text,
        _fullnameController.text, _emailController.text, _phoneController.text,
      );
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đăng ký thành công! Vui lòng đăng nhập.')));
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=> const LoginScreen()), (route) => false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'] ?? 'Đăng ký thất bại')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi đăng ký: $e')));
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            AuthHeader(
              title: "Register",
              onBackPressed: () => Navigator.pop(context),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextField(
                    title: "Username",
                    controller: _usernameController, 
                    hintText: 'Nhập Username'
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

                  CustomTextField(
                    title: "Full Name",
                    controller: _fullnameController, 
                    hintText: 'Nhập họ và tên'
                  ),
                  
                  CustomTextField(
                    title: "Mobile Number",
                    controller: _phoneController,
                    hintText: 'Nhập số điện thoại',
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                  ),
                  
                  CustomTextField(
                    title: "Email",
                    controller: _emailController,
                    hintText: 'Nhập email',
                    keyboardType: TextInputType.emailAddress,
                    inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
                  ),

                  const SizedBox(height: 10),
                  _buildTermsSection(),

                  const SizedBox(height: 15),
                  PrimaryButton(
                    text: "Đăng Ký",
                    isLoading: _isLoading,
                    onPressed: _register,
                  ),

                  const SizedBox(height: 15),
                  const SocialLoginSection(),

                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account? ", style: TextStyle(color: Colors.grey)),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen())),
                        child: const Text("Log in", style: TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.bold)),
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

  // Helper nhỏ để tạo Label đỡ lặp code trong file
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
    );
  }

  Widget _buildTermsSection() {
    return Column(
      children: [
        const Center(child: Text("By continuing, you agree to", style: TextStyle(fontSize: 12, color: Colors.grey))),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => _showPolicyDialog(context, "Terms of Use", "Here are the Terms of Use..."),
              child: const Text(" Terms of Use ", style: TextStyle(fontSize: 12, color: AppColors.primaryOrange)),
            ),
            const Text("and", style: TextStyle(fontSize: 12, color: Colors.grey)),
            GestureDetector(
              onTap: () => _showPolicyDialog(context, "Privacy Policy", "Nội dung chi tiết của Chính sách bảo mật."),
              child: const Text(" Privacy Policy.", style: TextStyle(fontSize: 12, color: AppColors.primaryOrange)),
            ),
          ],
        ),
      ],
    );
  }

  void _showPolicyDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(20),
            height: 400,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
                  ],
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(content, style: const TextStyle(fontSize: 14, height: 1.5), textAlign: TextAlign.justify),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}