import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile/src/features/chat/domain/entities/chat_message_entity.dart';
import 'package:mobile/src/core/theme/app_colors.dart';

class ConciergeMessageBubble extends StatelessWidget {
  final ChatMessageEntity message;
  final bool isMine;
  final VoidCallback? onRetry;

  const ConciergeMessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Text(
              message.content,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.42),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        left: isMine ? 56 : 0,
        right: isMine ? 0 : 56,
        top: 7,
        bottom: 7,
      ),
      child: Column(
        crossAxisAlignment: isMine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: isMine
                  ? AppColors.brandYellow
                  : Colors.white.withValues(alpha: 0.065),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMine ? 18 : 6),
                bottomRight: Radius.circular(isMine ? 6 : 18),
              ),
              border: Border.all(
                color: isMine
                    ? Colors.white.withValues(alpha: 0.20)
                    : Colors.white.withValues(alpha: 0.065),
              ),
            ),
            child: Text(
              message.content,
              style: TextStyle(
                color: isMine
                    ? AppColors.background
                    : Colors.white.withValues(alpha: 0.90),
                fontSize: 14,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateFormat('HH:mm').format(message.createdAt.toLocal()),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.30),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (isMine) ...[
                const SizedBox(width: 8),
                Text(
                  message.isFailed
                      ? 'Lỗi'
                      : message.isOptimistic
                      ? 'Đang gửi'
                      : message.status == 'READ'
                      ? 'Đã đọc'
                      : 'Đã gửi',
                  style: TextStyle(
                    color: message.isFailed
                        ? AppColors.accentPink
                        : Colors.white.withValues(alpha: 0.30),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (message.isFailed && onRetry != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onRetry,
                    child: const Text(
                      'Thử lại',
                      style: TextStyle(
                        color: AppColors.brandYellow,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ],
      ),
    );
  }
}
