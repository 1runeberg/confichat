/*
 * Copyright 2024 Rune Berg (http://runeberg.io | https://github.com/1runeberg)
 * Licensed under Apache 2.0 (https://www.apache.org/licenses/LICENSE-2.0)
 * SPDX-License-Identifier: Apache-2.0
 */

import 'dart:io';

import 'package:confichat/ui_widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:confichat/interfaces.dart';
import 'package:confichat/factories.dart';


typedef CallbackSwitchProvider = Function(AiProvider?);
class AppData {

  // Singleton setup
  static final AppData _instance = AppData._internal();
  static AppData get instance => _instance;

  late CallbackSwitchProvider callbackSwitchProvider;
  late final GlobalKey<NavigatorState> navigatorKey;
  AppData._internal() : super() {
    callbackSwitchProvider = defaultCallback;
    navigatorKey = GlobalKey<NavigatorState>();
  }

  // Class vars
  static const String appTitle = 'ConfiChat';
  static const String appStoragePath = 'confichat';
  static const String appSettingsFile = 'app.user.settings.local';
  static const String appFilenameBookend = 'cc';
  static const Map<String, String> headerJson = {'Content-Type': 'application/json'};

  static const String ignoreSystemPrompt = '!system_prompt_ignore';
  static const String promptDocs = '\n\nUse the following parsed documents for additional context:\n';
  static const String promptCode = '\n\nUse the following code for additional context:\n';

  // Public vars
  LlmApi api = LlmApiFactory.create(AiProvider.ollama.name);
  bool clearMessagesOnModelSwitch = true;
  bool filterHistoryByModel = false;
  bool haveUnsavedMessages = false;
  int appScrollDurationInms = 100;
  double windowWidth = 1024;
  double windowHeight = 1024;
  AiProvider defaultProvider = AiProvider.ollama;
  String rootPath = '';

  void defaultCallback(AiProvider? provider) {
  }

  void setProvider(AiProvider provider){

    switch (provider) {
      case AiProvider.ollama:
        api = LlmApiFactory.create(AiProvider.ollama.name);
        break;
      case AiProvider.openai:
        api = LlmApiFactory.create(AiProvider.openai.name);
        break;
      case AiProvider.llamacpp:
        api = LlmApiFactory.create(AiProvider.llamacpp.name);
        break;
      default:
        if (kDebugMode) { print('Unknown AI provider.');  }
    }
  }

  UserDeviceType getUserDeviceType(BuildContext context) {
  final double deviceWidth = MediaQuery.of(context).size.shortestSide;

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return UserDeviceType.desktop;
    } else if (Platform.isAndroid || Platform.isIOS) {
      if (deviceWidth > 600) {
        return UserDeviceType.tablet;
      } else {
        return UserDeviceType.phone;
      }
    } else {
      return UserDeviceType.desktop;
    }
  }

}

enum AiProvider {
  ollama('Ollama', 0),
  openai('OpenAI', 1),
  llamacpp('LlamaCpp', 2);

  final String name;
  final int id;
  const AiProvider(this.name, this.id);
}

enum UserDeviceType {
  desktop,
  phone,
  tablet
}

class ModelItem {
  final String id;
  final String name;

  bool allowDelete = true;
  bool supportsImages = true;

  ModelItem(this.id, this.name);
}

class ModelInfo {
  final String name;
  String parentModel = '';
  String rootModel = '';
  String createdOn = '';
  String languages = '';
  String parameterSize = '';
  String quantizationLevel = '';
  String systemPrompt = '';

  ModelInfo(this.name);

}

class ModelProvider with ChangeNotifier {
  List<ModelItem> _models = [];

  List<ModelItem> get models => _models;

  void updateModels(List<ModelItem> newModels) {
    _models = newModels;
    notifyListeners();
  }
}

class SelectedModelProvider with ChangeNotifier {
  ModelItem? _selectedModel;

  ModelItem? get selectedModel => _selectedModel;

  void updateSelectedModel(ModelItem? model) {
    if(_selectedModel == model) { return; } // no changes needed
    _selectedModel = model;
    notifyListeners();
  }
}

class ShowErrorDialog extends StatelessWidget {
  final String title;
  final String content;

  const ShowErrorDialog({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: DialogTitle(title: title),
      content: Text(content),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}
