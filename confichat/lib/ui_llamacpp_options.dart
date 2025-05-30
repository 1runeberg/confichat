/*
 * Copyright 2024-25 Rune Berg (http://runeberg.io | https://github.com/1runeberg)
 * Licensed under Apache 2.0 (https://www.apache.org/licenses/LICENSE-2.0)
 * SPDX-License-Identifier: Apache-2.0
 */

import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:confichat/ui_widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:confichat/app_data.dart';
import 'package:confichat/app_localizations.dart';

class LlamaCppOptions extends StatefulWidget {
  final AppData appData;

  const LlamaCppOptions({super.key, required this.appData});

  @override
  LlamaCppOptionsState createState() => LlamaCppOptionsState();
}

class LlamaCppOptionsState extends State<LlamaCppOptions> {
  final TextEditingController _schemeController = TextEditingController();
  final TextEditingController _hostController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  final TextEditingController _pathController = TextEditingController();
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
    _schemeController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _pathController.dispose();
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

      if (settings.containsKey(AiProvider.llamacpp.name) && AppData.instance.api.aiProvider.name ==  AiProvider.llamacpp.name) {

        // Set the form text
        _schemeController.text = settings[AiProvider.llamacpp.name]['scheme'] ?? 'http';
        _hostController.text = settings[AiProvider.llamacpp.name]['host'] ?? 'localhost';
        _portController.text = settings[AiProvider.llamacpp.name]['port']?.toString() ?? '8080';
        _pathController.text = settings[AiProvider.llamacpp.name]['path'] ?? '/v1';
        _apiKeyController.text = settings[AiProvider.llamacpp.name]['apikey'] ?? '';
        _applySettings();

      } else {
        _useDefaultSettings();
      }
    } else {
      _useDefaultSettings();
    }
  }

  void _useDefaultSettings() {
    _schemeController.text = 'http';
    _hostController.text = 'localhost';
    _portController.text = '8080';
    _pathController.text = '/v1';

    _applySettings();
  }

  void _applySettings() {
    if(widget.appData.api.aiProvider.name == AiProvider.llamacpp.name) { 
      AppData.instance.api.scheme = _schemeController.text;
      AppData.instance.api.host = _hostController.text;
      AppData.instance.api.port = int.tryParse(_portController.text) ?? 8080;
      AppData.instance.api.path = _pathController.text;
      AppData.instance.api.apiKey = _apiKeyController.text;
    }
  }

  Future<void> _saveSettings() async {
    final directory = AppData.instance.rootPath.isEmpty ? await getApplicationDocumentsDirectory() : Directory(AppData.instance.rootPath);
    final filePath = '${directory.path}/${AppData.appStoragePath}/${AppData.appSettingsFile}';

    final newSetting = {
      'scheme': _schemeController.text,
      'host': _hostController.text,
      'port': int.tryParse(_portController.text) ?? 11434,
      'path': _pathController.text,
      'apikey': _apiKeyController.text,
    };

    Map<String, dynamic> settings;
    final file = File(filePath);

    if (await file.exists()) {
      final content = await file.readAsString();
      settings = json.decode(content) as Map<String, dynamic>;

      if (settings.containsKey(AiProvider.llamacpp.name)) {
        settings[AiProvider.llamacpp.name] = newSetting;
      } else {
        settings[AiProvider.llamacpp.name] = newSetting;
      }
    } else {
      settings = { AiProvider.llamacpp.name: newSetting };
    }

    // Set in-memory values
    _applySettings();

    // Save the updated settings to disk
    await file.create(recursive: true);
    await file.writeAsString(const JsonEncoder.withIndent(' ').convert(settings));

    // Reset model values
     if(widget.appData.api.aiProvider.name == AiProvider.llamacpp.name) {
      AppData.instance.callbackSwitchProvider(AiProvider.llamacpp);
     }

    // Close window
    if (mounted) {
      Navigator.of(context).pop();
    }
  }


  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Window title
              DialogTitle(title: loc.translate('providerOptions.title').replaceAll('{provider}', AiProvider.llamacpp.name)),
              const SizedBox(height: 24),


                ConstrainedBox( constraints:  
                BoxConstraints(
                  minWidth: 300, 
                  maxHeight: widget.appData.getUserDeviceType(context) != UserDeviceType.phone ? 400 : 250, 
                ), 
                child: SingleChildScrollView(
                scrollDirection: Axis.vertical, 
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag, 
                child: Column ( children: [

                  // Scheme
                  const SizedBox(height: 16),
                  TextField(
                    controller: _schemeController,
                    decoration: InputDecoration(
                      labelText:  loc.translate('providerOptions.fields.scheme'),
                      labelStyle: Theme.of(context).textTheme.labelSmall,
                      border: const UnderlineInputBorder(),
                    ),
                  ),

                  // Host
                  const SizedBox(height: 16),
                  TextField(
                    controller: _hostController,
                    decoration:  InputDecoration(
                      labelText: loc.translate('providerOptions.fields.host'),
                      labelStyle: Theme.of(context).textTheme.labelSmall,
                      border: const UnderlineInputBorder(),
                    ),
                  ),

                  // Port
                  const SizedBox(height: 16),
                  TextField(
                    controller: _portController,
                    decoration: InputDecoration(
                      labelText: loc.translate('providerOptions.fields.port'),
                      labelStyle: Theme.of(context).textTheme.labelSmall,
                      border: const UnderlineInputBorder(),
                    ),
                  ),

                  // Path
                  const SizedBox(height: 16),
                  TextField(
                    controller: _pathController,
                    decoration: InputDecoration(
                      labelText: loc.translate('providerOptions.fields.path'),
                      labelStyle: Theme.of(context).textTheme.labelSmall,
                      border: const UnderlineInputBorder(),
                    ),
                  ),

                  // API Key
                  const SizedBox(height: 16),
                  TextField(
                    controller: _apiKeyController,
                    decoration: InputDecoration(
                      labelText: loc.translate('providerOptions.fields.apiKey'),
                      labelStyle: Theme.of(context).textTheme.labelSmall,
                      border: const UnderlineInputBorder(),
                    ),
                  ),

              ]))),

              // Buttons
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
                      child: Text(AppLocalizations.of(context).translate('providerOptions.buttons.save')),
                    ),

                    const SizedBox(width: 8),
                    ElevatedButton(
                      focusNode: _focusNode,
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(AppLocalizations.of(context).translate('providerOptions.buttons.cancel')),
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
