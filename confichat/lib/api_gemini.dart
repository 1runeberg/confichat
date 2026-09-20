/*
 * Copyright 2026 Rune Berg
 * Licensed under Apache 2.0 (https://www.apache.org/licenses/LICENSE-2.0)
 * SPDX-License-Identifier: Apache-2.0
 */

import 'api_openai.dart';
import 'app_data.dart';

/// Gemini's OpenAI-compatible chat, model, and streaming endpoints.
class ApiGemini extends ApiChatGPT {
  static final ApiGemini _instance = ApiGemini._internal();
  static ApiGemini get instance => _instance;

  factory ApiGemini() => _instance;

  ApiGemini._internal()
      : super.forProvider(
          AiProvider.gemini,
          'generativelanguage.googleapis.com',
          '/v1beta/openai',
        );
}
