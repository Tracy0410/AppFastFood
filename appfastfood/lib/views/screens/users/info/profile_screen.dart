import 'dart:convert';
import 'dart:io';
import 'package:appfastfood/models/user.dart';
import 'package:appfastfood/service/api_service.dart';
import 'package:appfastfood/utils/app_colors.dart';
import 'package:appfastfood/utils/storage_helper.dart';
import 'package:appfastfood/views/screens/users/info/address/address_list.dart';
import 'package:appfastfood/views/widget/auth_widgets.dart';
import 'package:appfastfood/views/widget/topbar_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  User? _currentUser;
  File? _selectedImage;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // Lấy thông tin user từ API
  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true); 

    try {
      String? token = await StorageHelper.getToken();
      
      if (token != null) {
        User? userFetchedFromApi = await ApiService().getProfile();
        
        if (mounted && userFetchedFromApi != null) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          String userJson = jsonEncode(userFetchedFromApi.toJson()); 
          await prefs.setString('user_data', userJson);
           setState(() {
            _currentUser = userFetchedFromApi;

            _nameController.text = _currentUser?.fullname ?? "";
            _emailController.text = _currentUser?.email ?? "";
            _phoneController.text = _currentUser?.phone ?? "";
            
            _dobController.text = _formatDateForDisplay(_currentUser?.birthday);
          });
        }
      }
    } catch (e) {
      print("Lỗi load profile: $e");
      // Có thể hiện thông báo lỗi nhẹ ở đây nếu muốn
    } finally {
      // 2. Tắt loading dù thành công hay thất bại
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Chọn ảnh từ Gallery
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  // Chọn ngày sinh
  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      // locale: const Locale("vi","VN")
    );
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('dd-MM-yyyy').format(picked);
      });
    }
  }

  // Chuyển từ yyyy-MM-dd (API) sang dd-MM-yyyy (Hiển thị)
  String _formatDateForDisplay(String? dateString) {
    if (dateString == null || dateString == "null" || dateString.isEmpty) {
      return "";
    }

    try {
      DateTime date = DateTime.parse(dateString);
      return DateFormat('dd-MM-yyyy').format(date);
    } catch (e) {
      try {
        DateTime date = DateFormat('dd/MM/yyyy').parse(dateString.replaceAll('-', '/'));
        return DateFormat('dd-MM-yyyy').format(date);
      } catch (e2) {
        return dateString; 
      }
    }
  }

  // Chuyển từ dd-MM-yyyy (Hiển thị) sang yyyy-MM-dd (Gửi API)
  String _formatDateForApi(String uiDate) {
    if (uiDate.isEmpty) return "";
    try {
      DateTime date = DateFormat('dd-MM-yyyy').parse(uiDate);
      return DateFormat('yyyy-MM-dd').format(date);
    } catch (e) {
      return uiDate; // Trả về nguyên gốc nếu lỗi
    }
  }

  // Hàm lưu thông tin
  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);

    String apiBirthday = _formatDateForApi(_dobController.text);
    
    // Gọi API update
    bool success = await ApiService().updateProfile(
      fullname: _nameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      birthday: apiBirthday,
      imageFile: _selectedImage,
    );

    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Cập nhật thành công!")));
      _loadUserProfile(); // Load lại để thấy ảnh mới từ DB trả về
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Cập nhật thất bại!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const TopBarPage(showBackButton: true, title: "Hồ sơ của tôi"),
          Expanded(
            child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFC529)))
            : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: _getAvatarImage() != null
                                ? Image(
                                    image: _getAvatarImage()!,
                                    fit: BoxFit.cover,
                                    width: 120,
                                    height: 120,
                                  )
                                : const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.grey,
                                  ),
                          ),
                        ),

                        // 2. Icon Camera nhỏ
                        Positioned(
                          bottom: -5,
                          right: -5,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 5,
                                )
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt_outlined, 
                              size: 20, 
                              color: AppColors.primaryOrange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  CustomTextField(
                    controller: _nameController,
                    title: "Họ Tên",
                    hintText: _currentUser?.fullname ?? "Nhập họ tên",
                    suffixIcon: const Icon(Icons.person_outlined),
                  ),

                  CustomTextField(
                    controller: _dobController,
                    title: "Ngày sinh",
                    hintText: _currentUser?.birthday ?? "dd-MM-yyyy",
                    suffixIcon: const Icon(Icons.calendar_today_outlined),
                    onTap: () => _selectDate(context),
                    textRead: true,
                  ),

                  CustomTextField(
                    controller: _emailController,
                    title: "Email",
                    hintText: _currentUser?.email ?? "Nhập email",
                    suffixIcon: const Icon(Icons.email_outlined),
                  ),

                  CustomTextField(
                    controller: _phoneController,
                    title: "Số Điện Thoại",
                    hintText: _currentUser?.phone ?? "Nhập số điện thoại",
                    suffixIcon: const Icon(Icons.phone_outlined),
                  ),

                  const SizedBox(height: 20),
                  Row(
                    children: [
                    //  Nút thay đổi địa chỉ
                    Expanded(
                      child: SizedBox(
                        height: 45, // Tăng chiều cao chút cho dễ bấm
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => AddressList()));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryOrange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 3,
                          ),
                          child: const Text(
                            "Địa chỉ",
                            style: TextStyle(
                              color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                            
                    const SizedBox(width: 15), // Khoảng cách giữa 2 nút

                    // Nút cập nhật
                    Expanded(
                      child: SizedBox(
                        height: 45,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _updateProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryOrange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 3,
                          ),
                          child: const Text(
                            "Cập nhật",
                            style: TextStyle(
                              color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget hiển thị ảnh: Ưu tiên ảnh vừa chọn > Ảnh từ server > Ảnh mặc định
  ImageProvider? _getAvatarImage() {
    if (_selectedImage != null) {
      return FileImage(_selectedImage!);
    }

    if (_currentUser?.image != null && _currentUser!.image!.isNotEmpty) {
      try {
        String imgString = _currentUser!.image!;

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
        print("Lỗi parse ảnh: $e");
      }
    }
    return null;
  }
}
