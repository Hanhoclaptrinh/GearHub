import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const _textHigh = Color(0xFFF1F1F5);
const _textMid = Color(0xFF9191A8);

class ShopReplyWidget extends StatefulWidget {
  final String reply;
  const ShopReplyWidget({super.key, required this.reply});

  @override
  State<ShopReplyWidget> createState() => _ShopReplyWidgetState();
}

class _ShopReplyWidgetState extends State<ShopReplyWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.reply, size: 14, color: _textMid),
              SizedBox(width: 8),
              Text(
                'Phản hồi từ GearHub',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _textHigh,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.reply,
            maxLines: _isExpanded ? null : 2,
            overflow: _isExpanded ? null : TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, color: _textMid, height: 1.4),
          ),
          if (widget.reply.length > 100) ...[
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isExpanded ? 'Thu gọn' : 'Xem thêm',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0077DE),
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
