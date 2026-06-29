import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mobile/src/features/chat/domain/entities/chat_message_entity.dart';
import 'package:mobile/src/core/theme/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile/src/core/utils/formatter_utils.dart';
import 'package:mobile/src/shared/models/product_model.dart';
import 'package:mobile/src/shared/models/product_variant_model.dart';
import 'package:mobile/src/features/product_detail/presentation/pages/product_detail_page.dart';

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

  Widget _buildAvatar(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final avatarBg = isDark ? const Color(0xFF1E2025) : const Color(0xFFECEFF3);
    final iconColor = message.isAi ? AppColors.champagne : cs.primary;
    final icon = message.isAi ? Icons.auto_awesome_rounded : Icons.support_agent_rounded;

    return Stack(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: avatarBg,
            shape: BoxShape.circle,
            border: Border.all(color: cs.outlineVariant, width: 0.8),
          ),
          child: Center(
            child: Icon(
              icon,
              size: 16,
              color: iconColor,
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.emerald400,
              shape: BoxShape.circle,
              border: Border.all(color: theme.scaffoldBackgroundColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  void _handleCardTap(BuildContext context, dynamic rec) {
    final p = rec.product;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailPage(
          product: ProductModel(
            id: p.id,
            name: p.name,
            tagline: '',
            price: p.price.toDouble(),
            image: p.thumbnailUrl ?? '',
            description: '',
            averageRating: p.rating?.toDouble() ?? 0.0,
            brandName: 'GearHub',
            variants: [
              ProductVariantModel(
                id: 'dummy',
                sku: 'dummy',
                name: p.name,
                price: p.price.toDouble(),
                stock: p.stock?.toInt() ?? 0,
                attributes: const {},
                isActive: true,
                imageUrl: p.thumbnailUrl,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (message.isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Text(
              message.content,
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.42),
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
        left: isMine ? 56 : 10,
        right: isMine ? 10 : 36,
        top: 7,
        bottom: 7,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMine) ...[
            _buildAvatar(context),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (message.isAi && !isMine) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 2, bottom: 6),
                    child: Text(
                      'GearHub AI',
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.38),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  decoration: BoxDecoration(
                    color: isMine ? AppColors.champagne : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMine ? 18 : 6),
                      bottomRight: Radius.circular(isMine ? 6 : 18),
                    ),
                    border: Border.all(
                      color: isMine
                          ? Colors.white.withValues(alpha: 0.20)
                          : cs.outlineVariant,
                    ),
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      color: isMine ? const Color(0xFF07070A) : cs.onSurface,
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
                        color: cs.onSurface.withValues(alpha: 0.30),
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
                              : cs.onSurface.withValues(alpha: 0.30),
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
                              color: AppColors.champagne,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
                if (message.recommendations != null &&
                    message.recommendations!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 240,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: message.recommendations!.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final rec = message.recommendations![index];
                        return _PressableCard(
                          onTap: () => _handleCardTap(context, rec),
                          child: _buildRecommendationCard(context, rec),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(BuildContext context, dynamic rec) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final p = rec.product;
    return Container(
      width: 140,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161619) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant, width: 0.8),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Container(
                color: cs.onSurface.withValues(alpha: 0.02),
                width: double.infinity,
                child: p.thumbnailUrl != null && p.thumbnailUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: p.thumbnailUrl!,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => const Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: AppColors.champagne,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Icon(
                          Icons.image_not_supported_outlined,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.24),
                          size: 24,
                        ),
                      )
                    : Icon(
                        Icons.image_not_supported_outlined,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.24),
                        size: 24,
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  formatVND(p.price.toDouble()),
                  style: const TextStyle(
                    color: AppColors.champagne,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (p.rating != null && p.rating! > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: AppColors.champagne,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        p.rating!.toStringAsFixed(1),
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.7),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
                if (rec.reason != null && rec.reason!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    rec.reason!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 9,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.champagne.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Xem chi tiết',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.champagne,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PressableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _PressableCard({required this.child, required this.onTap});

  @override
  State<_PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<_PressableCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
