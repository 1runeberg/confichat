/*
 * Copyright 2024-25 Rune Berg (http://runeberg.io | https://github.com/1runeberg)
 * Licensed under Apache 2.0 (https://www.apache.org/licenses/LICENSE-2.0)
 * SPDX-License-Identifier: Apache-2.0
 */

import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:confichat/app_data.dart';
import 'package:confichat/themes.dart';
import 'package:confichat/ui_widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class AppSettings extends StatefulWidget {
  final AppData appData;
  const AppSettings({super.key, required this.appData});

  @override
  AppSettingsState createState() => AppSettingsState();
}

class AppSettingsState extends State<AppSettings> {
  final FocusNode _focusNode = FocusNode();

  final TextEditingController _scrollDuration = TextEditingController();
  final TextEditingController _windowWidth = TextEditingController();
  final TextEditingController _windowHeight = TextEditingController();
  final TextEditingController _rootpath = TextEditingController();


  late bool clearMessages;
  late int scrollDuration;
  late double windowWidth;
  late double windowHeight;
  late bool hasChanges;
  late String selectedTheme;
  late String selectedDefaultProvider;
  late String rootPath;

  @override
  void initState() {
    super.initState();
    _loadDefaults();
    _loadSettings();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _scrollDuration.dispose();
    _windowWidth.dispose();
    _windowHeight.dispose();
    _rootpath.dispose();
    _focusNode.dispose();
    
    super.dispose();
  }

  void _loadDefaults() {
    setState(() {
      clearMessages = true;
      scrollDuration = 100;
      windowWidth = 1024;
      windowHeight = 1024;
      selectedTheme = 'Onyx';
      selectedDefaultProvider = 'Ollama';
      rootPath = '';

      _scrollDuration.text = scrollDuration.toString();
      _windowWidth.text = windowWidth.toString();
      _windowHeight.text = windowHeight.toString();
    });
  }

  Future<void> _loadSettings() async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/${AppData.appStoragePath}/${AppData.appSettingsFile}';
    final file = File(filePath);

    if (await file.exists()) {
      final content = await file.readAsString();
      final jsonContent = json.decode(content);

      if (jsonContent.containsKey('app')) {
        setState(() {
          clearMessages = jsonContent['app']['clearMessages'] ?? widget.appData.clearMessagesOnModelSwitch;
          scrollDuration = jsonContent['app']['appScrollDurationInms'] ?? widget.appData.appScrollDurationInms;
          windowWidth = jsonContent['app']['windowWidth'] ?? widget.appData.windowWidth;
          windowHeight = jsonContent['app']['windowHeight'] ?? widget.appData.windowHeight;
          selectedTheme = jsonContent['app']['selectedTheme'] ?? 'Onyx'; 
          selectedDefaultProvider = jsonContent['app']['selectedDefaultProvider'] ?? 'Ollama';
        });

        if(widget.appData.navigatorKey.currentContext != null){
          Provider.of<ThemeProvider>(widget.appData.navigatorKey.currentContext!, listen: false).setTheme(selectedTheme); 
        }
      }
    }

