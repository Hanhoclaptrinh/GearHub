import 'package:dio/dio.dart';
import 'package:mobile/src/features/address/data/models/address_model.dart';

class AddressRemoteDataSource {
  final Dio dio;

  AddressRemoteDataSource({required this.dio});

  Future<List<AddressModel>> getAddresses() async {
    final response = await dio.get('/address');
    final list = response.data as List;
    return list
        .map((e) => AddressModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AddressModel> createAddress({
    required String fullName,
    required String phone,
    required String province,
    required String district,
    required String ward,
    required String detail,
    required bool isDefault,
  }) async {
    final response = await dio.post(
      '/address',
      data: {
        'fullName': fullName,
        'phone': phone,
        'province': province,
        'district': district,
        'ward': ward,
        'detail': detail,
        'isDefault': isDefault,
      },
    );
    return AddressModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AddressModel> updateAddress({
    required String id,
    String? fullName,
    String? phone,
    String? province,
    String? district,
    String? ward,
    String? detail,
    bool? isDefault,
  }) async {
    final response = await dio.patch(
      '/address/$id',
      data: {
        if (fullName != null) 'fullName': fullName,
        if (phone != null) 'phone': phone,
        if (province != null) 'province': province,
        if (district != null) 'district': district,
        if (ward != null) 'ward': ward,
        if (detail != null) 'detail': detail,
        if (isDefault != null) 'isDefault': isDefault,
      },
    );
    return AddressModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteAddress(String id) async {
    await dio.delete('/address/$id');
  }

  Future<AddressModel> setDefaultAddress(String id) async {
    final response = await dio.patch('/address/$id/default');
    return AddressModel.fromJson(response.data as Map<String, dynamic>);
  }
}
