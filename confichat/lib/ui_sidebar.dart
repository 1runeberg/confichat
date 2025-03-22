/*
 * Copyright 2024-25 Rune Berg (http://runeberg.io | https://github.com/1runeberg)
 * Licensed under Apache 2.0 (https://www.apache.org/licenses/LICENSE-2.0)
 * SPDX-License-Identifier: Apache-2.0
 */

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:confichat/app_data.dart';
import 'package:confichat/chat_notifiers.dart';
import 'package:confichat/persistent_storage.dart';
import 'package:confichat/ui_app_settings.dart';
import 'package:confichat/ui_ollama_options.dart';
import 'package:confichat/ui_llamacpp_options.dart';
import 'package:confichat/ui_openai_options.dart';
import 'package:confichat/ui_anthropic_options.dart';
import 'package:confichat/ui_terms_and_conditions.dart';
import 'package:confichat/ui_widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:confichat/app_localizations.dart';

class Sidebar extends StatefulWidget {
  final ChatSessionSelectedNotifier chatSessionSelectedNotifier;
  final AppData appData;
  const Sidebar({super.key, required this.appData, required this.chatSessionSelectedNotifier});

  @override
  SidebarState createState() => SidebarState();
}

class SidebarState extends State<Sidebar> {
  String _modelName = '';
  List<String> _chatSessionFiles = [];

  // Data notifier to canvass of selected chat session
  void _onChatSessionSelect(String value) {
    widget.chatSessionSelectedNotifier.value = value;
  }

