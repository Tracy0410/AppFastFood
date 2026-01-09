import 'package:flutter/material.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Chỉ trả về phần nội dung (Body), không tạo Scaffold mới
    return Container(
      width: double.infinity,
      color: Colors.white, // Nền trắng
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "Câu hỏi thường gặp",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepOrange),
            ),
            SizedBox(height: 20),
            
            // Câu 1
            Text("1. Làm sao để đặt hàng?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 5),
            Text("Trả lời: Bạn chọn món ăn tại trang chủ, thêm vào giỏ hàng và tiến hành thanh toán."),
            Divider(height: 30),

            // Câu 2
            Text("2. Phí vận chuyển tính thế nào?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 5),
            Text("Trả lời: Phí vận chuyển được tính dựa trên khoảng cách từ cửa hàng đến địa chỉ của bạn."),
            Divider(height: 30),

            // Mục chính sách
            Text(
              "Chính sách bảo mật",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepOrange),
            ),
            SizedBox(height: 10),
            Text("Chúng tôi cam kết bảo mật tuyệt đối thông tin cá nhân của khách hàng..."),
          ],
        ),
      ),
    );
  }
}