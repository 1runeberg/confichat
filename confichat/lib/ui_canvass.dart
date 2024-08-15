/*
 * Copyright 2024 Rune Berg (http://runeberg.io | https://github.com/1runeberg)
 * Licensed under Apache 2.0 (https://www.apache.org/licenses/LICENSE-2.0)
 * SPDX-License-Identifier: Apache-2.0
 */

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:confichat/file_parser.dart';
import 'package:confichat/interfaces.dart';
import 'package:confichat/ui_advanced_options.dart';
import 'package:confichat/ui_save_session.dart';
import 'package:confichat/ui_widgets.dart';

import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'dart:convert';

import 'package:confichat/chat_notifiers.dart';
import 'package:confichat/persistent_storage.dart';
import 'package:confichat/app_data.dart';


class Canvass extends StatefulWidget {
  final ChatSessionSelectedNotifier chatSessionSelectedNotifier;
  final AppData appData;
  const Canvass({super.key, required this.appData, required this.chatSessionSelectedNotifier});

  @override
  CanvassState createState() => CanvassState();
}

class CanvassState extends State<Canvass> {
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _sessionNameController = TextEditingController();

  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNodePrompt = FocusNode();

  late Directory _chatSessionsDir;
  late SelectedModelProvider _selectedModelProvider;

  String currentChatSession = '';
  
  List<Map<String, dynamic>> chatData = [];
  Map<int, Iterable<String>> chatDocuments = {};
  Map<int, Iterable<String>> chatCodeFiles = {};

  List<String> base64Images = [];
  Map<String, String> documents = {}; 
  Map<String, String> codeFiles = {}; 


