import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

extension SharedUiL10n on BuildContext {
  SharedUiLocalizations get sharedL10n => SharedUiLocalizations.of(this);

  /// Alias matching teampilot's `context.l10n` for migrated widgets.
  SharedUiLocalizations get l10n => sharedL10n;
}

extension SharedUiL10nTheme on SharedUiLocalizations {
  String themeColorPresetName(String id) {
    return switch (id) {
      'ocean' => themePresetOcean,
      'violet' => themePresetViolet,
      'amber' => themePresetAmber,
      'forest' => themePresetForest,
      'graphite' => themePresetGraphite,
      _ => themePresetGraphite,
    };
  }
}
