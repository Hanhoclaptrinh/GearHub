import 'package:flutter/material.dart';

class TrendingBadge extends StatelessWidget {
  final String tag;
  const TrendingBadge({super.key, required this.tag});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tag.toUpperCase()) {
      'HOT' => (const Color(0x2EFF6B5B), const Color(0xFFFF6B5B)),
      'TRENDING' => (const Color(0x263CC878), const Color(0xFF3CC878)),
      'NEW' => (const Color(0x2E6EB0FF), const Color(0xFF6EB0FF)),
      'MATCH' => (const Color(0x2E00B4D8), const Color(0xFF00B4D8)),
      'AI PICK' => (const Color(0x2E8B5CF6), const Color(0xFF8B5CF6)),
      _ => (Colors.black.withValues(alpha: 0.05), Colors.black54),
    };

    if (tag.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            tag,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w900,
              color: fg,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
