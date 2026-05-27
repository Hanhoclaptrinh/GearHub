import 'dart:async';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/core/theme/app_colors.dart';
import 'package:vietnam_provinces/vietnam_provinces.dart';

class EditAddressPage extends StatefulWidget {
  final String initialName;
  final String initialPhone;
  final String? initialProvince;
  final String? initialDistrict;
  final String? initialWard;
  final String? initialDetail;
  final bool initialSaveAsDefault;
  final Function(
    String name,
    String phone,
    String province,
    String district,
    String ward,
    String detail,
    bool saveAsDefault,
  )
  onSave;

  const EditAddressPage({
    super.key,
    required this.initialName,
    required this.initialPhone,
    this.initialProvince,
    this.initialDistrict,
    this.initialWard,
    this.initialDetail,
    required this.initialSaveAsDefault,
    required this.onSave,
  });

  @override
  State<EditAddressPage> createState() => _EditAddressPageState();
}

class _EditAddressPageState extends State<EditAddressPage> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _detailedAddressController;
  late bool _saveAsDefault;
  InAppWebViewController? _webViewController;

  Province? _selectedProvince;
  District? _selectedDistrict;
  Ward? _selectedWard;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _phoneController = TextEditingController(text: widget.initialPhone);
    _detailedAddressController = TextEditingController(
      text: widget.initialDetail ?? '',
    );
    _saveAsDefault = widget.initialSaveAsDefault;

    _initializeAddressDivisions();
  }

  void _initializeAddressDivisions() {
    final provinceName = widget.initialProvince?.trim();
    if (provinceName != null && provinceName.isNotEmpty) {
      try {
        final provinces = VietnamProvinces.getProvinces();
        _selectedProvince = provinces.firstWhere(
          (p) => p.name.trim().toLowerCase() == provinceName.toLowerCase(),
        );

        final districtName = widget.initialDistrict?.trim();
        if (districtName != null && districtName.isNotEmpty) {
          final districts = VietnamProvinces.getDistricts(
            provinceCode: _selectedProvince!.code,
          );
          _selectedDistrict = districts.firstWhere(
            (d) => d.name.trim().toLowerCase() == districtName.toLowerCase(),
          );

          final wardName = widget.initialWard?.trim();
          if (wardName != null && wardName.isNotEmpty) {
            final wards = VietnamProvinces.getWards(
              provinceCode: _selectedProvince!.code,
              districtCode: _selectedDistrict!.code,
            );
            _selectedWard = wards.firstWhere(
              (w) => w.name.trim().toLowerCase() == wardName.toLowerCase(),
            );
          }
        }
      } catch (e) {
        debugPrint('Error matching initial address divisions: $e');
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _detailedAddressController.dispose();
    super.dispose();
  }

  String _normalize(String name) {
    return name
        .toLowerCase()
        .replaceAll(
          RegExp(
            r'^(thành phố|tỉnh|quận|huyện|thị xã|phường|xã|thị trấn|phố)\s+',
          ),
          '',
        )
        .trim();
  }

  Province? _findProvince(String part) {
    final provinces = VietnamProvinces.getProvinces();
    final normPart = _normalize(part);
    for (var p in provinces) {
      if (_normalize(p.name) == normPart ||
          p.name.toLowerCase().contains(normPart) ||
          normPart.contains(_normalize(p.name))) {
        return p;
      }
    }
    return null;
  }

  District? _findDistrict(Province province, String part) {
    final districts = VietnamProvinces.getDistricts(
      provinceCode: province.code,
    );
    final normPart = _normalize(part);
    for (var d in districts) {
      if (_normalize(d.name) == normPart ||
          d.name.toLowerCase().contains(normPart) ||
          normPart.contains(_normalize(d.name))) {
        return d;
      }
    }
    return null;
  }

  Ward? _findWard(Province province, District district, String part) {
    final wards = VietnamProvinces.getWards(
      provinceCode: province.code,
      districtCode: district.code,
    );
    final normPart = _normalize(part);
    for (var w in wards) {
      if (_normalize(w.name) == normPart ||
          w.name.toLowerCase().contains(normPart) ||
          normPart.contains(_normalize(w.name))) {
        return w;
      }
    }
    return null;
  }

  void _parseGeocodedAddress(String address) {
    if (address.isEmpty) return;

    try {
      final parts = address.split(',').map((p) => p.trim()).toList();
      if (parts.isNotEmpty && parts.last.toLowerCase() == 'việt nam') {
        parts.removeLast();
      }

      if (parts.length < 3) {
        _detailedAddressController.text = parts.join(', ');
        return;
      }

      final provincePart = parts.removeLast();
      final districtPart = parts.removeLast();
      final wardPart = parts.removeLast();

      final province = _findProvince(provincePart);
      if (province != null) {
        final district = _findDistrict(province, districtPart);
        if (district != null) {
          final ward = _findWard(province, district, wardPart);
          setState(() {
            _selectedProvince = province;
            _selectedDistrict = district;
            _selectedWard = ward;
            _detailedAddressController.text = parts.join(', ');
          });
          return;
        }
      }

      _detailedAddressController.text = address;
    } catch (e) {
      debugPrint('Error parsing geocoded address: $e');
      _detailedAddressController.text = address;
    }
  }

  // --- API Geocoding ---
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

  void _syncDropdownsToMap() async {
    if (_selectedProvince == null) return;

    final searchBuffer = [
      if (_selectedWard != null) _selectedWard!.name,
      if (_selectedDistrict != null) _selectedDistrict!.name,
      _selectedProvince!.name,
    ];

    final searchStr = searchBuffer.join(', ');
    final coords = await _forwardGeocode(searchStr);
    if (coords != null && _webViewController != null) {
      _webViewController?.evaluateJavascript(
        source: 'window.updatePin(${coords['lat']}, ${coords['lng']});',
      );
    }
  }

  void _showSearchSelectorSheet<T>({
    required String title,
    required List<T> items,
    required String Function(T item) getName,
    required ValueChanged<T> onSelect,
  }) {
    String searchQ = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredItems = items
                .where(
                  (item) => getName(
                    item,
                  ).toLowerCase().contains(searchQ.toLowerCase()),
                )
                .toList();

            final bottomPadding = MediaQuery.of(context).padding.bottom;
            final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              margin: EdgeInsets.only(bottom: keyboardHeight),
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                border: Border(
                  top: BorderSide(
                    color: AppColors.borderCardStrong,
                    width: 0.5,
                  ),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  // Handle bar
                  Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textDim.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Search box
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardSurfaceAltAlt,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.borderCardStrong,
                          width: 0.5,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        autofocus: true,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Tìm kiếm nhanh...',
                          hintStyle: TextStyle(
                            color: AppColors.textDim,
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                          icon: Icon(
                            LucideIcons.search,
                            size: 16,
                            color: AppColors.textDim,
                          ),
                        ),
                        onChanged: (val) {
                          setModalState(() {
                            searchQ = val;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // List
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        20,
                        0,
                        20,
                        20 + bottomPadding,
                      ),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        final name = getName(item);
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: AppColors.textDim,
                          ),
                          onTap: () {
                            onSelect(item);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _handleSave() {
    if (_nameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _selectedProvince == null ||
        _selectedDistrict == null ||
        _selectedWard == null ||
        _detailedAddressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.accentPink,
          content: Text(
            'Vui lòng nhập và chọn đủ thông tin địa chỉ.',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      );
      return;
    }

    widget.onSave(
      _nameController.text.trim(),
      _phoneController.text.trim(),
      _selectedProvince!.name,
      _selectedDistrict!.name,
      _selectedWard!.name,
      _detailedAddressController.text.trim(),
      _saveAsDefault,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: AppColors.background,
                elevation: 0,
                scrolledUnderElevation: 0,
                leading: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                centerTitle: true,
                title: const Text(
                  "Thông tin giao hàng",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
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

                      const _SectionLabel(text: "ĐỊA CHỈ GIAO HÀNG"),
                      const SizedBox(height: 10),
                      _buildSelector(
                        label: _selectedProvince?.name ?? '',
                        hint: "Tỉnh / Thành phố",
                        icon: LucideIcons.map,
                        onTap: () {
                          final provinces = VietnamProvinces.getProvinces();
                          _showSearchSelectorSheet<Province>(
                            title: "Chọn Tỉnh / Thành phố",
                            items: provinces,
                            getName: (p) => p.name,
                            onSelect: (p) {
                              setState(() {
                                _selectedProvince = p;
                                _selectedDistrict = null;
                                _selectedWard = null;
                              });
                              _syncDropdownsToMap();
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      _buildSelector(
                        label: _selectedDistrict?.name ?? '',
                        hint: "Quận / Huyện",
                        icon: LucideIcons.mapPin,
                        enabled: _selectedProvince != null,
                        onTap: () {
                          final districts = VietnamProvinces.getDistricts(
                            provinceCode: _selectedProvince!.code,
                          );
                          _showSearchSelectorSheet<District>(
                            title: "Chọn Quận / Huyện",
                            items: districts,
                            getName: (d) => d.name,
                            onSelect: (d) {
                              setState(() {
                                _selectedDistrict = d;
                                _selectedWard = null;
                              });
                              _syncDropdownsToMap();
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      _buildSelector(
                        label: _selectedWard?.name ?? '',
                        hint: "Phường / Xã",
                        icon: LucideIcons.navigation,
                        enabled: _selectedDistrict != null,
                        onTap: () {
                          final wards = VietnamProvinces.getWards(
                            provinceCode: _selectedProvince!.code,
                            districtCode: _selectedDistrict!.code,
                          );
                          _showSearchSelectorSheet<Ward>(
                            title: "Chọn Phường / Xã",
                            items: wards,
                            getName: (w) => w.name,
                            onSelect: (w) {
                              setState(() {
                                _selectedWard = w;
                              });
                              _syncDropdownsToMap();
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      _buildTextField(
                        _detailedAddressController,
                        "Số nhà, ngõ, tên đường...",
                        LucideIcons.house,
                      ),

                      const SizedBox(height: 16),

                      // Interactive Dark Map View
                      Container(
                        height: 220,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.borderCardStrong,
                            width: 0.5,
                          ),
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
                                          _parseGeocodedAddress(address);
                                        }
                                      },
                                    );
                                  },
                                );

                                // Pan to initial location if available
                                Future.delayed(
                                  const Duration(milliseconds: 1200),
                                  () {
                                    _syncDropdownsToMap();
                                  },
                                );
                              },
                            ),
                            Positioned(
                              bottom: 12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.cardSurfaceAlt.withValues(
                                    alpha: 0.85,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.borderCardStrong,
                                    width: 0.5,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      LucideIcons.move,
                                      size: 12,
                                      color: AppColors.slate400,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Kéo bản đồ để ghim vị trí',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.slate400,
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

                      const SizedBox(height: 24),

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
                            color: AppColors.cardSurfaceAlt,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.borderCardStrong,
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: _saveAsDefault
                                      ? AppColors.champagne
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: _saveAsDefault
                                        ? AppColors.champagne
                                        : AppColors.textDim,
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
                                  color: AppColors.slate400,
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
                color: AppColors.background,
                border: Border(
                  top: BorderSide(
                    color: AppColors.borderCardStrong,
                    width: 0.5,
                  ),
                ),
              ),
              child: GestureDetector(
                onTap: _handleSave,
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.champagne,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.champagne.withValues(alpha: 0.3),
                        blurRadius: 5,
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
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurfaceAltAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderCardStrong, width: 0.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          icon: Icon(icon, size: 18, color: AppColors.textDim),
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textDim, fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildSelector({
    required String label,
    required String hint,
    required IconData icon,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.cardSurfaceAltAlt,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderCardStrong, width: 0.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.textDim),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label.isNotEmpty ? label : hint,
                  style: TextStyle(
                    color: label.isNotEmpty
                        ? AppColors.textPrimary
                        : AppColors.textDim,
                    fontSize: 14,
                  ),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: AppColors.textDim,
              ),
            ],
          ),
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
            color: AppColors.champagne,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.textDim,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}
