import 'package:mobile/src/features/address/data/models/address_model.dart';

abstract class AddressRepository {
  Future<List<AddressModel>> getAddresses();
  Future<AddressModel> createAddress({
    required String fullName,
    required String phone,
    required String province,
    required String district,
    required String ward,
    required String detail,
    required bool isDefault,
  });
  Future<AddressModel> updateAddress({
    required String id,
    String? fullName,
    String? phone,
    String? province,
    String? district,
    String? ward,
    String? detail,
    bool? isDefault,
  });
  Future<void> deleteAddress(String id);
  Future<AddressModel> setDefaultAddress(String id);
}
