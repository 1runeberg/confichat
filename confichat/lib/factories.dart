/*
 * Copyright 2024-25 Rune Berg (http://runeberg.io | https://github.com/1runeberg)
 * Licensed under Apache 2.0 (https://www.apache.org/licenses/LICENSE-2.0)
 * SPDX-License-Identifier: Apache-2.0
 */


import 'package:confichat/interfaces.dart';

import 'package:confichat/api_ollama.dart';
import 'package:confichat/api_llamacpp.dart';
import 'package:confichat/api_openai.dart';
import 'package:confichat/api_anthropic.dart';


class LlmApiFactory {
  static LlmApi create(String apiProvider) {
    switch (apiProvider.toLowerCase()) {
      case 'ollama':
        return ApiOllama();
      case 'llamacpp':
        return ApiLlamaCpp();
      case 'openai':
        return ApiChatGPT();
      case 'anthropic':
        return ApiAnthropic();
      default:
        throw Exception('Unsupported API provider: $apiProvider');
    }
  }
}
