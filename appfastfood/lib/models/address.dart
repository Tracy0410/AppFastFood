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
}