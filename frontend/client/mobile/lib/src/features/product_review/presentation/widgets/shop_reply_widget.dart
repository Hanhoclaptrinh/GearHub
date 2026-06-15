import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color accentLineColor = isDark
        ? const Color(0xFF6366F1)
        : const Color(0xFF4F46E5);
    final Color textHigh = isDark
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF111111);
    final Color textMid = isDark
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF4B5563);
    final Color actionColor = isDark
        ? const Color(0xFF818CF8)
        : const Color(0xFF4F46E5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 2,
              height: 14,
              decoration: BoxDecoration(
                color: accentLineColor,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'PHẢN HỒI TỪ GEARHUB',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: textHigh,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          widget.reply,
          maxLines: _isExpanded ? null : 3,
          overflow: _isExpanded ? null : TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            color: textMid,
            height: 1.6,
            fontWeight: FontWeight.w400,
          ),
        ),
        if (widget.reply.length > 150) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isExpanded ? 'THU GỌN' : 'XEM THÊM',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: actionColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                  size: 12,
                  color: actionColor,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
