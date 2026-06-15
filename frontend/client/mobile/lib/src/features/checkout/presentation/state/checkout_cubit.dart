import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/src/core/network/api_client.dart';
import 'package:mobile/src/features/cart/domain/entities/cart_item_entity.dart';
import 'package:mobile/src/core/utils/error_formatter.dart';
import 'checkout_state.dart';

class CheckoutCubit extends Cubit<CheckoutState> {
  final ApiClient apiClient;

  CheckoutCubit({required this.apiClient}) : super(CheckoutInitial());

  Future<void> placeOrder({
    required String receiverName,
    required String receiverPhone,
    required String shippingAddress,
    required String note,
    required String paymentMethod,
    required List<CartItemEntity> items,
    String? voucherId,
  }) async {
    emit(CheckoutLoading());
    try {
      final orderPayload = {
        'receiverName': receiverName,
        'receiverPhone': receiverPhone,
        'shippingAddress': shippingAddress,
        'note': note,
        'paymentMethod': paymentMethod,
        'items': items
            .map(
              (item) => {
                'variantId': item.productVariant.id,
                'quantity': item.quantity,
              },
            )
            .toList(),
        if (voucherId != null) 'voucherId': voucherId,
      };

      final response = await apiClient.dio.post('/orders', data: orderPayload);
      final orderId = response.data['id'];

      String? paymentUrl;
      if (paymentMethod == 'PAYMENT_GATEWAY') {
        final paymentRes = await apiClient.dio.post(
          '/payment/create-url/$orderId',
          queryParameters: {'platform': 'mobile'},
        );
        paymentUrl = paymentRes.data['paymentUrl'];
      }

      emit(
        OrderPlacedSuccess(
          orderId: orderId,
          paymentUrl: paymentUrl,
          paymentMethod: paymentMethod,
        ),
      );
    } catch (e) {
      emit(
        CheckoutError(message: ErrorFormatter.format(e, 'Không thể đặt hàng.')),
      );
    }
  }
}
