/*
 * Copyright 2025 Rune Berg (http://runeberg.io | https://github.com/1runeberg)
 * Licensed under Apache 2.0 (https://www.apache.org/licenses/LICENSE-2.0)
 * SPDX-License-Identifier: Apache-2.0
 */

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confichat/language_config.dart';

class AppLocalizations {
  final Locale locale;

  static final Map<String, Map<String, dynamic>> _cachedTranslations = {};
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  late Map<String, dynamic> _localizedStrings;

  Future<bool> load() async {
    // Check if we already have this language cached
    if (_cachedTranslations.containsKey(locale.languageCode)) {
      _localizedStrings = _cachedTranslations[locale.languageCode]!;
      return true;
    }

    // Otherwise load from disk and cache it
    String jsonString = await rootBundle.loadString('assets/i18n/${locale.languageCode}.json');
    Map<String, dynamic> jsonMap = json.decode(jsonString);
    _localizedStrings = jsonMap;

    // Store in cache
    _cachedTranslations[locale.languageCode] = jsonMap;
    return true;
  }

  String translate(String key, {Map<String, String>? args, String? fallback}) {
    List<String> keys = key.split('.');
    dynamic value = _localizedStrings;

    for (String k in keys) {
      if (value is Map && value.containsKey(k)) {
        value = value[k];
      } else {
        return fallback ?? key;
      }
    }

    String result = value.toString();

    // Handle replacements if args provided
    if (args != null) {
      args.forEach((argKey, argValue) {
        result = result.replaceAll('{$argKey}', argValue);
      });
    }

    return result;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    // Use synchronous version
    return LanguageConfig().isLanguageSupportedSync(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    // Make sure language config is initialized before loading translations
    await LanguageConfig().ensureInitialized();

    // Only proceed if the language is actually supported
    if (await LanguageConfig().isLanguageSupported(locale.languageCode)) {
      AppLocalizations localizations = AppLocalizations(locale);
      await localizations.load();
      return localizations;
    }

    // Fallback to English if not supported
    AppLocalizations localizations = AppLocalizations(const Locale('en'));
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}