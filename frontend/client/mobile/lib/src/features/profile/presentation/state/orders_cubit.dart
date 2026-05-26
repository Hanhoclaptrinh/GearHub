import 'package:dio/dio.dart';
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
      emit(OrdersError(message: _extractErrorMessage(e, 'Không thể tải danh sách đơn hàng.')));
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
      emit(OrdersError(message: _extractErrorMessage(e, 'Không thể hủy đơn hàng.')));
    }
  }

  Future<void> reOrder(String orderId, List<String> orderItemIds) async {
    emit(OrdersLoading());
    try {
      final response = await apiClient.dio.post(
        '/orders/$orderId/re-order',
        data: {'orderItemIds': orderItemIds},
      );
      final message = response.data['message'] ?? 'Đã thêm sản phẩm vào giỏ hàng!';
      final List<dynamic> addedItems = response.data['addedItems'] ?? [];
      final List<String> variantIds = addedItems
          .map((item) => item['variantId']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();

      emit(ReorderSuccess(message: message, variantIds: variantIds));
      await fetchMyOrders();
    } catch (e) {
      emit(OrdersError(message: _extractErrorMessage(e, 'Không thể mua lại đơn hàng.')));
    }
  }

  String _extractErrorMessage(dynamic e, String defaultMessage) {
    if (e is DioException && e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
    }
    return defaultMessage;
  }
}
