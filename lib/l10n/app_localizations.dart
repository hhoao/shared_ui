import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of SharedUiLocalizations
/// returned by `SharedUiLocalizations.of(context)`.
///
/// Applications need to include `SharedUiLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: SharedUiLocalizations.localizationsDelegates,
///   supportedLocales: SharedUiLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the SharedUiLocalizations.supportedLocales
/// property.
abstract class SharedUiLocalizations {
  SharedUiLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static SharedUiLocalizations of(BuildContext context) {
    return Localizations.of<SharedUiLocalizations>(
      context,
      SharedUiLocalizations,
    )!;
  }

  static const LocalizationsDelegate<SharedUiLocalizations> delegate =
      _SharedUiLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get appTitle;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @settingsPageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Customize your Huji desktop experience'**
  String get settingsPageSubtitle;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @generalPageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Startup, storage, and privacy'**
  String get generalPageSubtitle;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @appearancePageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Theme, text size, and language'**
  String get appearancePageSubtitle;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @accountPageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign-in status and profile'**
  String get accountPageSubtitle;

  /// No description provided for @network.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get network;

  /// No description provided for @networkPageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'API environment and downloads'**
  String get networkPageSubtitle;

  /// No description provided for @themeModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme mode'**
  String get themeModeTitle;

  /// No description provided for @themeModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Default appearance or follow the system'**
  String get themeModeDescription;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeColorPresetTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme colors'**
  String get themeColorPresetTitle;

  /// No description provided for @themeColorPresetDescription.
  ///
  /// In en, this message translates to:
  /// **'Primary and accent colors for controls'**
  String get themeColorPresetDescription;

  /// No description provided for @typographyScaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get typographyScaleTitle;

  /// No description provided for @typographyScaleDescription.
  ///
  /// In en, this message translates to:
  /// **'UI text size. Standard follows the system'**
  String get typographyScaleDescription;

  /// No description provided for @typographyScaleCompact.
  ///
  /// In en, this message translates to:
  /// **'Compact'**
  String get typographyScaleCompact;

  /// No description provided for @typographyScaleStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get typographyScaleStandard;

  /// No description provided for @typographyScaleComfortable.
  ///
  /// In en, this message translates to:
  /// **'Comfortable'**
  String get typographyScaleComfortable;

  /// No description provided for @typographyScaleCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get typographyScaleCustom;

  /// No description provided for @typographyScaleCustomHint.
  ///
  /// In en, this message translates to:
  /// **'50–200'**
  String get typographyScaleCustomHint;

  /// No description provided for @uiZoomTitle.
  ///
  /// In en, this message translates to:
  /// **'Interface zoom'**
  String get uiZoomTitle;

  /// No description provided for @uiZoomDescription.
  ///
  /// In en, this message translates to:
  /// **'Scale text, icons, and spacing together'**
  String get uiZoomDescription;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageDescription.
  ///
  /// In en, this message translates to:
  /// **'Language for menus, buttons, and labels'**
  String get languageDescription;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageChinese.
  ///
  /// In en, this message translates to:
  /// **'中文'**
  String get languageChinese;

  /// No description provided for @themeModeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeModeLight;

  /// No description provided for @themeModeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeModeDark;

  /// No description provided for @themeModeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeModeSystem;

  /// No description provided for @themePresetGraphite.
  ///
  /// In en, this message translates to:
  /// **'Graphite'**
  String get themePresetGraphite;

  /// No description provided for @themePresetOcean.
  ///
  /// In en, this message translates to:
  /// **'Ocean'**
  String get themePresetOcean;

  /// No description provided for @themePresetViolet.
  ///
  /// In en, this message translates to:
  /// **'Violet'**
  String get themePresetViolet;

  /// No description provided for @themePresetAmber.
  ///
  /// In en, this message translates to:
  /// **'Amber'**
  String get themePresetAmber;

  /// No description provided for @themePresetForest.
  ///
  /// In en, this message translates to:
  /// **'Forest'**
  String get themePresetForest;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @actionOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get actionOk;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @windowControlMinimize.
  ///
  /// In en, this message translates to:
  /// **'Minimize'**
  String get windowControlMinimize;

  /// No description provided for @windowControlMaximize.
  ///
  /// In en, this message translates to:
  /// **'Maximize'**
  String get windowControlMaximize;

  /// No description provided for @windowControlRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get windowControlRestore;

  /// No description provided for @windowControlClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get windowControlClose;

  /// No description provided for @windowControlAlwaysOnTop.
  ///
  /// In en, this message translates to:
  /// **'Always on top'**
  String get windowControlAlwaysOnTop;

  /// No description provided for @workspaceCliConfigured.
  ///
  /// In en, this message translates to:
  /// **'Configured'**
  String get workspaceCliConfigured;

  /// No description provided for @workspaceCliNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Not configured'**
  String get workspaceCliNotConfigured;
}

class _SharedUiLocalizationsDelegate
    extends LocalizationsDelegate<SharedUiLocalizations> {
  const _SharedUiLocalizationsDelegate();

  @override
  Future<SharedUiLocalizations> load(Locale locale) {
    return SynchronousFuture<SharedUiLocalizations>(
      lookupSharedUiLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_SharedUiLocalizationsDelegate old) => false;
}

SharedUiLocalizations lookupSharedUiLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return SharedUiLocalizationsEn();
    case 'zh':
      return SharedUiLocalizationsZh();
  }

  throw FlutterError(
    'SharedUiLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
