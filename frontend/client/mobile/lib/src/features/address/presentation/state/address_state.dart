import 'package:mobile/src/features/address/data/models/address_model.dart';

abstract class AddressState {}

class AddressInitial extends AddressState {}

class AddressLoading extends AddressState {}

class AddressLoaded extends AddressState {
  final List<AddressModel> addresses;
  AddressLoaded({required this.addresses});
}

class AddressActionSuccess extends AddressState {
  final String message;
  AddressActionSuccess({required this.message});
}

class AddressError extends AddressState {
  final String message;
  AddressError({required this.message});
}
