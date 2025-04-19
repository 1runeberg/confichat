/*
 * Copyright 2025 Rune Berg (http://runeberg.io | https://github.com/1runeberg)
 * Licensed under Apache 2.0 (https://www.apache.org/licenses/LICENSE-2.0)
 * SPDX-License-Identifier: Apache-2.0
 */

import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:yaml/yaml.dart';

class LanguageConfig {
  static final LanguageConfig _instance = LanguageConfig._internal();
  factory LanguageConfig() => _instance;

  List<Map<String, dynamic>>? _languages;
  List<Locale>? _supportedLocales;
  Set<String>? _supportedLanguageCodes;
  bool _isInitialized = false;
  bool _isInitializing = false;
  final Completer<void> _initCompleter = Completer<void>();

  LanguageConfig._internal() {
    _initializeLanguages();
  }

  Future<void> _initializeLanguages() async {
    if (_isInitialized || _isInitializing) return;

    _isInitializing = true;
    try {
      final yamlString = await rootBundle.loadString('assets/i18n/languages.yaml');
      final yamlMap = json.decode(json.encode(loadYaml(yamlString)));
      _languages = List<Map<String, dynamic>>.from(yamlMap['languages']);

      // Cache supported locales and language codes
      _supportedLocales = _languages!.map((lang) {
        final country = lang['country'] as String?;
        return Locale(lang['code'] as String, country ?? '');
      }).toList();

      _supportedLanguageCodes = _languages!
          .map((lang) => lang['code'] as String)
          .toSet();

      _isInitialized = true;
      _initCompleter.complete();
    } catch (e) {
      if (kDebugMode) {
        print("LanguageConfig initialization error: $e");
      }

      _initCompleter.completeError(e);
    }
  }

  Future<void> ensureInitialized() async {
    if (_isInitialized) return;
    await _initCompleter.future;
  }

  bool isLanguageSupportedSync(String languageCode) {

    // Note: This check is here so we can assume a language is supported if it's
    //       not loaded to avoid blocking. Checking still happens when loading translations.
    //       Since we're loading from pubspec, this would just be an edge case.
    if (!_isInitialized || _supportedLanguageCodes == null) {
      return true;
    }
    return _supportedLanguageCodes!.contains(languageCode);
  }

  // Synchronous getter that returns cached locales or empty list
  List<Locale> getSupportedLocalesSync() {
    return _supportedLocales ?? [];
  }

  // Async version waits for initialization to complete
  Future<List<Locale>> getSupportedLocales() async {
    await ensureInitialized();
    return _supportedLocales!;
  }

  Future<bool> isLanguageSupported(String languageCode) async {
    await ensureInitialized();
    return _supportedLanguageCodes!.contains(languageCode);
  }

  Future<String> getLanguageName(String languageCode) async {
    await ensureInitialized();
    final language = _languages!.firstWhere(
            (lang) => lang['code'] == languageCode,
        orElse: () => {'code': languageCode, 'name': languageCode}
    );
    return language['name'] as String;
  }

  Future<List<Map<String, dynamic>>> getLanguageOptions() async {
    await ensureInitialized();
    return _languages!;
  }
}