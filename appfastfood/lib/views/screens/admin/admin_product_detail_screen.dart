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
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  
  String? _selectedCategory;
  bool _status = true;
  bool _isLoading = false;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  final List<String> _categories = [
    'Burger',
    'Pizza',
    'Đồ uống',
    'Tráng miệng',
    'Khai vị',
    'Combo'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _descriptionController = TextEditingController(text: widget.product.description);
    _priceController = TextEditingController(text: widget.product.price.toString());
    _status = widget.product.status == 1;
    _selectedCategory = _getCategoryNameFromId(widget.product.categoryId);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  String _getCategoryNameFromId(int? categoryId) {
    switch (categoryId) {
      case 1: return 'Burger';
      case 2: return 'Pizza';
      case 3: return 'Đồ uống';
      case 4: return 'Tráng miệng';
      case 5: return 'Khai vị';
      case 6: return 'Combo';
      default: return 'Burger';
    }
  }

  int _getCategoryIdFromName(String? categoryName) {
    switch (categoryName) {
      case 'Burger': return 1;
      case 'Pizza': return 2;
      case 'Đồ uống': return 3;
      case 'Tráng miệng': return 4;
      case 'Khai vị': return 5;
      case 'Combo': return 6;
      default: return 1;
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

Future<void> _updateProduct() async {
  print('Current status: $_status');
  if (!_formKey.currentState!.validate()) return;
  
  setState(() => _isLoading = true);
  
  try {
    Product updatedProduct = Product(
      id: widget.product.id,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      price: double.parse(_priceController.text),
      imageUrl: widget.product.imageUrl,
      categoryId: _getCategoryIdFromName(_selectedCategory),
      categoryName: _selectedCategory!, 
      status: _status ? 1 : 0,
      averageRating: widget.product.averageRating,
      reviewCount: widget.product.reviewCount,
    );print('Sending status: ${updatedProduct.status}');

    // TODO: Gọi API update sản phẩm
    // Cần tạo hàm updateProduct trong ApiService
    bool success = await ApiService().updateProduct(updatedProduct, _imageFile);
    
    // Tạm thời hiển thị thông báo thành công
    await Future.delayed(const Duration(seconds: 1));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Đã lưu thay đổi!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
    
    widget.onUpdated?.call();
    
    Navigator.pop(context);
    
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ Lỗi: $e'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chỉ tiết sản phẩm',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ảnh sản phẩm
                    GestureDetector(
                      onTap: _pickImage,
                      child: Center(
                        child: Stack(
                          children: [
                            Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                                image: _imageFile != null
                                    ? DecorationImage(
                                        image: FileImage(_imageFile!),
                                        fit: BoxFit.cover,
                                      )
                                    : (widget.product.imageUrl.isNotEmpty
                                        ? DecorationImage(
                                            image: NetworkImage(widget.product.imageUrl),
                                            fit: BoxFit.cover,
                                          )
                                        : null),
                              ),
                              child: _imageFile == null && widget.product.imageUrl.isEmpty
                                  ? const Icon(Icons.fastfood, size: 50, color: Colors.grey)
                                  : null,
                            ),
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(Icons.camera_alt, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Tên món
                    _buildLabel('Tên món:'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Nhập tên món',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập tên món';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Mô tả
                    _buildLabel('Mô tả:'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Nhập mô tả sản phẩm',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập mô tả';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Giá
                    _buildLabel('Giá:'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Nhập giá',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixText: 'đ ',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập giá';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Giá không hợp lệ';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Danh mục
                    _buildLabel('Danh mục:'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: _categories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCategory = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng chọn danh mục';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),

                    // Trạng thái hiển thị
                    _buildLabel('Trạng thái hiển thị'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _status ? 'Đang hiển thị' : 'Đang ẩn',
                            style: TextStyle(
                              color: _status ? Colors.green : Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Switch(
                            value: _status,
                            activeColor: Colors.green,
                            onChanged: (bool value) {
                              setState(() {
                                _status = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Nút hành động
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _updateProduct,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Lưu thay đổi',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: Colors.grey),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Hủy bỏ',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }
}