  @override
  void initState() {
    super.initState();

    // Listen for changes in the selected model
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) { // Ensure the widget is still mounted
        _selectedModelProvider = Provider.of<SelectedModelProvider>(context, listen: false);
        _selectedModelProvider.addListener(_onSelectedModelChange);
      }
    });

    // Initialize chat sessions directory if it doesn't exist
    _initializeDirectory(AppData.appStoragePath);

    // Request focus on the prompt input field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).requestFocus(_focusNodePrompt);
      }
    });
  }

  @override
  void dispose() {
    _selectedModelProvider.removeListener(_onSelectedModelChange);
    _focusNodePrompt.dispose();
    super.dispose();
  }

  Future<void> _onSelectedModelChange() async {
    final selectedModelProvider =
        Provider.of<SelectedModelProvider>(context, listen: false);
    final selectedModel = selectedModelProvider.selectedModel;
    
    if (selectedModel != null) {

      // Load any cached messages within the model (if any)
      _loadCachedMessages();

      // Clear selected chat session name
      _sessionNameController.text = '';

      // Load the model to memory
      _loadModelToMemory();
    }

  }

  @override
  Widget build(BuildContext context) {

    // Get selected model
    final selectedModelProvider = Provider.of<SelectedModelProvider>(context, listen: false);
    final selectedModel = selectedModelProvider.selectedModel;

    return ValueListenableBuilder<String>(
      valueListenable: widget.chatSessionSelectedNotifier,
      builder: (context, selectedChatSession, child) {
        
        // Load messages
        if( selectedChatSession.isNotEmpty && currentChatSession != selectedChatSession ){
            WidgetsBinding.instance.addPostFrameCallback((_) {   

              currentChatSession = selectedChatSession;   
              _loadChatSession(context, selectedChatSession);

              setState(() {
                _sessionNameController.text = currentChatSession;  
              });
              
          });
        }

        // Return UI
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Center( 
            child: FractionallySizedBox(
              widthFactor: 0.7,
              alignment: Alignment.centerRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [

                // (1) Chat history
                Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: chatData.length,
                      reverse: true,
                      padding: const EdgeInsets.all(8),
                      
                      itemBuilder: (context, index) {

                        int currentIndex = (chatData.length - 1) - index;
                          return ChatBubble(
                            isUser: chatData[currentIndex]['role'] == 'user', 
                            textData: chatData[currentIndex]['role'] == 'system' ? "!system_prompt_ignore" : chatData[currentIndex]['content'],
                            images: chatData[currentIndex]['images'],
                            documents: chatDocuments.containsKey(currentIndex) ? chatDocuments[currentIndex] : null,
                            codeFiles: chatCodeFiles.containsKey(currentIndex) ? chatCodeFiles[currentIndex] : null,
                          );

                      }
                    )
                ),

                // (2) Message area
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [ 

                      // (2.1) Media - if present
                      if (base64Images.isNotEmpty)
                        Wrap(
                          spacing: 8.0,
                          children: base64Images.map((image) {
                            return Stack(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return Dialog(
                                          child: ImagePreview(base64Image: image),
                                        );
                                      },
                                    );
                                  },
                                  child: Image.memory(
                                    base64Decode(image),
                                    height: 50,
                                    width: 50,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        base64Images.remove(image);
                                      });
                                    },
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.red,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 8),

                      // (2.2) Non-image files indicator
                      if (documents.isNotEmpty || codeFiles.isNotEmpty)
                        Wrap(
                          spacing: 8.0,
                          children: [
                            ...documents.keys.map((fileName) => _buildFileChip(fileName, 'Document')),
                            ...codeFiles.keys.map((fileName) => _buildFileChip(fileName, 'Code')),
                          ],
                        ),
                      const SizedBox(height: 8),

                      // (2.3) User input w/ drag and drop
                      DropTarget(
                        onDragDone: (details) {
                          _handleFileDrop(details);
                        },
                        onDragEntered: (details) {
                          // todo: Provide feedback for drag and drop
                        },
                        onDragExited: (details) {
                          // todo: Provide feedback for drag and drop
                        },
                        child: TextFormField(
                          controller: _promptController,
                          focusNode: _focusNodePrompt,
                          decoration: const InputDecoration(
                            labelText: 'Prompt (you can drag-and-drop files below)',
                            alignLabelWithHint: true,
                          ),
                          maxLines: 5,
                          onFieldSubmitted: _sendPrompt,
                          textInputAction: TextInputAction.send, // for soft keyboard
                        ),
                      ),

                      // (2.4) User actions bar
                      const SizedBox(height:5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          
                        // Prompt options
                        ElevatedButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (BuildContext context) {
                                  return AdvancedOptions(api: widget.appData.api, enableSystemPrompt: chatData.isEmpty);
                                },
                              );
                            },
                            child: const Text('Tuning'),
                          ),
                          const Spacer(),

                          // (2.4.1) Jump up
                          const SizedBox(width: 8),
                          FloatingActionButton.small(
                            shape: const CircleBorder(),
                            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                            hoverColor: Theme.of(context).colorScheme.primary,
                            elevation: 3.0,
                            hoverElevation: 3.0,
                            tooltip: 'Scroll to top',
                            onPressed: () => _scrollToTop(scrollDurationInms: widget.appData.appScrollDurationInms),
                            child: const Icon(Icons.vertical_align_top)
                            ),

                          // (2.4.2) Jump down
                          const SizedBox(width: 8),
                          FloatingActionButton.small(
                            shape: const CircleBorder(),
                            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                            hoverColor: Theme.of(context).colorScheme.primary,
                            elevation: 3.0,
                            hoverElevation: 3.0,
                            tooltip: 'Scroll to bottom',
                            onPressed: () => _scrollToBottom(scrollDurationInms: widget.appData.appScrollDurationInms),
                            child: const Icon(Icons.vertical_align_bottom)
                            ),

                          // (2.4.3) Reset
                          const SizedBox(width: 16),
                          FloatingActionButton.small(
                            shape: const CircleBorder(),
                            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                            hoverColor: Theme.of(context).colorScheme.primary,
                            elevation: 3.0,
                            hoverElevation: 3.0,
                            tooltip: 'Reset/Clear messages',
                            onPressed: _clearMessages,
                            child: const Icon(Icons.restart_alt)
                            ),

                          // (2.4.4) Save
                          const SizedBox(width: 8),
                          FloatingActionButton.small(
                            shape: const CircleBorder(),
                            backgroundColor: chatData.isEmpty ? Theme.of(context).colorScheme.surfaceDim : 
                                             Theme.of(context).colorScheme.secondaryContainer,
                            hoverColor: Theme.of(context).colorScheme.primary,
                            elevation: 3.0,
                            hoverElevation: 3.0,
                            tooltip: 'Save session',
                            onPressed: chatData.isEmpty ? null : () {
                              showDialog(
                                context: context,
                                barrierDismissible: false, 
                                builder: (BuildContext context) {
                                  return SaveChatSession(
                                    chatData: chatData,
                                    chatSessionsDir: _chatSessionsDir,
                                    selectedModelProvider: selectedModelProvider,
                                  );
                                },
                              );
                            },
                            child: const Icon(Icons.save_alt)
                            ),

                          // (2.4.5) Attach files
                          const SizedBox(width: 32),
                          FloatingActionButton.small(
                            shape: const CircleBorder(),
                            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                            hoverColor: Theme.of(context).colorScheme.primary,
                            elevation: 3.0,
                            hoverElevation: 3.0,
                            tooltip: 'Attach files',
                            onPressed: () => (selectedModel != null && selectedModel.supportsImages) ? _attachFiles() : null,
                            child: const Icon(Icons.attach_file)
                            ),

                          // (2.4.6) Send
                          const SizedBox(width: 8),
                          FloatingActionButton.small(
                            shape: const CircleBorder(),
                            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                            hoverColor: Theme.of(context).colorScheme.primary,
                            elevation: 3.0,
                            hoverElevation: 3.0,
                            tooltip: 'Send prompt',
                            onPressed: () => _sendPrompt(_promptController.text),
                            child: const Icon(Icons.send_sharp)
                            ),

                        ]
                      )

                    ],
                  ),
                ),

                const SizedBox(height:15),
              ],

              ),
            ), 
          )

        );

    });

  }

  // Handle drag and drop of  files to input area
  Future<void> _handleFileDrop(DropDoneDetails details) async {
    FocusScope.of(context).requestFocus(_focusNodePrompt);
    setState(() {
      FileParser.processDroppedFiles(details: details, context: context, outImages: base64Images, outDocuments: documents, outCodeFiles: codeFiles); 
    });
  }

  // Load cached messages from the selected model (if it exists)
  Future<bool> _loadCachedMessages() async {
    if (!mounted) return false;

    // Get selected model
    final selectedModelProvider = Provider.of<SelectedModelProvider>(context, listen: false);
    final selectedModel = selectedModelProvider.selectedModel;

    if(selectedModel!.name.isEmpty) {
      setState(() { _resetHistory(); });
      return false;
    }

    try {
      // Retrieve model info
      List<dynamic> messages = [];
      await widget.appData.api.getCachedMessagesInModel(messages, selectedModel.name);

      // Set chat history to cached messages
      if (messages.isNotEmpty) {
        setState(() {
          _resetHistory();
          for(var msg in messages){
            chatData.add(msg);
              _scrollToBottom();
          }
        });
        
      }
      else { 

        if(widget.appData.clearMessagesOnModelSwitch) {
          setState(() { _resetHistory(); });
        }
        
        return false; 
      }
      
    } catch (e) {

      if (kDebugMode) {
        print('Unable to retrieve model info(${widget.appData.api.host}): $e\n ${widget.appData.api.responseData}');

        if (mounted) {
          setState(() { _resetHistory(); });
        }

        return false;
      }
    }

    return true;
  }

  // Scroll to top of chat session
  void _scrollToTop({int scrollDurationInms = 1}) {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: Duration(milliseconds: scrollDurationInms),
      curve: Curves.easeOut,
    );
  }

  // Scroll to bottom of chat session
  void _scrollToBottom({int scrollDurationInms = 1}) {
    _scrollController.animateTo(
      0,
      duration: Duration(milliseconds: scrollDurationInms),
      curve: Curves.easeOut,
    );
  }

  // Clear messages with confirmation
  void _clearMessages() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const DialogTitle(title: 'Confirm Session Reset'),  
          content: const Text('Are you sure you want to clear all chat messages?'),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('Clear'),
              onPressed: () {
                Navigator.of(context).pop(); 
                _resetHistory();
                setState(() {
                  _promptController.text = '';
                }); 
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

  // Initialize directory for chat sessions if it doesn't exist
  Future<void> _initializeDirectory(String subDirectory) async {
    try {

      final directory = AppData.instance.rootPath.isEmpty ? await getApplicationDocumentsDirectory() : Directory(AppData.instance.rootPath);
      _chatSessionsDir = Directory('${directory.path}/$subDirectory');
      await _chatSessionsDir.create(recursive: true);

    } catch(e) { 
      if (kDebugMode) { print('Error creating chat sessions directory: $e\n$_chatSessionsDir'); }
    }

  }


  // Clear messages
  void _resetHistory() {
    setState(() {
      base64Images.clear();
      documents.clear();
      codeFiles.clear();

      chatDocuments.clear();
      chatCodeFiles.clear();
      chatData.clear();
    }); 

    // Reset prompt options
    widget.appData.api.temperature = widget.appData.api.defaultTemperature;
    widget.appData.api.probability = widget.appData.api.defaultProbability;
    widget.appData.api.maxTokens = widget.appData.api.defaultMaxTokens;
    widget.appData.api.systemPrompt = '';
  }

  void _loadChatSession(BuildContext context, String selectedChatSession) {
    final selectedModelProvider = Provider.of<SelectedModelProvider>(context, listen: false);
    final selectedModelName = selectedModelProvider.selectedModel?.name ?? 'Unknown Model';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Container( 
                width: 100, 
                height: 50, 
                alignment: Alignment.center, 
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer, 
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16.0),
                    topRight: Radius.circular(16.0), bottomLeft: Radius.circular(16.0),
                    bottomRight: Radius.circular(16.0),
                    )
                ),
                
                child: OutlinedText(
                      textData: 'Load Previous Chat Sessions', 
                      textStyle: Theme.of(context).textTheme.titleMedium,
                      ) 
              ),

          content: Text(
            'Are you sure you want to load chat session: $selectedChatSession?\n'
            'This will clear all current messages and if unsaved, will be lost.',
          ),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('Yes'),
              onPressed: () async {
                Navigator.of(context).pop(); // remove confirmation dialog
                Navigator.of(context).pop(); // remove sidebar

                // Read chat data file
                String jsonString = await PersistentStorage.readJsonFile(
                    _chatSessionsDir,   
                    selectedModelName,  
                    selectedChatSession  
                  );
                final jsonData = jsonDecode(jsonString);

                // Check for encrypted data
                String iv = PersistentStorage.isFileEncrypted(jsonData);

                if(iv.isNotEmpty) {
    
                  final options = jsonData['options'];
                  AppData.instance.api.temperature = options['temperature'] ?? AppData.instance.api.temperature;
                  AppData.instance.api.probability = options['probability'] ?? AppData.instance.api.probability;
                  AppData.instance.api.maxTokens = options['maxTokens'] ?? AppData.instance.api.maxTokens;
                  AppData.instance.api.stopSequences = List<String>.from(options['stopSequences'] ?? []);

                  // Set chat history (encrypted)
                  final messageHistory = jsonData['messages'];
                  await DecryptDialog.showDecryptDialog(
                    // ignore: use_build_context_synchronously
                    context: context, 
                    systemPrompt: options['systemPrompt'] ?? '', 
                    base64IV: iv,  
                    chatData: chatData, 
                    jsonData: messageHistory,
                    decryptContent: _decryptData );

                } else {

                  PersistentStorage.setAppData(jsonData);
                  final messageHistory = jsonData['messages'];

                  if(messageHistory != null && messageHistory.isNotEmpty)
                  {
                    setState(() {
                      chatData = List<Map<String, dynamic>>.from(jsonDecode(messageHistory));
                    });
                  }
                }

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

  Future<void> _sendPrompt(String? s) async {

    // Early exit if there's no prompt value
    if( _promptController.text.trim().isEmpty ) { 
      _promptController.clear();
      return; 
    }

    // Add system prompt
    if(chatData.isEmpty && widget.appData.api.systemPrompt.isNotEmpty)
    {
      setState(() {
        chatData.add({
          "role": "system", 
          "content": widget.appData.api.systemPrompt
          });
      });
    }

    // Add prompt to messages
    setState(() {
      chatData.add({
        "role": "user", 
        "content": _promptController.text,
        "images": base64Images.isNotEmpty ? List<String>.from(base64Images) : null
        });

      // Add any document or code file in to the chat data
      if(documents.isNotEmpty) { chatDocuments[chatData.length - 1] = documents.keys.toList(); }
      if(codeFiles.isNotEmpty) { chatCodeFiles[chatData.length - 1] = codeFiles.keys.toList(); }   
    });

    // Scroll to bottom
    _scrollToBottom();

    // ignore: use_build_context_synchronously
    FocusScope.of(context).requestFocus(_focusNodePrompt);

    // Send prompt with history to provider
    await _sendPromptWithHistory();

      // Clear prompt
    _promptController.clear();

  }

  Future<void> _sendPromptWithHistory() async {
    if (!mounted) return;

    final selectedModelProvider = Provider.of<SelectedModelProvider>(context, listen: false);
    final selectedModelName = selectedModelProvider.selectedModel?.name ?? 'Unknown Model';

      await widget.appData.api.sendPrompt(
        modelId: selectedModelName,
        messages: chatData,
        documents: documents,
        codeFiles: codeFiles,
        onStreamRequestSuccess: _onChatRequestSuccess,
        onStreamChunkReceived: _onChatChunkReceived,
        onStreamComplete: _onChatStreamComplete
      );

  } 

  Future<void> _loadModelToMemory() async {
    final selectedModelProvider = Provider.of<SelectedModelProvider>(context, listen: false);
    final selectedModelName = selectedModelProvider.selectedModel?.name ?? 'Unknown Model';

    FocusScope.of(context).requestFocus(_focusNodePrompt);

    await widget.appData.api.loadModelToMemory(selectedModelName);
  }

  int _onChatRequestSuccess(){
    setState(() {
      // Clear files
      base64Images.clear();
      documents.clear();
      codeFiles.clear();

      chatData.add({'role': 'assistant', 'content': ''});
      _scrollToBottom();
    });

    return chatData.length - 1;
  }

  void _onChatChunkReceived(int index, StreamChunk chunk){

    if (chunk.content.isNotEmpty) {
      setState(() {
        chatData[index]['content'] += chunk.content;
      });
    }
    
  }

  void _onChatStreamComplete(int index){
    //FocusScope.of(context).requestFocus(_focusNode_Prompt);
  }

  Widget _buildFileChip(String fileName, String fileType) {
    return Chip(
      label: Text(fileName),
      avatar: Icon(
        fileType == 'Document' ? Icons.description : Icons.code,
        size: 20,
      ),
      
      deleteIcon: const Icon(Icons.close,
          color: Colors.red,
          size: 16,), 
      
      onDeleted: () {
        setState(() {
          if (fileType == 'Document') {
            documents.remove(fileName);
          } else {
            codeFiles.remove(fileName);
          }
        });
      },
    );
  }

  Future<void> _attachFiles() async {

    try {
      // Use FilePicker to select files
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: true,
        allowedExtensions: [
          ...FileParser.imageFormats,
          ...FileParser.documentTextFormats,
          ...FileParser.documentBinaryFormats,
          ...FileParser.codeFormats,
        ]
      );

      if (result != null) {
          // ignore: use_build_context_synchronously
          await FileParser.processPlatformFiles(files: result.files, context: context, outImages: base64Images, outDocuments: documents, outCodeFiles: codeFiles );       
      }
    } catch (e) {
      if (kDebugMode) {print("Error picking files: $e");}
    }

      // ignore: use_build_context_synchronously
      FocusScope.of(context).requestFocus(_focusNodePrompt);

  }

  Future<bool> _decryptData(
    String systemPrompt,
    String base64IV,
    String encryptionKey,
    dynamic jsonData,
    List<Map<String, dynamic>> chatData
  ) async {

    try{

      // System prompt
      if(systemPrompt.isNotEmpty) {
        AppData.instance.api.systemPrompt = CryptoUtils.decryptString(
          base64IV: base64IV, 
          userKey: encryptionKey, 
          encryptedData: systemPrompt );
      }

      // Chat data
      CryptoUtils.decryptToChatData(base64IV: base64IV, userKey: encryptionKey, jsonData: jsonData, chatData: chatData); 

    }catch(error){
      if (kDebugMode) { print('Unable to decrypt file: $error'); }
      return false;
    }

    return true;
  }

} // CanvassState

