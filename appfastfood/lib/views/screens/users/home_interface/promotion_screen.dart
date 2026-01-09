import 'package:appfastfood/models/promotion.dart';
import 'package:appfastfood/service/api_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import '../../../../models/promotion.dart';
import '../../../../service/api_service.dart';

class PromotionScreen extends StatefulWidget {
  const PromotionScreen({super.key});

  @override
  State<PromotionScreen> createState() => _PromotionScreenState();
}

class _PromotionScreenState extends State<PromotionScreen> {
  late Future<List<Promotion>> _futurePromotions;

  @override
  void initState() {
    super.initState();
    _futurePromotions = ApiService().getPromotions();
  }

  @override
  Widget build(BuildContext context) {
    // Màu vàng theo thiết kế
    final yellowColor = const Color(0xFFFFC529); 
    // Màu đỏ cam theo thiết kế
    final redColor = const Color(0xFFE95322);

    return Scaffold(
      backgroundColor: Colors.white, // Nền trắng
      body: Column(
        children: [
          // 1. HEADER (Màu vàng)
          Container(
            padding: const EdgeInsets.only(top: 50, bottom: 20, left: 20, right: 20),
            width: double.infinity,
            decoration: BoxDecoration(
              color: yellowColor,
              // Bo tròn góc dưới nếu thích (trong ảnh của bạn thì thẳng, nhưng bo nhẹ sẽ đẹp hơn)
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Nếu muốn nút back thì bỏ comment dòng dưới
                // Icon(Icons.arrow_back_ios, size: 18, color: redColor),
                const Spacer(),
                const Text(
                  "Khuyến Mãi",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, 
                  ),
                ),
                const Spacer(),
                // Icon ảo để căn giữa text
                const SizedBox(width: 20), 
              ],
            ),
          ),

          // 2. DANH SÁCH VOUCHER
          Expanded(
            child: FutureBuilder<List<Promotion>>(
              future: _futurePromotions,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: redColor));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Chưa có chương trình khuyến mãi nào."));
                }

                final list = snapshot.data!;
                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 20),
                  itemBuilder: (context, index) {
                    final item = list[index];
                    return _buildVoucherCard(item, redColor);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Widget vẽ từng thẻ Voucher giống thiết kế
  Widget _buildVoucherCard(Promotion promo, Color redColor) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.centerRight,
      children: [
        // NỀN THẺ (Màu kem)
        Container(
          height: 80,
          width: double.infinity,
          margin: const EdgeInsets.only(right: 15), // Chừa chỗ cho cái tem thò ra
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F1D2), // Màu kem nhạt giống ảnh
            borderRadius: BorderRadius.circular(15),
          ),
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(right: 40.0), // Tránh chữ đè lên tem
            child: Text(
              promo.name,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),

        // TEM GIẢM GIÁ (Hình răng cưa màu đỏ)
        Positioned(
          right: 0,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: redColor, // Màu đỏ cam
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2), // Viền trắng cho nổi
              boxShadow: [
                 BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
              ]
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "-${promo.discountPercent.toInt()}%",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}