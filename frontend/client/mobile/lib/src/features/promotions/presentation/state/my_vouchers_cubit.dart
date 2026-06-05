import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mobile/src/core/utils/error_formatter.dart';
import '../../domain/repositories/promotions_repository.dart';
import '../../data/models/voucher_model.dart';

abstract class MyVouchersState extends Equatable {
  const MyVouchersState();

  @override
  List<Object?> get props => [];
}

class MyVouchersInitial extends MyVouchersState {}

class MyVouchersLoading extends MyVouchersState {}

class MyVouchersLoaded extends MyVouchersState {
  final List<VoucherModel> vouchers;

  const MyVouchersLoaded({required this.vouchers});

  @override
  List<Object?> get props => [vouchers];
}

class MyVouchersError extends MyVouchersState {
  final String message;

  const MyVouchersError({required this.message});

  @override
  List<Object?> get props => [message];
}

class MyVouchersCubit extends Cubit<MyVouchersState> {
  final PromotionsRepository _repository;

  MyVouchersCubit({required PromotionsRepository repository})
      : _repository = repository,
        super(MyVouchersInitial());

  Future<void> fetchMyVouchers() async {
    emit(MyVouchersLoading());
    try {
      final vouchers = await _repository.getMyVouchers();
      emit(MyVouchersLoaded(vouchers: vouchers));
    } catch (e) {
      emit(MyVouchersError(message: ErrorFormatter.format(e, 'Không thể tải danh sách ưu đãi.')));
    }
  }
}
