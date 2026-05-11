import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/core/di/injection.dart';
import 'package:mobile/src/features/explore/domain/repositories/explore_repository.dart';
import 'package:mobile/src/features/home/data/datasources/home_remote_datasource.dart';
import 'package:mobile/src/shared/models/product_model.dart';
import 'package:mobile/src/features/home/data/models/category_model.dart';
import 'package:mobile/src/features/home/presentation/widgets/search_history_tags_widget.dart';
import 'package:mobile/src/features/home/presentation/widgets/search_suggestion_item.dart';
import 'package:mobile/src/features/home/presentation/widgets/search_product_grid.dart';
import 'package:mobile/src/shared/widgets/product_filter_drawer.dart';
import 'package:mobile/src/shared/widgets/voice_search_modal.dart';
import 'package:mobile/src/shared/widgets/image_search_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

const _bg = Color(0xFF07070A);
const _surfaceAlt = Color(0xFF1C1C28);
const _border = Color(0xFF2A2A38);
const _accent = Color(0xFF6366F1);
const _accentSoft = Color(0x186366F1);
const _textHigh = Color(0xFFF1F1F5);
const _textMid = Color(0xFF9191A8);
const _textLow = Color(0xFF4A4A62);

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _controller = TextEditingController();
  Timer? _debounceTimer;
  bool _isLoading = false;
  List<ProductModel> _suggestions = [];
  bool _isFullSearchMode = false;
  List<ProductModel> _searchResults = [];

  // Category matching
  List<CategoryModel> _allCategories = [];
  List<CategoryModel> _matchedCategories = [];

  // Advanced search state
  File? _selectedImage;
  bool _isAnalyzingImage = false;

  // filtering/sorting state
  String _sortBy = ''; // 'price_asc' | 'price_desc'
  double? _minPrice;
  double? _maxPrice;

  // recent searches
  List<String> _searchHistory = [];

  // rcm search keywords
  List<String> _popularKeywords = [];

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    _loadPopularKeywords();
    _loadAllCategories();
  }

  void _loadAllCategories() async {
    try {
      final datasource = getIt<HomeRemoteDatasource>();
      final categories = await datasource.getParentCategories();
      setState(() {
        _allCategories = categories;
      });
    } catch (e) {
      debugPrint('[Search] Error loading categories: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _loadSearchHistory() {
    final prefs = getIt<SharedPreferences>();
    setState(() {
      _searchHistory = prefs.getStringList('recent_searches') ?? [];
    });
  }

  void _loadPopularKeywords() async {
    try {
      final datasource = getIt<HomeRemoteDatasource>();
      final List<String> keywords = [];

      // fetch top brands
      final brands = await datasource.getTopBrands();
      if (brands.isNotEmpty) {
        keywords.addAll(brands.map((b) => b.name).take(4));
      }

      // fetch top categories
      final categories = await datasource.getTopCategories();
      if (categories.isNotEmpty) {
        keywords.addAll(categories.map((c) => c.title).take(4));
      }

      if (keywords.isNotEmpty) {
        setState(() {
          _popularKeywords = keywords;
        });
      } else {
        // fallback
        setState(() {
          _popularKeywords = ['iPhone', 'Macbook', 'Màn hình', 'Bàn phím'];
        });
      }
    } catch (e) {
      debugPrint('[Search] Error loading popular keywords: $e');
      setState(() {
        _popularKeywords = ['iPhone', 'Macbook', 'Màn hình', 'Bàn phím'];
      });
    }
  }

  // luu tu khoa timkiem vao local storage
  Future<void> _saveSearchKeyword(String keyword) async {
    final cleanKeyword = keyword.trim();
    if (cleanKeyword.isEmpty) return;

    final prefs = getIt<SharedPreferences>();
    List<String> current = prefs.getStringList('recent_searches') ?? [];
    current.remove(cleanKeyword);
    current.insert(0, cleanKeyword);

    if (current.length > 10) {
      current = current.sublist(0, 10);
    }

    await prefs.setStringList('recent_searches', current);
    setState(() {
      _searchHistory = current;
    });
  }

  Future<void> _clearSearchHistory() async {
    final prefs = getIt<SharedPreferences>();
    await prefs.remove('recent_searches');
    setState(() {
      _searchHistory = [];
    });
  }

  // xoa lich su tim kiem
  Future<void> _removeKeywordFromHistory(String keyword) async {
    final prefs = getIt<SharedPreferences>();
    List<String> current = prefs.getStringList('recent_searches') ?? [];
    current.remove(keyword);
    await prefs.setStringList('recent_searches', current);
    setState(() {
      _searchHistory = current;
    });
  }

  void _onSearchChanged(String val) {
    if (_isFullSearchMode) {
      setState(() {
        _isFullSearchMode = false;
      });
    }

    if (val.trim().isEmpty) {
      setState(() {
        _suggestions = [];
      });
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _fetchSuggestions(val.trim());
      _matchCategories(val.trim());
    });
  }

  void _matchCategories(String query) {
    if (query.isEmpty) {
      setState(() => _matchedCategories = []);
      return;
    }
    final matches = _allCategories
        .where((c) => c.title.toLowerCase().contains(query.toLowerCase()))
        .take(3)
        .toList();
    setState(() => _matchedCategories = matches);
  }

  Future<void> _fetchSuggestions(String query) async {
    if (query.isEmpty) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final repository = getIt<ExploreRepository>();
      final items = await repository.getProducts(search: query, limit: 6);
      setState(() {
        _suggestions = items;
      });
    } catch (e) {
      debugPrint('[Search] Suggestion error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _executeFullSearch({String? keyword}) async {
    if (keyword != null) {
      _controller.text = keyword;
    }
    final q = _controller.text.trim();
    if (q.isEmpty) return;

    _debounceTimer?.cancel();
    _saveSearchKeyword(q);

    setState(() {
      _isLoading = true;
      _isFullSearchMode = true;
      // reset filter tranh xung dot
      if (keyword != null || _controller.text != q) {
        _minPrice = null;
        _maxPrice = null;
        _sortBy = '';
      }
      _searchResults = [];
      _suggestions = [];
    });

    try {
      final repository = getIt<ExploreRepository>();
      List<ProductModel> items = await repository.getProducts(
        search: q,
        limit: 40,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
      );

      if (_sortBy == 'price_asc') {
        items.sort((a, b) => a.price.compareTo(b.price));
      } else if (_sortBy == 'price_desc') {
        items.sort((a, b) => b.price.compareTo(a.price));
      }

      setState(() {
        _searchResults = items;
      });
    } catch (e) {
      debugPrint('[Search] Error executing search: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _openVoiceSearch() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'VoiceSearch',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => VoiceSearchModal(
        onResult: (text) {
          Navigator.pop(context);
          _executeFullSearch(keyword: text);
        },
      ),
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOut),
            ),
            child: child,
          ),
        );
      },
    );
  }

  Future<void> _openImageSearch() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _isAnalyzingImage = true;
      });

      // Gia lap thoi gian phan tich anh
      await Future.delayed(const Duration(seconds: 3));

      if (mounted) {
        setState(() {
          _isAnalyzingImage = false;
        });

        // Mo phong tim kiem: Tim kiem cac san pham thuoc hang 'Apple' hoac 'Sony'
        _executeFullSearch(keyword: 'Apple');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: _bg,
        endDrawer: ProductFilterDrawer(
          initialMinPrice: _minPrice,
          initialMaxPrice: _maxPrice,
          initialSortBy: _sortBy.isEmpty ? 'newest' : _sortBy,
          onApply: (min, max, sort) {
            setState(() {
              _minPrice = min;
              _maxPrice = max;
              _sortBy = sort;
            });
            _executeFullSearch();
          },
        ),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(74),
          child: Container(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: _surfaceAlt,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _border),
                      ),
                      child: TextField(
                        controller: _controller,
                        autofocus: true,
                        style: const TextStyle(color: _textHigh, fontSize: 15),
                        textInputAction: TextInputAction.search,
                        onChanged: _onSearchChanged,
                        onSubmitted: (_) => _executeFullSearch(),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            LucideIcons.search,
                            size: 18,
                            color: _textMid,
                          ),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_controller.text.isNotEmpty)
                                GestureDetector(
                                  onTap: () {
                                    _controller.clear();
                                    _onSearchChanged('');
                                  },
                                  child: const Icon(
                                    LucideIcons.x,
                                    size: 18,
                                    color: _textMid,
                                  ),
                                )
                              else ...[
                                GestureDetector(
                                  onTap: _openVoiceSearch,
                                  child: const Icon(
                                    LucideIcons.mic,
                                    size: 18,
                                    color: _textMid,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                GestureDetector(
                                  onTap: _openImageSearch,
                                  child: const Icon(
                                    LucideIcons.camera,
                                    size: 18,
                                    color: _textMid,
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                            ],
                          ),
                          hintText: 'Tìm kiếm sản phẩm...',
                          hintStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _textLow,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            _isLoading
                ? const Center(child: CircularProgressIndicator(color: _accent))
                : _isFullSearchMode
                ? SearchProductGrid(
                    searchResults: _searchResults,
                    currentSortBy: _sortBy,
                    onSortChanged: (sort) {
                      setState(() => _sortBy = sort);
                      _executeFullSearch();
                    },
                    onShowFilters: () =>
                        _scaffoldKey.currentState?.openEndDrawer(),
                  )
                : _buildSearchSuggestions(),
            if (_isAnalyzingImage && _selectedImage != null)
              ImageSearchOverlay(imageFile: _selectedImage!),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSuggestions() {
    final query = _controller.text.trim();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (query.isEmpty)
              SearchHistoryTagsWidget(
                searchHistory: _searchHistory,
                popularKeywords: _popularKeywords,
                onClearAllHistory: _clearSearchHistory,
                onRemoveHistoryItem: _removeKeywordFromHistory,
                onSearchKeyword: (k) => _executeFullSearch(keyword: k),
              ),
            if (query.isNotEmpty) ...[
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: _accentSoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.flame,
                      size: 14,
                      color: _accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Sản phẩm gợi ý',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: _textHigh,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_matchedCategories.isNotEmpty) ...[
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _matchedCategories.map((c) {
                    return GestureDetector(
                      onTap: () => _executeFullSearch(keyword: c.title),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _accentSoft,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: _accent.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              LucideIcons.layoutGrid,
                              size: 14,
                              color: _accent,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              c.title,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ],
              const SizedBox(height: 4),
              if (_suggestions.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(LucideIcons.searchX, size: 48, color: _textLow),
                        SizedBox(height: 16),
                        Text(
                          'Không tìm thấy sản phẩm gợi ý nào.',
                          style: TextStyle(color: _textMid, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _suggestions.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final p = _suggestions[index];
                    return SearchSuggestionItem(product: p);
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }
}