    _scrollDuration.text = scrollDuration.toString();
    _windowWidth.text = windowWidth.toString();
    _windowHeight.text = windowHeight.toString();
  }

  void _applySettings() {
    widget.appData.clearMessagesOnModelSwitch = clearMessages;
    widget.appData.appScrollDurationInms = scrollDuration;
    widget.appData.windowWidth = windowWidth;
    widget.appData.windowHeight = windowHeight;
  }

  Future<void> _saveSettings() async {

    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/${AppData.appStoragePath}/${AppData.appSettingsFile}';
    final file = File(filePath);

    Map<String, dynamic> content = {};

    // Check if file exists, if not create directory structure
    if (await file.exists()) {
      final currentContent = await file.readAsString();
      content = json.decode(currentContent);
    } else {
      final appDirectory = Directory('${directory.path}/${AppData.appStoragePath}');
      if (!await appDirectory.exists()) {
        await appDirectory.create(recursive: true);
      }
    }

    // Update or add the "app" object with new settings
    content['app'] = {
      'clearMessages': clearMessages,
      'appScrollDurationInms': scrollDuration,
      'windowWidth': windowWidth,
      'windowHeight': windowHeight,
      'selectedTheme': selectedTheme,
      'selectedDefaultProvider': selectedDefaultProvider,
    };

    await file.writeAsString(const JsonEncoder.withIndent(' ').convert(content));
    _applySettings();

    // ignore: use_build_context_synchronously
    Navigator.of(context).pop();
  }

  void _checkForUnsavedChanges() async {
    final directory = AppData.instance.rootPath.isEmpty ? await getApplicationDocumentsDirectory() : Directory(AppData.instance.rootPath);
    final filePath = '${directory.path}/${AppData.appStoragePath}/${AppData.appSettingsFile}';
    final file = File(filePath);

    if (!file.existsSync()) {
      hasChanges = true;
    } else {
      final content = file.readAsStringSync();
      final jsonContent = json.decode(content);

      hasChanges = jsonContent['app']?['clearMessages'] != clearMessages ||
          jsonContent['app']?['appScrollDurationInms'] != scrollDuration ||
          jsonContent['app']?['windowWidth'] != windowWidth ||
          jsonContent['app']?['windowHeight'] != windowHeight ||
          jsonContent['app']?['selectedTheme'] != selectedTheme; // Check theme changes
    }

    if (hasChanges) {
      _showUnsavedChangesDialog();
    } else {
      // ignore: use_build_context_synchronously
      Navigator.of(context).pop();
    }
  }

  void _showUnsavedChangesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const DialogTitle(title:'Unsaved Changes', isError: true),
        content:  Text('You have unsaved changes. Do you want to save them?', style: Theme.of(context).textTheme.bodyLarge,),
        actions: <Widget>[
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            focusNode: _focusNode,
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ThemeProvider themeProvider = Provider.of<ThemeProvider>(context);

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Window title
              const DialogTitle(title: 'Application Settings'),
              const SizedBox(height: 18),

              SingleChildScrollView(
                scrollDirection: Axis.vertical, 
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag, 
                child: Column ( children: [

                  // Clear messages
                  SwitchListTile(
                    title: const Text('Clear messages when switching Models'),
                    activeColor: Theme.of(context).colorScheme.secondary,
                    contentPadding: EdgeInsets.zero,
                    value: clearMessages,
                    onChanged: (value) {
                      setState(() {
                        clearMessages = value;
                      });
                    },
                  ),

                  // Theme switcher
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text('Theme', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      MenuAnchor(
                        builder: (BuildContext context, MenuController controller, Widget? child) {
                          return TextButton(
                            onPressed: controller.open,
                            child: Row(
                              children: [
                                Text(themeProvider.currentThemeName),
                                const Icon(Icons.arrow_drop_down),
                              ],
                            ),
                          );
                        },
                        menuChildren: themeProvider.themes.keys.map((String themeName) {
                          return MenuItemButton(
                            onPressed: () {
                              themeProvider.setTheme(themeName);
                              setState(() {
                                selectedTheme = themeName; // Update selected theme
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                              child: Text(themeName),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),

                  // Default AI Provider switcher
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text('Default provider', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      MenuAnchor(
                        builder: (BuildContext context, MenuController controller, Widget? child) {
                          return TextButton(
                            onPressed: controller.open,
                            child: Row(
                              children: [
                                Text(selectedDefaultProvider),
                                const Icon(Icons.arrow_drop_down),
                              ],
                            ),
                          );
                        },
                        menuChildren: AiProvider.values.map((AiProvider provider) {
                          return MenuItemButton(
                            onPressed: () {
                               setState(() { selectedDefaultProvider = provider.name; });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                              child: Text(provider.name),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),

                  // Scroll duration
                  const SizedBox(height: 8),
                  TextField(
                    controller: _scrollDuration,
                    decoration: InputDecoration(labelText: 'Auto-scroll duration (ms)', labelStyle: Theme.of(context).textTheme.labelSmall),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        scrollDuration = int.tryParse(value) ?? widget.appData.appScrollDurationInms;
                      });
                    },
                  ),

                  // Window width
                  TextField(
                    controller: _windowWidth,
                    decoration: InputDecoration(labelText: 'Default window width', labelStyle: Theme.of(context).textTheme.labelSmall),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      setState(() {
                        windowWidth = double.tryParse(value) ?? widget.appData.windowWidth;
                      });
                    },
                  ),

                  // Window height
                  TextField(
                    controller: _windowHeight,
                    decoration: InputDecoration(labelText: 'Default window height', labelStyle: Theme.of(context).textTheme.labelSmall),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      setState(() {
                        windowHeight = double.tryParse(value) ?? widget.appData.windowHeight;
                      });
                    },
                  ),

                  // Default app root path
                  TextField(
                      decoration: InputDecoration(
                        labelText: 'Override app data path (leave blank for system default)',
                        labelStyle: Theme.of(context).textTheme.labelSmall,
                      ),
                      readOnly: true,
                      controller: _rootpath,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextButton(
                          onPressed: _pickDirectory,
                          child: const Text('Pick Directory'),
                        ),
                      ]
                    ),
                  ]
                )
              ),

              // Buttons
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  ElevatedButton(
                    onPressed: _saveSettings,
                    child: const Text('Save'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    focusNode: _focusNode,
                    onPressed: _checkForUnsavedChanges,
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

Future<void> _pickDirectory() async {

    final systemPath = await getApplicationDocumentsDirectory();
    String? directory = await FilePicker.platform.getDirectoryPath();

    if (directory != null) {
      setState(() {
        _rootpath.text = systemPath.path == directory ? '' : directory;
        rootPath =  _rootpath.text;
      });
    }
  }
}
