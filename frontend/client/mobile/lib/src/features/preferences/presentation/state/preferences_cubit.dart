import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/src/features/preferences/domain/entities/shopping_preferences.dart';
import 'package:mobile/src/features/preferences/domain/repositories/preferences_repository.dart';
import 'package:mobile/src/features/preferences/presentation/state/preferences_state.dart';

class PreferencesCubit extends Cubit<PreferencesState> {
  final PreferencesRepository _repository;

  PreferencesCubit({required PreferencesRepository repository})
    : _repository = repository,
      super(const PreferencesInitial());

  Future<void> load({required String userId}) async {
    emit(const PreferencesLoading());
    try {
      final preferences = await _repository.getPreferences();
      emit(
        PreferencesLoaded(
          preferences: preferences,
          shouldShowOnboarding: _repository.shouldShowOnboarding(
            userId: userId,
            preferences: preferences,
          ),
        ),
      );
    } catch (e) {
      emit(PreferencesError(message: _extractError(e)));
    }
  }

  Future<void> save({
    required String userId,
    required ShoppingPreferences preferences,
  }) async {
    emit(const PreferencesLoading());
    try {
      final saved = await _repository.savePreferences(preferences);
      await _repository.markOnboardingSeen(userId);
      emit(
        PreferencesSaved(
          preferences: saved,
          shouldShowOnboarding: false,
        ),
      );
    } catch (e) {
      emit(PreferencesError(message: _extractError(e)));
    }
  }

  Future<void> skip({required String userId}) async {
    emit(const PreferencesLoading());
    try {
      final skipped = await _repository.skipOnboarding();
      await _repository.markOnboardingSeen(userId);
      emit(
        PreferencesSkipped(
          preferences: skipped,
          shouldShowOnboarding: false,
        ),
      );
    } catch (e) {
      emit(PreferencesError(message: _extractError(e)));
    }
  }

  String _extractError(dynamic e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        return data['message'] as String? ?? 'Không thể cập nhật sở thích';
      }
      if (e.type == DioExceptionType.connectionError) {
        return 'Không thể kết nối đến máy chủ';
      }
    }
    return 'Không thể cập nhật sở thích';
  }
}
