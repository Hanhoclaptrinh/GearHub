import 'package:mobile/src/features/preferences/domain/entities/shopping_preferences.dart';

abstract class PreferencesRepository {
  Future<ShoppingPreferences> getPreferences();

  Future<ShoppingPreferences> savePreferences(ShoppingPreferences preferences);

  Future<ShoppingPreferences> skipOnboarding();

  bool shouldShowOnboarding({
    required String userId,
    required ShoppingPreferences? preferences,
  });

  Future<void> markOnboardingSeen(String userId);
}
