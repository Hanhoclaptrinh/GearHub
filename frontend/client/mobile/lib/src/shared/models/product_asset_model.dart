enum AssetType { image, glb, usdz }

class ProductAssetModel {
  final String id;
  final AssetType type;
  final String url;
  final bool isPrimary;
  final double? arScale;
  final double? positionX;
  final double? positionY;
  final double? positionZ;

  const ProductAssetModel({
    required this.id,
    required this.type,
    required this.url,
    this.isPrimary = false,
    this.arScale,
    this.positionX,
    this.positionY,
    this.positionZ,
  });

  factory ProductAssetModel.fromJson(Map<String, dynamic> json) {
    return ProductAssetModel(
      id: json['id'] as String,
      type: _parseType(json['type'] as String? ?? 'IMAGE'),
      url: json['url'] as String,
      isPrimary: json['isPrimary'] as bool? ?? false,
      arScale: (json['arScale'] as num?)?.toDouble(),
      positionX: (json['positionX'] as num?)?.toDouble(),
      positionY: (json['positionY'] as num?)?.toDouble(),
      positionZ: (json['positionZ'] as num?)?.toDouble(),
    );
  }

  static AssetType _parseType(String type) {
    switch (type.toUpperCase()) {
      case 'GLB':
        return AssetType.glb;
      case 'USDZ':
        return AssetType.usdz;
      default:
        return AssetType.image;
    }
  }
}
