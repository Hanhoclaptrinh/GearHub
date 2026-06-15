import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/src/core/theme/app_colors.dart';
import 'package:mobile/src/features/chat/presentation/state/concierge_cubit.dart';
import 'package:mobile/src/features/chat/presentation/state/concierge_state.dart';
import 'package:mobile/src/features/chat/presentation/widgets/concierge_composer.dart';
import 'package:mobile/src/features/chat/presentation/widgets/concierge_empty_state.dart';
import 'package:mobile/src/features/chat/presentation/widgets/concierge_message_bubble.dart';

class ConciergeScreen extends StatefulWidget {
  const ConciergeScreen({super.key});

  @override
  State<ConciergeScreen> createState() => _ConciergeScreenState();
}

class _ConciergeScreenState extends State<ConciergeScreen>
    with WidgetsBindingObserver {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final isActive = state == AppLifecycleState.resumed;
    context.read<ConciergeCubit>().setScreenActive(isActive);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: BlocConsumer<ConciergeCubit, ConciergeState>(
        listenWhen: (previous, current) =>
            previous.messages.length != current.messages.length ||
            previous.errorMessage != current.errorMessage,
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Theme.of(context).colorScheme.surface,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          _scrollToBottom();
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Stack(
              children: [
                const _ConciergeBackdrop(),
                SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      _ConciergeHeader(state: state),
                      Expanded(child: _buildBody(context, state)),
                      if (state.isClosed ||
                          (state.room == null && state.canStartNewRoom))
                        _ClosedConversationFooter(state: state)
                      else
                        ConciergeComposer(
                          disabled: state.isLoading,
                          disabledText: state.isClosed
                              ? 'Cuộc trò chuyện đã kết thúc'
                              : state.isLoading
                              ? 'Đang kết nối Concierge...'
                              : null,
                          onSend: context.read<ConciergeCubit>().send,
                          onTyping: context.read<ConciergeCubit>().sendTyping,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, ConciergeState state) {
    final cs = Theme.of(context).colorScheme;
    if (state.isLoading && state.messages.isEmpty) {
      return Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
        ),
      );
    }

    if (state.messages.isEmpty) {
      return const ConciergeEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
      itemCount:
          state.messages.length +
          (state.nextCursor != null ? 1 : 0) +
          (state.isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (state.nextCursor != null && index == 0) {
          return Center(
            child: TextButton(
              onPressed: state.isLoadingOlder
                  ? null
                  : context.read<ConciergeCubit>().loadOlder,
              child: Text(
                state.isLoadingOlder ? 'Đang tải...' : 'Xem tin nhắn cũ hơn',
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.42),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          );
        }

        final offset = state.nextCursor != null ? 1 : 0;
        final messageIndex = index - offset;
        if (messageIndex >= state.messages.length) {
          return _TypingIndicator(typingUserId: state.typingUserId);
        }

        final message = state.messages[messageIndex];
        final isMine =
            !message.isSystem &&
            !message.isAi &&
            (message.clientMessageId != null ||
                (message.senderId != null &&
                    message.senderId != state.room?.staffId));
        return ConciergeMessageBubble(
          message: message,
          isMine: isMine,
          onRetry: message.isFailed
              ? () => context.read<ConciergeCubit>().retryMessage(message)
              : null,
        );
      },
    );
  }
}

class _ConciergeHeader extends StatelessWidget {
  final ConciergeState state;

  const _ConciergeHeader({required this.state});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 16, 14),

          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 24,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tư vấn khách hàng',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: state.isConnected
                                ? AppColors.emerald400
                                : Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.24),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          state.isClosed
                              ? 'Cuộc hội thoại đã kết thúc'
                              : state.isConnected
                              ? 'Nhân viên tư vấn'
                              : 'Đang kết nối lại',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  final String? typingUserId;

  const _TypingIndicator({this.typingUserId});

  @override
  Widget build(BuildContext context) {
    final name = typingUserId == 'ai' ? 'GearHub AI' : 'GearHub';

    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 8),
      child: Row(
        children: [
          for (var i = 0; i < 3; i++)
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 5),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.34),
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: 6),
          Text(
            '$name đang phản hồi',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClosedConversationFooter extends StatelessWidget {
  final ConciergeState state;

  const _ClosedConversationFooter({required this.state});

  @override
  Widget build(BuildContext context) {
    final hasClosedRoom = state.isClosed;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            18,
            14,
            18,
            14 + MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).scaffoldBackgroundColor.withValues(alpha: 0.92),
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                hasClosedRoom
                    ? 'Cuộc hội thoại đã kết thúc'
                    : 'Bạn muốn trao đổi với GearHub?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: state.isStartingNewRoom
                      ? null
                      : context.read<ConciergeCubit>().startNewConversation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    disabledBackgroundColor: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.12),
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    state.isStartingNewRoom
                        ? 'Đang tạo cuộc hội thoại...'
                        : 'Bắt đầu cuộc hội thoại mới',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConciergeBackdrop extends StatelessWidget {
  const _ConciergeBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: Theme.of(context).scaffoldBackgroundColor),
        Positioned(
          top: -180,
          right: -170,
          child: Container(
            width: 420,
            height: 420,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.045),
            ),
          ),
        ),
        Positioned(
          bottom: -120,
          left: -160,
          child: Container(
            width: 340,
            height: 340,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.06),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.surface.withValues(alpha: 0.72),
                  Theme.of(context).scaffoldBackgroundColor,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
