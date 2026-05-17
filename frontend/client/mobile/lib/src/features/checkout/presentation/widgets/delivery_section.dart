import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/core/theme/app_colors.dart';

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
                color: AppColors.textPrimary,
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
                  color: AppColors.brandYellow.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.brandYellow.withValues(alpha: 0.25),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  hasInfo ? "Chỉnh sửa" : "Thêm địa chỉ",
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: AppColors.brandYellow,
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
            color: AppColors.cardSurfaceAlt,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderCardStrong, width: 0.5),
          ),
          child: hasInfo
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.user,
                          size: 16,
                          color: AppColors.slate400,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (phone.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Container(
                            width: 1,
                            height: 14,
                            color: AppColors.borderCardStrong,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            phone,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.slate400,
                            ),
                          ),
                        ],
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Container(
                        height: 1,
                        color: AppColors.borderCardStrong,
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          LucideIcons.mapPin,
                          size: 16,
                          color: AppColors.brandBlue,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            address,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.slate400,
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
                        Icon(
                          LucideIcons.mapPin,
                          size: 28,
                          color: AppColors.textDim,
                        ),
                        SizedBox(height: 10),
                        Text(
                          "Chưa có địa chỉ giao hàng",
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.slate400,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Nhấn 'Thêm địa chỉ' để bắt đầu",
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textDim,
                          ),
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
