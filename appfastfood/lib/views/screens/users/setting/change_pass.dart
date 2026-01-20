import 'package:appfastfood/service/api_service.dart';
import 'package:appfastfood/utils/app_colors.dart';
import 'package:appfastfood/views/screens/users/info/forgot_pass_screen.dart';
import 'package:appfastfood/views/widget/auth_widgets.dart';
import 'package:appfastfood/views/widget/topbar_page.dart';
import 'package:flutter/material.dart';

class ChangePass extends StatefulWidget{
  const ChangePass({super.key});

  @override
  State<ChangePass> createState() => _ChangePass();
}

class _ChangePass extends State<ChangePass>{
  final TextEditingController _oldPassController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  bool _obscureNewPassword = true;
  bool _obscureOldPassword = true;
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  void _handleChangePassword() async {
    final oldPass = _oldPassController.text.trim();
    final newPass = _newPassController.text.trim();
    final confirmPass = _confirmPassController.text.trim();

    if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      _showMsg("Vui lòng nhập đầy đủ thông tin");
      return;
    }

    if (newPass != confirmPass) {
      _showMsg("Mật khẩu xác nhận không khớp");
      return;
    }

    if (newPass.length < 8) {
      _showMsg("Mật khẩu mới phải có ít nhất 8 ký tự");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await _apiService.changePassword(oldPass, newPass, confirmPass);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      if (result['success']) {
        _showMsg(result['message'] ?? "Đổi mật khẩu thành công!", isError: false);

        _oldPassController.clear();
        _newPassController.clear();
        _confirmPassController.clear();
      } else {
        _showMsg(result['message'] ?? "Đổi mật khẩu thất bại");
      }
    }
  }
  void _showMsg(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            TopBarPage(showBackButton: true, title: "Thay Đổi Mật Khẩu"),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24,vertical: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextField(
                    title: "Mật Khẩu Cũ",
                    controller: _oldPassController, 
                    hintText: "Nhập mật khẩu cũ",
                    obscureText: _obscureOldPassword,
                    suffixIcon: IconButton(
                      icon: Icon(_obscureOldPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.primaryOrange),
                      onPressed: () => setState(() => _obscureOldPassword = !_obscureOldPassword)
                    ),
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotPassScreen()));
                      },
                      child: const Text(
                        "Forget Password",
                        style: TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  CustomTextField(
                    title: "Mật Khẩu Mới",
                    controller: _newPassController, 
                    hintText: "Nhập mật khẩu Mới",
                    obscureText: _obscureNewPassword,
                    suffixIcon: IconButton(
                      icon: Icon(_obscureNewPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.primaryOrange),
                      onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword)
                    ),
                  ),

                  CustomTextField(
                    title: "Mật Khẩu Cũ",
                    controller: _confirmPassController, 
                    hintText: "Nhập mật khẩu cũ",
                    obscureText: _obscureNewPassword,
                    suffixIcon: IconButton(
                      icon: Icon(_obscureNewPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.primaryOrange),
                      onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword)
                    ),
                  ),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleChangePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryOrange,
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white) : const Text(
                            "Đổi Mật Khẩu",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1
                            ),
                          ),
                    ),
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