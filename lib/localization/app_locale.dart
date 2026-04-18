import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

/// Single source of truth for locale decisions in this app.
///
/// Policy:
/// - Device language is Japanese (`ja`) => Japanese UI
/// - Otherwise => English UI
class AppLocale {
  static const Locale ja = Locale('ja');
  static const Locale en = Locale('en');

  /// Resolve the app locale from a device locale.
  ///
  /// We intentionally only distinguish Japanese vs non-Japanese.
  static Locale resolve(Locale? deviceLocale) {
    if (deviceLocale?.languageCode == 'ja') return ja;
    return en;
  }

  /// Returns the effective language code used by the app UI (`ja` or `en`).
  ///
  /// Prefer this over reading `.locale.languageCode` directly.
  static String languageCode(BuildContext context) {
    // Primary: AppLocalizations (follows MaterialApp's locale resolution)
    try {
      return AppLocalizations.of(context).locale.languageCode;
    } catch (_) {
      // Fallback: device locale -> app policy
      final device = Localizations.maybeLocaleOf(context);
      return resolve(device).languageCode;
    }
  }

  /// Returns the effective language code (`ja` or `en`) from an [AppLocalizations]
  /// instance, without callers reading `.locale.languageCode` directly.
  static String languageCodeFromL10n(AppLocalizations l10n) {
    return resolve(l10n.locale).languageCode;
  }

  static bool isJapanese(BuildContext context) => languageCode(context) == 'ja';
  static bool isEnglish(BuildContext context) => languageCode(context) == 'en';
}


