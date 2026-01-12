import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/products.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'VNĐ',
      decimalDigits: 0,
    );

    return Container(
      padding: EdgeInsets.all(5),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 250,
              width: 450,
              child: product.imageUrl.isNotEmpty
                  ? Image.network(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.white,
                          child: Icon(Icons.image_not_supported),
                        );
                      },
                    )
                  : SizedBox(
                      height: 150,
                      child: Icon(Icons.image_not_supported),
                    ),
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  product.name,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.orange,
                ),
                child: Row(
                  children: [
                    Text("${product.averageRating}"),
                    Icon(Icons.star, color: Colors.yellow),
                  ],
                ),
              ),
              SizedBox(width: 8),

              // 3. Sử dụng formatter ở đây
              Text(
                formatCurrency.format(product.price),
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold, // Nên in đậm giá tiền cho dễ nhìn
                  color: Colors.red, // (Tuỳ chọn) Đổi màu giá tiền cho nổi bật
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Divider(),
        ],
      ),
    );
  }
}
