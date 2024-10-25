/*
 * Copyright 2024 Rune Berg (http://runeberg.io | https://github.com/1runeberg)
 * Licensed under Apache 2.0 (https://www.apache.org/licenses/LICENSE-2.0)
 * SPDX-License-Identifier: Apache-2.0
 */

import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:confichat/ui_widgets.dart';
import 'package:path_provider/path_provider.dart';

import 'package:confichat/app_data.dart';


class AnthropicOptions extends StatefulWidget {
  final AppData appData;

  const AnthropicOptions({super.key, required this.appData});

  @override
  AnthropicOptionsState createState() => AnthropicOptionsState();
}

class AnthropicOptionsState extends State<AnthropicOptions> {
  final TextEditingController _apiKeyController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final directory = AppData.instance.rootPath.isEmpty ? await getApplicationDocumentsDirectory() : Directory(AppData.instance.rootPath);
    final filePath ='${directory.path}/${AppData.appStoragePath}/${AppData.appSettingsFile}';

    if (await File(filePath).exists()) {
      final fileContent = await File(filePath).readAsString();
      final Map<String, dynamic> settings = json.decode(fileContent);

      if (settings.containsKey(AiProvider.anthropic.name)) {

        // Set the form text
        _apiKeyController.text = settings[AiProvider.anthropic.name]['apikey'] ?? '';

        if(widget.appData.api.aiProvider.name == AiProvider.anthropic.name){ _applyValues(); }

      } else {
        _useDefaultSettings();
      }
    } else {
      _useDefaultSettings();
    }
  }

  void _useDefaultSettings() {
    _applyValues();
  }

  void _applyValues() {
    if(widget.appData.api.aiProvider.name == AiProvider.anthropic.name) { 
      AppData.instance.api.apiKey = _apiKeyController.text; }
  }

  Future<void> _saveSettings() async {
    // Set file path
    final directory = AppData.instance.rootPath.isEmpty ? await getApplicationDocumentsDirectory() : Directory(AppData.instance.rootPath);
    final filePath = '${directory.path}/${AppData.appStoragePath}/${AppData.appSettingsFile}';

    // Set new valuie
    final newSetting = {
      'apikey': _apiKeyController.text,
    };

    // Save to disk
    Map<String, dynamic> settings;
    final file = File(filePath);
  
    if (await file.exists()) {
      // If the file exists, read the content and parse it
      final content = await file.readAsString();
      settings = json.decode(content) as Map<String, dynamic>;

      // Check if the object name exists, and update it
      if (settings.containsKey(AiProvider.anthropic.name)) {
        settings[AiProvider.anthropic.name] = newSetting;
      } else {
        settings[AiProvider.anthropic.name] = newSetting;
      }
    } else {
      settings = { AiProvider.anthropic.name: newSetting };
    }

    // Update in-memory values
    _applyValues();

    // Save the updated settings to disk
    await file.create(recursive: true);
    await file.writeAsString(const JsonEncoder.withIndent(' ').convert(settings));

    // Reset model values
    if(widget.appData.api.aiProvider.name == AiProvider.anthropic.name) {
      AppData.instance.callbackSwitchProvider(AiProvider.anthropic);
    }

    // Close window
    if (mounted) {
      Navigator.of(context).pop();
    }
  }


  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Window title
              DialogTitle(title: '${AiProvider.anthropic.name} Options'),
              const SizedBox(height: 24),

              TextField(
                controller: _apiKeyController,
                decoration: InputDecoration(
                  labelText: 'API Key',
                  labelStyle: Theme.of(context).textTheme.labelSmall,
                  border: const UnderlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),
              Align(
                alignment: Alignment.bottomRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    ElevatedButton(
                      onPressed: () async {
                        await _saveSettings();
                      },
                      child: const Text('Save'),
                    ),

                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      focusNode: _focusNode,
                      child: const Text('Cancel'),
                    ),

                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
