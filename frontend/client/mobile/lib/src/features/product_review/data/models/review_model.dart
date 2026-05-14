import 'package:mobile/src/features/product_review/domain/entities/review_entity.dart';

class ReviewModel extends ReviewEntity {
  const ReviewModel({
    required super.id,
    required super.userId,
    required super.productId,
    super.orderId,
    required super.rating,
    super.comment,
    super.reply,
    required super.isVerifiedPurchase,
    required super.createdAt,
    required super.userName,
    super.userAvatar,
    required super.images,
    super.variantName,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final profile = user?['profile'] as Map<String, dynamic>?;
    final assets = (json['assets'] as List<dynamic>?) ?? [];

    return ReviewModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      productId: json['productId'] as String,
      orderId: json['orderId'] as String?,
      rating: (json['rating'] as num).toInt(),
      comment: json['comment'] as String?,
      reply: json['reply'] as String?,
      isVerifiedPurchase: json['isVerifiedPurchase'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      userName: profile?['fullName'] as String? ?? 'Người dùng GearHub',
      userAvatar: profile?['avatarUrl'] as String?,
      images: assets.map((e) => e['url'] as String).toList(),
      variantName: json['variantName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'productId': productId,
      'orderId': orderId,
      'rating': rating,
      'comment': comment,
      'reply': reply,
      'isVerifiedPurchase': isVerifiedPurchase,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
