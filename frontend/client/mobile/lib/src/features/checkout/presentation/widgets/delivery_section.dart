import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const _surface = Color(0xFF14141E);
const _border = Color(0xFF2A2A38);
const _accent = Color(0xFFFDE047);
const _textHigh = Color(0xFFF1F1F5);
const _textMid = Color(0xFF9191A8);
const _textLow = Color(0xFF4A4A62);

class DeliverySection extends StatelessWidget {
  final String name;
  final String phone;
  final String address;
  final VoidCallback onEdit;

  const DeliverySection({
    super.key,
    required this.name,
    required this.phone,
    required this.address,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasInfo = name.isNotEmpty && address.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Địa chỉ giao hàng",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: _textHigh,
              ),
            ),
            GestureDetector(
              onTap: onEdit,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _accent.withValues(alpha: 0.25),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  hasInfo ? "Chỉnh sửa" : "Thêm địa chỉ",
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: _accent,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border, width: 0.5),
          ),
          child: hasInfo
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.user, size: 16, color: _textMid),
                        const SizedBox(width: 10),
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: _textHigh,
                          ),
                        ),
                        if (phone.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Container(width: 1, height: 14, color: _border),
                          const SizedBox(width: 12),
                          Text(
                            phone,
                            style: const TextStyle(
                              fontSize: 13,
                              color: _textMid,
                            ),
                          ),
                        ],
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Container(height: 1, color: _border),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          LucideIcons.mapPin,
                          size: 16,
                          color: Color(0xFF0077ED),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            address,
                            style: const TextStyle(
                              fontSize: 14,
                              color: _textMid,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      children: [
                        Icon(LucideIcons.mapPin, size: 28, color: _textLow),
                        SizedBox(height: 10),
                        Text(
                          "Chưa có địa chỉ giao hàng",
                          style: TextStyle(
                            fontSize: 14,
                            color: _textMid,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Nhấn 'Thêm địa chỉ' để bắt đầu",
                          style: TextStyle(fontSize: 12, color: _textLow),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
