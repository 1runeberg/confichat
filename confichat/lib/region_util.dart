/*
 * Copyright 2025 Rune Berg (http://runeberg.io | https://github.com/1runeberg)
 * Licensed under Apache 2.0 (https://www.apache.org/licenses/LICENSE-2.0)
 * SPDX-License-Identifier: Apache-2.0
 */

import 'dart:io';
import 'package:flutter/services.dart';

class RegionUtil {
  static const _storefrontChannel = MethodChannel('io.confichat/storefront');
  static bool _isUSStorefront = false;

  static bool get canShowProviderLinks =>
      !(Platform.isIOS || Platform.isMacOS) || _isUSStorefront;

  static Future<void> refreshStorefront() async {
    if (!(Platform.isIOS || Platform.isMacOS)) return;
    try {
      final code = await _storefrontChannel
          .invokeMethod<String>('countryCode')
          .timeout(const Duration(seconds: 5));
      _isUSStorefront = code?.toUpperCase() == 'USA';
    } on PlatformException {
      _isUSStorefront = false;
    } on MissingPluginException {
      _isUSStorefront = false;
    } on Exception {
      _isUSStorefront = false;
    }
  }
}
