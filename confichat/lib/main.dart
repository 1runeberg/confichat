/*
 * Copyright 2024 Rune Berg (http://runeberg.io | https://github.com/1runeberg)
 * Licensed under Apache 2.0 (https://www.apache.org/licenses/LICENSE-2.0)
 * SPDX-License-Identifier: Apache-2.0
 */

import 'package:flutter/material.dart';
import 'package:confichat/themes.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:desktop_window/desktop_window.dart';
import 'dart:io';
import 'dart:convert';

import 'package:confichat/app_data.dart';
import 'package:confichat/chat_notifiers.dart';
import 'package:confichat/ui_sidebar.dart';
import 'package:confichat/ui_canvass.dart';
import 'package:confichat/ui_app_bar.dart';


void main() {
  runApp(
    MultiProvider(
      providers: [
          ChangeNotifierProvider(create: (context) => ThemeProvider()),
          ChangeNotifierProvider(create: (context) => ModelProvider()),
          ChangeNotifierProvider(create: (context) => SelectedModelProvider()),
      ],
      child: const ConfiChat(),
    ),
  );
}

class ConfiChat extends StatelessWidget {
  const ConfiChat({super.key});

  Future<void> _loadAppSettings(BuildContext context) async {
    final directory = AppData.instance.rootPath.isEmpty ? await getApplicationDocumentsDirectory() : Directory(AppData.instance.rootPath);
    final filePath =
        '${directory.path}/${AppData.appStoragePath}/${AppData.appSettingsFile}';
    final file = File(filePath);

    if (await file.exists()) {
      final content = await file.readAsString();
      final jsonContent = json.decode(content);

      if (jsonContent.containsKey('app')) {
        // Apply settings if they exist
        final appData = AppData.instance;
        appData.clearMessagesOnModelSwitch =
            jsonContent['app']['clearMessages'] ?? appData.clearMessagesOnModelSwitch;
        appData.appScrollDurationInms =
            jsonContent['app']['appScrollDurationInms'] ?? appData.appScrollDurationInms;
        appData.windowWidth =
            jsonContent['app']['windowWidth'] ?? appData.windowWidth;
        appData.windowHeight =
            jsonContent['app']['windowHeight'] ?? appData.windowHeight;

        // Set theme
        if (context.mounted) {
          final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
          final selectedTheme = jsonContent['app']['selectedTheme'] ?? 'Light';
          themeProvider.setTheme(selectedTheme); 
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _loadAppSettings(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return MaterialApp(
                title: AppData.appTitle,
                theme: themeProvider.currentTheme,
                home: HomePage(appData: AppData.instance),
              );
            },
          );
        } else {
          // Display a loading screen with a logo and a progress indicator
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/confichat_logo.png',
                      width: 100, // Set the desired width for the logo
                      height: 100, // Set the desired height for the logo
                    ),
                    const SizedBox(height: 20),
                    const CircularProgressIndicator(),
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
  }
}

class HomePage extends StatefulWidget {
  final AppData appData;
  const HomePage({super.key, required this.appData});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  final ChatSessionSelectedNotifier chatSessionSelectedNotifier = ChatSessionSelectedNotifier();

  TextEditingController providerController = TextEditingController();
  AiProvider? selectedProvider;

  TextEditingController providerModel = TextEditingController();
  ModelItem? selectedModel;

  @override
  void initState() {
      super.initState();

      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        DesktopWindow.setWindowSize(Size(widget.appData.windowWidth, widget.appData.windowHeight));
      }
  }

  @override
  void dispose() {
    providerModel.dispose();
    providerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold( 
      
      // (1) App bar
      appBar: CCAppBar(appData: widget.appData, chatSessionSelectedNotifier: chatSessionSelectedNotifier, providerController: providerController, providerModel: providerModel),
      
      // (2) Drawer
      drawer: Sidebar( appData: widget.appData, chatSessionSelectedNotifier: chatSessionSelectedNotifier),

      // (3) Chat canvass
      body: Column( children: [ Expanded(
              child: Canvass(appData: widget.appData, chatSessionSelectedNotifier: chatSessionSelectedNotifier)
            )])   
    
    );
  }

} //HomePageState
