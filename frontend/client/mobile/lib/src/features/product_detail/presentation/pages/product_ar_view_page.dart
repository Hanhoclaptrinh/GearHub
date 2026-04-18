import 'package:ar_flutter_plugin_2/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin_2/models/ar_anchor.dart';
import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin_2/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_2/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_2/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_2/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_2/models/ar_node.dart';
import 'package:ar_flutter_plugin_2/models/ar_hittest_result.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import 'package:mobile/src/features/home/domain/models/product.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ProductARViewPage extends StatefulWidget {
  final Product product;

  const ProductARViewPage({super.key, required this.product});

  @override
  State<ProductARViewPage> createState() => _ProductARViewPageState();
}

class _ProductARViewPageState extends State<ProductARViewPage> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;

  List<ARNode> nodes = [];
  List<ARAnchor> anchors = [];

  bool isInitializing = true;
  bool isObjectPlaced = false;

  bool hasDetectedPlane = false;

  @override
  void dispose() {
    try {
      arSessionManager?.dispose();
    } catch (e) {
      debugPrint('AR dispose error: $e');
    }
    super.dispose();
  }

  // khoi tao ARView
  void onARViewCreated(
    ARSessionManager sessionManager,
    ARObjectManager objectManager,
    ARAnchorManager anchorManager,
    ARLocationManager locationManager,
  ) {
    arSessionManager = sessionManager;
    arObjectManager = objectManager;
    arAnchorManager = anchorManager;

    arSessionManager!.onInitialize(
      showFeaturePoints: true,
      showPlanes: true, // plane overlay
      showWorldOrigin: false,
      handlePans: true,
      handleRotation: true,
      handleTaps: true,
    );

    arObjectManager!.onInitialize();

    arSessionManager!.onPlaneOrPointTap = onPlaneOrPointTapped;

    setState(() => isInitializing = false);
  }

  Future<void> onPlaneOrPointTapped(
    List<ARHitTestResult> hitTestResults,
  ) async {
    if (isObjectPlaced || hitTestResults.isEmpty) return;

    // xac dinh diem cham co nam tren mat phang khong
    final planeHit = hitTestResults.cast<ARHitTestResult?>().firstWhere(
      (hit) => hit?.type == ARHitTestResultType.plane,
      orElse: () =>
          null, // tra ve null khi khong tim thay cu cham nao trung be mat phang
    );

    if (planeHit == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Chưa nhận diện được mặt phẳng. Hãy di chuyển camera chậm hơn',
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // da co plane
    if (!hasDetectedPlane && mounted) {
      setState(() => hasDetectedPlane = true);
    }

    // thuc hien dat anchor tai diem vua cham trung
    // anchor giup vat the khong bi troi trong khong gian
    var newAnchor = ARPlaneAnchor(transformation: planeHit.worldTransform);

    bool? didAddAnchor = await arAnchorManager?.addAnchor(newAnchor);

    if (didAddAnchor == true) {
      anchors.add(newAnchor);

      // khoi tao mot obj 3d ao truoc khi dua vao thuc te
      var newNode = ARNode(
        type: NodeType.localGLTF2,
        uri: 'assets/models/model1.glb',
        scale: Vector3(0.2, 0.2, 0.2), // scale vat the de test
        position: Vector3(0, 0, 0), // nam chinh giua anchor
        rotation: Vector4(1.0, 0.0, 0.0, 0.0),
      );

      // dua vat the vao khong gian
      bool? didAddNode = await arObjectManager?.addNode(
        newNode,
        planeAnchor: newAnchor,
      );

      if (didAddNode == true) {
        nodes.add(newNode);
        if (mounted) setState(() => isObjectPlaced = true);
      } else {
        _showSnack('Không thể render model. Kiểm tra lại đường dẫn assets');
      }
    } else {
      // fallback: dat node khong can anchor (dung planeHit)
      var fallbackNode = ARNode(
        type: NodeType.localGLTF2,
        uri: 'assets/models/model1.glb',
        scale: Vector3(0.2, 0.2, 0.2),
        position: Vector3(
          planeHit.worldTransform.getColumn(3).x,
          planeHit.worldTransform.getColumn(3).y,
          planeHit.worldTransform.getColumn(3).z,
        ),
        rotation: Vector4(1.0, 0.0, 0.0, 0.0),
      );

      bool? didAddNode = await arObjectManager?.addNode(fallbackNode);
      if (didAddNode == true) {
        nodes.add(fallbackNode);
        if (mounted) setState(() => isObjectPlaced = true);
      } else {
        _showSnack('Đặt vật thể thất bại. Thử lại');
      }
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  // xoa vat the & anchor khoi khong gian
  Future<void> removeNode() async {
    for (var node in nodes) {
      await arObjectManager?.removeNode(node);
    }
    nodes.clear();
    for (var anchor in anchors) {
      arAnchorManager?.removeAnchor(anchor);
    }
    anchors.clear();

    if (mounted) {
      setState(() => isObjectPlaced = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          ARView(
            onARViewCreated: onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
          ),

          SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.3),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                if (isObjectPlaced)
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0, top: 8.0),
                    child: IconButton(
                      icon: const Icon(
                        LucideIcons.refreshCcw,
                        color: Colors.white,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.3),
                      ),
                      onPressed: removeNode,
                    ),
                  ),
              ],
            ),
          ),

          if (isInitializing)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),

          if (!isInitializing)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildHintBadge(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHintBadge() {
    final IconData icon;
    final String text;

    if (isObjectPlaced) {
      icon = LucideIcons.move3d;
      text = 'Kéo để di chuyển, chụm để scale';
    } else if (hasDetectedPlane) {
      icon = LucideIcons.mousePointerClick;
      text = 'Nhấn vào mặt phẳng để đặt sản phẩm';
    } else {
      icon = LucideIcons.scan;
      text = 'Di chuyển camera chậm để quét mặt phẳng';
    }

    return Container(
      key: ValueKey('$isObjectPlaced-$hasDetectedPlane'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
