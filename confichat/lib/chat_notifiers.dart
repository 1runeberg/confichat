/*
 * Copyright 2024 Rune Berg (http://runeberg.io | https://github.com/1runeberg)
 * Licensed under Apache 2.0 (https://www.apache.org/licenses/LICENSE-2.0)
 * SPDX-License-Identifier: Apache-2.0
 */

import 'package:flutter/material.dart';

// Value notifier (chat session) for the sidebar to the canvass
class ChatSessionSelectedNotifier extends ValueNotifier<String> {
  ChatSessionSelectedNotifier() : super('');
}
