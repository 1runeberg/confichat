/*
 * Copyright 2024 Rune Berg (http://runeberg.io | https://github.com/1runeberg)
 * Licensed under Apache 2.0 (https://www.apache.org/licenses/LICENSE-2.0)
 * SPDX-License-Identifier: Apache-2.0
 */

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:confichat/app_data.dart';
import 'package:confichat/interfaces.dart';
import 'package:confichat/persistent_storage.dart';
import 'package:confichat/ui_widgets.dart';


class SaveChatSession extends StatefulWidget {
  final List<Map<String, dynamic>> chatData;
  final Directory chatSessionsDir;
  final SelectedModelProvider selectedModelProvider;

  const SaveChatSession({
    super.key,
    required this.chatData,
    required this.chatSessionsDir,
    required this.selectedModelProvider,
  });

  @override
  SaveChatSessionState createState() => SaveChatSessionState();

}


class SaveChatSessionState extends State<SaveChatSession>  {

  bool _encrypt = false;
  bool _suggested = false;

  final TextEditingController _sessionNameController = TextEditingController();
  final TextEditingController _encryptionKeyController = TextEditingController();
  final TextEditingController _confirmKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _sessionNameController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _sessionNameController.dispose();
    _encryptionKeyController.dispose();
    _confirmKeyController.dispose();
    super.dispose();
  }

  void _showResultDialog(BuildContext context, {required bool success, required String message}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: DialogTitle(title: success ? 'Success' : 'Fail', isError: !success,),
          content: SelectableText(message),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the result dialog
                Navigator.of(context).pop(); // Close the save dialog
              },
            ),
          ],
        );
      },
    );
  }

  void _suggestName(int index, StreamChunk chunk)
  {
    if(_sessionNameController.text.length < 150 ){
      _sessionNameController.text += chunk.content;
    }
  }

  Future<void> _saveChatSession(BuildContext context) async {
    final selectedModelName = widget.selectedModelProvider.selectedModel?.name ?? 'Unknown Model';

    // Check for valid name
    if (_sessionNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          content: const Text('Name is required'),
        ),
      );
    }

    // Cleanup filename
    final RegExp pattern = RegExp(r'[<>:"/\\|?*\x00-\x1F]');
    
    // Replace all matches of the pattern with an underscore
    String cleaned = _sessionNameController.text.replaceAll(pattern, '');

    // Trim leading and trailing spaces and dots
    cleaned = cleaned.trim().replaceAll(RegExp(r'^\.+|\.+$'), '');

    // Check encryption params
    if (_encrypt 
        && _encryptionKeyController.text.isNotEmpty
        && _encryptionKeyController.text != _confirmKeyController.text
    ){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          content: const Text('Encyption key and confirmation does not match!'),
        ),
      );

      return;
    }

    // Encrypt chat data if needed 
    String iv = _encrypt ? CryptoUtils.encryptChatDataGenerateIV(userKey: _encryptionKeyController.text, chatData: widget.chatData) : '';

    // Encrypt system prompt
    if( _encrypt && AppData.instance.api.systemPrompt.trim().isNotEmpty) { 
      AppData.instance.api.systemPrompt = CryptoUtils.encryptStringIV(
        base64IV: iv, 
        userKey: _encryptionKeyController.text, 
        data: AppData.instance.api.systemPrompt );
    }

    // Save the messages as a json object/array
    String fileName = cleaned;
    String content = jsonEncode(widget.chatData);

    try {
      await PersistentStorage.saveFile(
        widget.chatSessionsDir, 
        selectedModelName, 
        fileName, 
        content,
        iv
        );

      // Decrypt chat data back after save (for active session)
      if(_encrypt) { 

        if(AppData.instance.api.systemPrompt.isNotEmpty) {
          // System prompt
          AppData.instance.api.systemPrompt = CryptoUtils.decryptString(
            base64IV: iv, 
            userKey: _encryptionKeyController.text, 
            encryptedData: AppData.instance.api.systemPrompt );
        }
        
        // Chat data
        CryptoUtils.decryptChatData(base64IV: iv, userKey: _encryptionKeyController.text, chatData: widget.chatData); 
      }


      // Success
      String folder = PersistentStorage.cleanupModelName(selectedModelName);
      AppData.instance.haveUnsavedMessages = false;
      _showResultDialog(
        // ignore: use_build_context_synchronously
        context,
        success: true,
        message: 'Saved to: \n${widget.chatSessionsDir.path}/$folder/${AppData.appFilenameBookend}$fileName${AppData.appFilenameBookend}.json',
      );


    } catch (e) {

      // Error
      String folder = PersistentStorage.cleanupModelName(selectedModelName);
      _showResultDialog(
        // ignore: use_build_context_synchronously
        context,
        success: false,
        message: 'Failed to save: $e\nFile: ${widget.chatSessionsDir.path}/$folder/${AppData.appFilenameBookend}$fileName${AppData.appFilenameBookend}.json',
      );
      if (kDebugMode) {
        print('Failed to save: $e\nFile: ${widget.chatSessionsDir.path}/$folder/${AppData.appFilenameBookend}$fileName${AppData.appFilenameBookend}.json');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedModelName = widget.selectedModelProvider.selectedModel?.name ?? 'Unknown Model';

    if(!_suggested) {
      AppData.instance.api.sendPrompt(
            modelId: selectedModelName, 
            messages: widget.chatData,
            getSummary: true,
            onStreamChunkReceived: _suggestName,
          );

      _suggested = true;
    }

    return AlertDialog(
      title: const DialogTitle(title: 'Save Chat Session'), 
      content: SingleChildScrollView(
      scrollDirection: Axis.vertical,      
      child: ConstrainedBox( constraints:  
        const BoxConstraints(
          minWidth: 300, 
          maxWidth: 300,
          maxHeight: 400, 
        ), 
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          // Model name
          TextField(
            controller: TextEditingController(text: selectedModelName),
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Model Name',
            ),
          ),

          // File name
          TextFormField(
            controller: _sessionNameController,
            decoration: InputDecoration(
              labelText: 'Session subject (filename) *',
               suffixIcon: _sessionNameController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _sessionNameController.clear();
                    },
                  )
                : null,
            ),
            maxLines: 3,
            maxLength: 150,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a name (this will also be used as the filename)';
              }
              return null;
            },
          ),

          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              const Text('Encrypt', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Switch(
                value: _encrypt,
                onChanged: (bool value) {
                  setState(() {
                    _encrypt = value;
                  });
                },
              ),
            ],
          ),

          // Encryption key
          TextFormField(
            controller: _encryptionKeyController,
            decoration: const InputDecoration(
              labelText: 'Encryption Key',
            ),
            obscureText: true,
            enabled: _encrypt,
          ),

          // Confirm encryption key
          TextFormField(
            controller: _confirmKeyController,
            decoration: const InputDecoration(
              labelText: 'Confirm Key',
            ),
            obscureText: true,
            enabled: _encrypt,
          ),

        ],
      ),),),
      
      actions: <Widget>[

        // Save button
        ElevatedButton(
          child: const Text('Save'),
          onPressed: () => _saveChatSession(context),
        ),

        // Cancel button
        ElevatedButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop(); // Close the save dialog
          },
        ),
      ],
      
    );
  }
}
