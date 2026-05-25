import 'package:mobile/src/features/address/data/datasources/address_remote_datasource.dart';
import 'package:mobile/src/features/address/data/models/address_model.dart';
import 'package:mobile/src/features/address/domain/repositories/address_repository.dart';

class AddressRepositoryImpl implements AddressRepository {
  final AddressRemoteDataSource remoteDataSource;

  AddressRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<AddressModel>> getAddresses() {
    return remoteDataSource.getAddresses();
  }

  @override
  Future<AddressModel> createAddress({
    required String fullName,
    required String phone,
    required String province,
    required String district,
    required String ward,
    required String detail,
    required bool isDefault,
  }) {
    return remoteDataSource.createAddress(
      fullName: fullName,
      phone: phone,
      province: province,
      district: district,
      ward: ward,
      detail: detail,
      isDefault: isDefault,
    );
  }

  @override
  Future<AddressModel> updateAddress({
    required String id,
    String? fullName,
    String? phone,
    String? province,
    String? district,
    String? ward,
    String? detail,
    bool? isDefault,
  }) {
    return remoteDataSource.updateAddress(
      id: id,
      fullName: fullName,
      phone: phone,
      province: province,
      district: district,
      ward: ward,
      detail: detail,
      isDefault: isDefault,
    );
  }

  @override
  Future<void> deleteAddress(String id) {
    return remoteDataSource.deleteAddress(id);
  }

  @override
  Future<AddressModel> setDefaultAddress(String id) {
    return remoteDataSource.setDefaultAddress(id);
  }
}
