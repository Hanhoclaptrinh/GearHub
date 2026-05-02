import 'package:mobile/src/shared/models/product_asset_model.dart';
import 'package:mobile/src/shared/models/product_variant_model.dart';

class ProductModel {
  final String id;
  final String baseName;
  final String tagline;
  final double basePrice;
  final String baseImage;
  final String? tag;
  final int viewsCount;
  final int soldCount;
  final double averageRating;
  final int reviewCount;
  final String description;
  final Map<String, dynamic>? vaultSpecs;
  final Map<String, dynamic>? commonSpecs;
  final String? brandName;
  final List<ProductVariantModel> variants;
  final List<ProductAssetModel> assets;
  final List<String> attributeConfig;

  const ProductModel({
    required this.id,
    required String name,
    required this.tagline,
    required double price,
    required String image,
    required this.description,
    this.tag,
    this.viewsCount = 0,
    this.soldCount = 0,
    this.averageRating = 0.0,
    this.reviewCount = 0,
    this.vaultSpecs,
    this.commonSpecs,
    this.brandName,
    this.variants = const [],
    this.assets = const [],
    this.attributeConfig = const [],
  })  : baseName = name,
        basePrice = price,
        baseImage = image;

  String get name {
    if (variants.isEmpty) return baseName;
    final firstVariant = variants.where((v) => v.isActive).firstOrNull ?? variants.first;
    String displayName = baseName;
    final nonColorConfigs = <String>[];
    firstVariant.attributes.forEach((key, val) {
      final k = key.toLowerCase();
      if (!k.contains('màu') && !k.contains('color') && !k.contains('mau')) {
        nonColorConfigs.add(val.toString());
      }
    });
    if (nonColorConfigs.isNotEmpty) {
      displayName += ' ' + nonColorConfigs.join(' ');
    }
    return displayName;
  }

  double get price {
    if (variants.isEmpty) return basePrice;
    final firstVariant = variants.where((v) => v.isActive).firstOrNull ?? variants.first;
    return firstVariant.price;
  }

  String get image {
    if (variants.isEmpty) return baseImage;
    final activeVariants = variants.where((v) => v.isActive).toList();
    final firstVariant = activeVariants.firstOrNull ?? variants.first;
    if (firstVariant.imageUrl != null && firstVariant.imageUrl!.isNotEmpty) {
      return firstVariant.imageUrl!;
    }
    for (final v in activeVariants) {
      if (v.imageUrl != null && v.imageUrl!.isNotEmpty) {
        return v.imageUrl!;
      }
    }
    for (final v in variants) {
      if (v.imageUrl != null && v.imageUrl!.isNotEmpty) {
        return v.imageUrl!;
      }
    }
    return baseImage;
  }

  List<ProductAssetModel> get imageAssets =>
      assets.where((a) => a.type == AssetType.image).toList();

  ProductAssetModel? get primaryImageAsset {
    final primary = imageAssets.where((a) => a.isPrimary);
    return primary.isNotEmpty ? primary.first : null;
  }

  ProductAssetModel? get glbAsset {
    final glbs = assets.where((a) => a.type == AssetType.glb);
    return glbs.isNotEmpty ? glbs.first : null;
  }

  ProductAssetModel? get usdzAsset {
    final usdz = assets.where((a) => a.type == AssetType.usdz);
    return usdz.isNotEmpty ? usdz.first : null;
  }

  bool get has3DModel => glbAsset != null;

  bool get hasAR => glbAsset != null || usdzAsset != null;

  List<String> get galleryUrls {
    if (imageAssets.isEmpty) {
      return image.isNotEmpty ? [image] : [];
    }
    final sorted = List<ProductAssetModel>.from(imageAssets)
      ..sort((a, b) {
        if (a.isPrimary && !b.isPrimary) return -1;
        if (!a.isPrimary && b.isPrimary) return 1;
        return 0;
      });
    return sorted.map((a) => a.url).toList();
  }

