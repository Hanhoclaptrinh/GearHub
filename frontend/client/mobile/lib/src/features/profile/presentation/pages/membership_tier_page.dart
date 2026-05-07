import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/core/utils/formatter_utils.dart';

const _bg = Color(0xFF0A0A10);
const _surface = Color(0xFF14141E);
const _surfaceAlt = Color(0xFF1C1C28);
const _border = Color(0xFF2A2A38);
const _textHigh = Color(0xFFF1F1F5);
const _textMid = Color(0xFF9191A8);
const _textLow = Color(0xFF4A4A62);

class MembershipTierPage extends StatelessWidget {
  final double totalSpent;

  const MembershipTierPage({super.key, required this.totalSpent});

  @override
  Widget build(BuildContext context) {
    String currentTier = 'BẠC';
    String nextTier = 'VÀNG';
    double nextTarget = 15000000.0;
    double progress = totalSpent / nextTarget;

    Color startColor = const Color(0xFF64748B);
    Color endColor = const Color(0xFF94A3B8);
    IconData tierIcon = LucideIcons.shield;

    if (totalSpent >= 150000000.0) {
      currentTier = 'VIP';
      nextTier = 'MAX';
      nextTarget = 150000000.0;
      progress = 1.0;
      startColor = const Color(0xFFEF4444);
      endColor = const Color(0xFFEC4899);
      tierIcon = LucideIcons.crown;
    } else if (totalSpent >= 50000000.0) {
      currentTier = 'KIM CƯƠNG';
      nextTier = 'VIP';
      nextTarget = 150000000.0;
      progress = (totalSpent - 50000000.0) / (150000000.0 - 50000000.0);
      startColor = const Color(0xFF06B6D4);
      endColor = const Color(0xFF3B82F6);
      tierIcon = LucideIcons.gem;
    } else if (totalSpent >= 15000000.0) {
      currentTier = 'VÀNG';
      nextTier = 'KIM CƯƠNG';
      nextTarget = 50000000.0;
      progress = (totalSpent - 15000000.0) / (50000000.0 - 15000000.0);
      startColor = const Color(0xFFF59E0B);
      endColor = const Color(0xFFFCD34D);
      tierIcon = LucideIcons.sparkles;
    }

    if (progress > 1.0) progress = 1.0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: _textMid,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Hạng thành viên',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: _textHigh,
              letterSpacing: 1,
            ),
          ),
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // current tier card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [startColor, endColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: startColor.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(tierIcon, color: Colors.white, size: 32),
                        ),
                        Text(
                          currentTier,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'TỔNG CHI TIÊU TÍCH LŨY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white70,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatVND(totalSpent),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // progress bar to next tier
              if (currentTier != 'VIP') ...[
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: _border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tiến trình hạng $nextTier',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: _textHigh,
                            ),
                          ),
                          Text(
                            '${(progress * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: startColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 10,
                          backgroundColor: _surfaceAlt,
                          valueColor: AlwaysStoppedAnimation<Color>(startColor),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Bạn cần chi tiêu thêm ${formatVND(nextTarget - totalSpent)} để thăng hạng $nextTier.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: _textLow,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              // tier rules/rewards
              const Text(
                'QUYỀN LỢI TỪNG HẠNG THÀNH VIÊN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: _textLow,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              _buildTierDetailItem(
                'HẠNG BẠC',
                'Dưới 15,000,000 đ',
                'Tích lũy 0.5% giá trị đơn hàng.',
                const Color(0xFF64748B),
                LucideIcons.shield,
              ),
              const SizedBox(height: 12),
              _buildTierDetailItem(
                'HẠNG VÀNG',
                '15,000,000 đ - 50,000,000 đ',
                'Tích lũy 1% giá trị đơn hàng.',
                const Color(0xFFF59E0B),
                LucideIcons.sparkles,
              ),
              const SizedBox(height: 12),
              _buildTierDetailItem(
                'KIM CƯƠNG',
                '50,000,000 đ - 150,000,000 đ',
                'Tích lũy 1.5% giá trị đơn hàng.',
                const Color(0xFF06B6D4),
                LucideIcons.gem,
              ),
              const SizedBox(height: 12),
              _buildTierDetailItem(
                'HẠNG VIP',
                'Trên 150,000,000 đ',
                'Tích lũy 2% giá trị đơn hàng.',
                const Color(0xFFEF4444),
                LucideIcons.crown,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTierDetailItem(
    String tierName,
    String spendingLimit,
    String rewardDesc,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tierName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: color,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        spendingLimit,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _textLow,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  rewardDesc,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _textMid,
                    fontWeight: FontWeight.w600,
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