class DecryptDialog {

  static Future<void> showDecryptDialog({
    required BuildContext context,
    required String systemPrompt,
    required String base64IV,
    required dynamic jsonData,
    required List<Map<String, dynamic>> chatData,
    required Future<bool> Function(
        String systemPrompt,
        String base64IV,
        String encryptionKey,
        dynamic jsonData,
        List<Map<String, dynamic>> chatData
      ) decryptContent
  }) async {

    final TextEditingController keyController = TextEditingController();

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {

        return AlertDialog(
          title: const Text('Encrypted Content'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('This chat contains encrypted content. Please provide the key to decrypt.'),
              TextField(
                controller: keyController,
                decoration: const InputDecoration(
                  labelText: 'Encryption key',
                ),
                obscureText: true,
              ),
            ],
          ),

          actions: <Widget>[
            ElevatedButton(
              onPressed: () async {
                String key = keyController.text;
                bool success = await decryptContent(systemPrompt, base64IV, keyController.text, jsonData, chatData);
                if (success) {
                  // ignore: use_build_context_synchronously
                  Navigator.of(context).pop(); // Close the dialog on success
                } else {
                  // ignore: use_build_context_synchronously
                  _showErrorDialog(context, key);
                }
              },
              child: const Text('Decrypt'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  static void _showErrorDialog(BuildContext context, String key) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text('Unable to decrypt with key: $key'),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the error dialog
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
} 