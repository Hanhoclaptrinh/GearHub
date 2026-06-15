import 'dart:async';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/core/theme/app_colors.dart';
import 'package:mobile/src/core/theme/app_theme.dart';
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

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _detailedAddressFocus = FocusNode();

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

    _nameFocus.addListener(() => setState(() {}));
    _phoneFocus.addListener(() => setState(() {}));
    _detailedAddressFocus.addListener(() => setState(() {}));

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
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _detailedAddressFocus.dispose();
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

  ///phân tích chuỗi địa chỉ geocoded thành các thành phần tỉnh, huyện, xã
  ///tự động cập nhật vào các biến trạng thái tương ứng
  void _parseGeocodedAddress(String address) {
    //thoát nếu địa chỉ rỗng
    if (address.isEmpty) return;

    try {
      //tách chuỗi thành các thành phần và loại bỏ khoảng trắng thừa
      final parts = address.split(',').map((p) => p.trim()).toList();

      if (parts.isNotEmpty && parts.last.toLowerCase() == 'việt nam') {
        parts.removeLast();
      }

      //nếu không đủ thành phần phân cấp thì gán trực tiếp vào địa chỉ chi tiết
      if (parts.length < 3) {
        _detailedAddressController.text = parts.join(', ');
        return;
      }

      //lấy các thành phần tỉnh, huyện, xã từ cuối danh sách
      final provincePart = parts.removeLast();
      final districtPart = parts.removeLast();
      final wardPart = parts.removeLast();

      //tìm kiếm tỉnh trong db
      final province = _findProvince(provincePart);
      if (province != null) {
        //tìm kiếm huyện thuộc tỉnh
        final district = _findDistrict(province, districtPart);
        if (district != null) {
          //tìm kiếm xã thuộc huyện
          final ward = _findWard(province, district, wardPart);

          //cập nhật trạng thái và địa chỉ chi tiết còn lại
          setState(() {
            _selectedProvince = province;
            _selectedDistrict = district;
            _selectedWard = ward;
            _detailedAddressController.text = parts.join(', ');
          });
          return;
        }
      }

      //fallback nếu không tìm thấy phân cấp hành chính chính xác
      _detailedAddressController.text = address;
    } catch (e) {
      //ghi log lỗi và giữ nguyên địa chỉ gốc
      debugPrint('error parsing geocoded address: $e');
      _detailedAddressController.text = address;
    }
  }

  ///thực hiện truy vấn ngược để lấy địa chỉ từ tọa độ
  ///api nominatim openstreetmap và trả về địa chỉ định dạng chuỗi
  Future<String> _reverseGeocode(double lat, double lng) async {
    try {
      final dio = dio_pkg.Dio();

      //api reverse geocoding
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

    //trả về tọa độ dưới dạng chuỗi nếu không lấy được địa chỉ
    return '$lat, $lng';
  }

  ///thực hiện truy vấn tìm tọa độ từ chuỗi địa chỉ
  ///api nominatim openstreetmap và trả về map chứa lat và lng
  Future<Map<String, double>?> _forwardGeocode(String address) async {
    try {
      final dio = dio_pkg.Dio();

      //api forward geocoding
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

      //kiểm tra phản hồi và trích xuất tọa độ
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

    //trả về null nếu không tìm thấy tọa độ
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
        final theme = Theme.of(context);
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
            final isDark = theme.brightness == Brightness.dark;
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              margin: EdgeInsets.only(bottom: keyboardHeight),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0C0C10)
                    : theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outlineVariant,
                    width: 1.0,
                  ),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  //handle bar
                  Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.3,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  //search box
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF161622)
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                          width: 0.8,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        autofocus: true,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm nhanh...',
                          hintStyle: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.6),
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          icon: Icon(
                            LucideIcons.search,
                            size: 16,
                            color: isDark
                                ? AppColors.champagne
                                : theme.colorScheme.primary,
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
                  const SizedBox(height: 16),
                  //list
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
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF14141E)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant,
                              width: 0.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: .02),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 2,
                            ),
                            title: Text(
                              name,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 12,
                              color: isDark
                                  ? AppColors.champagne
                                  : theme.colorScheme.primary,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            onTap: () {
                              onSelect(item);
                              Navigator.pop(context);
                            },
                          ),
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
    final theme = Theme.of(context);
    if (_nameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _selectedProvince == null ||
        _selectedDistrict == null ||
        _selectedWard == null ||
        _detailedAddressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: theme.colorScheme.danger,
          content: const Text(
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
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: theme.scaffoldBackgroundColor,
                elevation: 0,
                scrolledUnderElevation: 0,
                leading: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: theme.colorScheme.onSurface,
                    size: 22,
                  ),
                ),
                centerTitle: true,
                title: Text(
                  "Thông tin giao hàng",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
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
                        context,
                        _nameController,
                        _nameFocus,
                        "Họ và tên",
                        LucideIcons.user,
                      ),
                      const SizedBox(height: 10),
                      _buildTextField(
                        context,
                        _phoneController,
                        _phoneFocus,
                        "Số điện thoại",
                        LucideIcons.phone,
                        keyboardType: TextInputType.phone,
                      ),

                      const SizedBox(height: 28),

                      const _SectionLabel(text: "ĐỊA CHỈ GIAO HÀNG"),
                      const SizedBox(height: 10),
                      _buildSelector(
                        context,
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
                        context,
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
                        context,
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
                        context,
                        _detailedAddressController,
                        _detailedAddressFocus,
                        "Số nhà, ngõ, tên đường...",
                        LucideIcons.house,
                      ),
                      const SizedBox(height: 16),
                      //map view
                      Container(
                        height: 230,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant,
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: .06),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
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
                                data: _getMapHtml(
                                  theme.brightness == Brightness.dark,
                                ),
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
                                Future.delayed(
                                  const Duration(milliseconds: 1200),
                                  () {
                                    _syncDropdownsToMap();
                                  },
                                );
                              },
                            ),
                            //gps tag
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: .75),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF22C55E,
                                    ).withValues(alpha: .2),
                                    width: 0.5,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'GPS ACTIVE',
                                      style: TextStyle(
                                        color: Color(0xFF22C55E),
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            //map drag
                            Positioned(
                              bottom: 12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.brightness == Brightness.dark
                                      ? const Color(
                                          0xFF14141E,
                                        ).withValues(alpha: .9)
                                      : Colors.white.withValues(alpha: .9),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: theme.colorScheme.outlineVariant,
                                    width: 0.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      LucideIcons.move,
                                      size: 12,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Kéo bản đồ để ghim vị trí',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w700,
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
                          HapticFeedback.selectionClick();
                          setState(() => _saveAsDefault = !_saveAsDefault);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: _saveAsDefault
                                ? (isDark
                                      ? AppColors.champagne.withValues(
                                          alpha: 0.05,
                                        )
                                      : theme.colorScheme.primary.withValues(
                                          alpha: 0.03,
                                        ))
                                : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _saveAsDefault
                                  ? (isDark
                                        ? AppColors.champagne
                                        : theme.colorScheme.primary)
                                  : theme.colorScheme.outlineVariant,
                              width: _saveAsDefault ? 1.0 : 0.8,
                            ),
                          ),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: _saveAsDefault
                                      ? (isDark
                                            ? AppColors.champagne
                                            : theme.colorScheme.primary)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: _saveAsDefault
                                        ? (isDark
                                              ? AppColors.champagne
                                              : theme.colorScheme.primary)
                                        : theme.colorScheme.onSurfaceVariant
                                              .withValues(alpha: 0.6),
                                    width: 1.5,
                                  ),
                                ),
                                child: _saveAsDefault
                                    ? Icon(
                                        Icons.check,
                                        size: 13,
                                        color: isDark
                                            ? Colors.black
                                            : Colors.white,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "Lưu làm địa chỉ mặc định",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: _saveAsDefault
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  color: _saveAsDefault
                                      ? theme.colorScheme.onSurface
                                      : theme.colorScheme.onSurfaceVariant,
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
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outlineVariant,
                    width: 0.8,
                  ),
                ),
              ),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _handleSave();
                },
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.15)
                          : Colors.black.withValues(alpha: 0.08),
                      width: 0.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      "XÁC NHẬN ĐỊA CHỈ",
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 0.8,
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
    BuildContext context,
    TextEditingController controller,
    FocusNode focusNode,
    String hint,
    IconData icon, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isFocused = focusNode.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isFocused
            ? (isDark ? const Color(0xFF161622) : Colors.white)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFocused
              ? (isDark ? AppColors.champagne : theme.colorScheme.primary)
              : theme.colorScheme.outlineVariant,
          width: isFocused ? 1.2 : 0.8,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color:
                      (isDark ? AppColors.champagne : theme.colorScheme.primary)
                          .withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isFocused
                  ? (isDark
                        ? AppColors.champagne.withValues(alpha: 0.12)
                        : theme.colorScheme.primary.withValues(alpha: 0.08))
                  : (isDark
                        ? const Color(0xFF20202A)
                        : theme.colorScheme.outlineVariant.withValues(
                            alpha: 0.25,
                          )),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 14,
              color: isFocused
                  ? (isDark ? AppColors.champagne : theme.colorScheme.primary)
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          hintText: hint,
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.65),
            fontSize: 13,
            fontWeight: FontWeight.normal,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildSelector(
    BuildContext context, {
    required String label,
    required String hint,
    required IconData icon,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasValue = label.isNotEmpty;

    return Opacity(
      opacity: enabled ? 1.0 : 0.55,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasValue
                  ? (isDark
                        ? AppColors.champagne.withValues(alpha: 0.35)
                        : theme.colorScheme.primary.withValues(alpha: 0.3))
                  : theme.colorScheme.outlineVariant,
              width: 0.8,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: hasValue
                      ? (isDark
                            ? AppColors.champagne.withValues(alpha: 0.08)
                            : theme.colorScheme.primary.withValues(alpha: 0.05))
                      : (isDark
                            ? const Color(0xFF20202A)
                            : theme.colorScheme.outlineVariant.withValues(
                                alpha: 0.25,
                              )),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 14,
                  color: hasValue
                      ? (isDark
                            ? AppColors.champagne
                            : theme.colorScheme.primary)
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hasValue ? label : hint,
                  style: TextStyle(
                    color: hasValue
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.65,
                          ),
                    fontSize: 14,
                    fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMapHtml(bool isDark) {
    final bgColor = isDark ? '#0A0A10' : '#F8F9FC';
    final tileUrl = isDark
        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
        : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png';
    final pinStroke = isDark ? '#0A0A10' : '#FFFFFF';
    final pinFill = isDark ? '#D8B76A' : '#1A1D26';

    return """
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
      <style>
        body { margin: 0; padding: 0; background: $bgColor; position: relative; }
        #map { height: 100vh; width: 100vw; }
        .center-pin {
          position: absolute;
          top: 50%;
          left: 50%;
          transform: translate(-50%, -100%);
          z-index: 1000;
          pointer-events: none;
        }
        @keyframes radar-pulse {
          0% {
            transform: translate(-50%, -50%) scale(0.2);
            opacity: 0.8;
          }
          100% {
            transform: translate(-50%, -50%) scale(1.6);
            opacity: 0;
          }
        }
        .radar-ring {
          position: absolute;
          top: 50%;
          left: 50%;
          transform: translate(-50%, -50%);
          width: 50px;
          height: 50px;
          border: 3px solid $pinFill;
          border-radius: 50%;
          animation: radar-pulse 2.2s infinite ease-out;
          pointer-events: none;
          z-index: 999;
        }
        .leaflet-control-attribution { display: none !important; }
      </style>
    </head>
    <body>
      <div class="radar-ring"></div>
      <div class="center-pin">
        <svg width="36" height="36" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
          <path d="M12 2C8.13 2 5 5.13 5 9C5 14.25 12 22 12 22C12 22 19 14.25 19 9C19 5.13 15.87 2 12 2Z" fill="$pinFill" stroke="$pinStroke" stroke-width="2"/>
          <circle cx="12" cy="9" r="3" fill="$pinStroke"/>
        </svg>
      </div>
      <div id="map"></div>
      <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
      <script>
        var map = L.map('map', { zoomControl: false }).setView([21.028511, 105.804817], 14);
        L.tileLayer('$tileUrl', {
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
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w900,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 0.5,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }
}
