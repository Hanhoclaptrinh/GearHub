import 'package:equatable/equatable.dart';
import 'package:mobile/src/features/preferences/domain/entities/shopping_preferences.dart';

abstract class PreferencesState extends Equatable {
  const PreferencesState();

  @override
  List<Object?> get props => [];
}

class PreferencesInitial extends PreferencesState {
  const PreferencesInitial();
}

class PreferencesLoading extends PreferencesState {
  const PreferencesLoading();
}

class PreferencesLoaded extends PreferencesState {
  final ShoppingPreferences preferences;
  final bool shouldShowOnboarding;

  const PreferencesLoaded({
    required this.preferences,
    required this.shouldShowOnboarding,
  });

  @override
  List<Object?> get props => [preferences, shouldShowOnboarding];
}

class PreferencesSaved extends PreferencesLoaded {
  const PreferencesSaved({
    required super.preferences,
    required super.shouldShowOnboarding,
  });
}

class PreferencesSkipped extends PreferencesLoaded {
  const PreferencesSkipped({
    required super.preferences,
    required super.shouldShowOnboarding,
  });
}

class PreferencesError extends PreferencesState {
  final String message;

  const PreferencesError({required this.message});

  @override
  List<Object?> get props => [message];
}
