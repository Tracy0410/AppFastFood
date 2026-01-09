import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import 'package:flutter/services.dart';

// 1. Header màu vàng dùng chung
class AuthHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBackPressed;

  const AuthHeader({
    super.key,
    required this.title,
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      decoration: const BoxDecoration(
        color: AppColors.yellowHeader,
      ),
      child: SafeArea(
        child: Stack(
          children: [
            Positioned(
              left: 10,
              top: 10,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: onBackPressed,
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  title,
                  style: const TextStyle(
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
    );
  }
}

//TextField được style sẵn
class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String? title;
  final bool obscureText;
  final bool textRead;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter> inputFormatters;
  final VoidCallback? onTap;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.title,
    this.obscureText = false,
    this.textRead=false,
    this.suffixIcon,
    this.keyboardType,
    this.inputFormatters = const [],
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: const TextStyle(
              fontWeight: FontWeight.bold, 
              color: AppColors.textDark
            ),
          ),
          const SizedBox(height: 5),
        ],

        TextFormField(
          controller: controller,
          obscureText: obscureText,
          readOnly: textRead,
          keyboardType: keyboardType,
          onTap: onTap,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.inputBg,
            hintText: hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
            suffixIcon: suffixIcon,
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

// Nút bấm chính
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 45,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryOrange,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 3,
        ),
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                text,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
      ),
    );
  }
}

// Khu vực Social Icons
class SocialLoginSection extends StatelessWidget {
  const SocialLoginSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Center(
            child: Text("or sign up with", style: TextStyle(color: Colors.grey))),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSocialButton("assets/google_Icon.jpg", Colors.white),
            const SizedBox(width: 10),
            _buildSocialButton("assets/facebook_Icon.jpg", Colors.white),
          ],
        ),
      ],
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
      child: Padding(
          padding: const EdgeInsets.all(5),
          child: Image.asset(assetName, fit: BoxFit.contain)),
    );
  }
}