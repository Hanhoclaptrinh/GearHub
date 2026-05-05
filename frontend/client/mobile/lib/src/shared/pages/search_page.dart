import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/src/core/di/injection.dart';
import 'package:mobile/src/features/explore/domain/repositories/explore_repository.dart';
import 'package:mobile/src/features/home/data/datasources/home_remote_datasource.dart';
import 'package:mobile/src/shared/models/product_model.dart';
import 'package:mobile/src/features/home/presentation/widgets/search_history_tags_widget.dart';
import 'package:mobile/src/features/home/presentation/widgets/search_suggestion_item.dart';
import 'package:mobile/src/features/home/presentation/widgets/search_product_grid.dart';
import 'package:mobile/src/shared/widgets/product_filter_drawer.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF9FAFB),
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
          color: Colors.white,
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      onChanged: _onSearchChanged,
                      onSubmitted: (_) => _executeFullSearch(),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          LucideIcons.search,
                          size: 18,
                          color: Color(0xFF9CA3AF),
                        ),
                        suffixIcon: _controller.text.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  _controller.clear();
                                  _onSearchChanged('');
                                },
                                child: const Icon(
                                  LucideIcons.x,
                                  size: 18,
                                  color: Color(0xFF6B7280),
                                ),
                              )
                            : null,
                        hintText: 'Tìm kiếm sản phẩm...',
                        hintStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF9CA3AF),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
            )
          : _isFullSearchMode
          ? SearchProductGrid(
              searchResults: _searchResults,
              onShowFilters: () => _scaffoldKey.currentState?.openEndDrawer(),
            )
          : _buildSearchSuggestions(),
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
              const Row(
                children: [
                  Icon(LucideIcons.flame, size: 16, color: Colors.orange),
                  SizedBox(width: 8),
                  Text(
                    'Sản phẩm gợi ý',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0A0A0F),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_suggestions.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Không tìm thấy sản phẩm gợi ý nào.',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _suggestions.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 14),
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
