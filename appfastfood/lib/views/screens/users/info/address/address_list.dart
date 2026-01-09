import 'package:appfastfood/models/address.dart';
import 'package:appfastfood/service/api_service.dart';
import 'package:appfastfood/views/screens/users/info/address/new_address.dart';
import 'package:appfastfood/views/widget/topbar_page.dart';
import 'package:flutter/material.dart';

class AddressList extends StatefulWidget {
  const AddressList({super.key});

  @override
  State<AddressList> createState() => _AddressListState();
}

class _AddressListState extends State<AddressList> {
  List<Address> _addressList = [];
  bool _isLoading = true;
  int _selectedIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadAddresslist();
  }

  Future<void> _loadAddresslist() async {
    try {
      // Gọi API lấy danh sách địa chỉ từ backend
      List<Address> data = await ApiService().getAddress();
      if (mounted) {
        setState(() {
          _addressList = data;
          _isLoading = false;
          
          int defaultIndex = data.indexWhere((element) => element.isDefault == true);
          if (defaultIndex != -1) {
            _selectedIndex = defaultIndex;
          } else if (data.isNotEmpty) {
            _selectedIndex = 0;
          }
        });
      }
    } catch (e) {
      print("Lỗi tải danh sách địa chỉ: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Hàm chọn địa chỉ mặc định
  Future<void> _onSelectAddress(int index, int addressId) async {
    if (_selectedIndex == index) return;

    bool success = await ApiService().setDefaultAddress(addressId);

    if (mounted) {
      if (success) {
        setState(() {
          _selectedIndex = index;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Đã đổi địa chỉ giao hàng mặc định"),
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lỗi kết nối, vui lòng thử lại")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Màu cam chủ đạo theo thiết kế
    final Color primaryOrange = const Color(0xFFE85826); 
    final Color lightPinkButton = const Color(0xFFFFE0CC);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Widget TopBar có sẵn của bạn
          const TopBarPage(showBackButton: true, title: "Địa chỉ"),
          
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: primaryOrange))
                : _addressList.isEmpty
                    ? Center(
                        child: Text(
                          "Chưa có địa chỉ nào",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        itemCount: _addressList.length,
                        // Đường kẻ mờ màu cam nhạt giữa các item
                        separatorBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Divider(color: Colors.orange.shade100, height: 1),
                        ),
                        itemBuilder: (context, index) {
                          final addressItem = _addressList[index];
                          
                          return InkWell(
                            onTap: () => _onSelectAddress(index, addressItem.addressId),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Icon Ngôi nhà
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Icon(
                                      Icons.home_outlined,
                                      color: primaryOrange,
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  
                                  // Nội dung text (Title + Address)
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Hiển thị 'addressType'
                                        Text(
                                          addressItem.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF333333),
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        // Hiển thị 'address'
                                        Text(
                                          "${addressItem.streetAddress}, ${addressItem.district}, ${addressItem.city}",
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          softWrap: false,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                            height: 1.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // 3. Nút Radio tròn đồng tâm
                                  Transform.scale(
                                    scale: 1.2,
                                    child: Radio<int>(
                                      value: index,
                                      groupValue: _selectedIndex,
                                      activeColor: primaryOrange,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      onChanged: (value) {
                                        if (value != null) {
                                          _onSelectAddress(value, addressItem.addressId);
                                        }
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () async {
                                      // Gọi API
                                      bool success = await ApiService().deleteAddress(addressItem.addressId);
                                      
                                      // Kiểm tra màn hình còn hiển thị không
                                      if (context.mounted) {
                                        if (success) {
                                          setState(() {
                                            _addressList.removeAt(index);

                                            if (_selectedIndex == index) {
                                              _selectedIndex = 0; 
                                            }
                                            else if(_selectedIndex > index){
                                              _selectedIndex--;
                                            }
                                          });

                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text("Đã xóa địa chỉ thành công")),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text("Lỗi khi xóa địa chỉ")),
                                          );
                                        }
                                      }
                                    },
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          
          // Nút Thêm Địa Chỉ ở dưới cùng
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
            child: SizedBox(
              width: 220,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (context) => const NewAddress())
                  );
                  if (result == true) {
                    _loadAddresslist(); 
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: lightPinkButton, // Màu nền hồng nhạt
                  foregroundColor: primaryOrange, // Màu chữ cam
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  "Thêm Địa Chỉ",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}