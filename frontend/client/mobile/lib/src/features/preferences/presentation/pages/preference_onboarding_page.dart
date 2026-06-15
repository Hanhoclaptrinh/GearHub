import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/src/core/di/injection.dart';
import 'package:mobile/src/features/explore/domain/repositories/explore_repository.dart';
import 'package:mobile/src/features/home/domain/entities/category_entity.dart';
import 'package:mobile/src/features/home/domain/entities/brand_entity.dart';
import 'package:mobile/src/features/home/domain/repositories/home_repository.dart';
import 'package:mobile/src/features/home/presentation/pages/main_screen.dart';
import 'package:mobile/src/features/preferences/presentation/widgets/category_onboarding_step.dart';
import 'package:mobile/src/features/preferences/presentation/widgets/brand_onboarding_step.dart';
import 'package:mobile/src/features/preferences/presentation/widgets/style_onboarding_step.dart';
import 'package:mobile/src/features/preferences/presentation/state/preferences_cubit.dart';
import 'package:mobile/src/features/preferences/domain/entities/shopping_preferences.dart';
import 'package:mobile/src/features/preferences/data/models/shopping_preferences_model.dart';
import 'package:mobile/src/features/auth/presentation/state/auth_cubit.dart';
import 'package:mobile/src/features/auth/presentation/state/auth_state.dart';
import 'package:mobile/src/features/preferences/presentation/widgets/use_case_onboarding_step.dart';
import 'package:mobile/src/features/preferences/presentation/widgets/budget_onboarding_step.dart';
import 'package:mobile/src/features/preferences/presentation/widgets/onboarding_progress_dialog.dart';

class PreferenceOnboardingPage extends StatefulWidget {
  const PreferenceOnboardingPage({super.key});

  @override
  State<PreferenceOnboardingPage> createState() =>
      _PreferenceOnboardingPageState();
}

class _PreferenceOnboardingPageState extends State<PreferenceOnboardingPage> {
  int _currentStep = 1;
  final int _totalSteps = 5;

  //categories selection state
  List<CategoryEntity> _categories = [];
  final Set<String> _selectedCategoryIds = {};
  bool _isLoadingCategories = true;

  //brands selection state
  List<BrandEntity> _brands = [];
  final Set<String> _selectedBrandIds = {};
  bool _isLoadingBrands = true;

  //styles selection state
  final Set<String> _selectedStyleTags = {};

  //use cases selection state
  final Set<String> _selectedUseCases = {};

