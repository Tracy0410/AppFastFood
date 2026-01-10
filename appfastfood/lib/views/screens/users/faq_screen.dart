import 'package:flutter/material.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  // 1. Tách dữ liệu ra đây để sau này dễ thêm sửa xóa
  final List<Map<String, String>> _faqs = const [
    {
      "question": "Làm sao để đặt hàng?",
      "answer": "Bạn chọn món ăn tại trang chủ, chọn size/topping, thêm vào giỏ hàng và tiến hành thanh toán qua các bước xác nhận."
    },
    {
      "question": "Phí vận chuyển tính thế nào?",
      "answer": "Phí vận chuyển được tính tự động dựa trên khoảng cách từ cửa hàng gần nhất đến địa chỉ của bạn (khoảng 5.000đ/km)."
    },
    {
      "question": "Tôi có thể hủy đơn hàng không?",
      "answer": "Bạn chỉ có thể hủy đơn hàng khi trạng thái là 'Đang chờ xác nhận'. Nếu quán đã làm món, bạn không thể hủy."
    },
    {
      "question": "Thời gian giao hàng bao lâu?",
      "answer": "Thông thường từ 15-30 phút tùy vào khoảng cách và tình hình giao thông/thời tiết."
    },
    {
      "question": "Phương thức thanh toán hỗ trợ?",
      "answer": "Chúng tôi hỗ trợ Tiền mặt (COD), Chuyển khoản ngân hàng và Ví điện tử VNPay."
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold( // Dùng Scaffold để chuẩn cấu trúc hơn là Container
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Câu hỏi thường gặp",
              style: TextStyle(
                fontSize: 22, 
                fontWeight: FontWeight.bold, 
                color: Colors.deepOrange
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Giải đáp các thắc mắc chung của khách hàng",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // 2. Dùng map để render danh sách tự động
            ..._faqs.map((faq) => Card(
              elevation: 0, // Bỏ bóng nếu muốn phẳng
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade200)
              ),
              margin: const EdgeInsets.only(bottom: 10),
              child: ExpansionTile(
                // Màu icon khi mở ra
                iconColor: Colors.deepOrange, 
                // Màu chữ khi mở ra
                textColor: Colors.deepOrange,
                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                title: Text(
                  faq["question"]!,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                      faq["answer"]!,
                      style: TextStyle(color: Colors.grey[700], height: 1.4),
                    ),
                  )
                ],
              ),
            )),

            const SizedBox(height: 20),
            
            // Phần chính sách
            const Text(
              "Chính sách bảo mật",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepOrange),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8)
              ),
              child: const Text(
                "Chúng tôi cam kết bảo mật tuyệt đối thông tin cá nhân của khách hàng theo chính sách bảo vệ quyền riêng tư hiện hành. Mọi thông tin chỉ được dùng để phục vụ việc giao hàng và chăm sóc khách hàng.",
                style: TextStyle(height: 1.5, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}