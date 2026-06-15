import 'package:dio/dio.dart';
import 'package:mobile/src/features/preferences/data/models/shopping_preferences_model.dart';
import 'package:mobile/src/features/preferences/domain/entities/shopping_preferences.dart';

class PreferencesRemoteDatasource {
  final Dio _dio;

  PreferencesRemoteDatasource({required Dio dio}) : _dio = dio;

  Future<ShoppingPreferencesModel> getPreferences() async {
    final response = await _dio.get('/users/preferences');
    return ShoppingPreferencesModel.fromJson(
      response.data as Map<String, dynamic>?,
    );
  }

  Future<ShoppingPreferencesModel> updatePreferences(
    ShoppingPreferences preferences, {
    bool completed = false,
    bool skipped = false,
  }) async {
    final payload = ShoppingPreferencesModel.fromEntity(
      preferences,
    ).toJson(completed: completed, skipped: skipped);

    final response = await _dio.patch('/users/preferences', data: payload);
    return ShoppingPreferencesModel.fromJson(
      response.data as Map<String, dynamic>?,
    );
  }
}