  //budget selection state
  int? _budgetMin;
  int? _budgetMax;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadBrands();
  }

  Future<void> _loadCategories() async {
    try {
      final repo = getIt<ExploreRepository>();
      final categories = await repo.getParentCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể tải danh mục sản phẩm')),
        );
      }
    }
  }

  Future<void> _loadBrands() async {
    try {
      final repo = getIt<HomeRepository>();
      final allBrands = await repo.getBrands();
      final activeBrands = allBrands.where((b) => b.isActive ?? true).toList();
      if (mounted) {
        setState(() {
          _brands = activeBrands;
          _isLoadingBrands = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingBrands = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể tải danh sách thương hiệu')),
        );
      }
    }
  }

  void _nextStep() {
    if (_currentStep < _totalSteps) {
      setState(() {
        _currentStep++;
      });
    } else {
      _finishOnboarding();
    }
  }

  void _prevStep() {
    if (_currentStep > 1) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _skipOnboarding() {
    //chuyển thẳng về trang cuối
    setState(() {
      _currentStep = _totalSteps;
    });
  }

  void _finishOnboarding() {
    final authState = context.read<AuthCubit>().state;
    final preferences = ShoppingPreferences(
      categoryIds: _selectedCategoryIds.toList(),
      brandIds: _selectedBrandIds.toList(),
      styleTags: _selectedStyleTags.toList(),
      useCases: _selectedUseCases.toList(),
      budgetRange: BudgetRangePreference(min: _budgetMin, max: _budgetMax),
    );

    if (authState is AuthAuthenticated) {
      final userId = authState.user.id;
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: .5),
        builder: (dialogContext) {
          return OnboardingProgressDialog(
            onSaveAction: () async {
              await context.read<PreferencesCubit>().save(
                userId: userId,
                preferences: preferences,
              );
              final prefs = getIt<SharedPreferences>();
              await prefs.setBool('pref_onboarding_processed', true);
            },
            onFinish: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const MainScreen()),
              );
            },
          );
        },
      );
    } else {
      //lưu prefer vào local nếu chưa auth
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: .5),
        builder: (dialogContext) {
          return OnboardingProgressDialog(
            onSaveAction: () async {
              final prefs = getIt<SharedPreferences>();
              final prefJson = jsonEncode(
                ShoppingPreferencesModel.fromEntity(preferences).toJson(),
              );
              await prefs.setString('local_shopping_preferences', prefJson);
              await prefs.setBool('pref_onboarding_processed', true);
              await Future.delayed(const Duration(seconds: 2));
            },
            onFinish: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const MainScreen()),
              );
            },
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                clipBehavior: Clip.none,
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 30.0, bottom: 8.0),
                        child: _buildHeader(theme),
                      ),

                      //step content
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: _buildStepContent(theme),
                      ),

                      const SizedBox(height: 150),
                    ],
                  ),
                ),
              ),
            ),
            //footer
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: theme.scaffoldBackgroundColor,
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom,
                ),
                child: _buildFooterButton(theme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Stack(
        children: [
          if (_currentStep > 1)
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: theme.colorScheme.onSurface,
                  size: 22,
                ),
                onPressed: _prevStep,
              ),
            ),
          Align(
            alignment: Alignment.center,
            child: Text(
              '$_currentStep / $_totalSteps',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withValues(alpha: .6),
              ),
            ),
          ),
          if (_currentStep < _totalSteps)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _skipOnboarding,
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurface.withValues(
                    alpha: .8,
                  ),
                ),
                child: Text(
                  'Bỏ qua',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepContent(ThemeData theme) {
    switch (_currentStep) {
      case 1:
        return CategoryOnboardingStep(
          categories: _categories,
          selectedCategoryIds: _selectedCategoryIds,
          onCategoryToggled: (id) {
            setState(() {
              if (_selectedCategoryIds.contains(id)) {
                _selectedCategoryIds.remove(id);
              } else {
                _selectedCategoryIds.add(id);
              }
            });
          },
          isLoading: _isLoadingCategories,
        );
      case 2:
        return BrandOnboardingStep(
          brands: _brands,
          selectedBrandIds: _selectedBrandIds,
          onBrandToggled: (id) {
            setState(() {
              if (_selectedBrandIds.contains(id)) {
                _selectedBrandIds.remove(id);
              } else {
                _selectedBrandIds.add(id);
              }
            });
          },
          isLoading: _isLoadingBrands,
        );
      case 3:
        return StyleOnboardingStep(
          selectedStyleTags: _selectedStyleTags,
          onStyleToggled: (tag) {
            setState(() {
              if (_selectedStyleTags.contains(tag)) {
                _selectedStyleTags.remove(tag);
              } else {
                _selectedStyleTags.add(tag);
              }
            });
          },
        );
      case 4:
        return UseCaseOnboardingStep(
          selectedUseCases: _selectedUseCases,
          onUseCaseToggled: (tag) {
            setState(() {
              if (_selectedUseCases.contains(tag)) {
                _selectedUseCases.remove(tag);
              } else {
                _selectedUseCases.add(tag);
              }
            });
          },
        );
      case 5:
        return BudgetOnboardingStep(
          currentMinPrice: _budgetMin,
          currentMaxPrice: _budgetMax,
          onBudgetChanged: (min, max) {
            setState(() {
              _budgetMin = min;
              _budgetMax = max;
            });
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildFooterButton(ThemeData theme) {
    final isLastStep = _currentStep == _totalSteps;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          onPressed: _nextStep,
          child: Text(
            isLastStep ? 'Hoàn thành' : 'Tiếp theo',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
