import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:mobile/src/features/address/domain/repositories/address_repository.dart';
import 'address_state.dart';

class AddressCubit extends Cubit<AddressState> {
  final AddressRepository repository;

  AddressCubit({required this.repository}) : super(AddressInitial());

  Future<void> fetchAddresses() async {
    emit(AddressLoading());
    try {
      final list = await repository.getAddresses();
      emit(AddressLoaded(addresses: list));
    } catch (e) {
      emit(AddressError(message: _getErrorMessage(e)));
    }
  }

  Future<void> createAddress({
    required String fullName,
    required String phone,
    required String province,
    required String district,
    required String ward,
    required String detail,
    required bool isDefault,
  }) async {
    emit(AddressLoading());
    try {
      await repository.createAddress(
        fullName: fullName,
        phone: phone,
        province: province,
        district: district,
        ward: ward,
        detail: detail,
        isDefault: isDefault,
      );
      emit(AddressActionSuccess(message: 'Thêm địa chỉ thành công'));
      await fetchAddresses();
    } catch (e) {
      emit(AddressError(message: _getErrorMessage(e)));
    }
  }

  Future<void> updateAddress({
    required String id,
    String? fullName,
    String? phone,
    String? province,
    String? district,
    String? ward,
    String? detail,
    bool? isDefault,
  }) async {
    emit(AddressLoading());
    try {
      await repository.updateAddress(
        id: id,
        fullName: fullName,
        phone: phone,
        province: province,
        district: district,
        ward: ward,
        detail: detail,
        isDefault: isDefault,
      );
      emit(AddressActionSuccess(message: 'Cập nhật địa chỉ thành công'));
      await fetchAddresses();
    } catch (e) {
      emit(AddressError(message: _getErrorMessage(e)));
    }
  }

  Future<void> deleteAddress(String id) async {
    emit(AddressLoading());
    try {
      await repository.deleteAddress(id);
      emit(AddressActionSuccess(message: 'Xóa địa chỉ thành công'));
      await fetchAddresses();
    } catch (e) {
      emit(AddressError(message: _getErrorMessage(e)));
    }
  }

  Future<void> setDefaultAddress(String id) async {
    emit(AddressLoading());
    try {
      await repository.setDefaultAddress(id);
      emit(AddressActionSuccess(message: 'Đặt địa chỉ mặc định thành công'));
      await fetchAddresses();
    } catch (e) {
      emit(AddressError(message: _getErrorMessage(e)));
    }
  }

  String _getErrorMessage(dynamic e) {
    if (e is DioException && e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map && data.containsKey('message')) {
        final msg = data['message'];
        if (msg is List) return msg.join(', ');
        return msg.toString();
      }
    }
    return e.toString();
  }
}
