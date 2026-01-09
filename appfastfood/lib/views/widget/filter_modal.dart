import 'package:flutter/material.dart';

class CategoryItem {
  final String id;
  final String name;
  CategoryItem({required this.id, required this.name});
}

class FilterModal extends StatefulWidget {
  final List<CategoryItem> categories;
  // Sửa lại: chỉ trả về maxPrice (vì min luôn là 0)
  final Function(String categoryId, int rating, double maxPrice) onApply;

  const FilterModal({
    super.key,
    required this.categories,
    required this.onApply,
  });

  @override
  State<FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<FilterModal> {
  String _selectedCategoryId = "All";
  int _selectedRating = 0;
  double _currentMaxPrice = 150000; // Giá trần mặc định

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Container(
              width: 50, height: 5,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 20),

          // 1. Categories
          const Text("Categories", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildChoiceChip("All", "All"),
              ...widget.categories.map((cat) => _buildChoiceChip(cat.name, cat.id)),
            ],
          ),
          
          const SizedBox(height: 20),

          // 2. Mức độ đánh giá
          const Text("Mức độ đánh giá", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(5, (index) {
              int star = index + 1;
              bool isSelected = _selectedRating == star;
              return InkWell(
                onTap: () => setState(() => _selectedRating = star),
                child: Container(
                  width: 50, height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFFFC529).withOpacity(0.2) : Colors.grey.shade100,
                    shape: BoxShape.circle,
                    border: isSelected ? Border.all(color: const Color(0xFFE95322), width: 2) : null,
                  ),
                  child: Text(
                    "$star", 
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? const Color(0xFFE95322) : Colors.black,
                      fontSize: 16
                    )
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 20),

          // 3. Giá & Nút Check
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Giá tối đa", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton(
                onPressed: () {
                  // Trả về maxPrice
                  widget.onApply(_selectedCategoryId, _selectedRating, _currentMaxPrice);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE95322),
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(12),
                ),
                child: const Icon(Icons.check, color: Colors.white),
              )
            ],
          ),
          
          // DÙNG SLIDER THAY VÌ RANGE SLIDER
          Slider(
            value: _currentMaxPrice,
            min: 0,
            max: 500000, 
            divisions: 50,
            activeColor: const Color(0xFFE95322),
            inactiveColor: Colors.grey.shade300,
            label: "${(_currentMaxPrice/1000).toInt()}k",
            onChanged: (value) => setState(() => _currentMaxPrice = value),
          ),
          
          // Text hiển thị khoảng giá đang chọn
          Center(
            child: Text(
              "0đ - ${(_currentMaxPrice).toStringAsFixed(0)}đ",
              style: const TextStyle(
                color: Color(0xFFE95322), 
                fontWeight: FontWeight.bold,
                fontSize: 16
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildChoiceChip(String label, String id) {
    bool isSelected = _selectedCategoryId == id;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFFFFC529),
      backgroundColor: Colors.grey.shade200,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87, 
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
      ),
      onSelected: (selected) => setState(() => _selectedCategoryId = id),
    );
  }
}