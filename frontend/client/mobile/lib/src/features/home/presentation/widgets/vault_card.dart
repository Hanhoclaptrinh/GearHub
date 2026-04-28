import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/src/core/utils/formatter_utils.dart';
import 'package:mobile/src/shared/models/product_model.dart';

class VaultCard extends StatelessWidget {
  final ProductModel product;
  final int index;
  final double currentPage;

  const VaultCard({
    super.key,
    required this.product,
    required this.index,
    required this.currentPage,
  });

  @override
  Widget build(BuildContext context) {
    final diff = (currentPage - index);
    final absDiff = diff.abs();

    final opacity = (1 - absDiff * 1.5).clamp(0.0, 1.0);
    final parallaxOffset = diff * 50;
    final translateY = (absDiff * 30).clamp(0.0, 30.0); // truot theo Y cho text

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        print('prod vip');
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF070707),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: const Text(
                    '[ S-CLASS EDITION ]',
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),

            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 11,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.05),
                            ),
                            gradient: RadialGradient(
                              colors: [
                                Colors.blueAccent.withValues(alpha: 0.15),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        Transform.translate(
                          offset: Offset(-parallaxOffset, 0),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Hero(
                              tag: 'vault_${product.id}',
                              child: product.image.startsWith('http')
                                  ? CachedNetworkImage(
                                      imageUrl: product.image,
                                      fit: BoxFit.contain,
                                      filterQuality: FilterQuality.medium,
                                      placeholder: (context, url) =>
                                          const Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                      errorWidget: (context, url, error) =>
                                          const Icon(
                                            Icons.broken_image_outlined,
                                            size: 40,
                                            color: Colors.black12,
                                          ),
                                    )
                                  : Image.asset(
                                      product.image,
                                      fit: BoxFit.contain,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // specs
                  Expanded(
                    flex: 9,
                    child: Opacity(
                      opacity: opacity,
                      child: Transform.translate(
                        offset: Offset(0, translateY),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: product.vaultSpecs != null
                                ? _buildRightSpecs(product.vaultSpecs!)
                                : [],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.02),
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.fade,
                          softWrap: false,
                        ),
                        const SizedBox(height: 4),
                        if (product.price == 0)
                          Text(
                            '[ PRICE ON REQUEST ]',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        else
                          Text(
                            formatVND(product.price),
                            style: const TextStyle(
                              color: Color(0xFFFFD700),
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'CONTACT',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // xay dung specs xep doc
  List<Widget> _buildRightSpecs(Map<String, dynamic> specs) {
    final keys = specs.keys.toList();
    final List<Widget> widgets = [];

    for (var i = 0; i < keys.length && i < 3; i++) {
      final key = keys[i];
      final dynamic rawValue = specs[key];
      final List<dynamic> valuesList = (rawValue is List)
          ? rawValue
          : [rawValue];

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$key //',
                style: const TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              ...valuesList.map(
                (val) => Text(
                  val.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return widgets;
  }
}