  // Load chat sessions (if any)
  Future<void> _loadChatSessionFiles(String modelName, bool forceLoad) async {
    
    // Early exits
    if(modelName.isEmpty) { return; }
    if(modelName == _modelName && !forceLoad) { return; }

    _modelName = modelName;
    final userDirectory = AppData.instance.rootPath.isEmpty ? await getApplicationDocumentsDirectory() : Directory(AppData.instance.rootPath);
    final directory = Directory('${userDirectory.path}/${AppData.appStoragePath}');

    List<String> files = [];
    await PersistentStorage.getJsonFilenames(filenames: files, directory: directory, modelName: modelName, withExtension: false);

    setState(() {
      _chatSessionFiles = files;
    });

  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Consumer<SelectedModelProvider>(
      builder: (context, selectedModelProvider, child) {

        // Refresh chat session files when selected model changes
        if(selectedModelProvider.selectedModel != null){
            _loadChatSessionFiles(selectedModelProvider.selectedModel!.name, false);
        }
        
        // Open drawer
        return Drawer( 
          backgroundColor: Theme.of(context).colorScheme.secondary,
          child: Column( children: [
 
              // (1) Header
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                ),
                child: Row( mainAxisAlignment: MainAxisAlignment.center, children: [Image.asset(
                'assets/confichat_logo_text_outline.png',
                fit: BoxFit.scaleDown,
              )]) ,
              ),      
    
              // (2) Accordion
              Expanded( child: ListView(
              children: [

                // (2.1) Chat sessions
                ExpansionTile(   

                  title: OutlinedText(
                    textData: loc.translate('sidebar.sections.chatSessions'),
                    outlineWidth: 1,
                    textColor: Theme.of(context).colorScheme.onSurface,
                    outlineColor: Theme.of(context).colorScheme.surface,
                    textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

                  leading: OutlinedIcon(
                    icon: Icons.forum,
                    size: 25.0,
                    iconColor: Theme.of(context).colorScheme.surface,
                    outlineColor: Theme.of(context).colorScheme.surfaceDim,
                    outlineWidth: 1.0,
                  ),

                  initiallyExpanded: true,
                  maintainState: true,
                  children:  [
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                      maxHeight: 400.0, 
                      ),
                      child: SingleChildScrollView(
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag, 
                        child: Column(
                          children: _chatSessionFiles.map((filename) {
                            return ListTile(
                              title: Text(filename),
                              onTap: () {
                                _onChatSessionSelect(filename);
                              },
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  _handlePopupMenuAction(value, filename, selectedModelProvider.selectedModel);
                                },
                                itemBuilder: (context) => [

                                  // Allow updates if there are unsaved messages
                                  if(widget.appData.haveUnsavedMessages )
                                  PopupMenuItem(
                                    value: 'update',
                                    child: Text(loc.translate('sidebar.options.update')),
                                  ),

                                  PopupMenuItem(
                                    value: 'rename',
                                    child: Text(loc.translate('sidebar.options.rename')),
                                  ),

                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text(loc.translate('sidebar.options.delete')),
                                  ),

                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),

                // (2.2) Settings
                ExpansionTile(

                  title: OutlinedText(
                    textData: loc.translate('sidebar.sections.settings'),
                    outlineWidth: 1,
                    textColor: Theme.of(context).colorScheme.onSurface,
                    outlineColor: Theme.of(context).colorScheme.surface,
                    textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

                  leading: OutlinedIcon(
                    icon: Icons.settings,
                    size: 25.0,
                    iconColor: Theme.of(context).colorScheme.surface,
                    outlineColor: Theme.of(context).colorScheme.surfaceDim,
                    outlineWidth: 1.0,
                  ),

                  initiallyExpanded: true,
                  maintainState: true,
                  children: <Widget>[

                    // (2.2.1) Ollama options
                    ListTile(
                      title: Text(AiProvider.ollama.name),
                      onTap: () {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) {
                            return OllamaOptions(appData: widget.appData);
                          },
                        );
                      },
                    ),

                    // (2.2.2) LlamaCpp options
                    ListTile(
                      title: Text(AiProvider.llamacpp.name),
                      onTap: () {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) {
                            return LlamaCppOptions(appData: widget.appData);
                          },
                        );
                      },
                    ),

                    // (2.2.3) OpenAI options
                    ListTile(
                      title: Text(AiProvider.openai.name),
                      onTap: () {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) {
                            return ChatGPTOptions(appData: widget.appData);
                          },
                        );
                      },
                    ),

                    // (2.2.4) Anthropic options
                    ListTile(
                      title: Text(AiProvider.anthropic.name),
                      onTap: () {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) {
                            return AnthropicOptions(appData: widget.appData);
                          },
                        );
                      },
                    ),

                    // (2.2.5) App settings
                    ListTile(
                      title: Text(loc.translate('sidebar.options.applicationSettings')),
                      onTap: () {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) {
                            return AppSettings(appData: widget.appData);
                          },
                        );
                      },
                    ),

                  ],
                ),

                // (2.3) Legal
                ExpansionTile(

                  title: OutlinedText(
                    textData: loc.translate('sidebar.sections.legal'),
                    outlineWidth: 1,
                    textColor: Theme.of(context).colorScheme.onSurface,
                    outlineColor: Theme.of(context).colorScheme.surface,
                    textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

                  leading: OutlinedIcon(
                    icon: Icons.policy,
                    size: 25.0,
                    iconColor: Theme.of(context).colorScheme.surface,
                    outlineColor: Theme.of(context).colorScheme.surfaceDim,
                    outlineWidth: 1.0,
                  ),

                  initiallyExpanded: false,
                  maintainState: true,
                  children: <Widget>[

                    // (2.3.1) Terms and Conditions
                    ListTile(
                      title: Text(loc.translate('sidebar.legal.termsAndConditions')),
                      onTap: () {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) {
                            return const TermsAndConditions();
                          },
                        );
                      },
                    ),

                    // (2.3.2) Licenses
                    ListTile(
                      title: Text(loc.translate('sidebar.legal.thirdPartyLicenses')),
                      onTap: () {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) {
                            return const LicensePage();
                          },
                        );
                      },
                    ),

                  ],
                ),              
              
              ],
            ),
          ),
        ],
      ),
    );
  
    }, // builder(consumer)
  );
 }

  void _handlePopupMenuAction(String action, String filename, ModelItem? model) async {
    switch (action) {

      case 'update':
        await _updateChatSession(filename, model);
        break;

      case 'rename':
        _showRenameDialog(filename, model);
        break;

      case 'delete':
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: DialogTitle(title: AppLocalizations.of(context).translate('sidebar.confirmDelete.title'), isError: true),
              content: Text(AppLocalizations.of(context).translate('sidebar.confirmDelete.message').replaceAll('{filename}', filename), style: Theme.of(context).textTheme.bodyLarge,),
              actions: [
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); 
                    _deleteChatSession(filename, model);
                  },
                  child: Text(AppLocalizations.of(context).translate('sidebar.confirmDelete.buttons.delete')),
                ),
                ElevatedButton(
                  autofocus: true,
                  onPressed: () {
                    Navigator.of(context).pop(); 
                  },
                  child: Text(AppLocalizations.of(context).translate('sidebar.confirmDelete.buttons.cancel')),
                ),
              ],
            );
          },
        );
        break;

    }

  } // _handlePopupMenuAction

  Future<void> _deleteChatSession(String filename, ModelItem? model) async {

    if(model==null){ return; }

    final userDirectory = AppData.instance.rootPath.isEmpty ? await getApplicationDocumentsDirectory() : Directory(AppData.instance.rootPath);
    final directory = Directory('${userDirectory.path}/${AppData.appStoragePath}');
    await PersistentStorage.deleteFile(directory, model.name, filename);
    _loadChatSessionFiles(model.name, true);

  } // _deleteChatSession

  void _showRenameDialog(String filename, ModelItem? model) {
    final TextEditingController newNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: DialogTitle(title: AppLocalizations.of(context).translate('sidebar.renameDialog.title')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: TextEditingController(text: filename),
                readOnly: true,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).translate('sidebar.renameDialog.fields.name'),
                  labelStyle: Theme.of(context).textTheme.labelSmall,
                  border: const UnderlineInputBorder(),
                ),
              ),

              const SizedBox(height: 10),
              TextFormField(
                controller: newNameController,
                decoration:  InputDecoration(
                  labelText: AppLocalizations.of(context).translate('sidebar.renameDialog.fields.newName'),
                  labelStyle: Theme.of(context).textTheme.labelSmall,
                  border: const UnderlineInputBorder(),
                ),
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  } 
                  
                  if (!RegExp(r'^[a-zA-Z0-9]([a-zA-Z0-9 _\-]*(?!\.\.))*[a-zA-Z0-9]?$')
                      .hasMatch(value)) {
                    return AppLocalizations.of(context).translate('sidebar.renameDialog.validation.invalidFormat');
                  }

                  return null;
                },
              ),
            ],
          ),
          
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                final newName = newNameController.text.trim();
                if (newName.isNotEmpty) {
                  Navigator.of(context).pop();
                  _renameChatSession(filename, newName, model);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(backgroundColor: Theme.of(context).colorScheme.error, content: Text(AppLocalizations.of(context).translate('sidebar.renameDialog.validation.required'))),
                  );
                }
              },
              child: Text(AppLocalizations.of(context).translate('sidebar.renameDialog.buttons.rename')),
            ),
            
            ElevatedButton(
              autofocus: true,
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context).translate('sidebar.renameDialog.buttons.cancel')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _renameChatSession(String oldName, String newName, ModelItem? model) async {

      if(model==null){ return; }

      final userDirectory = AppData.instance.rootPath.isEmpty ? await getApplicationDocumentsDirectory() : Directory(AppData.instance.rootPath);
      final directory = Directory('${userDirectory.path}/${AppData.appStoragePath}');
      await PersistentStorage.renameFile(directory, model.name, oldName, newName);
      await _loadChatSessionFiles(model.name, true);

  } // _renameChatSession

  Future<void> _updateChatSession(String filename, ModelItem? model) async {

    if(model==null || widget.appData.callbackUpdateSession == null){ return; }

    // Check for encryption
    final directory = AppData.instance.rootPath.isEmpty ? await getApplicationDocumentsDirectory() : Directory(AppData.instance.rootPath);
    Directory chatSessionsDir = Directory('${directory.path}/${AppData.appStoragePath}');
    EncryptionPayload encryptionPayload = await PersistentStorage.getEncryptionPayload(chatSessionsDir, model.name, filename);

    // Close sidebar
    if(mounted){ Navigator.of(context).pop();  }

    // Get the canvass to update the chat session
    await widget.appData.callbackUpdateSession!(chatSessionsDir, model.name, filename, encryptionPayload);

  }

} // Sidebar state