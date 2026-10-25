/*
 * Copyright 2024-25 Rune Berg (http://runeberg.io | https://github.com/1runeberg)
 * Licensed under Apache 2.0 (https://www.apache.org/licenses/LICENSE-2.0)
 * SPDX-License-Identifier: Apache-2.0
 */

import 'package:confichat/app_data.dart';
import 'package:confichat/factories.dart';
import 'package:confichat/interfaces.dart';
import 'package:flutter/foundation.dart';

class ProviderValidator {
  /// Checks if local providers (Ollama, LlamaCPP or llmman) are available
  static Future<AiProvider?> validateLocalProviders(AppData appData) async {
    try {
      // Try Ollama first (priority)
      List<ModelItem> ollamaModels = [];
      final ollama = LlmApiFactory.create(AiProvider.ollama.name);
      await ollama.loadSettings();
      bool ollamaSuccess = await _canGetModels(ollama, ollamaModels);
      
      if (ollamaSuccess && ollamaModels.isNotEmpty) {
        return AiProvider.ollama;
      }
      
      // Try LlamaCPP second
      List<ModelItem> llamaModels = [];
      final llamacpp = LlmApiFactory.create(AiProvider.llamacpp.name);
      await llamacpp.loadSettings();
      bool llamaSuccess = await _canGetModels(llamacpp, llamaModels);
      
      if (llamaSuccess && llamaModels.isNotEmpty) {
        return AiProvider.llamacpp;
      }

      // Try llmman third
      List<ModelItem> llmmanModels = [];
      final llmman = LlmApiFactory.create(AiProvider.llmman.name);
      await llmman.loadSettings();
      bool llmmanSuccess = await _canGetModels(llmman, llmmanModels);

      if (llmmanSuccess && llmmanModels.isNotEmpty) {
        return AiProvider.llmman;
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error validating local providers: $e");
      }
    }
    return null;
  }
  
  /// Check if an online provider has an API key configured
  static Future<AiProvider?> checkApiKeyConfigured(AppData appData) async {
    try {
      // Check OpenAI
      final openai = LlmApiFactory.create(AiProvider.openai.name);
      await openai.loadSettings();
      if (openai.apiKey.isNotEmpty) {
        return AiProvider.openai;
      }
      
      // Check Anthropic
      final anthropic = LlmApiFactory.create(AiProvider.anthropic.name);
      await anthropic.loadSettings();
      if (anthropic.apiKey.isNotEmpty) {
        return AiProvider.anthropic;
      }

      // Check Gemini
      final gemini = LlmApiFactory.create(AiProvider.gemini.name);
      await gemini.loadSettings();
      if (gemini.apiKey.isNotEmpty) {
        return AiProvider.gemini;
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error checking API keys: $e");
      }
    }
    return null;
  }
  
  static Future<bool> _canGetModels(LlmApi api, List<ModelItem> models) async {
    try {
      await api.getModels(models);
      return true;
    } catch (e) {
      return false;
    }
  }
}
