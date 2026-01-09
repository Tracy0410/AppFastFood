import 'package:appfastfood/service/api_service.dart';
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
                  
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}