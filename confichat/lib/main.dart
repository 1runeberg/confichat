/*
 * Copyright 2024-25 Rune Berg (http://runeberg.io | https://github.com/1runeberg)
 * Licensed under Apache 2.0 (https://www.apache.org/licenses/LICENSE-2.0)
 * SPDX-License-Identifier: Apache-2.0
 */

import 'dart:ui';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:desktop_window/desktop_window.dart';
import 'package:confichat/ui_widgets.dart';
import 'package:confichat/themes.dart';
import 'package:confichat/app_data.dart';
import 'package:confichat/chat_notifiers.dart';
import 'package:confichat/ui_sidebar.dart';
import 'package:confichat/ui_canvass.dart';
import 'package:confichat/ui_app_bar.dart';
import 'package:confichat/language_config.dart';
import 'package:confichat/app_localizations.dart';
import 'package:confichat/locale_provider.dart';
import 'package:confichat/provider_validator.dart';
import 'package:confichat/ui_provider_setup.dart';
import 'package:confichat/region_util.dart';
import 'package:confichat/hinge_util.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RegionUtil.refreshStorefront();
  HingeUtil.listen();
  runApp(
    MultiProvider(
      providers: [
          ChangeNotifierProvider(create: (context) => ThemeProvider()),
          ChangeNotifierProvider(create: (context) => LocaleProvider()),
          ChangeNotifierProvider(create: (context) => ModelProvider()),
          ChangeNotifierProvider(create: (context) => SelectedModelProvider()),
      ],
      child: const ConfiChat(),
    ),
  );
}

class ConfiChat extends StatelessWidget {
  const ConfiChat({super.key});

