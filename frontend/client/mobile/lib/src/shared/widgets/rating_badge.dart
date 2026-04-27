import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const _kGold = Color(0xFFCBA97A);
const _kGoldDim = Color(0xFF1C1508);

class RatingBadge extends StatelessWidget {
  final double rating;
  final bool isCompact;

  const RatingBadge({super.key, required this.rating, this.isCompact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 6 : 8, vertical: 4),
      decoration: BoxDecoration(
        color: _kGoldDim.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kGold.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.star, color: _kGold, size: 12),
          const SizedBox(width: 4),
          Text(
            rating.toString(),
            style: const TextStyle(
              color: _kGold,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.2,
            ),
          ),
          if (!isCompact) ...[
            const SizedBox(width: 4),
            Text(
              "| TOP",
              style: TextStyle(
                color: _kGold.withValues(alpha: 0.5),
                fontSize: 9,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
