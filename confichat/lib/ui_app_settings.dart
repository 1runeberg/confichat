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
import 'package:confichat/app_localizations.dart';
import 'package:confichat/locale_provider.dart';

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
  late String selectedLanguage;

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
      selectedLanguage = 'en';
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
          selectedLanguage = jsonContent['app']['selectedLanguage'] ?? 'en';
          selectedDefaultProvider = jsonContent['app']['selectedDefaultProvider'] ?? 'Ollama';
        });

        // Set theme
        if(widget.appData.navigatorKey.currentContext != null){
          Provider.of<ThemeProvider>(widget.appData.navigatorKey.currentContext!, listen: false).setTheme(selectedTheme); 
        }

        // Set language
        if(widget.appData.navigatorKey.currentContext != null){
          Provider.of<LocaleProvider>(widget.appData.navigatorKey.currentContext!, listen: false)
              .setLocale(Locale(selectedLanguage, ''));
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
      'selectedLanguage': selectedLanguage,
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
          jsonContent['app']?['selectedTheme'] != selectedTheme ||
          jsonContent['app']?['selectedLanguage'] != selectedLanguage;
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
        title: DialogTitle(title: AppLocalizations.of(context).translate('appSettings.unsavedChanges.title'), isError: true),
        content:  Text(AppLocalizations.of(context).translate('appSettings.unsavedChanges.message'), style: Theme.of(context).textTheme.bodyLarge,),
        actions: <Widget>[
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(AppLocalizations.of(context).translate('appSettings.buttons.cancel')),
          ),
          ElevatedButton(
            focusNode: _focusNode,
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text(AppLocalizations.of(context).translate('appSettings.buttons.exit')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
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
              DialogTitle(title: loc.translate('appSettings.title')),
              const SizedBox(height: 18),

              SingleChildScrollView(
                scrollDirection: Axis.vertical, 
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag, 
                child: Column ( children: [

                  // Clear messages
                  SwitchListTile(
                    title: Text(loc.translate('appSettings.clearMessages')),
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
                      Text(loc.translate('appSettings.theme'), style: TextStyle(fontSize: 16)),
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

                  // Language switcher
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(AppLocalizations.of(context).translate('language'), style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      MenuAnchor(
                        builder: (BuildContext context, MenuController controller, Widget? child) {
                          return TextButton(
                            onPressed: controller.open,
                            child: Row(
                              children: [
                                Text(selectedLanguage == 'en' ? 'English' :
                                selectedLanguage == 'ar' ? 'العربية' :
                                selectedLanguage == 'de' ? 'Deutsch' :
                                selectedLanguage == 'es' ? 'Español' :
                                selectedLanguage == 'fil' ? 'Filipino' :
                                selectedLanguage == 'fr' ? 'Français' :
                                selectedLanguage == 'he' ? 'עברית' :
                                selectedLanguage == 'it' ? 'Italiano' :
                                selectedLanguage == 'th' ? 'ไทย' :
                                selectedLanguage == 'zh' ? '中文' : 'English'),
                                const Icon(Icons.arrow_drop_down),
                              ],
                            ),
                          );
                        },
                        menuChildren: [
                          MenuItemButton(
                            onPressed: () {
                              setState(() {
                                selectedLanguage = 'en';
                                if(widget.appData.navigatorKey.currentContext != null) {
                                  Provider.of<LocaleProvider>(widget.appData.navigatorKey.currentContext!, listen: false)
                                      .setLocale(const Locale('en', ''));
                                }
                              });
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                              child: Text('English'),
                            ),
                          ),
                          MenuItemButton(
                            onPressed: () {
                              setState(() {
                                selectedLanguage = 'ar';
                                if(widget.appData.navigatorKey.currentContext != null) {
                                  Provider.of<LocaleProvider>(widget.appData.navigatorKey.currentContext!, listen: false)
                                      .setLocale(const Locale('ar', ''));
                                }
                              });
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                              child: Text('العربية'),
                            ),
                          ),
                          MenuItemButton(
                            onPressed: () {
                              setState(() {
                                selectedLanguage = 'de';
                                if(widget.appData.navigatorKey.currentContext != null) {
                                  Provider.of<LocaleProvider>(widget.appData.navigatorKey.currentContext!, listen: false)
                                      .setLocale(const Locale('de', ''));
                                }
                              });
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                              child: Text('Deutsch'),
                            ),
                          ),
                          MenuItemButton(
                            onPressed: () {
                              setState(() {
                                selectedLanguage = 'es';
                                if(widget.appData.navigatorKey.currentContext != null) {
                                  Provider.of<LocaleProvider>(widget.appData.navigatorKey.currentContext!, listen: false)
                                      .setLocale(const Locale('es', ''));
                                }
                              });
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                              child: Text('Español'),
                            ),
                          ),
                          MenuItemButton(
                            onPressed: () {
                              setState(() {
                                selectedLanguage = 'fil';
                                if(widget.appData.navigatorKey.currentContext != null) {
                                  Provider.of<LocaleProvider>(widget.appData.navigatorKey.currentContext!, listen: false)
                                      .setLocale(const Locale('fil', ''));
                                }
                              });
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                              child: Text('Filipino'),
                            ),
                          ),
                          MenuItemButton(
                            onPressed: () {
                              setState(() {
                                selectedLanguage = 'fr';
                                if(widget.appData.navigatorKey.currentContext != null) {
                                  Provider.of<LocaleProvider>(widget.appData.navigatorKey.currentContext!, listen: false)
                                      .setLocale(const Locale('fr', ''));
                                }
                              });
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                              child: Text('Français'),
                            ),
                          ),
                          MenuItemButton(
                            onPressed: () {
                              setState(() {
                                selectedLanguage = 'he';
                                if(widget.appData.navigatorKey.currentContext != null) {
                                  Provider.of<LocaleProvider>(widget.appData.navigatorKey.currentContext!, listen: false)
                                      .setLocale(const Locale('he', ''));
                                }
                              });
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                              child: Text('עברית'),
                            ),
                          ),
                          MenuItemButton(
                            onPressed: () {
                              setState(() {
                                selectedLanguage = 'it';
                                if(widget.appData.navigatorKey.currentContext != null) {
                                  Provider.of<LocaleProvider>(widget.appData.navigatorKey.currentContext!, listen: false)
                                      .setLocale(const Locale('it', ''));
                                }
                              });
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                              child: Text('Italiano'),
                            ),
                          ),
                          MenuItemButton(
                            onPressed: () {
                              setState(() {
                                selectedLanguage = 'th';
                                if(widget.appData.navigatorKey.currentContext != null) {
                                  Provider.of<LocaleProvider>(widget.appData.navigatorKey.currentContext!, listen: false)
                                      .setLocale(const Locale('th', ''));
                                }
                              });
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                              child: Text('ไทย'),
                            ),
                          ),
                          MenuItemButton(
                            onPressed: () {
                              setState(() {
                                selectedLanguage = 'zh';
                                if(widget.appData.navigatorKey.currentContext != null) {
                                  Provider.of<LocaleProvider>(widget.appData.navigatorKey.currentContext!, listen: false)
                                      .setLocale(const Locale('zh', 'CN'));
                                }
                              });
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                              child: Text('中文'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Default AI Provider switcher
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(loc.translate('appSettings.defaultProvider'), style: TextStyle(fontSize: 16)),
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
                    decoration: InputDecoration(labelText: loc.translate('appSettings.scrollDuration'), labelStyle: Theme.of(context).textTheme.labelSmall),
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
                    decoration: InputDecoration(labelText: loc.translate('appSettings.windowWidth'), labelStyle: Theme.of(context).textTheme.labelSmall),
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
                    decoration: InputDecoration(labelText: loc.translate('appSettings.windowHeight'), labelStyle: Theme.of(context).textTheme.labelSmall),
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
                        labelText: loc.translate('appSettings.overridePath'),
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
                          child: Text(loc.translate('appSettings.pickDirectory')),
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
                    child: Text(loc.translate('appSettings.buttons.save')),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    focusNode: _focusNode,
                    onPressed: _checkForUnsavedChanges,
                    child: Text(loc.translate('appSettings.buttons.cancel')),
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
