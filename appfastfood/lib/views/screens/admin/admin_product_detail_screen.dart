import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:appfastfood/service/api_service.dart';
import 'package:appfastfood/models/products.dart';

class AdminProductDetailScreen extends StatefulWidget {
  final Product product;
  final Function()? onUpdated;

  const AdminProductDetailScreen({
    super.key,
    required this.product,
    this.onUpdated,
  });

  @override
  State<AdminProductDetailScreen> createState() => _AdminProductDetailScreenState();
}

class _AdminProductDetailScreenState extends State<AdminProductDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  
  final Map<String, int> _categories = {
    'Burger': 1,
    'Pizza': 2,
    'Mì Ý': 3,
    'Cơm': 4,
    'Gà Rán': 5,
    'Đồ uống': 6,
  };
  
  String _selectedCategoryName = 'Burger';
  bool _status = true;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _descController = TextEditingController(text: widget.product.description);
    _priceController = TextEditingController(text: widget.product.price.toStringAsFixed(0));
    
    _status = widget.product.status == 1;

    _selectedCategoryName = _categories.keys.firstWhere(
      (k) => _categories[k] == widget.product.id, 
      orElse: () => 'Burger'
    );
  }

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    // Tạo object mới - ĐÃ BỎ average_rating
    Product updateData = Product(
      id: widget.product.id,
      name: _nameController.text,
      description: _descController.text,
      price: double.tryParse(_priceController.text) ?? 0,
      imageUrl: widget.product.imageUrl,
      categoryId: _categories[_selectedCategoryName] ?? 1,
      categoryName: _selectedCategoryName,
      status: _status ? 1 : 0,
      // average_rating đã được bỏ
    );

    bool success = await _apiService.updateProduct(updateData, _imageFile);
    
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cập nhật thành công!"), backgroundColor: Colors.green));
      if (widget.onUpdated != null) widget.onUpdated!();
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi cập nhật sản phẩm"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.product.id != 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Sửa món ăn #${widget.product.id}" : "Thêm món mới"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. CHỌN ẢNH
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 160, height: 160,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: _imageFile != null
                            ? Image.file(_imageFile!, fit: BoxFit.cover)
                            : (widget.product.imageUrl.isNotEmpty
                                ? Image.network(widget.product.imageUrl, fit: BoxFit.cover)
                                : const Icon(Icons.add_a_photo, size: 50, color: Colors.grey)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Center(child: Text("Chạm vào ảnh để thay đổi", style: TextStyle(color: Colors.grey))),
                  const SizedBox(height: 20),

                  // 2. INPUT FIELDS
                  _buildTextField("Tên món ăn", _nameController),
                  const SizedBox(height: 15),
                  
                  _buildTextField("Giá tiền (VNĐ)", _priceController, isNumber: true),
                  const SizedBox(height: 15),

                  Text("Danh mục", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedCategoryName,
                        items: _categories.keys.map((String key) {
                          return DropdownMenuItem(value: key, child: Text(key));
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedCategoryName = val!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  _buildTextField("Mô tả chi tiết", _descController, maxLines: 3),
                  const SizedBox(height: 20),

                  // 3. TRẠNG THÁI (Ẩn/Hiện)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    decoration: BoxDecoration(
                      color: _status ? Colors.green[50] : Colors.red[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _status ? Colors.green : Colors.red),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Trạng thái hiển thị", style: TextStyle(fontWeight: FontWeight.bold, color: _status ? Colors.green : Colors.red)),
                            Text(_status ? "Sản phẩm đang hiển thị trên App" : "Sản phẩm đang bị ẩn", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        Switch(
                          value: _status,
                          activeColor: Colors.green,
                          inactiveThumbColor: Colors.red,
                          onChanged: (val) => setState(() => _status = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 4. BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFB039),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text("LƯU THAY ĐỔI", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (_isLoading)
            Container(color: Colors.black45, child: const Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          maxLines: maxLines,
          validator: (val) => val == null || val.isEmpty ? "Vui lòng nhập $label" : null,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          ),
        ),
      ],
    );
  }
}