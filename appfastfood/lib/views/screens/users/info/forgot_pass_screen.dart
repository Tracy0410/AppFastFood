import 'package:appfastfood/service/api_service.dart';
import 'package:appfastfood/utils/app_colors.dart';
import 'package:appfastfood/utils/storage_helper.dart';
import 'package:appfastfood/views/screens/login_screen.dart';
import 'package:appfastfood/views/widget/auth_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ForgotPassScreen extends StatefulWidget {
  const ForgotPassScreen({super.key});

  @override
  State<ForgotPassScreen> createState() => _ForgotPassScreenState();
}

class _ForgotPassScreenState extends State<ForgotPassScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  Future<void> _sendOtp() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập email"), backgroundColor: Colors.orange),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await _apiService.sendOtp(_emailController.text.trim());
      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Mã xác thực đã được gửi đến email của bạn"), backgroundColor: Colors.green),
          );
        }
        else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Gửi mã thất bại'), backgroundColor: Colors.red));
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

  Future<void> _resetPass() async {
    if (_emailController.text.isEmpty || _otpController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng mật khẩu đầy đủ')),
      );
      return;
    }
    if (_newPassController.text != _confirmPassController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mật khẩu không khớp')),
      );
      return;
    }

    setState(() { _isLoading = true; });
    try {
      final response = await _apiService.resetPassword(
        _emailController.text,
        _otpController.text,
        _confirmPassController.text,
      );
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đặt lại mật khẩu thành công! Vui lòng đăng nhập.')));

        String? token = await StorageHelper.getToken();
        if (token != null && token.isNotEmpty) {
          Navigator.pop(context); 
        } else {
          Navigator.pushAndRemoveUntil(
            context, 
            MaterialPageRoute(builder: (context) => const LoginScreen()), 
            (route) => false
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Đặt lại mật khẩu thất bại')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi đặt lại mật khẩu: $e')),
      );
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
              title: "Forgot Password",
              onBackPressed: () => Navigator.pop(context),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Hãy nhập mật khẩu có ít nhất 8 ký tự để bảo vệ tài khoản của bạn.",
                    style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
                  ),
                  const SizedBox(height: 10),

                  //Email
                  CustomTextField(
                    title: "Email",
                    controller: _emailController,
                    hintText: 'Nhập email',
                    keyboardType: TextInputType.emailAddress,
                    inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
                  ),
                  
                  // OTP và nút gửi OTP
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          title: "OTP",
                          controller: _otpController,
                          hintText: 'Nhập mã OTP',
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly,LengthLimitingTextInputFormatter(6)],
                          suffixIcon:Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  height: 24,
                                  width: 1,
                                  color: Colors.grey.withOpacity(0.5),
                                  margin: const EdgeInsets.symmetric(horizontal: 10)
                                ),

                                _isLoading?const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey)
                                ):GestureDetector(
                                  onTap:_sendOtp,
                                  child: const Text("Gửi OTP", 
                                  style: TextStyle(
                                    color: AppColors.primaryOrange,
                                    fontWeight: FontWeight.bold
                                  )),
                                )
                              ],
                            )
                          )
                        ),
                      ),
                    ],
                  ),

                  // New Password
                  CustomTextField(
                    title: "New Password",
                    controller: _newPassController,
                    hintText: 'Nhập mật khẩu mới',
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.primaryOrange),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword)
                    ),
                  ),

                  // Confirm Password
                  CustomTextField(
                    title: "Confirm Password",
                    controller: _confirmPassController,
                    hintText: 'Xác nhận mật khẩu mới',
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.primaryOrange),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword)
                    ),
                  ),

                  const SizedBox(height: 15),
                  PrimaryButton(
                    text: "Đặt lại mật khẩu", 
                    onPressed: _resetPass)
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}