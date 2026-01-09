import 'package:appfastfood/service/api_service.dart';
import 'package:appfastfood/utils/app_colors.dart';
import 'package:appfastfood/views/widget/auth_widgets.dart';
import 'package:appfastfood/views/widget/topbar_page.dart';
import 'package:flutter/material.dart';

class NewAddress extends StatefulWidget {
  const NewAddress({super.key});

  @override
  State<NewAddress> createState() => _NewAddressState();
}

class _NewAddressState extends State<NewAddress> {
  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();

  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>(); // Để validate form

  // Màu chủ đạo lấy từ TopBar
  final Color primaryColor = const Color(0xFFFFC529);

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Gọi API lưu địa chỉ
    bool success = await ApiService().addAddress(
      _nameController.text,
      _streetController.text,
      _districtController.text,
      _cityController.text,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Thêm địa chỉ thành công!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Trả về true để reload list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Lỗi hệ thống. Vui lòng thử lại!"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 1. Header
          const TopBarPage(title: "Thêm Địa Chỉ Mới", showBackButton: true),

          // 2. Body form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                        ),
                        child: Icon(
                          Icons.home_outlined,
                          size: 100,
                          color: AppColors.primaryOrange,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Input Tên
                    CustomTextField(
                      controller: _nameController,
                      title: "Tên địa chỉ",
                      hintText: "VD: nhà, công ty,..",
                      suffixIcon: const Icon(Icons.person_outline),
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      "Địa chỉ giao hàng",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Input Đường/Số nhà
                    CustomTextField(
                      controller: _streetController,
                      title: "Số nhà, Tên đường",
                      hintText: "VD: 123 Đường Nguyễn Huệ, P. Bến Nghé",
                      suffixIcon: const Icon(Icons.home_outlined),
                    ),
                    const SizedBox(height: 15),

                    // Input Quận/Huyện
                    CustomTextField(
                      controller: _districtController,
                      title: "Quận / Huyện",
                      hintText: "VD: Quận 1",
                      suffixIcon: const Icon(Icons.map_outlined),
                    ),
                    const SizedBox(height: 15),

                    // Input Tỉnh/TP
                    CustomTextField(
                      controller: _cityController,
                      title: "Tỉnh / Thành phố",
                      hintText: "VD: TP. Hồ Chí Minh",
                      suffixIcon: const Icon(Icons.location_city_outlined),
                    ),
                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryOrange,
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                "LƯU ĐỊA CHỈ",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}