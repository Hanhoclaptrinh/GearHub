import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/core/di/injection.dart';
import 'package:mobile/src/features/auth/presentation/state/auth_cubit.dart';
import 'package:mobile/src/features/auth/presentation/state/auth_state.dart';
import 'package:mobile/src/features/chat/presentation/pages/concierge_screen.dart';
import 'package:mobile/src/features/chat/presentation/state/concierge_cubit.dart';
import 'package:mobile/src/shared/widgets/auth_required_modal.dart';

class ConciergeEntryButton extends StatelessWidget {
  final String? label;
  final bool compact;
  final Color foreground;

  const ConciergeEntryButton({
    super.key,
    this.label,
    this.compact = false,
    this.foreground = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    if (label == null || compact) {
      return GestureDetector(
        onTap: () => open(context),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(LucideIcons.headset, color: foreground, size: 22),
        ),
      );
    }

    return GestureDetector(
      onTap: () => open(context),
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.headset, color: foreground, size: 17),
          const SizedBox(width: 10),
          Text(
            label!,
            style: TextStyle(
              color: foreground,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  static void open(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      AuthRequiredModal.show(context);
      return;
    }

    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (_, animation, __) => BlocProvider(
          create: (_) => getIt<ConciergeCubit>()..open(),
          child: const ConciergeScreen(),
        ),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.04, 0.04),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }
}
