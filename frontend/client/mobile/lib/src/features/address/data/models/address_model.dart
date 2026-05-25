class AddressModel {
  final String id;
  final String userId;
  final String fullName;
  final String phone;
  final String province;
  final String district;
  final String ward;
  final String detail;
  final bool isDefault;

  AddressModel({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.phone,
    required this.province,
    required this.district,
    required this.ward,
    required this.detail,
    required this.isDefault,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      province: json['province'] as String? ?? '',
      district: json['district'] as String? ?? '',
      ward: json['ward'] as String? ?? '',
      detail: json['detail'] as String? ?? '',
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'fullName': fullName,
      'phone': phone,
      'province': province,
      'district': district,
      'ward': ward,
      'detail': detail,
      'isDefault': isDefault,
    };
  }

  String get fullAddressText => "$detail, $ward, $district, $province";
}
