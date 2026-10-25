/*
 * Copyright 2026 Rune Berg (http://runeberg.io | https://github.com/1runeberg)
 * Licensed under Apache 2.0 (https://www.apache.org/licenses/LICENSE-2.0)
 * SPDX-License-Identifier: Apache-2.0
 */

import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

enum HingeStatus { unknown, closed, partiallyOpen, fullyOpen }

// Duo layouts (none keeps the standard phone and tablet layouts)
enum DuoLayout {
  none, folded, landscape, portrait;

  // Folded and unfolded landscape move the prompt actions to the side rail
  bool get hasRail => this == folded || this == landscape;
}

class HingeUtil {
  static const _hingeChannel = EventChannel('io.confichat/hinge');

  // Current hinge status (null on devices without a hinge)
  static final ValueNotifier<HingeStatus?> status = ValueNotifier(null);

  static bool get hasHinge => status.value != null;
  static bool get isHingeOpen =>
      status.value == HingeStatus.partiallyOpen || status.value == HingeStatus.fullyOpen;

  static DuoLayout layoutFor(Size size) {
    switch (status.value) {
      case HingeStatus.closed:
        return DuoLayout.folded;

      case HingeStatus.partiallyOpen:
      case HingeStatus.fullyOpen:
        return size.width > size.height ? DuoLayout.landscape : DuoLayout.portrait;

      default:
        return DuoLayout.none;
    }
  }

  static void listen() {
    if (!Platform.isIOS) return;

    _hingeChannel.receiveBroadcastStream().listen(
      (event) {
        status.value = event is String
            ? HingeStatus.values.asNameMap()[event] ?? HingeStatus.unknown
            : null;
      },
      onError: (_) => status.value = null,
    );
  }
}
