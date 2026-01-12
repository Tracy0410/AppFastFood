class Address {
  final int addressId;
  final int userId;
  final String name;
  final String streetAddress;
  final String district;
  final String city;
  final bool isDefault;
  final int status;

  Address({
    required this.addressId,
    required this.userId,
    required this.name,
    required this.streetAddress,
    required this.district,
    required this.city,
    required this.isDefault,
    required this.status
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      addressId: int.tryParse(json['address_id']?.toString() ?? '0') ?? 0,
      userId: int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      
      name: json['recipient_name']?.toString() ?? '', 
      streetAddress: json['street_address']?.toString() ?? '', 
      district: json['district']?.toString() ?? '', 
      city: json['city']?.toString() ?? '', 
      
      isDefault: (json['is_default'] == 1 || json['is_default'] == true), 
      status: int.tryParse(json['status']?.toString() ?? '0') ?? 0,
    );
  }
    Map<String, dynamic> toJson() {
    return {
      'address_id': addressId,
      'user_id': userId,
      'recipient_name': name,
      'street_address': streetAddress,
      'district': district,
      'city': city,
      'is_default': isDefault ? 1 : 0,
      'status': status,
    };
  }
  
  // Hàm helper để hiển thị địa chỉ đầy đủ
  String get fullAddress => "$streetAddress, $district, $city";
}