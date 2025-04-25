/*
 * Copyright 2024-25 Rune Berg (http://runeberg.io | https://github.com/1runeberg)
 * Licensed under Apache 2.0 (https://www.apache.org/licenses/LICENSE-2.0)
 * SPDX-License-Identifier: Apache-2.0
 */

import 'package:confichat/app_data.dart';
import 'package:flutter/foundation.dart';

class ProviderValidator {
  /// Checks if local providers (Ollama or LlamaCPP) are available
  static Future<AiProvider?> validateLocalProviders(AppData appData) async {
    try {
      // Try Ollama first (priority)
      List<ModelItem> ollamaModels = [];
      appData.setProvider(AiProvider.ollama);
      await appData.api.loadSettings();
      bool ollamaSuccess = await _canGetModels(appData, ollamaModels);
      
      if (ollamaSuccess && ollamaModels.isNotEmpty) {
        return AiProvider.ollama;
      }
      
      // Try LlamaCPP second
      List<ModelItem> llamaModels = [];
      appData.setProvider(AiProvider.llamacpp);
      await appData.api.loadSettings();
      bool llamaSuccess = await _canGetModels(appData, llamaModels);
      
      if (llamaSuccess && llamaModels.isNotEmpty) {
        return AiProvider.llamacpp;
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error validating local providers: $e");
      }
    }
    return null;
  }
  
  /// Check if online provider has an API key configured
  static Future<AiProvider?> checkApiKeyConfigured(AppData appData) async {
    try {
      // Check OpenAI
      appData.setProvider(AiProvider.openai);
      await appData.api.loadSettings();
      if (appData.api.apiKey.isNotEmpty) {
        return AiProvider.openai;
      }
      
      // Check Anthropic
      appData.setProvider(AiProvider.anthropic);
      await appData.api.loadSettings();
      if (appData.api.apiKey.isNotEmpty) {
        return AiProvider.anthropic;
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error checking API keys: $e");
      }
    }
    return null;
  }
  
  static Future<bool> _canGetModels(AppData appData, List<ModelItem> models) async {
    try {
      await appData.api.getModels(models);
      return true;
    } catch (e) {
      return false;
    }
  }
}