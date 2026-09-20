/*
 * Copyright 2024-25 Rune Berg (http://runeberg.io | https://github.com/1runeberg)
 * Licensed under Apache 2.0 (https://www.apache.org/licenses/LICENSE-2.0)
 * SPDX-License-Identifier: Apache-2.0
 */

import 'package:confichat/api_ollama.dart';
import 'package:confichat/app_data.dart';

/// llmman (https://github.com/llmmanorg/llmman) is a local model runner that
/// serves the Ollama API on port 17434, so it reuses the Ollama client as-is.
class ApiLlmman extends ApiOllama {

  static final ApiLlmman _instance = ApiLlmman._internal();
  static ApiLlmman get instance => _instance;

  // Factory constructor
  factory ApiLlmman() {
    return _instance;
  }

  ApiLlmman._internal() : super.forProvider(AiProvider.llmman, 17434);

} // ApiLlmman
