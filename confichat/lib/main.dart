/*
 * Copyright 2024 Rune Berg (http://runeberg.io | https://github.com/1runeberg)
 * Licensed under Apache 2.0 (https://www.apache.org/licenses/LICENSE-2.0)
 * SPDX-License-Identifier: Apache-2.0
 */

import 'dart:ui';

import 'package:confichat/ui_widgets.dart';
import 'package:flutter/material.dart';
import 'package:confichat/themes.dart';
import 'package:flutter/scheduler.dart';
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
          final selectedTheme = jsonContent['app']['selectedTheme'] ?? 'Onyx';
          themeProvider.setTheme(selectedTheme); 
        }

        // Set default provider
        if(context.mounted){
          final defaultProvider = jsonContent['app']['selectedDefaultProvider'] ?? 'Ollama';

          AiProvider selectedProvider;
          switch (defaultProvider.toLowerCase()) {
            case 'ollama':
              selectedProvider = AiProvider.ollama;
              break;
            case 'llamacpp':
              selectedProvider = AiProvider.llamacpp;
              break;
            case 'openai':
              selectedProvider = AiProvider.openai;
              break;
            case 'anthropic':
              selectedProvider = AiProvider.anthropic;
              break;
            default:
              selectedProvider = AiProvider.ollama; // Fallback to Ollama if the string doesn't match
              break;
          }

          AppData.instance.defaultProvider = selectedProvider;
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
                navigatorKey: AppData.instance.navigatorKey,
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
                    Image.asset('assets/confichat_logo.png', width: 100, height: 100,),
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

class _HomePageState extends State<HomePage>  {
  final ChatSessionSelectedNotifier chatSessionSelectedNotifier = ChatSessionSelectedNotifier();
  TextEditingController providerController = TextEditingController();
  AiProvider? selectedProvider;

  TextEditingController providerModel = TextEditingController();
  ModelItem? selectedModel;

  late final AppLifecycleListener _lifecycleListener;
  late AppLifecycleState? _lifecycleState;

  @override
  void initState() {
    super.initState();

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      DesktopWindow.setWindowSize(Size(widget.appData.windowWidth, widget.appData.windowHeight));
    }

    _lifecycleState = SchedulerBinding.instance.lifecycleState;
    _lifecycleListener = AppLifecycleListener(
      onExitRequested:  _checkForUnsavedChat
    );
  }

   Future<AppExitResponse> _checkForUnsavedChat() async {

    // If there are no unsaved changes, proceed to exit
    if(!widget.appData.haveUnsavedMessages) { return AppExitResponse.exit;}

    bool shouldExit = false;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const DialogTitle(title: 'Warning', isError: true),
          content: Text(
            'There are unsaved messages in the current chat window - they will be lost. Proceed?',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          actions: [
            ElevatedButton(
              child: const Text('Yes'),
              onPressed: () {
                shouldExit = true;
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Cancel'),
              onPressed: () {
                shouldExit = false;
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );

    return shouldExit ? AppExitResponse.exit : AppExitResponse.cancel;
 
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
