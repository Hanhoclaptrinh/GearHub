import 'package:equatable/equatable.dart';

class ReviewEntity extends Equatable {
  final String id;
  final String userId;
  final String productId;
  final String? orderId;
  final int rating;
  final String? comment;
  final String? reply;
  final bool isVerifiedPurchase;
  final DateTime createdAt;
  final String userName;
  final String? userAvatar;
  final List<String> images;
  final String? variantName;

  const ReviewEntity({
    required this.id,
    required this.userId,
    required this.productId,
    this.orderId,
    required this.rating,
    this.comment,
    this.reply,
    required this.isVerifiedPurchase,
    required this.createdAt,
    required this.userName,
    this.userAvatar,
    required this.images,
    this.variantName,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    productId,
    orderId,
    rating,
    comment,
    reply,
    isVerifiedPurchase,
    createdAt,
    userName,
    userAvatar,
    images,
    variantName,
  ];
}