  ProductModel copyWith({
    String? id,
    String? name,
    String? tagline,
    double? price,
    String? image,
    String? tag,
    int? viewsCount,
    int? soldCount,
    double? averageRating,
    int? reviewCount,
    String? description,
    Map<String, dynamic>? vaultSpecs,
    Map<String, dynamic>? commonSpecs,
    String? brandName,
    List<ProductVariantModel>? variants,
    List<ProductAssetModel>? assets,
    List<String>? attributeConfig,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.baseName,
      tagline: tagline ?? this.tagline,
      price: price ?? this.basePrice,
      image: image ?? this.baseImage,
      tag: tag ?? this.tag,
      viewsCount: viewsCount ?? this.viewsCount,
      soldCount: soldCount ?? this.soldCount,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
      description: description ?? this.description,
      vaultSpecs: vaultSpecs ?? this.vaultSpecs,
      commonSpecs: commonSpecs ?? this.commonSpecs,
      brandName: brandName ?? this.brandName,
      variants: variants ?? this.variants,
      assets: assets ?? this.assets,
      attributeConfig: attributeConfig ?? this.attributeConfig,
    );
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    double price = 0.0;
    List<ProductVariantModel> variants = [];

    if (json['variants'] != null && (json['variants'] as List).isNotEmpty) {
      variants = (json['variants'] as List)
          .map((v) => ProductVariantModel.fromJson(v))
          .toList();
      price = variants.isNotEmpty ? variants.first.price : 0.0;
    } else if (json['price'] != null) {
      price = double.tryParse(json['price']?.toString() ?? '0') ?? 0.0;
    }

    List<ProductAssetModel> assets = [];
    if (json['assets'] != null && (json['assets'] as List).isNotEmpty) {
      assets = (json['assets'] as List)
          .map((a) => ProductAssetModel.fromJson(a as Map<String, dynamic>))
          .toList();
    }

    List<String> attributeConfig = [];
    if (json['attributeConfig'] != null) {
      attributeConfig = List<String>.from(json['attributeConfig']);
    }

    Map<String, dynamic>? commonSpecs;
    if (json['metadata'] != null && json['metadata'] is Map) {
      final meta = json['metadata'] as Map<String, dynamic>;
      if (meta['common_specs'] != null && meta['common_specs'] is Map) {
        commonSpecs = Map<String, dynamic>.from(meta['common_specs']);
      }
    }

    final String desc = json['description'] ?? '';
    final String? apiTagline = json['tagline'];

    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      tagline: (apiTagline != null && apiTagline.isNotEmpty)
          ? apiTagline
          : _extractFirstSentence(desc),
      price: price,
      image: json['thumbnailUrl'] ?? '',
      tag: 'MỚI',
      viewsCount: json['viewsCount'] as int? ?? 0,
      soldCount: json['soldCount'] as int? ?? 0,
      averageRating:
          double.tryParse(json['averageRating']?.toString() ?? '0.0') ?? 0.0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      description: desc,
      vaultSpecs: json['vaultSpecs'] != null ? Map<String, dynamic>.from(json['vaultSpecs']) : null,
      commonSpecs: commonSpecs,
      brandName: json['brand']?['name'] as String?,
      variants: variants,
      assets: assets,
      attributeConfig: attributeConfig,
    );
  }

  static String _extractFirstSentence(String description) {
    if (description.isEmpty) return '';
    final String firstSentence = description.split(RegExp(r'[.!?]')).first;
    final String trimmed = firstSentence.trim();
    if (trimmed.length > 60) {
      return '${trimmed.substring(0, 57).trim()}...';
    }
    return trimmed;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': baseName,
      'tagline': tagline,
      'price': basePrice,
      'thumbnailUrl': baseImage,
      'tag': tag,
      'viewsCount': viewsCount,
      'soldCount': soldCount,
      'averageRating': averageRating,
      'reviewCount': reviewCount,
      'description': description,
      'vaultSpecs': vaultSpecs,
      'brand': brandName != null ? {'name': brandName} : null,
      'variants': variants.map((e) => e.toJson()).toList(),
      'attributeConfig': attributeConfig,
    };
  }
}
