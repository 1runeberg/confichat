/*
 * Copyright 2024-25 Rune Berg (http://runeberg.io | https://github.com/1runeberg)
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
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'dart:convert';
import 'package:confichat/chat_notifiers.dart';
import 'package:confichat/persistent_storage.dart';
import 'package:confichat/app_data.dart';
import 'package:confichat/app_localizations.dart';


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
  final ScrollController _actionsScrollController = ScrollController();
  final FocusNode _focusNodePrompt = FocusNode();

  late Directory _chatSessionsDir;
  late SelectedModelProvider _selectedModelProvider;
  
  List<Map<String, dynamic>> chatData = [];
  Map<int, Iterable<String>> chatDocuments = {};
  Map<int, Iterable<String>> chatCodeFiles = {};

  List<ImageFile> base64Images = [];
  Map<String, String> documents = {}; 
  Map<String, String> codeFiles = {}; 
  Map<int, bool> processingData = {};


  @override
  void initState() {
    super.initState();

    // Set callback to update chat session
    widget.appData.callbackUpdateSession = updateChatSession;

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
        if(_actionsScrollController.hasClients) {_actionsScrollController.jumpTo(_actionsScrollController.position.maxScrollExtent);}
        FocusScope.of(context).requestFocus(_focusNodePrompt);
      }
    });
  }

  @override
  void dispose() {
    _selectedModelProvider.removeListener(_onSelectedModelChange);
    _scrollController.dispose();
    _actionsScrollController.dispose();
    _focusNodePrompt.dispose();
    super.dispose();
  }

  Future<void> _onSelectedModelChange() async {
    final selectedModelProvider =
        Provider.of<SelectedModelProvider>(context, listen: false);
    final selectedModel = selectedModelProvider.selectedModel;
    
    if (selectedModel != null) {

      // Reset selected chat session
      _sessionNameController.text = '';
      widget.chatSessionSelectedNotifier.value = '';

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

    UserDeviceType deviceType = widget.appData.getUserDeviceType(context);

    // Get selected model
    final selectedModelProvider = Provider.of<SelectedModelProvider>(context, listen: false);
    final selectedModel = selectedModelProvider.selectedModel;
    final loc = AppLocalizations.of(context);

    return ValueListenableBuilder<String>(
      valueListenable: widget.chatSessionSelectedNotifier,
      builder: (context, selectedChatSession, child) {
        
        // Load messages
        if( selectedChatSession.isNotEmpty && _sessionNameController.text != selectedChatSession ){
            WidgetsBinding.instance.addPostFrameCallback((_) {   

              setState(() {
                _sessionNameController.text = selectedChatSession;              
                _loadChatSession(context, selectedChatSession);
              });
              
          });
        }

        // Return UI
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Center( 
            child: FractionallySizedBox(
              widthFactor: deviceType == UserDeviceType.desktop ? 0.7 : 0.9,
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
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.all(8),
                      
                      itemBuilder: (context, index) {

                        int currentIndex = (chatData.length - 1) - index;
                        return ChatBubble(
                          isUser: chatData[currentIndex]['role'] == 'user', 
                          animateIcon: processingData.containsKey(currentIndex) && processingData[currentIndex]!,
                          fnChatActionCallback: _processChatAction,
                          index: currentIndex,
                          textData: chatData[currentIndex]['role'] == 'system' ? "!system_prompt_ignore" : chatData[currentIndex]['content'],
                          images: chatData[currentIndex]['images'] != null
                              ? (chatData[currentIndex]['images'] as List<Map<String, String>>)
                                  .map((item) => item['base64'] as String) 
                                  .toList() 
                              : null,

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
                                          child: ImagePreview(base64Image: image.base64),
                                        );
                                      },
                                    );
                                  },
                                  child: Image.memory(
                                    base64Decode(image.base64),
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
                      if( deviceType == UserDeviceType.desktop ) DropTarget(
                        onDragDone: (details) {
                          _handleFileDrop(details);
                        },
                        onDragEntered: (details) {
                          // todo: Provide feedback for drag and drop
                        },
                        onDragExited: (details) {
                          // todo: Provide feedback for drag and drop
                        },
                        child: ShiftEnterTextFormField(parentContext: context,  focusNode: _focusNodePrompt, promptController: _promptController, sendFunction: _sendPrompt),
                      ),

                      if( deviceType != UserDeviceType.desktop ) 
                      TextFormField(
                          controller: _promptController,
                          focusNode: _focusNodePrompt,
                          decoration: InputDecoration(
                            labelText: loc.translate('canvass.promptLabel'),
                            alignLabelWithHint: true,
                          ),
                          minLines: 1,
                          maxLines: 5,
                          onFieldSubmitted: _sendPromptMobile,
                          textInputAction: TextInputAction.newline, // for soft keyboard
                        ),

                      // (2.4) User actions bar
                      const SizedBox(height:5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          
                        // Prompt options
                        Align(
                        alignment: Alignment.centerLeft, 
                        child:
                        ElevatedButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (BuildContext context) {
                                  return AdvancedOptions(api: widget.appData.api, enableSystemPrompt: true);
                                },
                              );
                            },
                            child:  Text(loc.translate('canvass.tuningLabel')),
                          ),),
                        
                        // Add spacer if there's enough space (not on phones)
                        if (deviceType != UserDeviceType.phone) const Spacer(),

                        if (deviceType != UserDeviceType.phone) 
                        Row( children: _buildActionButtons(context, deviceType, selectedModelProvider, selectedModel)), 

                        if (deviceType == UserDeviceType.phone) Expanded( child:
                        SingleChildScrollView(
                            controller: _actionsScrollController,
                            scrollDirection: Axis.horizontal,
                            child: Row( children: _buildActionButtons(context, deviceType, selectedModelProvider, selectedModel)), 
                            ), 
                        ),


                      ]) 

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
      setState(() { _resetHistory(true); });
      return false;
    }

    try {
      // Retrieve model info
      List<dynamic> messages = [];
      await widget.appData.api.getCachedMessagesInModel(messages, selectedModel.name);

      // Set chat history to cached messages
      if (messages.isNotEmpty) {
        setState(() {
          _resetHistory(true);
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
          title: DialogTitle(title: AppLocalizations.of(context).translate('canvass.confirmSessionResetDialog.title'), isError: true),
          content: Text( AppLocalizations.of(context).translate('canvass.confirmSessionResetDialog.message'), style: Theme.of(context).textTheme.bodyLarge,),
          actions: <Widget>[
            ElevatedButton(
              child: Text( AppLocalizations.of(context).translate('canvass.confirmSessionResetDialog.clearButton')),
              onPressed: () {
                Navigator.of(context).pop(); 
                _resetHistory(true);
                setState(() {
                  _promptController.text = '';
                }); 
              },
            ),
            ElevatedButton(
              child: Text( AppLocalizations.of(context).translate('canvass.confirmSessionResetDialog.cancelButton')),
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
  Future<void> _resetHistory([bool force = false]) async {

    bool shouldCancel = false;

    if(!force && widget.appData.haveUnsavedMessages)
    {
      if(widget.appData.haveUnsavedMessages){

        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: DialogTitle(title: AppLocalizations.of(context).translate('canvass.warningDialog.title'), isError: true),
              content: Text(
                      AppLocalizations.of(context).translate('canvass.warningDialog.message'),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
              actions: <Widget>[

                ElevatedButton(
                  child: Text(AppLocalizations.of(context).translate('canvass.warningDialog.yesButton')),
                  onPressed: () {
                    shouldCancel = false;
                    Navigator.of(context).pop();
                  },
                ),

                ElevatedButton(
                  child: Text(AppLocalizations.of(context).translate('canvass.warningDialog.cancelButton')),
                  onPressed: () {
                    shouldCancel = true;
                    Navigator.of(context).pop();
                  },
                ),

              ],
            );
          },
        );

      }
    }

    // Cancel if user intervened
    if(shouldCancel) { return; }

    setState(() {
      base64Images.clear();
      documents.clear();
      codeFiles.clear();

      chatDocuments.clear();
      chatCodeFiles.clear();
      chatData.clear();

      // Reset selected chat session
      _sessionNameController.text = '';
      widget.chatSessionSelectedNotifier.value = '';
    }); 

    // Untag unsaved changes
    widget.appData.haveUnsavedMessages = false;

    // Reset prompt options
    widget.appData.api.temperature = widget.appData.api.defaultTemperature;
    widget.appData.api.probability = widget.appData.api.defaultProbability;
    widget.appData.api.maxTokens = widget.appData.api.defaultMaxTokens;
    widget.appData.api.systemPrompt = '';
  }

  void _loadChatSession(BuildContext context, String selectedChatSession) {
    final selectedModelProvider = Provider.of<SelectedModelProvider>(context, listen: false);
    final selectedModelName = selectedModelProvider.selectedModel?.name ?? AppLocalizations.of(context).translate('canvass.saveChatSession.validation.unknownModel');

    showDialog(
      context: context,
      barrierDismissible: false,
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
                
                child: DialogTitle(
                      title: AppLocalizations.of(context).translate('canvass.loadChatSessionDialog.title'),
                      isError: true,
                      ) 
              ),

          content: Text(
             AppLocalizations.of(context).translate('canvass.loadChatSessionDialog.message').replaceAll('{sessionName}', selectedChatSession),
             style: Theme.of(context).textTheme.bodyMedium,
          ),
          actions: <Widget>[
            ElevatedButton(
              child: Text(AppLocalizations.of(context).translate('canvass.loadChatSessionDialog.yesButton')),
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

                  if(mounted){
                    await DecryptDialog.showDecryptDialog(
                      // ignore: use_build_context_synchronously
                      systemPrompt: options['systemPrompt'] ?? '', 
                      base64IV: iv,  
                      chatData: chatData, 
                      jsonData: messageHistory,
                      decryptContent: _decryptData );
                  }

                } else {

                  PersistentStorage.setAppData(jsonData);
                  final messageHistory = jsonDecode(jsonData['messages']);

                  if (messageHistory != null && messageHistory.isNotEmpty) {
                    setState(() {
                      chatData = List<Map<String, dynamic>>.from(messageHistory.map((message) {
                        // Handle images separately
                        if (message['images'] != null) {
                          var images = message['images'] as List<dynamic>;

                          // Prepare a list to hold parsed images
                          List<Map<String, String>> parsedImages = [];

                          for (var item in images) {
                            if (item is String) {
                              // If the item is a String, assume it's a base64 and set the default ext - v0.4.0 and below
                              parsedImages.add({
                                'ext': 'jpeg', // Default extension from v0.4.0
                                'base64': item,
                              });
                            } else if (item is Map<String, dynamic>) {
                              // If the item is a Map<String, dynamic>, extract base64 = v0.5.0 and above
                              parsedImages.add({
                                'ext': item['ext'] ?? 'jpeg', // Get the ext if available, otherwise default to 'jpeg' (0.4.0)
                                'base64': item['base64'] ?? '', // Get the base64 value
                              });
                            }
                          }

                          // Assign the parsed images back to the message
                          message['images'] = parsedImages.isNotEmpty ? parsedImages : null;
                        }

                        return message; // Return the modified message
                      }));
                    });
              }}}
            ),

            ElevatedButton(
              child: Text(AppLocalizations.of(context).translate('canvass.loadChatSessionDialog.cancelButton')),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> updateChatSession(Directory chatSessionsDir, String modelName, String filename, EncryptionPayload encryptionPayload) async {
    
    bool isEncrypted = encryptionPayload.base64IV.isNotEmpty && encryptionPayload.encryptedData.isNotEmpty;
    TextEditingController encryptionKeyController = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: false,
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
                
                child: DialogTitle(
                      title: AppLocalizations.of(context).translate('canvass.updateChatSessionDialog.title'),
                      isError: true,
                      ) 
              ),

          content:        
            ConstrainedBox( constraints: const BoxConstraints(maxWidth: 400), 
            child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

                // Warning message
                Text(
                  AppLocalizations.of(context).translate('canvass.updateChatSessionDialog.message').replaceAll('{sessionName}', filename),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),

                // Get key if encryption is enabled
                if(isEncrypted) const SizedBox(height: 8),
                if(isEncrypted) 
                  TextFormField(
                    controller: encryptionKeyController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context).translate('canvass.updateChatSessionDialog.encryptionKeyLabel'),
                    ),
                    obscureText: true,
                  ),

            ])),

          actions: <Widget>[
            ElevatedButton(
              child: Text(AppLocalizations.of(context).translate('canvass.updateChatSessionDialog.yesButton')),
              onPressed: () async {

                // Check encryption key
                if(isEncrypted){

                  if(encryptionKeyController.text.isEmpty){
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(backgroundColor: Theme.of(context).colorScheme.error,
                          content: Text(AppLocalizations.of(context).translate('canvass.updateChatSessionDialog.provideKey')))
                    );
                  } else {

                    // Validate encryption key
                    if(CryptoUtils.testKey(encryptionPayload: encryptionPayload, userKey: encryptionKeyController.text)){

                      try{ 
                        // Update encrypted chat session
                        CryptoUtils.encryptChatDataWithIV(base64IV: encryptionPayload.base64IV, userKey: encryptionKeyController.text, chatData: chatData);
                        String content = jsonEncode(chatData);
                        await _saveSession(chatSessionsDir, modelName, filename, content, encryptionPayload.base64IV, encryptionKeyController.text);

                        // Decrypt system prompt for current session
                        if(AppData.instance.api.systemPrompt.isNotEmpty) {
                          AppData.instance.api.systemPrompt = CryptoUtils.decryptString(
                            base64IV: encryptionPayload.base64IV, 
                            userKey: encryptionKeyController.text, 
                            encryptedData: AppData.instance.api.systemPrompt );
                        }
                      
                        // Decrypt chat data back for current session
                        CryptoUtils.decryptChatData(base64IV: encryptionPayload.base64IV, userKey: encryptionKeyController.text, chatData: chatData); 

                        // Inform user of status
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            content:  Text(AppLocalizations.of(context).translate('canvass.updateChatSessionDialog.chatUpdateSuccess'))));

                      } catch(e) {
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Theme.of(context).colorScheme.error,
                            content: Text(AppLocalizations.of(context).translate('canvass.updateChatSessionDialog.chatUpdateFail').replaceAll( "{sessionName}", e.toString()))));
                      } finally{
                        // ignore: use_build_context_synchronously
                        Navigator.of(context).pop(); 
                      }

                    } else{
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(backgroundColor: Theme.of(context).colorScheme.error,
                            content: Text(AppLocalizations.of(context).translate('canvass.updateChatSessionDialog.incorrectKey')))
                      );
                    }

                  }

                } else {
                  // Update chat session
                  String content = jsonEncode(chatData);
                  await _saveSession(chatSessionsDir, modelName, filename, content, '', '');

                  // Inform user of status
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      content: Text(AppLocalizations.of(context).translate('canvass.updateChatSessionDialog.chatUpdateSuccess'))));

                  // ignore: use_build_context_synchronously
                  Navigator.of(context).pop(); 
                }

              }
            ),
            ElevatedButton(
              child: Text(AppLocalizations.of(context).translate('canvass.updateChatSessionDialog.cancelButton')),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveSession(Directory chatSessionsDir, String modelname, String filename, String content, String base64IV, String userKey) async {

    // Encrypt system prompt
    if( base64IV.isNotEmpty && userKey.isNotEmpty && AppData.instance.api.systemPrompt.trim().isNotEmpty) { 
      AppData.instance.api.systemPrompt = CryptoUtils.encryptStringIV(
        base64IV: base64IV, 
        userKey: userKey, 
        data: AppData.instance.api.systemPrompt );
    }

    try {
      await PersistentStorage.saveFile(
        chatSessionsDir, 
        modelname, 
        filename, 
        content,
        base64IV
        );

      widget.appData.haveUnsavedMessages = false;
    } catch (e) {
      throw Exception(e);
    }
  }


  Future<void> _sendPromptMobile(String? s) async {
    await _sendPrompt(s, null);
  }

  Future<void> _sendPrompt(String? s, FocusNode? f) async {

    // Get selected model
    final selectedModelProvider = Provider.of<SelectedModelProvider>(context, listen: false);
    final selectedModel = selectedModelProvider.selectedModel;

    // Check if valid model is selected
    if (selectedModel == null || selectedModel.name.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: DialogTitle(
              title: AppLocalizations.of(context).translate('providerSetup.noModelSelected'), 
              isError: true),
            content: Text(
              AppLocalizations.of(context).translate('providerSetup.noModelSelectedMessage'),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(AppLocalizations.of(context).translate('providerSetup.okButton')),
              ),
            ],
          );
        },
      );

      return;
    }

    // Set prompt text
    String promptText = _promptController.text.trim();
    if(s!= null && s.isNotEmpty) { promptText = s.trim(); }

    // Early exit if there's no prompt value
    if( promptText.isEmpty) { 
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
    } else if(chatData.isNotEmpty 
      && widget.appData.api.systemPrompt.isNotEmpty 
      && chatData[0].containsKey('role')
      && chatData[0].containsKey('content')) {

        setState(() {
          if( chatData[0]['role'] == 'system') {
            // update system prompt
            chatData[0]['content'] = widget.appData.api.systemPrompt;
          } else {
            // Add system prompt
            chatData.insert( 0, {
              "role": "system", 
              "content": widget.appData.api.systemPrompt
            });
          }
        });

    }

    // Add prompt to messages
    setState(() {
      chatData.add({
        "role": "user", 
        "content": promptText,
        "images": base64Images.isNotEmpty
          ? base64Images.map((image) => {
              "ext": image.ext,
              "base64": image.base64,
            }).toList()
          : null
        });

      // Add any document or code file in to the chat data
      if(documents.isNotEmpty) { chatDocuments[chatData.length - 1] = documents.keys.toList(); }
      if(codeFiles.isNotEmpty) { chatCodeFiles[chatData.length - 1] = codeFiles.keys.toList(); }   

      // Reset selected chat session
      _sessionNameController.text = '';
      widget.chatSessionSelectedNotifier.value = '';
    });

    // Tag unsaved messages for warning
    widget.appData.haveUnsavedMessages = true;


    // ignore: use_build_context_synchronously
    FocusScope.of(context).requestFocus(_focusNodePrompt);
    if( f!= null ) {
      FocusScope.of(context).requestFocus(f);
    }

    // Send prompt with history to provider
    await _sendPromptWithHistory();

    // Clear prompt
    setState(() {
      _promptController.clear();
    });

  }

  Future<void> _sendPromptWithHistory({bool clearUserPrompt = true}) async {
    if (!mounted) return;

    final selectedModelProvider = Provider.of<SelectedModelProvider>(context, listen: false);
    final selectedModelName = selectedModelProvider.selectedModel?.name ?? AppLocalizations.of(context).translate('canvass.saveChatSession.validation.unknownModel');

    widget.appData.api.sendPrompt(
      modelId: selectedModelName,
      messages: chatData,
      documents: documents,
      codeFiles: codeFiles,
      onStreamRequestSuccess: _onChatRequestSuccess,
      onStreamCancel: _onChatStreamCancel,
      onStreamChunkReceived: _onChatChunkReceived,
      onStreamComplete: _onChatStreamComplete,
      onStreamRequestError: _onChatRequestError,
      onStreamingError: _onChatStreamError
    );

    setState(() {
      if(clearUserPrompt){
        // Clear files
        base64Images.clear();
        documents.clear();
        codeFiles.clear();
      }

      // Add placeholder
      chatData.add({'role': 'assistant', 'content': ''});
      int index = chatData.length - 1;
      processingData[index] = false; // disable cancel button until our request goes through
      _scrollToBottom();
    });
  } 

  Future<void> _loadModelToMemory() async {
    final selectedModelProvider = Provider.of<SelectedModelProvider>(context, listen: false);
    final selectedModelName = selectedModelProvider.selectedModel?.name ?? AppLocalizations.of(context).translate('canvass.saveChatSession.validation.unknownModel');

    FocusScope.of(context).requestFocus(_focusNodePrompt);

    await widget.appData.api.loadModelToMemory(selectedModelName);
  }

  int _onChatRequestSuccess(){
    int chatDataIndex = chatData.length - 1;

    if(processingData.containsKey(chatDataIndex)) {
      processingData[chatDataIndex] = true;
    }
    return chatDataIndex;
  }

  void _onChatRequestError( dynamic error ){

    // Check and remove placeholder
    int index = chatData.length - 1;
    setState(() {
      if(chatData[index]['role'] == 'assistant' && chatData[index]['content'].isEmpty ){
        chatData.removeAt(index);

        if(processingData.containsKey(index)){ processingData.remove(index); }
        _scrollToBottom();
      }
    });

    final String errorMessage = error.toString();
    ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(backgroundColor: Theme.of(context).colorScheme.error,
                        content: Text(AppLocalizations.of(context).translate('canvass.chatStream.errorCompletion').replaceAll("{errorMessage}", errorMessage))),
                  );
  }

  dynamic _onChatStreamError( int index, dynamic error ){
    _onChatStreamComplete(index);
    ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(backgroundColor: Theme.of(context).colorScheme.error,
                        content: Text(AppLocalizations.of(context).translate('canvass.chatStream.errorStream').replaceAll("{errorMessage}", error))),
                  );
  }

  void _processChatAction(ChatActionPayload payload) {

    // Cancel
    if( payload.actionType == ChatActionType.cancel)
    {
      if(processingData.containsKey(payload.index)) {
            processingData[payload.index] = false;
          }

      return;
    }

    // Regenerate
    if( payload.actionType == ChatActionType.regenerate)
    {
      setState(() {
        // Remove the message
        // todo: cache so user can switch back to prior responses
        chatData.removeAt(payload.index);

      });

      // If this is(was) the last message - regenerate
      if(payload.index == chatData.length)
      {
           _sendPromptWithHistory(clearUserPrompt: false);
      } 
      return;
    }

    // Delete
    if( payload.actionType == ChatActionType.delete)
    {
      setState(() {
        chatData.removeAt(payload.index);
      });
      return;
    }

  }

  bool _onChatStreamCancel(int index){
    // No cancel request received for this response
    if(!processingData.containsKey(index) || processingData[index] == true){
      return false;
    }

    // Cancel requested - api should call chatStreamComplete callback
    if(processingData.containsKey(index) && processingData[index] == false){
        return true;
    }

    return false;
  }

  void _onChatChunkReceived(int index, StreamChunk chunk){

    if (chunk.content.isNotEmpty) {
      setState(() {
        chatData[index]['content'] += chunk.content;
      });
    }
    
  }

  void _onChatStreamComplete(int index){
    setState(() {
      // Remove processing indicator
      processingData.remove(index);
      
      // Handle empty response
      if( chatData[index]['content'].isEmpty ) {
        chatData[index]['content'] = '*...*';
      }

      // Force refresh list
      _scrollToBottom();    
    });
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
          setState(() {
            FileParser.processPlatformFiles(files: result.files, context: context, outImages: base64Images, outDocuments: documents, outCodeFiles: codeFiles );       
          });
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

  List<Widget> _buildActionButtons(
    BuildContext context, 
    UserDeviceType deviceType, 
    SelectedModelProvider selectedModelProvider,
    ModelItem? selectedModel ) {
    return [
      const SizedBox(width: 8),
      FloatingActionButton.small(
        shape: const CircleBorder(),
        backgroundColor: chatData.length < 3
          ? Theme.of(context).colorScheme.surfaceDim
          : Theme.of(context).colorScheme.secondaryContainer,
        hoverColor: chatData.length < 3
          ? Theme.of(context).colorScheme.surfaceDim
          : Theme.of(context).colorScheme.secondaryContainer,
        elevation: 3.0,
        hoverElevation: 3.0,
        tooltip: AppLocalizations.of(context).translate('canvass.scrollToTopTooltip'),
        onPressed: () => _scrollToTop(scrollDurationInms: widget.appData.appScrollDurationInms),
        child: const Icon(Icons.vertical_align_top),
      ),
      const SizedBox(width: 8),
      FloatingActionButton.small(
        shape: const CircleBorder(),
        backgroundColor: chatData.length < 3
          ? Theme.of(context).colorScheme.surfaceDim
          : Theme.of(context).colorScheme.secondaryContainer,
        hoverColor: chatData.length < 3
          ? Theme.of(context).colorScheme.surfaceDim
          : Theme.of(context).colorScheme.secondaryContainer,
        elevation: 3.0,
        hoverElevation: 3.0,
        tooltip: AppLocalizations.of(context).translate('canvass.scrollToBottomTooltip'),
        onPressed: () => _scrollToBottom(scrollDurationInms: widget.appData.appScrollDurationInms),
        child: const Icon(Icons.vertical_align_bottom),
      ),
      const SizedBox(width: 16),
      FloatingActionButton.small(
        shape: const CircleBorder(),
        backgroundColor: chatData.isEmpty
          ? Theme.of(context).colorScheme.surfaceDim
          : Theme.of(context).colorScheme.secondaryContainer,
        hoverColor: chatData.isEmpty
          ? Theme.of(context).colorScheme.surfaceDim
          : Theme.of(context).colorScheme.secondaryContainer,
        elevation: 3.0,
        hoverElevation: 3.0,
        tooltip:  AppLocalizations.of(context).translate('canvass.resetMessagesTooltip'),
        onPressed: chatData.isEmpty ? null : _clearMessages,
        child: const Icon(Icons.restart_alt),
      ),
      const SizedBox(width: 8),
      FloatingActionButton.small(
        shape: const CircleBorder(),
        backgroundColor: chatData.isEmpty
            ? Theme.of(context).colorScheme.surfaceDim
            : Theme.of(context).colorScheme.secondaryContainer,
        hoverColor: chatData.isEmpty
            ? Theme.of(context).colorScheme.surfaceDim
            : Theme.of(context).colorScheme.secondaryContainer,
        elevation: 3.0,
        hoverElevation: 3.0,
        tooltip: AppLocalizations.of(context).translate('canvass.saveSessionTooltip'),
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
        child: const Icon(Icons.save_alt),
      ),
      SizedBox(width: deviceType != UserDeviceType.phone ? 32 : 18),
      FloatingActionButton.small(
        shape: const CircleBorder(),
        backgroundColor: (selectedModel !=null  && selectedModel.supportsImages)
          ? Theme.of(context).colorScheme.secondaryContainer
          : Theme.of(context).colorScheme.surfaceDim,
        hoverColor: (selectedModel !=null  && selectedModel.supportsImages)
          ? Theme.of(context).colorScheme.secondaryContainer
          : Theme.of(context).colorScheme.surfaceDim,
        elevation: 3.0,
        hoverElevation: 3.0,
        tooltip: AppLocalizations.of(context).translate('canvass.attachFilesTooltip'),
        onPressed: (selectedModel !=null  && selectedModel.supportsImages) ? _attachFiles : null,
        child: const Icon(Icons.attach_file),
      ),
      const SizedBox(width: 8),
      FloatingActionButton.small(
        shape: const CircleBorder(),
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        hoverColor: Theme.of(context).colorScheme.primary,
        elevation: 3.0,
        hoverElevation: 3.0,
        tooltip: AppLocalizations.of(context).translate('canvass.sendPromptTooltip'),
        onPressed: () => _sendPrompt(_promptController.text, null),
        child: const Icon(Icons.send_sharp),
      ),
    ];
  }

} // CanvassState

class DecryptDialog {

  static Future<void> showDecryptDialog({
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
      context: AppData.instance.navigatorKey.currentContext!,
      barrierDismissible: false,
      builder: (BuildContext context) {

        return AlertDialog(
          title: DialogTitle(title: AppLocalizations.of(context).translate('canvass.encryptedContentDialog.title')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppLocalizations.of(context).translate('canvass.encryptedContentDialog.message'), style: Theme.of(context).textTheme.bodyLarge,),
              TextField(
                controller: keyController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).translate('canvass.encryptedContentDialog.encryptionKeyLabel'),
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
              child: Text(AppLocalizations.of(context).translate('canvass.encryptedContentDialog.decryptButton')),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text(AppLocalizations.of(context).translate('canvass.encryptedContentDialog.cancelButton')),
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
          title: Text(AppLocalizations.of(context).translate('canvass.encryptedContentDialog.errorDialog.title')),
          content: Text(AppLocalizations.of(context).translate('canvass.encryptedContentDialog.errorDialog.message').replaceAll("{key}", key)),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the error dialog
              },
              child: Text(AppLocalizations.of(context).translate('canvass.encryptedContentDialog.errorDialog.closeButton')),
            ),
          ],
        );
      },
    );
  }
}

class ShiftEnterTextFormField extends StatefulWidget {
  final BuildContext parentContext;
  final FocusNode focusNode;
  final TextEditingController promptController;
  final Future<void> Function(String?, FocusNode?) sendFunction;
  const ShiftEnterTextFormField({super.key, required this.parentContext, required this.focusNode, required this.promptController, required this.sendFunction} );

  @override
  ShiftEnterTextFormFieldState createState() => ShiftEnterTextFormFieldState();
}

class ShiftEnterTextFormFieldState extends State<ShiftEnterTextFormField> {
  final FocusNode focusKeyEvents = FocusNode();

  @override
  void dispose() {
    focusKeyEvents.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
  return KeyboardListener(
    focusNode: focusKeyEvents,
    onKeyEvent: (KeyEvent event) {
      if (event is KeyDownEvent) {
        if (HardwareKeyboard.instance.isShiftPressed  && event.logicalKey == LogicalKeyboardKey.enter) {
          // Capture shift-enter
        } else if (HardwareKeyboard.instance.isControlPressed  && event.logicalKey == LogicalKeyboardKey.enter) {
          // Capture ctrl-enter
          widget.promptController.text += '\n';
        } else if (event.logicalKey == LogicalKeyboardKey.enter) {
            sendPromptKeyEvent();
        }
      }
    },
    child: TextFormField(
          controller: widget.promptController,
          focusNode: widget.focusNode,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context).translate('canvass.promptMessage'),
            alignLabelWithHint: true,
          ),
          maxLines: 5,
          autofocus: true,
          //textInputAction: TextInputAction.send,
    ));
  }

  void sendPromptKeyEvent() async {
    
    final String promptText = widget.promptController.text.toString(); // copy

    // Clear prompt
    setState(() {
      widget.promptController.clear();
    });

    await widget.sendFunction(promptText, focusKeyEvents);

    // ignore: use_build_context_synchronously
    FocusScope.of(context).requestFocus(widget.focusNode);

  }

}