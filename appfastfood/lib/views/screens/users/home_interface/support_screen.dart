import 'package:flutter/material.dart';
import 'package:appfastfood/views/screens/users/home_screen.dart'; 

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Danh sách câu hỏi thường gặp
    final List<Map<String, String>> faqs = [
      {
        "question": "Làm sao để hủy đơn hàng đã đặt?",
        "answer":
            "Bạn có thể hủy đơn hàng trực tiếp trên ứng dụng theo các bước sau:\n1. Vào mục 'Đơn hàng của tôi'\n2. Chọn đơn hàng muốn hủy\n3. Nhấn nút 'Hủy đơn hàng'.",
      },
      {
        "question": "Tôi có thể thay đổi địa chỉ giao hàng không?",
        "answer":
            "Có, bạn có thể thay đổi trong phần Cài đặt hồ sơ hoặc ngay tại màn hình thanh toán trước khi đặt hàng.",
      },
      {
        "question": "Tại sao đơn hàng của tôi bị giao chậm?",
        "answer":
            "Có thể do thời tiết xấu hoặc nhà hàng đang quá tải. Bạn vui lòng kiểm tra mục 'Theo dõi đơn hàng' để biết chi tiết.",
      },
      {
        "question": "Chính sách hoàn tiền khi món ăn bị hỏng/thiếu?",
        "answer":
            "Vui lòng chụp ảnh và liên hệ bộ phận CSKH ngay lập tức để được hỗ trợ hoàn tiền hoặc đổi món.",
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCD057),
        elevation: 0,
        centerTitle: true,
        // 1. NÚT BACK (Quay lại Menu/Màn hình trước)
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Trợ Giúp",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        // 2. NÚT HOME (Về trang chủ)
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined, size: 30, color: Colors.white),
            onPressed: () {
              // Chuyển về Home và xóa các màn hình cũ trong stack
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomePageScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              color: const Color(0xFFFCD057).withOpacity(0.3),
              child: const Text(
                "Chúng Tôi Có Thể Giúp Gì Cho Bạn?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFE95322),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            ...faqs.map((faq) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 5,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: ExpansionTile(
                    title: Text(
                      faq['question']!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF4A3B2C),
                      ),
                    ),
                    childrenPadding: const EdgeInsets.all(16),
                    expandedAlignment: Alignment.centerLeft,
                    textColor: const Color(0xFFE95322), // Màu chữ title khi mở
                    iconColor: const Color(0xFFE95322), // Màu mũi tên khi mở
                    children: [
                      Text(
                        faq['answer']!,
                        style: const TextStyle(color: Colors.grey, height: 1.5),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}