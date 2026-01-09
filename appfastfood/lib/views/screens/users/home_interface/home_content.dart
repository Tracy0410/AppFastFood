import 'package:appfastfood/views/screens/users/product_detail.dart';
import 'package:appfastfood/views/widget/product_card.dart';
import 'package:flutter/material.dart';
import '../../../../models/products.dart';

class HomeContent extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final List<Product> displayProducts;
  final Future<List<Product>> productsFuture;
  final Function(String) onCategorySelected;
  final Future<List<Product>> Function() onRefresh;

  const HomeContent({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.displayProducts,
    required this.productsFuture,
    required this.onCategorySelected,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. Danh sách Category
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = category == selectedCategory;
              return GestureDetector(
                onTap: () => onCategorySelected(category), // Gọi hàm callback
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFE95322) : Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // 2. Danh sách sản phẩm (Product List)
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh, // Gọi hàm refresh
            child: FutureBuilder<List<Product>>(
              future: productsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text("Lỗi: ${snapshot.error}"));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Không có sản phẩm nào"));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(10),
                  separatorBuilder: (context, index) => const SizedBox(height: 20),
                  itemCount: displayProducts.length,
                  itemBuilder: (context, index) {
                    final product = displayProducts[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailScreen(product: product),
                          ),
                        );
                      },
                      child: ProductCard(product: product),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}