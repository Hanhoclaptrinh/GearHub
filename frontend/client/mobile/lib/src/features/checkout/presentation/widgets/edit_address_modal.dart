import 'dart:async';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const _bg = Color(0xFF0A0A10);
const _surface = Color(0xFF14141E);
const _surfaceAlt = Color(0xFF1C1C28);
const _border = Color(0xFF2A2A38);
const _accent = Color(0xFFF59E0B);
const _textHigh = Color(0xFFF1F1F5);
const _textMid = Color(0xFF9191A8);
const _textLow = Color(0xFF4A4A62);
const _pink = Color(0xFFFF6B8A);

class EditAddressPage extends StatefulWidget {
  final String initialName;
  final String initialPhone;
  final String initialAddress;
  final bool initialSaveAsDefault;
  final Function(String name, String phone, String address, bool saveAsDefault)
  onSave;

  const EditAddressPage({
    super.key,
    required this.initialName,
    required this.initialPhone,
    required this.initialAddress,
    required this.initialSaveAsDefault,
    required this.onSave,
  });

  @override
  State<EditAddressPage> createState() => _EditAddressPageState();
}

class _EditAddressPageState extends State<EditAddressPage> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _detailedAddressController;
  late bool _saveAsDefault;
  InAppWebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _phoneController = TextEditingController(text: widget.initialPhone);

    if (widget.initialAddress.contains(',')) {
      final parts = widget.initialAddress.split(',');
      _detailedAddressController = TextEditingController(text: parts[0].trim());
      _addressController = TextEditingController(
        text: parts.sublist(1).join(',').trim(),
      );
    } else {
      _detailedAddressController = TextEditingController();
      _addressController = TextEditingController(text: widget.initialAddress);
    }

    _saveAsDefault = widget.initialSaveAsDefault;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _detailedAddressController.dispose();
    super.dispose();
  }

  Future<String> _reverseGeocode(double lat, double lng) async {
    try {
      final dio = dio_pkg.Dio();
      final response = await dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': lat,
          'lon': lng,
          'format': 'json',
          'accept-language': 'vi',
        },
        options: dio_pkg.Options(
          headers: {'User-Agent': 'GearHub/1.0 (mobile client)'},
        ),
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data['display_name'] ?? '$lat, $lng';
      }
    } catch (_) {}
    return '$lat, $lng';
  }

  Future<Map<String, double>?> _forwardGeocode(String address) async {
    try {
      final dio = dio_pkg.Dio();
      final response = await dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': address,
          'format': 'json',
          'limit': 1,
          'accept-language': 'vi',
        },
        options: dio_pkg.Options(
          headers: {'User-Agent': 'GearHub/1.0 (mobile client)'},
        ),
      );
      if (response.statusCode == 200 &&
          response.data is List &&
          (response.data as List).isNotEmpty) {
        final first = response.data[0];
        return {
          'lat': double.parse(first['lat']),
          'lng': double.parse(first['lon']),
        };
      }
    } catch (_) {}
    return null;
  }

  void _handleSave() {
    if (_nameController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: _pink,
          content: Text(
            'Vui lòng nhập đủ thông tin.',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      );
      return;
    }

    String finalAddress = _detailedAddressController.text.trim().isNotEmpty
        ? "${_detailedAddressController.text.trim()}, ${_addressController.text.trim()}"
        : _addressController.text.trim();

    widget.onSave(
      _nameController.text.trim(),
      _phoneController.text.trim(),
      finalAddress,
      _saveAsDefault,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: _bg,
                elevation: 0,
                scrolledUnderElevation: 0,
                leading: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: _textMid,
                  ),
                ),
                centerTitle: true,
                title: const Text(
                  "Thông tin giao hàng",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _textHigh,
                    letterSpacing: -0.5,
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      const _SectionLabel(text: "NGƯỜI NHẬN"),
                      const SizedBox(height: 10),
                      _buildTextField(
                        _nameController,
                        "Họ và tên",
                        LucideIcons.user,
                      ),
                      const SizedBox(height: 10),
                      _buildTextField(
                        _phoneController,
                        "Số điện thoại",
                        LucideIcons.phone,
                        keyboardType: TextInputType.phone,
                      ),

                      const SizedBox(height: 28),

                      const _SectionLabel(text: "ĐỊA CHỈ"),
                      const SizedBox(height: 10),
                      _buildTextField(
                        _addressController,
                        "Tìm kiếm hoặc chọn trên bản đồ",
                        LucideIcons.mapPin,
                        maxLines: 2,
                        onSubmitted: (val) async {
                          if (val.trim().isNotEmpty) {
                            final coords = await _forwardGeocode(val.trim());
                            if (coords != null) {
                              _webViewController?.evaluateJavascript(
                                source:
                                    'window.updatePin(${coords['lat']}, ${coords['lng']});',
                              );
                            }
                          }
                        },
                        onChanged: (val) {
                          Timer? addressDebounce;
                          addressDebounce;
                          addressDebounce = Timer(
                            const Duration(milliseconds: 1000),
                            () async {
                              if (val.trim().isNotEmpty) {
                                final coords = await _forwardGeocode(
                                  val.trim(),
                                );
                                if (coords != null) {
                                  _webViewController?.evaluateJavascript(
                                    source:
                                        'window.updatePin(${coords['lat']}, ${coords['lng']});',
                                  );
                                }
                              }
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      _buildTextField(
                        _detailedAddressController,
                        "Số nhà, tên tòa nhà, phòng...",
                        LucideIcons.house,
                      ),

                      const SizedBox(height: 16),

                      Container(
                        height: 240,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _border, width: 0.5),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            InAppWebView(
                              gestureRecognizers:
                                  <Factory<OneSequenceGestureRecognizer>>{
                                    Factory<OneSequenceGestureRecognizer>(
                                      () => EagerGestureRecognizer(),
                                    ),
                                  },
                              initialData: InAppWebViewInitialData(
                                data: _mapHtml,
                              ),
                              onWebViewCreated: (controller) {
                                _webViewController = controller;
                                Timer? debounceTimer;
                                controller.addJavaScriptHandler(
                                  handlerName: 'onLocationChange',
                                  callback: (args) async {
                                    final double lat = args[0];
                                    final double lng = args[1];
                                    debounceTimer?.cancel();
                                    debounceTimer = Timer(
                                      const Duration(milliseconds: 600),
                                      () async {
                                        final address = await _reverseGeocode(
                                          lat,
                                          lng,
                                        );
                                        if (mounted) {
                                          setState(() {
                                            _addressController.text = address;
                                          });
                                        }
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                            // map overlay hint
                            Positioned(
                              bottom: 12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _surface.withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _border,
                                    width: 0.5,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      LucideIcons.move,
                                      size: 12,
                                      color: _textMid,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Kéo để chọn vị trí',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: _textMid,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() => _saveAsDefault = !_saveAsDefault);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: _surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _border, width: 0.5),
                          ),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: _saveAsDefault
                                      ? _accent
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: _saveAsDefault ? _accent : _textLow,
                                    width: 2,
                                  ),
                                ),
                                child: _saveAsDefault
                                    ? const Icon(
                                        Icons.check,
                                        size: 14,
                                        color: Colors.black,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                "Lưu làm địa chỉ mặc định",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _textMid,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 100 + bottomPadding),
                    ],
                  ),
                ),
              ),
            ],
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPadding + 16),
              decoration: const BoxDecoration(
                color: _bg,
                border: Border(top: BorderSide(color: _border, width: 0.5)),
              ),
              child: GestureDetector(
                onTap: _handleSave,
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: _accent,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: _accent.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      "XÁC NHẬN ĐỊA CHỈ",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    int maxLines = 1,
    TextInputType? keyboardType,
    ValueChanged<String>? onSubmitted,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border, width: 0.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        onSubmitted: onSubmitted,
        onChanged: onChanged,
        style: const TextStyle(color: _textHigh, fontSize: 14),
        textInputAction: onSubmitted != null
            ? TextInputAction.search
            : TextInputAction.next,
        decoration: InputDecoration(
          icon: Icon(icon, size: 18, color: _textLow),
          suffixIcon: onSubmitted != null
              ? IconButton(
                  icon: const Icon(
                    LucideIcons.search,
                    size: 16,
                    color: _accent,
                  ),
                  onPressed: () => onSubmitted(controller.text),
                )
              : null,
          hintText: hint,
          hintStyle: const TextStyle(color: _textLow, fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  static const _mapHtml = """
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
  <style>
    body { margin: 0; padding: 0; background: #0A0A10; position: relative; }
    #map { height: 100vh; width: 100vw; }
    .center-pin {
      position: absolute;
      top: 50%;
      left: 50%;
      transform: translate(-50%, -100%);
      z-index: 1000;
      pointer-events: none;
    }
    .leaflet-control-attribution { display: none !important; }
  </style>
</head>
<body>
  <div class="center-pin">
    <svg width="36" height="36" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path d="M12 2C8.13 2 5 5.13 5 9C5 14.25 12 22 12 22C12 22 19 14.25 19 9C19 5.13 15.87 2 12 2Z" fill="#F59E0B" stroke="#0A0A10" stroke-width="2"/>
      <circle cx="12" cy="9" r="3" fill="#0A0A10"/>
    </svg>
  </div>
  <div id="map"></div>
  <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
  <script>
    var map = L.map('map', { zoomControl: false }).setView([21.028511, 105.804817], 14);
    L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', {
      maxZoom: 19
    }).addTo(map);

    map.on('moveend', function() {
      var center = map.getCenter();
      window.flutter_inappwebview.callHandler('onLocationChange', center.lat, center.lng);
    });

    window.updatePin = function(lat, lng) {
      map.setView(new L.LatLng(lat, lng), 15);
    };
  </script>
</body>
</html>
""";
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: _accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: _textLow,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}
