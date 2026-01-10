import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ai_chat_screen.dart';
import 'home_screen.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _header(context),
          _subHeader(),
          Expanded(child: _menu(context)),
        ],
      ),
    );
  }

  // GIỮ NGUYÊN HEADER CỦA BẠN
  Widget _header(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(15, 50, 15, 15),
        color: const Color(0xFFFFD54F),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back_ios, color: Colors.white),
            ),
            const Text(
              "Liên Hệ Với Cửa Hàng",
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            InkWell(
              onTap: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomePageScreen()),
                (_) => false,
              ),
              child: const Icon(Icons.home_outlined, color: Colors.white),
            ),
          ],
        ),
      );

  // GIỮ NGUYÊN SUBHEADER CỦA BẠN
  Widget _subHeader() => Container(
        width: double.infinity, // Thêm width infinity để full màn hình
        padding: const EdgeInsets.all(12),
        color: const Color(0xFFFFF8E1),
        child: const Text(
          "Hỏi đáp tự động với AI",
          textAlign: TextAlign.center, // Canh giữa cho đẹp giống ảnh
          style: TextStyle(
              fontWeight: FontWeight.w600, color: Color(0xFFE65100)),
        ),
      );

  // THAY ĐỔI: GOM 2 MỤC VÀO TRONG 1 CÁI EXPANSION TILE
  Widget _menu(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ExpansionTile(
            shape: const Border(), // Bỏ viền mặc định khi mở
            title: const Text(
              "Liên hệ với cửa hàng",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            childrenPadding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
            children: [
              // MỤC 1: HOTLINE (Giữ nguyên logic của bạn)
              _item(
                icon: Icons.phone,
                text: "Hotline: 0306231094",
                onTap: () {
                  Clipboard.setData(
                      const ClipboardData(text: "0306231094"));
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Đã sao chép")));
                },
              ),
              const SizedBox(height: 10),
              // MỤC 2: CHAT AI (Giữ nguyên logic của bạn)
              _item(
                icon: Icons.smart_toy,
                text: "Chat với Trợ lý ảo",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AIChatScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      );

  // GIỮ NGUYÊN HÀM ITEM CỦA BẠN
  Widget _item(
          {required IconData icon,
          required String text,
          required VoidCallback onTap}) =>
      InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.grey[50], // Chỉnh nhẹ màu nền item con cho dễ nhìn
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFFE65100)),
              const SizedBox(width: 15),
              Text(text,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
}