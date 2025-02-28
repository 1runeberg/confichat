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


class OllamaOptions extends StatefulWidget {
  final AppData appData;

  const OllamaOptions({super.key, required this.appData});

  @override
  OllamaOptionsState createState() => OllamaOptionsState();
}

class OllamaOptionsState extends State<OllamaOptions> {
  final TextEditingController _schemeController = TextEditingController();
  final TextEditingController _hostController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  final TextEditingController _pathController = TextEditingController();

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

    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final directory = AppData.instance.rootPath.isEmpty ? await getApplicationDocumentsDirectory() : Directory(AppData.instance.rootPath);
    final filePath ='${directory.path}/${AppData.appStoragePath}/${AppData.appSettingsFile}';

    if (await File(filePath).exists()) {
      final fileContent = await File(filePath).readAsString();
      final Map<String, dynamic> settings = json.decode(fileContent);

      if (settings.containsKey(AiProvider.ollama.name) && AppData.instance.api.aiProvider.name ==  AiProvider.ollama.name) {

        // Set the form text
        _schemeController.text = settings[AiProvider.ollama.name]['scheme'] ?? 'http';
        _hostController.text = settings[AiProvider.ollama.name]['host'] ?? 'localhost';
        _portController.text = settings[AiProvider.ollama.name]['port']?.toString() ?? '11434';
        _pathController.text = settings[AiProvider.ollama.name]['path'] ?? '/api';
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
    _portController.text = '11434';
    _pathController.text = '/api';

    _applySettings();
  }

  void _applySettings() {
    if(widget.appData.api.aiProvider.name == AiProvider.ollama.name) { 
      AppData.instance.api.scheme = _schemeController.text;
      AppData.instance.api.host = _hostController.text;
      AppData.instance.api.port = int.tryParse(_portController.text) ?? 11434;
      AppData.instance.api.path = _pathController.text;
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
    };

    Map<String, dynamic> settings;
    final file = File(filePath);

    if (await file.exists()) {
      final content = await file.readAsString();
      settings = json.decode(content) as Map<String, dynamic>;

      if (settings.containsKey(AiProvider.ollama.name)) {
        settings[AiProvider.ollama.name] = newSetting;
      } else {
        settings[AiProvider.ollama.name] = newSetting;
      }
    } else {
      settings = { AiProvider.ollama.name: newSetting };
    }

    // Set in-memory values
    _applySettings();

    // Save the updated settings to disk
    await file.create(recursive: true);
    await file.writeAsString(const JsonEncoder.withIndent(' ').convert(settings));

    // Reset model values
     if(widget.appData.api.aiProvider.name == AiProvider.ollama.name) {
      AppData.instance.callbackSwitchProvider(AiProvider.ollama);
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Window title
              DialogTitle(title:  '${AiProvider.ollama.name} Options'),
              const SizedBox(height: 24),


                ConstrainedBox( constraints:  
                BoxConstraints(
                  minWidth: 300, 
                  maxHeight: widget.appData.getUserDeviceType(context) != UserDeviceType.phone ? 400 : 250, 
                ), 
                child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag, 
                scrollDirection: Axis.vertical, child: Column ( children: [

                  // Scheme
                  const SizedBox(height: 16),
                  TextField(
                    controller: _schemeController,
                    decoration: InputDecoration(
                      labelText: 'Scheme',
                      labelStyle: Theme.of(context).textTheme.labelSmall,
                      border: const UnderlineInputBorder(),
                    ),
                  ),

                  // Host
                  const SizedBox(height: 16),
                  TextField(
                    controller: _hostController,
                    decoration:  InputDecoration(
                      labelText: 'Host',
                      labelStyle: Theme.of(context).textTheme.labelSmall,
                      border: const UnderlineInputBorder(),
                    ),
                  ),

                  // Port
                  const SizedBox(height: 16),
                  TextField(
                    controller: _portController,
                    decoration: InputDecoration(
                      labelText: 'Port', 
                      labelStyle: Theme.of(context).textTheme.labelSmall,
                      border: const UnderlineInputBorder(),
                    ),
                  ),

                  // Path
                  const SizedBox(height: 16),
                  TextField(
                    controller: _pathController,
                    decoration: InputDecoration(
                      labelText: 'Path',
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
                      child: const Text('Save'),
                    ),

                    const SizedBox(width: 8),
                    ElevatedButton(
                      focusNode: _focusNode,
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
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
