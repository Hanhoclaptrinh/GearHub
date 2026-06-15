import 'package:mobile/src/features/preferences/data/datasources/preferences_local_datasource.dart';
import 'package:mobile/src/features/preferences/data/datasources/preferences_remote_datasource.dart';
import 'package:mobile/src/features/preferences/domain/entities/shopping_preferences.dart';
import 'package:mobile/src/features/preferences/domain/repositories/preferences_repository.dart';

class PreferencesRepositoryImpl implements PreferencesRepository {
  final PreferencesRemoteDatasource _remoteDatasource;
  final PreferencesLocalDatasource _localDatasource;

  PreferencesRepositoryImpl({
    required PreferencesRemoteDatasource remoteDatasource,
    required PreferencesLocalDatasource localDatasource,
  }) : _remoteDatasource = remoteDatasource,
       _localDatasource = localDatasource;

  @override
  Future<ShoppingPreferences> getPreferences() {
    return _remoteDatasource.getPreferences();
  }

  @override
  Future<ShoppingPreferences> savePreferences(ShoppingPreferences preferences) {
    return _remoteDatasource.updatePreferences(preferences, completed: true);
  }

  @override
  Future<ShoppingPreferences> skipOnboarding() {
    return _remoteDatasource.updatePreferences(
      const ShoppingPreferences(),
      skipped: true,
    );
  }

  @override
  bool shouldShowOnboarding({
    required String userId,
    required ShoppingPreferences? preferences,
  }) {
    if (_localDatasource.hasSeenOnboarding(userId)) return false;
    return preferences?.shouldAskOnboarding ?? true;
  }

  @override
  Future<void> markOnboardingSeen(String userId) {
    return _localDatasource.markOnboardingSeen(userId);
  }
}
