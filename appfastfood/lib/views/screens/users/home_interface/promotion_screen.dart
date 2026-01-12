import 'package:appfastfood/models/promotion.dart';
import 'package:appfastfood/service/api_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Nhớ thêm package intl vào pubspec.yaml nếu chưa có

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

  bool _isActive(Promotion promo) {
    final now = DateTime.now();

    try {
      DateTime start = DateTime.parse(promo.startDate.toString()); 
      DateTime end = DateTime.parse(promo.endDate.toString());
      
      return now.isAfter(start) && now.isBefore(end);
    } catch (e) {
      return false;
    }
  }

  // Hàm format ngày hiển thị (dd/MM/yyyy)
  String _formatDisplayDate(dynamic dateStr) {
    try {
      DateTime date = DateTime.parse(dateStr.toString());
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return "Unknown";
    }
  }

  @override
  Widget build(BuildContext context) {
    final yellowColor = const Color(0xFFFFC529); 
    final redColor = const Color(0xFFE95322);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 1. HEADER
          Container(
            padding: const EdgeInsets.only(top: 50, bottom: 20, left: 20, right: 20),
            width: double.infinity,
            decoration: BoxDecoration(
              color: yellowColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: const Center(
              child: Text(
                "Khuyến Mãi",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, 
                ),
              ),
            ),
          ),

          // 2. DANH SÁCH VOUCHER (Đã lọc)
          Expanded(
            child: FutureBuilder<List<Promotion>>(
              future: _futurePromotions,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: redColor));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Không có dữ liệu khuyến mãi."));
                }

                // --- LOGIC LỌC TẠI ĐÂY ---
                // Chỉ lấy những cái đang diễn ra (Active)
                final allList = snapshot.data!;
                final activeList = allList.where((item) => _isActive(item)).toList();

                if (activeList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy, size: 50, color: Colors.grey[400]),
                        const SizedBox(height: 10),
                        const Text("Chưa có chương trình khuyến mãi nào đang diễn ra.", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: activeList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 20),
                  itemBuilder: (context, index) {
                    final item = activeList[index];
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

  Widget _buildVoucherCard(Promotion promo, Color redColor) {
    // Format ngày để hiển thị
    String startStr = _formatDisplayDate(promo.startDate);
    String endStr = _formatDisplayDate(promo.endDate);

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.centerRight,
      children: [
        // NỀN THẺ
        Container(
          height: 95, // Tăng chiều cao để chứa dòng ngày tháng
          width: double.infinity,
          margin: const EdgeInsets.only(right: 15),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F1D2),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 3))
            ]
          ),
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(right: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tên chương trình
                Text(
                  promo.name,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                
                // Dòng hiển thị Ngày Bắt Đầu - Ngày Kết Thúc
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_month_outlined, size: 14, color: Colors.grey[700]),
                      const SizedBox(width: 5),
                      Text(
                        "$startStr - $endStr",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // TEM GIẢM GIÁ
        Positioned(
          right: 0,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: redColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [
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