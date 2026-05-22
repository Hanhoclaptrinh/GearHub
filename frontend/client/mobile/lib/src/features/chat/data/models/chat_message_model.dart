import 'dart:convert';
import 'package:mobile/src/features/chat/domain/entities/chat_message_entity.dart';
import 'package:mobile/src/features/chat/data/models/product_recommendation_model.dart';

DateTime? _parseOptionalDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

DateTime _parseDate(dynamic value) {
  return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
}

class ChatMessageModel extends ChatMessageEntity {
  const ChatMessageModel({
    required super.id,
    required super.roomId,
    required super.senderId,
    required super.content,
    required super.type,
    required super.status,
    required super.readAt,
    required super.isAi,
    required super.createdAt,
    super.clientMessageId,
    super.isOptimistic,
    super.isFailed,
    super.recommendations,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    final bool isAi = json['isAi'] == true;
    String rawContent = json['content']?.toString() ?? '';
    List<ProductRecommendationModel>? recommendations;

    if (isAi && rawContent.isNotEmpty) {
      try {
        final parsed = jsonDecode(rawContent);
        if (parsed is Map<String, dynamic>) {
          rawContent = parsed['message']?.toString() ?? rawContent;
          try {
            final recs = parsed['recommendations'];
            if (recs is List && recs.isNotEmpty) {
              recommendations = recs
                  .map((e) {
                    if (e is Map) {
                      return ProductRecommendationModel.fromJson(
                        Map<String, dynamic>.from(e),
                      );
                    }
                    return null;
                  })
                  .whereType<ProductRecommendationModel>()
                  .toList();
            }
          } catch (_) {}
        }
      } catch (_) {
        final regExp = RegExp(
          r'"message"\s*:\s*"((?:[^"\\]|\\.)*)"',
          dotAll: true,
        );
        final match = regExp.firstMatch(rawContent);
        if (match != null) {
          final extracted = match.group(1);
          if (extracted != null) {
            rawContent = extracted
                .replaceAll(r'\n', '\n')
                .replaceAll(r'\"', '"')
                .replaceAll(r'\\', '\\');
          }
        }
      }
    }

    return ChatMessageModel(
      id: json['id']?.toString() ?? '',
      roomId: json['roomId']?.toString() ?? '',
      senderId: json['senderId']?.toString(),
      content: rawContent,
      type: json['type']?.toString() ?? 'TEXT',
      status: json['status']?.toString() ?? 'SENT',
      readAt: _parseOptionalDate(json['readAt']),
      isAi: isAi,
      createdAt: _parseDate(json['createdAt']),
      clientMessageId: json['clientMessageId']?.toString(),
      recommendations: recommendations,
    );
  }
}
