/*
 * Copyright 2024 Rune Berg (http://runeberg.io | https://github.com/1runeberg)
 * Licensed under Apache 2.0 (https://www.apache.org/licenses/LICENSE-2.0)
 * SPDX-License-Identifier: Apache-2.0
 */

import 'package:confichat/ui_terms_and_conditions.dart';
import 'package:flutter/material.dart';

import 'dart:io';

import 'package:confichat/app_data.dart';
import 'package:confichat/chat_notifiers.dart';
import 'package:confichat/persistent_storage.dart';
import 'package:confichat/ui_app_settings.dart';
import 'package:confichat/ui_chatgpt_options.dart';
import 'package:confichat/ui_ollama_options.dart';
import 'package:confichat/ui_widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';


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
                    textData: 'Chat Sessions', 
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
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'rename',
                                    child: Text('Rename'),
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
                    textData: 'Settings', 
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

                    // (2.2.2) OpenAI options
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

                    // (2.2.3) App settings
                    ListTile(
                      title: const Text('Application settings'),
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
                    textData: 'Legal', 
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
                      title: const Text('Terms and Conditions'),
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
                      title: const Text('Third-Party Licenses'),
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

  void _handlePopupMenuAction(String action, String filename, ModelItem? model) {
    switch (action) {

      case 'delete':
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const DialogTitle(title: 'Confirm Delete'),
              content: Text('Are you sure you want to delete $filename?'),
              actions: [
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); 
                    _deleteChatSession(filename, model);
                  },
                  child: const Text('Delete'),
                ),
                ElevatedButton(
                  autofocus: true,
                  onPressed: () {
                    Navigator.of(context).pop(); 
                  },
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
        break;

      case 'rename':
        _showRenameDialog(filename, model);
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
          title: const DialogTitle(title: 'Rename'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: TextEditingController(text: filename),
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: Theme.of(context).textTheme.labelSmall,
                  border: const UnderlineInputBorder(),
                ),
              ),

              const SizedBox(height: 10),
              TextFormField(
                controller: newNameController,
                decoration:  InputDecoration(
                  labelText: 'New name *',
                  labelStyle: Theme.of(context).textTheme.labelSmall,
                  border: const UnderlineInputBorder(),
                ),
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  } 
                  
                  if (!RegExp(r'^[a-zA-Z0-9]([a-zA-Z0-9 _\-]*(?!\.\.))*[a-zA-Z0-9]?$')
                      .hasMatch(value)) {
                    return 'Invalid format: Use only alphanumeric characters. May include spaces, underscores, hyphens, or periods, but not consecutive periods.';
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
                    SnackBar(backgroundColor: Theme.of(context).colorScheme.primaryContainer, content: const Text('New name is required')),
                  );
                }
              },
              child: const Text('Rename'),
            ),
            
            ElevatedButton(
              autofocus: true,
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
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

} // Sidebar state