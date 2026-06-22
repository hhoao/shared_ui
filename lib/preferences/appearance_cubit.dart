import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_ui/preferences/appearance_preferences.dart';
import 'package:shared_ui/preferences/appearance_preferences_store.dart';
import 'package:shared_ui/theme/app_theme.dart';

class AppearanceCubit extends Cubit<AppearancePreferences> {
  AppearanceCubit({AppearancePreferencesStore? store})
      : _store = store ?? AppearancePreferencesStore(),
        super(const AppearancePreferences()) {
    _load();
  }

  final AppearancePreferencesStore _store;

  Future<void> _load() async {
    try {
      final prefs = await _store.load();
      emit(prefs);
    } catch (_) {
      emit(const AppearancePreferences());
    }
  }

  Future<void> setThemeMode(String mode) async {
    final next = state.copyWith(themeMode: mode);
    emit(next);
    await _store.save(next);
  }

  Future<void> setThemeColorPreset(String preset) async {
    final next = state.copyWith(
      themeColorPreset: normalizeThemeColorPreset(preset),
    );
    emit(next);
    await _store.save(next);
  }

  Future<void> setLocale(String locale) async {
    final next = state.copyWith(locale: locale);
    emit(next);
    await _store.save(next);
  }

  Future<void> setTypographyScale(String scale, {double? custom}) async {
    final next = state.copyWith(
      typographyScale: scale,
      typographyScaleCustomMultiplier:
          custom ?? state.typographyScaleCustomMultiplier,
    );
    emit(next);
    await _store.save(next);
  }

  Future<void> setUiZoomScale(String scale, {double? custom}) async {
    final next = state.copyWith(
      uiZoomScale: scale,
      uiZoomCustomMultiplier: custom ?? state.uiZoomCustomMultiplier,
    );
    emit(next);
    await _store.save(next);
  }
}
