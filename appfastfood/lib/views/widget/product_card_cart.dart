import 'package:appfastfood/models/cartItem.dart';
import 'package:flutter/material.dart';

class CardProductCart extends StatefulWidget {
  final CartItem item;
  final VoidCallback onIncrease; // Hàm gọi khi bấm tăng
  final VoidCallback onDecrease; // Hàm gọi khi bấm giảm
  final VoidCallback onDelete;

  const CardProductCart({
    super.key,
    required this.item,
    required this.onIncrease,
    required this.onDecrease,
    required this.onDelete,
  });

  @override
  State<CardProductCart> createState() => _CardProductCartState();
}

class _CardProductCartState extends State<CardProductCart> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: SizedBox(
              width: 80,
              height: 80,
              child: widget.item.imageUrl.isNotEmpty
                  ? Image.network(
                      widget.item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                      ),
                    )
                  : const Icon(Icons.image_not_supported, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 15),

          // 2. Tên và Giá
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.item.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Text(
                  '${widget.item.price} VNĐ', // Hoặc format tiền tệ nếu muốn
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFFE95322),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              // Nút Trừ
              InkWell(
                onTap: widget.onDecrease,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Color(0xFFE95322),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.remove,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  '${widget.item.quantity}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              InkWell(
                onTap: widget.onIncrease,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE95322),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, size: 18, color: Colors.white),
                ),
              ),
            ],
          ),
          SizedBox(width: 20),
          InkWell(
            onTap: widget.onDelete,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Color(0xFFE95322),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.delete_outlined),
            ),
          ),
        ],
      ),
    );
  }
}
