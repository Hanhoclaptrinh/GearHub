import 'package:ar_flutter_plugin_2/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin_2/models/ar_anchor.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ar_flutter_plugin_2/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_2/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_2/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_2/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_2/models/ar_node.dart';
import 'package:ar_flutter_plugin_2/models/ar_hittest_result.dart';
import 'package:mobile/src/core/utils/formatter_utils.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import 'package:mobile/src/shared/models/product_model.dart';
import 'package:mobile/src/shared/models/product_variant_model.dart';
import 'package:mobile/src/shared/models/product_asset_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/shared/mixins/wishlist_mixin.dart';
import 'package:mobile/src/shared/mixins/cart_mixin.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/src/features/cart/presentation/state/cart_cubit.dart';
import 'package:mobile/src/features/cart/presentation/state/cart_state.dart';

class ProductARViewPage extends StatefulWidget {
  final ProductModel product;
  final ProductVariantModel? initialVariant;

  const ProductARViewPage({
    super.key,
    required this.product,
    this.initialVariant,
  });

  @override
  State<ProductARViewPage> createState() => _ProductARViewPageState();
}

class _ProductARViewPageState extends State<ProductARViewPage>
    with
        SingleTickerProviderStateMixin,
        WishlistMixin<ProductARViewPage>,
        CartMixin<ProductARViewPage> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;

  List<ARNode> nodes = [];
  List<ARAnchor> anchors = [];

  bool isInitializing = true;
  bool isObjectPlaced = false;
  bool hasDetectedPlane = false;

  //cờ chống tap dồn/tap khi đang xử lý — tránh gọi addNode nhiều lần
  //chồng nhau khi addNode còn đang chạy.
  bool isPlacingObject = false;

  ProductVariantModel? selectedVariant;
  Matrix4? lastPlaneTransform;
  double _scaleMultiplier = 1.0;

  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final Animation<double> _headerFade = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
  );
  late final Animation<Offset> _headerSlide =
      Tween<Offset>(begin: const Offset(0, -0.08), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _entrance,
          curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
        ),
      );
  late final Animation<double> _barFade = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0.25, 1.0, curve: Curves.easeOutCubic),
  );
  late final Animation<Offset> _barSlide =
      Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _entrance,
          curve: const Interval(0.25, 1.0, curve: Curves.easeOutCubic),
        ),
      );

  late final AnimationController _crosshairPulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  //lọc ra các biến thể thực sự có mô hình GLB đi kèm
  List<ProductVariantModel> get arVariants {
    final glbVariantIds = widget.product.assets
        .where((a) => a.type == AssetType.glb && a.variantId != null)
        .map((a) => a.variantId!)
        .toSet();
    return widget.product.variants
        .where((v) => glbVariantIds.contains(v.id))
        .toList();
  }

  String _getVariantColorName(ProductVariantModel variant) {
    String colorStr = '';
    variant.attributes.forEach((key, val) {
      final k = key.toLowerCase();
      if (k.contains('màu') || k.contains('color') || k.contains('mau')) {
        colorStr = val.toString().trim();
      }
    });
    if (colorStr.isEmpty) {
      colorStr = variant.name.trim();
    }
    return colorStr;
  }

  List<ProductVariantModel> get uniqueColorArVariants {
    final Map<String, ProductVariantModel> uniqueColors = {};
    for (final variant in arVariants) {
      final colorName = _getVariantColorName(variant).toLowerCase();
      if (!uniqueColors.containsKey(colorName)) {
        uniqueColors[colorName] = variant;
      }
    }
    return uniqueColors.values.toList();
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialVariant != null) {
      selectedVariant = widget.initialVariant;
    } else {
      final variantsWithModel = arVariants;
      if (variantsWithModel.isNotEmpty) {
        selectedVariant = variantsWithModel.firstWhere(
          (v) => v.isActive,
          orElse: () => variantsWithModel.first,
        );
      } else if (widget.product.variants.isNotEmpty) {
        selectedVariant = widget.product.variants.firstWhere(
          (v) => v.isActive,
          orElse: () => widget.product.variants.first,
        );
      }
    }
    checkInitialWishlist(widget.product.id);
  }

  //lấy asset GLB của biến thể đang chọn
  ProductAssetModel? _getVariantGlb() {
    if (selectedVariant == null) return null;

    //thử lấy trực tiếp từ variant đang chọn
    for (final asset in widget.product.assets) {
      if (asset.type == AssetType.glb &&
          asset.variantId == selectedVariant!.id) {
        return asset;
      }
    }

    //nếu không tìm thấy, thử tìm bất kỳ variant nào có cùng màu và có file GLB
    final currentColor = _getVariantColorName(selectedVariant!).toLowerCase();
    for (final variant in widget.product.variants) {
      final colorVal = _getVariantColorName(variant).toLowerCase();
      if (colorVal == currentColor) {
        for (final asset in widget.product.assets) {
          if (asset.type == AssetType.glb && asset.variantId == variant.id) {
            return asset;
          }
        }
      }
    }
    return null;
  }

  //tìm biến thể phù hợp
  ProductVariantModel _findMatchingVariant(
    ProductVariantModel targetColorVariant,
  ) {
    final newColor = _getVariantColorName(targetColorVariant).toLowerCase();

    //tìm thuộc tính phi màu sắc của variant đang chọn hiện tại
    final currentSpecs = <String, dynamic>{};
    if (selectedVariant != null) {
      selectedVariant!.attributes.forEach((key, val) {
        final k = key.toLowerCase();
        if (!k.contains('màu') && !k.contains('color') && !k.contains('mau')) {
          currentSpecs[key] = val;
        }
      });
    }

    ProductVariantModel? bestMatch;
    for (final variant in widget.product.variants) {
      final colorVal = _getVariantColorName(variant).toLowerCase();
      if (colorVal == newColor) {
        bool allSpecsMatch = true;
        currentSpecs.forEach((key, val) {
          if (variant.attributes[key]?.toString().toLowerCase() !=
              val.toString().toLowerCase()) {
            allSpecsMatch = false;
          }
        });
        if (allSpecsMatch) {
          bestMatch = variant;
          break;
        }
      }
    }
    return bestMatch ?? targetColorVariant;
  }

  String get _modelUri {
    final vGlb = _getVariantGlb();
    if (vGlb != null && vGlb.url.startsWith('http')) {
      return vGlb.url;
    }
    final glb = widget.product.glbAsset;
    if (glb != null && glb.url.startsWith('http')) {
      return glb.url;
    }
    return 'assets/models/model1.glb';
  }

  NodeType get _modelNodeType {
    final vGlb = _getVariantGlb();
    if (vGlb != null && vGlb.url.startsWith('http')) {
      return NodeType.webGLB;
    }
    final glb = widget.product.glbAsset;
    if (glb != null && glb.url.startsWith('http')) {
      return NodeType.webGLB;
    }
    return NodeType.localGLTF2;
  }

  //hệ số scale của model
  //các model đã được chỉnh sửa về tỷ lệ thực tế nên mặc định là 1
  double get _modelScale {
    final vGlb = _getVariantGlb();
    return vGlb?.arScale ?? widget.product.glbAsset?.arScale ?? 1.0;
  }

  String get _cleanProductName {
    final name = selectedVariant != null
        ? selectedVariant!.name
        : widget.product.baseName;
    return name.split('-').first.trim();
  }

  @override
  void dispose() {
    _entrance.dispose();
    _crosshairPulse.dispose();
    try {
      arSessionManager?.dispose();
    } catch (e) {
      debugPrint('AR dispose error: $e');
    }
    super.dispose();
  }

  void onARViewCreated(
    ARSessionManager sessionManager,
    ARObjectManager objectManager,
    ARAnchorManager anchorManager,
    ARLocationManager locationManager,
  ) {
    arSessionManager = sessionManager;
    arObjectManager = objectManager;
    arAnchorManager = anchorManager;

    //khởi tạo phiên ar
    arSessionManager!.onInitialize(
      showFeaturePoints: false,
      showPlanes: false,
      showWorldOrigin: false,
      handlePans: true,
      handleRotation: true,
      handleTaps: true,
    );

    arObjectManager!.onInitialize();
    arSessionManager!.onPlaneOrPointTap = onPlaneOrPointTapped;

    //đăng ký callback phát hiện mặt phẳng để cập nhật hint ngay khi có thể
    arSessionManager!.onPlaneDetected = (arPlane) {
      if (!hasDetectedPlane && mounted) {
        setState(() => hasDetectedPlane = true);
      }
    };

    //lắng nghe cử chỉ để lưu trữ vị trí, xoay, thu phóng mới của vật thể
    arObjectManager!.onPanEnd = (nodeName, transform) {
      lastPlaneTransform = transform;
    };
    arObjectManager!.onRotationEnd = (nodeName, transform) {
      lastPlaneTransform = transform;
    };

    setState(() => isInitializing = false);
    _entrance.forward();
  }

  Future<void> onPlaneOrPointTapped(
    List<ARHitTestResult> hitTestResults,
  ) async {
    //chặn tap khi: đã đặt vật thể / đang xử lý 1 lượt đặt khác / không có kết quả hit test
    if (isObjectPlaced || isPlacingObject || hitTestResults.isEmpty) return;
    final planeHit = hitTestResults.cast<ARHitTestResult?>().firstWhere(
      (hit) => hit?.type == ARHitTestResultType.plane,
      orElse: () => null,
    );

    if (planeHit == null) {
      _showSnack(
        'Chưa nhận diện được mặt phẳng. Hãy di chuyển camera chậm hơn',
      );
      return;
    }

    if (!hasDetectedPlane && mounted) {
      setState(() => hasDetectedPlane = true);
    }

    setState(() => isPlacingObject = true);

    try {
      //tạo điểm neo cố định (ARPlaneAnchor) để cố định chính xác vị trí trong không gian thực
      final planeAnchor = ARPlaneAnchor(
        transformation: planeHit.worldTransform,
      );
      bool? didAddAnchor = await arAnchorManager?.addAnchor(planeAnchor);

      if (didAddAnchor == true) {
        anchors.add(planeAnchor);

        final initialScale = _modelScale * _scaleMultiplier;
        var newNode = ARNode(
          name: 'node_${DateTime.now().microsecondsSinceEpoch}',
          type: _modelNodeType,
          uri: _modelUri,
          scale: Vector3(initialScale, initialScale, initialScale),
        );

        //liên kết node với điểm neo giúp vật thể không bị trôi và hỗ trợ các cử chỉ kéo/xoay chính xác
        bool? didAddNode = await arObjectManager?.addNode(
          newNode,
          planeAnchor: planeAnchor,
        );

        if (didAddNode == true) {
          nodes.add(newNode);
          lastPlaneTransform = planeHit.worldTransform;
          if (mounted) setState(() => isObjectPlaced = true);
        } else {
          await arAnchorManager?.removeAnchor(planeAnchor);
          anchors.remove(planeAnchor);
          _showSnack('Không thể hiển thị vật thể. Thử lại');
        }
      } else {
        _showSnack('Không thể tạo điểm neo. Thử lại');
      }
    } catch (e) {
      debugPrint('Error placing object: $e');
      _showSnack('Đã xảy ra lỗi khi đặt vật thể. Thử lại');
    } finally {
      if (mounted) setState(() => isPlacingObject = false);
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
            letterSpacing: 0.2,
            fontSize: 13,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> removeNode() async {
    try {
      for (var node in nodes) {
        await arObjectManager?.removeNode(node);
      }
    } catch (e) {
      debugPrint('Error removing nodes: $e');
    }
    nodes.clear();
    try {
      for (var anchor in anchors) {
        await arAnchorManager?.removeAnchor(anchor);
      }
    } catch (e) {
      debugPrint('Error removing anchors: $e');
    }
    anchors.clear();
    lastPlaneTransform = null;

    if (mounted) {
      setState(() {
        isObjectPlaced = false;
        hasDetectedPlane = false;
        _scaleMultiplier = 1.0;
      });
    }
  }

  Future<void> selectVariant(ProductVariantModel variant) async {
    final matchedVariant = _findMatchingVariant(variant);
    if (selectedVariant?.id == matchedVariant.id) return;

    setState(() {
      selectedVariant = matchedVariant;
    });

    //nếu sản phẩm đã được đặt trên mặt phẳng, hoán đổi node 3D sang màu mới
    if (isObjectPlaced && nodes.isNotEmpty) {
      final currentTransform = lastPlaneTransform;

      //xóa các node cũ khỏi màn hình
      try {
        for (var node in nodes) {
          await arObjectManager?.removeNode(node);
        }
      } catch (e) {
        debugPrint('Error removing nodes on variant change: $e');
      }
      nodes.clear();

      final initialScale = _modelScale * _scaleMultiplier;
      //tạo node mới cho biến thể mới với tên duy nhất
      var newNode = ARNode(
        name: 'node_${DateTime.now().microsecondsSinceEpoch}',
        type: _modelNodeType,
        uri: _modelUri,
        scale: Vector3(initialScale, initialScale, initialScale),
      );

      bool? didAddNode;
      //tái sử dụng điểm neo (anchor) hiện tại để tránh trôi lệch vị trí
      if (anchors.isNotEmpty) {
        didAddNode = await arObjectManager?.addNode(
          newNode,
          planeAnchor: anchors.last as ARPlaneAnchor,
        );
      } else {
        if (currentTransform != null) {
          newNode.transform = currentTransform;
        }
        didAddNode = await arObjectManager?.addNode(newNode);
      }

      if (didAddNode == true) {
        nodes.add(newNode);
      } else {
        _showSnack('Không thể hiển thị biến thể mới. Thử lại');
        setState(() {
          isObjectPlaced = false;
        });
      }
    }
  }

  void _applyScale(double multiplier) {
    if (nodes.isEmpty) return;

    final node = nodes.first;
    final baseScale = _modelScale;
    final targetScale = baseScale * multiplier;
    node.scale = Vector3(targetScale, targetScale, targetScale);
  }

  void _onScaleSliderChanged(double value) {
    setState(() {
      _scaleMultiplier = value;
    });
    _applyScale(value);
  }

  static const Color _ink = Color(0xFF0A0A0A);
  static const Color _ivory = Color(0xFFF7F5F1);
  static const Color _champagne = Color(0xFFC9A876);
  static const Color _hairline = Color(0x29FFFFFF);

  @override
  Widget build(BuildContext context) {
    final listVariants = uniqueColorArVariants;
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return BlocListener<CartCubit, CartState>(
      listener: (context, state) {
        if (state is CartAddSuccess && isAddingToCart) {
          setState(() => isAddingToCart = false);
          _showSnack('Đã thêm sản phẩm vào giỏ hàng');
        }
        if (state is CartError && isAddingToCart) {
          setState(() => isAddingToCart = false);
        }
      },
      child: Scaffold(
        backgroundColor: _ink,
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            ARView(
              onARViewCreated: onARViewCreated,
              planeDetectionConfig: PlaneDetectionConfig.horizontal,
            ),

            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 260,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _ink.withValues(alpha: 0.78),
                        _ink.withValues(alpha: 0.42),
                        _ink.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 220,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        _ink.withValues(alpha: 0.62),
                        _ink.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            Positioned(
              top: topPad + 14,
              left: 20,
              right: 20,
              child: FadeTransition(
                opacity: _headerFade,
                child: SlideTransition(
                  position: _headerSlide,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _GlassIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        iconSize: 22,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'TRẢI NGHIỆM SẢN PHẨM TRONG KHÔNG GIAN THỰC',
                              style: TextStyle(
                                color: _champagne.withValues(alpha: 0.92),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.6,
                                fontFamily: 'Inter',
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _cleanProductName,
                              style: const TextStyle(
                                color: _ivory,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.1,
                                fontFamily: 'Inter',
                                height: 1.25,
                                shadows: [
                                  Shadow(
                                    color: Color(0xCC000000),
                                    blurRadius: 14,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              formatVND(
                                selectedVariant != null
                                    ? selectedVariant!.price
                                    : widget.product.basePrice,
                              ),
                              style: TextStyle(
                                color: _ivory.withValues(alpha: 0.72),
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0.2,
                                fontFamily: 'Inter',
                                shadows: const [
                                  Shadow(
                                    color: Color(0x99000000),
                                    blurRadius: 10,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),

                            if (listVariants.length >= 2) ...[
                              const SizedBox(height: 14),
                              SizedBox(
                                height: 36,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: listVariants.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 12),
                                  itemBuilder: (context, index) {
                                    final variant = listVariants[index];
                                    final isSelected =
                                        selectedVariant != null &&
                                        _getVariantColorName(
                                              selectedVariant!,
                                            ).toLowerCase() ==
                                            _getVariantColorName(
                                              variant,
                                            ).toLowerCase();
                                    final imageUrl = variant.imageUrl ?? widget.product.image;

                                    return _VariantSwatch(
                                      imageUrl: imageUrl,
                                      isSelected: isSelected,
                                      accent: _champagne,
                                      onTap: () => selectVariant(variant),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(width: 14),

                      _GlassIconButton(
                        icon: isWishlisted
                            ? Icons.favorite_rounded
                            : LucideIcons.heart,
                        iconColor: isWishlisted
                            ? const Color(0xFFE11D48)
                            : Colors.white,
                        iconSize: 17,
                        onTap: () {
                          toggleWishlist(widget.product.id);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            if (isInitializing)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _ivory.withValues(alpha: 0.85),
                        ),
                        strokeWidth: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Đang khởi tạo camera',
                      style: TextStyle(
                        color: _ivory.withValues(alpha: 0.55),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.6,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),

            if (!isInitializing && !isObjectPlaced)
              IgnorePointer(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _crosshairPulse,
                    builder: (context, child) {
                      final t = _crosshairPulse.value;
                      return Opacity(
                        opacity: 0.55 + (0.25 * t),
                        child: Transform.scale(
                          scale: 1.0 + (0.06 * t),
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: hasDetectedPlane
                              ? _champagne.withValues(alpha: 0.85)
                              : Colors.white.withValues(alpha: 0.55),
                          width: 1.4,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: hasDetectedPlane
                                ? _champagne
                                : Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            if (isPlacingObject)
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _hairline, width: 0.6),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.6,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _ivory.withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Đang đặt mô hình...',
                            style: TextStyle(
                              color: _ivory.withValues(alpha: 0.75),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.3,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            if (!isInitializing)
              Positioned(
                bottom: 128 + bottomPad,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 320),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.15),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: _buildHintBadge(),
                    ),
                  ),
                ),
              ),

            if (!isInitializing && isObjectPlaced)
              Positioned(
                bottom: 182 + bottomPad,
                left: 30,
                right: 30,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.50),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _hairline, width: 0.6),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'KÍCH THƯỚC MÔ HÌNH',
                            style: TextStyle(
                              color: _champagne.withValues(alpha: 0.9),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.0,
                              fontFamily: 'Inter',
                            ),
                          ),
                          Text(
                            '${(_scaleMultiplier * 100).toInt()}%',
                            style: const TextStyle(
                              color: _ivory,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 2,
                          activeTrackColor: _champagne,
                          inactiveTrackColor: Colors.white.withValues(
                            alpha: 0.16,
                          ),
                          thumbColor: _ivory,
                          overlayColor: _champagne.withValues(alpha: 0.15),
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 7,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 16,
                          ),
                        ),
                        child: Slider(
                          value: _scaleMultiplier,
                          min: 0.05,
                          max: 3.0,
                          onChanged: _onScaleSliderChanged,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (!isInitializing)
              Positioned(
                bottom: 36 + bottomPad,
                left: 20,
                right: 20,
                child: FadeTransition(
                  opacity: _barFade,
                  child: SlideTransition(
                    position: _barSlide,
                    child: Row(
                      children: [
                        if (isObjectPlaced) ...[
                          _GlassIconButton(
                            icon: LucideIcons.trash2,
                            iconSize: 17,
                            size: 52,
                            onTap: removeNode,
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(child: _buildCartButton()),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartButton() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (selectedVariant != null) {
              handleAddToCart(
                variant: selectedVariant!,
                product: widget.product,
                quantity: 1,
              );
            }
          },
          splashColor: _ink.withValues(alpha: 0.08),
          highlightColor: _ink.withValues(alpha: 0.04),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: _ivory,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                isAddingToCart
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.6,
                          color: _ink,
                        ),
                      )
                    : Icon(
                        LucideIcons.shoppingBag,
                        color: _ink.withValues(alpha: 0.88),
                        size: 16,
                      ),
                const SizedBox(width: 10),
                Text(
                  isAddingToCart ? 'Đang thêm...' : 'Thêm vào giỏ hàng',
                  style: TextStyle(
                    color: _ink.withValues(alpha: 0.92),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 1,
                  height: 14,
                  color: _ink.withValues(alpha: 0.14),
                ),
                const SizedBox(width: 10),
                Text(
                  formatVND(
                    selectedVariant != null
                        ? selectedVariant!.price
                        : widget.product.basePrice,
                  ),
                  style: TextStyle(
                    color: _ink.withValues(alpha: 0.55),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.1,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHintBadge() {
    final String text;

    if (isObjectPlaced) {
      text = 'Kéo để di chuyển  ·  Chỉnh kích thước bên dưới';
    } else if (isPlacingObject) {
      text = 'Đang xử lý...';
    } else if (hasDetectedPlane) {
      text = 'Nhắm vào tâm khung hình và chạm để đặt sản phẩm';
    } else {
      text = 'Di chuyển camera chậm để quét mặt phẳng';
    }

    return Container(
      key: ValueKey('$isObjectPlaced-$hasDetectedPlane-$isPlacingObject'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: _hairline, width: 0.6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: _ivory.withValues(alpha: 0.70),
          fontSize: 11.5,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.3,
          fontFamily: 'Inter',
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final double size;
  final VoidCallback onTap;
  final Color? iconColor;

  const _GlassIconButton({
    required this.icon,
    required this.onTap,
    this.iconSize = 16,
    this.size = 40,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          splashColor: Colors.white.withValues(alpha: 0.08),
          highlightColor: Colors.white.withValues(alpha: 0.04),
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.45),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 0.8,
              ),
            ),
            child: Icon(icon, color: iconColor ?? Colors.white, size: iconSize),
          ),
        ),
      ),
    );
  }
}

class _VariantSwatch extends StatelessWidget {
  final String imageUrl;
  final bool isSelected;
  final Color accent;
  final VoidCallback onTap;

  const _VariantSwatch({
    required this.imageUrl,
    required this.isSelected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: 32,
        height: 32,
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? accent : Colors.white.withValues(alpha: 0.22),
            width: isSelected ? 1.5 : 0.8,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF14141E),
            image: imageUrl.isNotEmpty
                ? DecorationImage(
                    image: CachedNetworkImageProvider(imageUrl),
                    fit: BoxFit.cover,
                  )
                : null,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
