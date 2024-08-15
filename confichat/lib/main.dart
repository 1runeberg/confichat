/*
 * Copyright 2024 Rune Berg (http://runeberg.io | https://github.com/1runeberg)
 * Licensed under Apache 2.0 (https://www.apache.org/licenses/LICENSE-2.0)
 * SPDX-License-Identifier: Apache-2.0
 */

import 'package:flutter/material.dart';
import 'package:confichat/themes.dart';
import 'package:confichat/ui_widgets.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:desktop_window/desktop_window.dart';
import 'dart:io';
import 'dart:convert';

import 'package:confichat/app_data.dart';
import 'package:confichat/chat_notifiers.dart';
import 'package:confichat/ui_sidebar.dart';
import 'package:confichat/ui_add_model.dart';
import 'package:confichat/ui_config_model.dart';
import 'package:confichat/ui_canvass.dart';


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
      _switchProvider(AiProvider.ollama);
      _populateModelList(true); 

      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        DesktopWindow.setWindowSize(Size(widget.appData.windowWidth, widget.appData.windowHeight));
      }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      // (1) Application bar
      appBar: AppBar(
        title: Row(mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Image.asset(
                'assets/confichat_logo.png',
                fit: BoxFit.contain,
              ),
            ],
          ),

        toolbarHeight: 80.0,
        toolbarOpacity: 0.8,
        elevation: 5.0,
        shadowColor: const Color.fromARGB(255, 145, 145, 145),
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),

        actions: <Widget> [

          // (1.1) Model providers
          Container(
            margin: const EdgeInsets.all(10),
            child: ( 
              DropdownMenu<AiProvider>(
                    initialSelection: AiProvider.ollama,             
                    controller: providerController,
                    requestFocusOnTap: true,
                    textStyle: TextStyle( color: Theme.of(context).colorScheme.surface, fontWeight: FontWeight.normal, fontSize: 18 ),
                    label: OutlinedText(
                      textData: 'Provider', 
                      outlineColor: Theme.of(context).colorScheme.onSurface,
                      textStyle: TextStyle( color: Theme.of(context).colorScheme.surface, fontWeight: FontWeight.bold, fontSize: 18)
                    ),

                  inputDecorationTheme: InputDecorationTheme(
                    enabledBorder: OutlineInputBorder( borderSide: BorderSide(color: Theme.of(context).colorScheme.surface) ),
                    focusedBorder: OutlineInputBorder( borderSide: BorderSide(color: Theme.of(context).colorScheme.surface) ),
                    fillColor: Theme.of(context).colorScheme.tertiaryContainer,
                    suffixIconColor: Theme.of(context).colorScheme.surface,
                    filled: true,
                  ),

                  onSelected: (AiProvider? provider) { _switchProvider(provider); },
                  dropdownMenuEntries: AiProvider.values
                      .map<DropdownMenuEntry<AiProvider>>(
                          (AiProvider modelProvider) {
                    return DropdownMenuEntry<AiProvider>(
                      value: modelProvider,
                      label: modelProvider.name,
                    );
                  }).toList(),
                )
              ),
          ),

          // (1.2) Models
          Consumer<ModelProvider>( builder: (context, modelProvider, child) {
          return Container(
            margin: const EdgeInsets.all(10),
            child: DropdownMenu<ModelItem>(
                        controller: providerModel,
                        enabled: modelProvider.models.isNotEmpty,
                        width: 200,
                        requestFocusOnTap: true,
                        textStyle: TextStyle( color: Theme.of(context).colorScheme.surface, fontWeight: FontWeight.normal, fontSize: 18 ),
                        label: OutlinedText(
                          textData: 'Current Model', 
                          outlineColor: Colors.black,
                          textStyle: TextStyle( color: Theme.of(context).colorScheme.surface, fontWeight: FontWeight.bold, fontSize: 18)
                        ),

                        inputDecorationTheme: InputDecorationTheme(
                          enabledBorder: OutlineInputBorder( borderSide: BorderSide(color: Theme.of(context).colorScheme.surface) ),
                          focusedBorder: OutlineInputBorder( borderSide: BorderSide(color: Theme.of(context).colorScheme.surface) ),
                          fillColor: Theme.of(context).colorScheme.tertiaryContainer,
                          suffixIconColor: Theme.of(context).colorScheme.surface,
                          filled: true,
                        ),

                        onSelected: (ModelItem? model) {

                          if(model != null){
                            if(widget.appData.clearMessagesOnModelSwitch) {
                              _showModelChangeWarning(context, model);
                            } else {
                              _setModelItem(model);
                            }
                          }
                          
                        },
                        dropdownMenuEntries: modelProvider.models
                            .map((modelItem) => DropdownMenuEntry<ModelItem>(
                                  value: modelItem,
                                  label: modelItem.name,
                                )).toList(),
            )
          ); 
          }),

          // (1.3) Config button
          Consumer<ModelProvider>( builder: (context, modelProvider, child) {
            return IconButton(
              icon: const Icon(Icons.build_circle_rounded), 
              hoverColor: Theme.of(context).colorScheme.secondaryContainer,
              onPressed: modelProvider.models.isEmpty ? null : () async {
                await showDialog(
                  context: context, 
                  builder: 
                    (BuildContext context) { return ModelConfigDialog(modelName: providerModel.text); }
                );
              });
          },),

          // (1.4) Add button
          Consumer<ModelProvider>( builder: (context, modelProvider, child) {
            return IconButton(
              icon: const Icon(Icons.add_circle), 
              hoverColor: Theme.of(context).colorScheme.secondaryContainer,
              disabledColor: Theme.of(context).colorScheme.surfaceDim,
              onPressed: modelProvider.models.isEmpty || widget.appData.api.aiProvider.id > 0  ? null : () async {
    
                // Collect the names of all models into a list
                List<String> modelList = modelProvider.models.map((model) => model.name).toList();

                await showDialog(
                  context: context, 
                  builder: 
                    (BuildContext context) { return AddModelDialog(modelNames: modelList); }
                );
                
                _populateModelList(false);

              });
          },),

        ]),

      // (2) Drawer
      drawer: Sidebar( appData: widget.appData, chatSessionSelectedNotifier: chatSessionSelectedNotifier),

      // (3) Chat canvass
      body: Column( children: [ Expanded(
              child: Canvass(appData: widget.appData, chatSessionSelectedNotifier: chatSessionSelectedNotifier)
            )])

    );
  }

  Future<void> _populateModelList(bool selectFirst) async {
    
    // Check for api app settings
    await widget.appData.api.loadSettings();

    // Retrieve active models for provider
    List<ModelItem> newModels = [];
    await widget.appData.api.getModels(newModels);

    if (mounted){
      // Update the provider with the new models
      Provider.of<ModelProvider>(context, listen: false).updateModels(newModels);
    
      // Update the selected model
      if (newModels.isNotEmpty) {
        final selectedModelProvider = Provider.of<SelectedModelProvider>(context, listen: false);  
        final initialModel = selectFirst ? newModels.first : newModels.last; 
        selectedModelProvider.updateSelectedModel(initialModel);
        providerModel.text = initialModel.name; 
      } else {
        providerModel.clear();
      }
    } 
  }

  void _showModelChangeWarning(BuildContext context, ModelItem newModel) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Warning'),
          content: const Text(
            'Any messages in the current chat window will be lost. Proceed?',
          ),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('Yes'),
              onPressed: () {
                _setModelItem(newModel);
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _setModelItem(ModelItem newModel){
    if(mounted) {
      setState(() {
        selectedModel = newModel;
        providerModel.text = newModel.name;
        Provider.of<SelectedModelProvider>(context, listen: false).updateSelectedModel(newModel);
      });
    }
  }

  void _switchProvider(AiProvider? provider){

    if(provider == null) {return; }
    widget.appData.setProvider(provider);

    if(mounted) {
      setState(() {
        selectedProvider = provider;
      });

      _populateModelList(true);
    }
  }

} //HomePageState
