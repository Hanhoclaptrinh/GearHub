import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/src/core/network/api_client.dart';
import 'orders_state.dart';

class OrdersCubit extends Cubit<OrdersState> {
  final ApiClient apiClient;

  OrdersCubit({required this.apiClient}) : super(OrdersInitial());

  Future<void> fetchMyOrders({String? status}) async {
    emit(OrdersLoading());
    try {
      final queryParams = <String, dynamic>{'limit': 100};
      if (status != null && status != 'ALL') {
        queryParams['status'] = status;
      }

      final response = await apiClient.dio.get(
        '/orders/my-orders',
        queryParameters: queryParams,
      );

      final List<dynamic> orders = response.data['data'] ?? [];
      emit(OrdersLoaded(orders: orders));
    } catch (e) {
      emit(OrdersError(message: e.toString()));
    }
  }

  Future<void> cancelOrder(String orderId, String reason) async {
    emit(OrdersLoading());
    try {
      await apiClient.dio.patch(
        '/orders/$orderId/cancel',
        data: {'reason': reason},
      );
      emit(OrderActionSuccess(message: 'Yêu cầu hủy đơn đã được gửi thành công!'));
      await fetchMyOrders();
    } catch (e) {
      emit(OrdersError(message: 'Không thể hủy đơn hàng: $e'));
    }
  }

  Future<void> reOrder(String orderId) async {
    emit(OrdersLoading());
    try {
      await apiClient.dio.post('/orders/$orderId/re-order');
      emit(OrderActionSuccess(message: 'Mua lại thành công! Đơn hàng mới đã được tạo.'));
      await fetchMyOrders();
    } catch (e) {
      emit(OrdersError(message: 'Không thể mua lại đơn hàng: $e'));
    }
  }
}
