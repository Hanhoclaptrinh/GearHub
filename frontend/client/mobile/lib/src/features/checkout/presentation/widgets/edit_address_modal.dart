import 'dart:async';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class EditAddressModal extends StatefulWidget {
  final String initialName;
  final String initialPhone;
  final String initialAddress;
  final bool initialSaveAsDefault;
  final Function(String name, String phone, String address, bool saveAsDefault) onSave;

  const EditAddressModal({
    super.key,
    required this.initialName,
    required this.initialPhone,
    required this.initialAddress,
    required this.initialSaveAsDefault,
    required this.onSave,
  });

  @override
  State<EditAddressModal> createState() => _EditAddressModalState();
}

class _EditAddressModalState extends State<EditAddressModal> {
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
    
    // Split address on first comma if it exists
    if (widget.initialAddress.contains(',')) {
      final parts = widget.initialAddress.split(',');
      _detailedAddressController = TextEditingController(text: parts[0].trim());
      _addressController = TextEditingController(text: parts.sublist(1).join(',').trim());
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
          headers: {
            'User-Agent': 'GearHub/1.0 (mobile client)',
          },
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
          headers: {
            'User-Agent': 'GearHub/1.0 (mobile client)',
          },
        ),
      );
      if (response.statusCode == 200 && response.data is List && (response.data as List).isNotEmpty) {
        final first = response.data[0];
        return {
          'lat': double.parse(first['lat']),
          'lng': double.parse(first['lon']),
        };
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Thông tin giao hàng",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(_nameController, "Tên người nhận", LucideIcons.user),
                      const SizedBox(height: 12),
                      _buildTextField(_phoneController, "Số điện thoại", LucideIcons.phone),
                      const SizedBox(height: 12),
                      _buildTextField(
                        _addressController,
                        "Địa chỉ từ bản đồ hoặc tìm kiếm",
                        LucideIcons.mapPin,
                        maxLines: 2,
                        onSubmitted: (val) async {
                          if (val.trim().isNotEmpty) {
                            final coords = await _forwardGeocode(val.trim());
                            if (coords != null) {
                              _webViewController?.evaluateJavascript(
                                source: 'window.updatePin(${coords['lat']}, ${coords['lng']});',
                              );
                            }
                          }
                        },
                        onChanged: (val) {
                          Timer? addressDebounce;
                          addressDebounce;
                          addressDebounce = Timer(const Duration(milliseconds: 1000), () async {
                            if (val.trim().isNotEmpty) {
                              final coords = await _forwardGeocode(val.trim());
                              if (coords != null) {
                                _webViewController?.evaluateJavascript(
                                  source: 'window.updatePin(${coords['lat']}, ${coords['lng']});',
                                );
                              }
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        _detailedAddressController,
                        "Số nhà, tên tòa nhà, phòng (Ví dụ: Số 12, Tòa ABC...)",
                        LucideIcons.house,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Kéo thả ghim trên bản đồ để chọn vị trí chính xác",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      Container(
                        height: 220,
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InAppWebView(
                          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                            Factory<OneSequenceGestureRecognizer>(
                              () => EagerGestureRecognizer(),
                            ),
                          },
                          initialData: InAppWebViewInitialData(
                            data: """
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
  <style>
    body { margin: 0; padding: 0; background: #fff; position: relative; }
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
      <path d="M12 2C8.13 2 5 5.13 5 9C5 14.25 12 22 12 22C12 22 19 14.25 19 9C19 5.13 15.87 2 12 2Z" fill="#3B82F6" stroke="white" stroke-width="2"/>
      <circle cx="12" cy="9" r="3" fill="white"/>
    </svg>
  </div>
  <div id="map"></div>
  <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
  <script>
    var map = L.map('map', { zoomControl: false }).setView([21.028511, 105.804817], 14);
    L.tileLayer('https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png', {
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
""",
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
                                debounceTimer = Timer(const Duration(milliseconds: 600), () async {
                                  final address = await _reverseGeocode(lat, lng);
                                  setModalState(() {
                                    _addressController.text = address;
                                  });
                                });
                              },
                            );
                          },
                        ),
                      ),
                      Row(
                        children: [
                          Checkbox(
                            value: _saveAsDefault,
                            activeColor: const Color(0xFF3B82F6),
                            onChanged: (val) {
                              setModalState(() {
                                _saveAsDefault = val ?? true;
                              });
                            },
                          ),
                          const Text(
                            "Lưu làm thông tin nhận hàng mặc định",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () {
                          if (_nameController.text.trim().isEmpty ||
                              _addressController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Vui lòng nhập đủ thông tin.'),
                                backgroundColor: Colors.red,
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
                        },
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              "Xác nhận",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    int maxLines = 1,
    ValueChanged<String>? onSubmitted,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        onSubmitted: onSubmitted,
        onChanged: onChanged,
        textInputAction: onSubmitted != null ? TextInputAction.search : TextInputAction.next,
        decoration: InputDecoration(
          icon: Icon(icon, size: 20, color: const Color(0xFF94A3B8)),
          suffixIcon: onSubmitted != null
              ? IconButton(
                  icon: const Icon(LucideIcons.search, size: 18, color: Color(0xFF3B82F6)),
                  onPressed: () => onSubmitted(controller.text),
                )
              : null,
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
