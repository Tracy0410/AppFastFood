import 'package:appfastfood/views/screens/users/product_detail.dart';
import 'package:appfastfood/views/widget/product_card.dart';
import 'package:flutter/material.dart';
import '../../../../models/products.dart';

class FavoriteContent extends StatefulWidget {
  final List<Product>? favoriteProducts;
  final Future<void> Function() onRefresh;
  final Future<List<Product>>? productsFuture;

  const FavoriteContent({
    super.key,
    required this.favoriteProducts,
    required this.onRefresh,
    required this.productsFuture,
  });

  @override
  State<FavoriteContent> createState() => _FavoriteContentState();
}

class _FavoriteContentState extends State<FavoriteContent> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: FutureBuilder<List<Product>>(
          future: widget.productsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Lỗi: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 200),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.favorite_border,
                          size: 80,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Chưa có sản phẩm yêu thích',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
            final List<Product> realFavoriteList = snapshot.data!;

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(10),
              separatorBuilder: (context, index) => const SizedBox(height: 20),
              itemCount: realFavoriteList.length,
              itemBuilder: (context, index) {
                final product = realFavoriteList[index];
                return GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProductDetailScreen(product: product),
                      ),
                    );
                    widget.onRefresh();
                  },
                  child: ProductCard(product: product),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
