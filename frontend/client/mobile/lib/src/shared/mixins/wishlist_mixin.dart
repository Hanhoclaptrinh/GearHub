import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/src/core/di/injection.dart';
import 'package:mobile/src/features/auth/presentation/state/auth_cubit.dart';
import 'package:mobile/src/features/auth/presentation/state/auth_state.dart';
import 'package:mobile/src/features/wishlist/domain/repositories/wishlist_repository.dart';
import 'package:mobile/src/shared/widgets/auth_required_modal.dart';

mixin WishlistMixin<T extends StatefulWidget> on State<T> {
  final WishlistRepository wishlistRepository = getIt<WishlistRepository>();
  bool isWishlisted = false;

  Future<void> checkInitialWishlist(String productId) async {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      try {
        final isFav = await wishlistRepository.checkIsFavorite(productId);
        if (mounted) {
          setState(() {
            isWishlisted = isFav;
          });
        }
      } catch (e) {
        debugPrint('Error checking wishlist status: $e');
      }
    }
  }

  Future<void> toggleWishlist(String productId, {VoidCallback? onAnimation}) async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      AuthRequiredModal.show(context);
      return;
    }
    
    HapticFeedback.lightImpact();
    if (onAnimation != null) {
      onAnimation();
    }

    setState(() => isWishlisted = !isWishlisted);
    
    try {
      await wishlistRepository.toggleWishlist(productId);
    } catch (e) {
      if (mounted) {
        setState(() => isWishlisted = !isWishlisted);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi khi cập nhật danh sách yêu thích')),
        );
      }
    }
  }
}
