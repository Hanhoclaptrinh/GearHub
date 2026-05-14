import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const _accent = Color(0xFFE2B93B);
const _textHigh = Color(0xFFFFFFFF);
const _textMid = Color(0xFF9494A1);

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 2,
              height: 14,
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'PHẢN HỒI TỪ GEARHUB',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: _textHigh,
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
          style: const TextStyle(
            fontSize: 13,
            color: _textMid,
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
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: _accent,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                  size: 12,
                  color: _accent,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