  Future<bool> _loadAppSettings(BuildContext context) async {
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

        // Set language
        if (context.mounted) {
          final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
          final languageConfig = LanguageConfig();
          
          if (jsonContent['app'].containsKey('selectedLanguage')) {
            // Use saved language preference from settings
            final selectedLanguage = jsonContent['app']['selectedLanguage'];
            localeProvider.setLocale(Locale(selectedLanguage, ''));
          } else {
            // Use system language if available and supported
            final systemLocale = PlatformDispatcher.instance.locale.languageCode;
            if (languageConfig.isLanguageSupportedSync(systemLocale)) {
              localeProvider.setLocale(Locale(systemLocale, ''));
            } else {
              // Default to English if system language not supported
              localeProvider.setLocale(const Locale('en', ''));
            }
          }

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
            case 'gemini':
              selectedProvider = AiProvider.gemini;
              break;
            case 'llmman':
              selectedProvider = AiProvider.llmman;
              break;
            default:
              selectedProvider = AiProvider.ollama; // Fallback to Ollama if the string doesn't match
              break;
          }

          AppData.instance.defaultProvider = selectedProvider;
        }

      }
    }

    // Validate AI provider availability - implemented in the requirements
    if (context.mounted) {
      return await ProviderValidator.validateLocalProviders(AppData.instance) != null ||
             await ProviderValidator.checkApiKeyConfigured(AppData.instance) != null;
    }
    
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _loadAppSettings(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          // Update Theme and Locale providers
          return Consumer2<ThemeProvider, LocaleProvider>(
            builder: (context, themeProvider, localeProvider, child) {
              return MaterialApp(
                navigatorKey: AppData.instance.navigatorKey,
                debugShowCheckedModeBanner: false,
                title: AppData.appTitle,
                theme: themeProvider.currentTheme,
                locale: localeProvider.locale,
                supportedLocales: LanguageConfig().getSupportedLocalesSync(),
                localizationsDelegates: [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                home: HomePage(appData: AppData.instance, providerValid: snapshot.data ?? false),
                builder: (context, child) => _buildFoldedDuoTheme(context, child!),
              );
            },
          );

        } else {
          // Display a loading screen with a logo and a progress indicator
          return MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: LanguageConfig().getSupportedLocalesSync(),
            debugShowCheckedModeBanner: false,
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

// Folded Duo loses width to the status bar strip, so dialogs use narrower side insets
Widget _buildFoldedDuoTheme(BuildContext context, Widget child) {
  return ValueListenableBuilder<HingeStatus?>(
    valueListenable: HingeUtil.status,
    builder: (context, hingeStatus, _) {
      if (hingeStatus != HingeStatus.closed) return child;

      final theme = Theme.of(context);
      return Theme(
        data: theme.copyWith(
          dialogTheme: theme.dialogTheme.copyWith(
            insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
          ),
        ),
        child: child,
      );
    },
  );
}

class HomePage extends StatefulWidget {
  final AppData appData;
  final bool providerValid; 
  const HomePage({super.key, required this.appData, required this.providerValid});

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

  bool _validProvider = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Keep the chat and app bar state when the Duo layout moves them
  final GlobalKey _appBarKey = GlobalKey();
  final GlobalKey _canvassKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    _validProvider = widget.providerValid;

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      DesktopWindow.setWindowSize(Size(widget.appData.windowWidth, widget.appData.windowHeight));
    }

    _lifecycleState = SchedulerBinding.instance.lifecycleState;
    _lifecycleListener = AppLifecycleListener(
      onExitRequested:  _checkForUnsavedChat
    );

    // Check for valid provider after UI is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkProviderValidity();
    });

  }

  Future<void> _checkProviderValidity() async {
    if (!_validProvider && mounted) {
      bool isValid = await ProviderSetupManager.validateAndSetupProvider(
        context, 
        widget.appData,
        _scaffoldKey
      );
      
      if (mounted) {
        setState(() {
          _validProvider = isValid;
        });
        
        if (!isValid) {
          _showProviderSetup();
        }
      }
    }
  }

  void _showProviderSetup() {
    if (mounted) {
      ProviderSetupManager.showProviderSetupDialog(
        context, 
        widget.appData,
        _scaffoldKey  // Pass the scaffoldKey
      );
    }
  }

   Future<AppExitResponse> _checkForUnsavedChat() async {

    // If there are no unsaved changes, proceed to exit
    if(!widget.appData.haveUnsavedMessages) { return AppExitResponse.exit;}

    bool shouldExit = false;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: DialogTitle(title: AppLocalizations.of(context).translate("warning"), isError: true),
          content: Text(
            AppLocalizations.of(context).translate("unsavedMessagesWarning"),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          actions: [
            ElevatedButton(
              child: Text(AppLocalizations.of(context).translate("yes")),
              onPressed: () {
                shouldExit = true;
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text(AppLocalizations.of(context).translate("cancel")),
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
    return ValueListenableBuilder<HingeStatus?>(
      valueListenable: HingeUtil.status,
      builder: (context, hingeStatus, child) => _buildHomePage(context),
    );
  }

  Widget _buildHomePage(BuildContext context) {

    // Unfolded Duo landscape keeps the sidebar docked open (the drawer remains for provider setup)
    final dockSidebar = HingeUtil.layoutFor(MediaQuery.sizeOf(context)) == DuoLayout.landscape;

    // Close a floating drawer left open from portrait once the sidebar docks
    if (dockSidebar && (_scaffoldKey.currentState?.isDrawerOpen ?? false)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scaffoldKey.currentState?.closeDrawer());
    }

    final appBar = CCAppBar(
      key: _appBarKey,
      appData: widget.appData,
      chatSessionSelectedNotifier: chatSessionSelectedNotifier,
      providerController: providerController,
      providerModel: providerModel,
      showMenuButton: !dockSidebar,
    );

    final canvass = Canvass(key: _canvassKey, appData: widget.appData, chatSessionSelectedNotifier: chatSessionSelectedNotifier);

    return Scaffold( 
      key: _scaffoldKey,

      // (1) App bar (the docked layout places it above the chat only)
      appBar: dockSidebar ? null : appBar,
      
      // (2) Drawer
      drawer: Sidebar(appData: widget.appData, chatSessionSelectedNotifier: chatSessionSelectedNotifier),
      drawerEnableOpenDragGesture: !dockSidebar,

      onDrawerChanged: (isOpen) {
          if (!isOpen) {
            // Re-validate ai/llm provider when drawer is closed
            _checkProviderValidity();
          }
      },

      // (3) Chat canvass
      body: dockSidebar
          ? _buildDockedLayout(context, appBar, canvass)
          : Column( children: [ Expanded( child: canvass )]),
    
    );
  }

  // Full-height sidebar beside the app bar and chat, drawn last so its shadow falls on the chat
  Widget _buildDockedLayout(BuildContext context, PreferredSizeWidget appBar, Widget canvass) {
    const sidebarWidth = 304.0;

    return Stack(
      children: [
        Positioned.fill(
          left: sidebarWidth,
          child: Column(
            children: [
              SizedBox(height: appBar.preferredSize.height + MediaQuery.paddingOf(context).top, child: appBar),
              Expanded(child: canvass),
            ],
          ),
        ),

        // The status bar strip is on the far edge, so the sidebar ignores its inset
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: sidebarWidth,
          child: MediaQuery.removePadding(
            context: context,
            removeRight: true,
            child: Sidebar(appData: widget.appData, chatSessionSelectedNotifier: chatSessionSelectedNotifier, docked: true),
          ),
        ),
      ],
    );
  }

} //HomePageState
