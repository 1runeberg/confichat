/*
 * Copyright 2024 Rune Berg (http://runeberg.io | https://github.com/1runeberg)
 * Licensed under Apache 2.0 (https://www.apache.org/licenses/LICENSE-2.0)
 * SPDX-License-Identifier: Apache-2.0
 */

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'interfaces.dart';
import 'package:intl/intl.dart';

import 'package:confichat/app_data.dart';


class ApiChatGPT extends LlmApi{

  static final ApiChatGPT _instance = ApiChatGPT._internal();
  static ApiChatGPT get instance => _instance;

  factory ApiChatGPT() {
    return _instance;
  }

  ApiChatGPT._internal() : super(AiProvider.openai) {

      scheme = 'https';
      host = 'api.openai.com';
      port = 443; 
      path = '/v1';

      defaultTemperature = 1.0;
      defaultProbability = 1.0;
      defaultMaxTokens = 4096;
      defaultStopSequences = [];

      temperature = 1.0;
      probability = 1.0;
      maxTokens = 4096;
      stopSequences = [];
  }

  // Implementations
  @override
  Future<void> loadSettings() async {
    final directory = AppData.instance.rootPath.isEmpty ? await getApplicationDocumentsDirectory() : Directory(AppData.instance.rootPath);
    final filePath ='${directory.path}/${AppData.appStoragePath}/${AppData.appSettingsFile}';

    if (await File(filePath).exists()) {
      final fileContent = await File(filePath).readAsString();
      final Map<String, dynamic> settings = json.decode(fileContent);

      if (settings.containsKey(AiProvider.openai.name)) {

        // Override values in memory from disk
        apiKey = settings[AiProvider.openai.name]['apikey'] ?? '';
      }
    } 
  }

  @override
  Future<void> getModels(List<ModelItem> outModels) async  {

    try {
        
        // Add authorization header
        final Map<String, String> headers = {'Authorization': 'Bearer $apiKey'};

        // Retrieve active models for provider
        await getData(url: getUri('/models'), requestHeaders: headers);

        // Decode response
        final Map<String, dynamic> jsonData = jsonDecode(responseData);
        final List<dynamic> modelsJson = jsonData['data'];

        // Parse to ModelItem
        for (var json in modelsJson) {
          final String id = json['id'];
          outModels.add(ModelItem(id, id));
        }

      } catch (e) {
        // Catch and handle the FormatException
        if (kDebugMode) { print('Unable to retrieve models ($host): $e\n $responseData'); }
    } 

  } 

  @override
  Future<void> getCachedMessagesInModel(List<dynamic> outCachedMessages, String modelId) async {    
  }

  @override
  Future<void> loadModelToMemory(String modelId) async {
    return; // no need to preload model with chatgpt online models
  }

  @override
  Future<void> getModelInfo(ModelInfo outModelInfo, String modelId) async {

    try {

      // Add authorization header
      final Map<String, String> headers = {'Authorization': 'Bearer $apiKey'};

      // Send api request
      await getData(
        url: getUri('/models/$modelId'),
        requestHeaders: headers
      );

      // Decode response
      Map<String, dynamic> jsonData = jsonDecode(responseData);
      outModelInfo.parameterSize = '';
      outModelInfo.parentModel = jsonData['id'];
      outModelInfo.quantizationLevel = '';        
      outModelInfo.rootModel = '';
      outModelInfo.languages = '';
      outModelInfo.systemPrompt = '';

      // Parse unix timestamp
      int? unixTimestamp = jsonData['created'];

      if(unixTimestamp != null){
        final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(unixTimestamp * 1000, isUtc: true);
        final String formattedDate = DateFormat('yyyy-MMM-dd HH:mm:ss').format(dateTime);
        outModelInfo.createdOn = '$formattedDate (UTC)';
      } else {
        outModelInfo.createdOn = '';
      }

    } catch (e) {
      // Catch and handle the FormatException
      if (kDebugMode) {
        print('Unable to retrieve models: $e\n ${AppData.instance.api.responseData}');
      }
    }

  }

  @override
  Future<void> deleteModel(String modelId) async {
    // todo: allow deletion of tuned models
  }

  @override
  Future<void> sendPrompt({
    required String modelId, 
    required List<Map<String, dynamic>> messages,
    bool? getSummary,
    Map<String, String>? documents,
    Map<String, String>? codeFiles,
    CallbackPassVoidReturnInt? onStreamRequestSuccess,
    CallbackPassIntReturnBool? onStreamCancel,
    CallbackPassIntChunkReturnVoid? onStreamChunkReceived,
    CallbackPassIntReturnVoid? onStreamComplete,
    CallbackPassDynReturnVoid? onStreamRequestError,
    CallbackPassIntDynReturnVoid? onStreamingError 
  }) async {
      try {

        // Set if this is a summary request
        getSummary = getSummary ?? false;

        // Add documents if present
        applyDocumentContext(messages: messages, documents: documents, codeFiles: codeFiles );       
        
        // Filter out empty stop sequences
        List<String> filteredStopSequences = stopSequences.where((s) => s.trim().isNotEmpty).toList();

        // Assemble headers
        Map<String, String> headers = {'Authorization': 'Bearer $apiKey'};
        headers.addAll(AppData.headerJson);

        // Parse message for sending to chatgpt
        List<Map<String, dynamic>> apiMessages = [];

        for (var message in messages) {
          List<Map<String, dynamic>> contentList = [];

          // Add the text content
          if (message['content'] != null && message['content'].isNotEmpty) {
            contentList.add({
              "type": "text",
              "text": message['content'],
            });
          }

          // Add the images if any
          if (message['images'] != null) {
            for (var imageUrl in message['images']) {
              contentList.add({
                "type": "image_url",
                "image_url": {"url": "data:image/jpeg;base64,$imageUrl"},
              });
            }
          }

          apiMessages.add({
            "role": message['role'],
            "content": contentList,
          });
        }

        // Add summary prompt
        if( getSummary ) {
          apiMessages.add({
              "role": 'user',
              "content": summaryPrompt,
            });
        }

        // Assemble request
        final request = http.Request('POST', getUri('/chat/completions'))
          ..headers.addAll(headers);

        request.body = jsonEncode({
              'model': modelId,
              'messages': apiMessages,
              'temperature': temperature,
              'top_p': probability,
              'max_tokens': maxTokens,
               if (filteredStopSequences.isNotEmpty) 'stop': filteredStopSequences,
              'stream': true
        });

        // Send request and await streamed response
        final response = await request.send();

        // Check the status of the response
        if (response.statusCode == 200) {

          // Handle callback if any
          int indexPayload = 0;
          if(onStreamRequestSuccess != null) { indexPayload = onStreamRequestSuccess();  }

          // Listen for json object stream from api
          StreamSubscription<String>? streamSub;
          streamSub = response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter()) // Split by lines
            .transform(SseTransformer()) // Transform into SSE events
            .listen((chunk) {

              // Check if user requested a cancel
              bool cancelRequested = onStreamCancel != null;
              if(cancelRequested){ cancelRequested = onStreamCancel(indexPayload); }
              if(cancelRequested){
                if(onStreamComplete != null) { onStreamComplete(indexPayload); }
                          streamSub?.cancel();
                          return;
              }

              // Handle callback (if any)
              if(chunk.isNotEmpty) 
              { 
                // Uncomment for testing
                //print(chunk);

                // Parse the JSON string
                Map<String, dynamic> jsonMap = jsonDecode(chunk);
                
                // Extract the first choice
                if (jsonMap.containsKey('choices') && jsonMap['choices'].isNotEmpty) {
                  var firstChoice = jsonMap['choices'][0];
                  var delta = firstChoice['delta'];

                  // Extract the content
                  if (delta.containsKey('content')) {
                    String content = delta['content'];
                    if (content.isNotEmpty && onStreamChunkReceived != null) {
                      onStreamChunkReceived(indexPayload, StreamChunk(content)); 
                    }
                  }
                }

              }

          }, onDone: () { 

              if(onStreamComplete != null) { onStreamComplete(indexPayload); }

          }, onError: (error) {

              if (kDebugMode) {print('Streamed data request failed with error: $error');}
              if(onStreamingError != null) { onStreamingError(indexPayload, error);  }
          });

        } else {
          if (kDebugMode) {print('Streamed data request failed with status: ${response.statusCode}\n');}
          if(onStreamRequestError != null) { onStreamRequestError(response.statusCode);  }
        } 
    } catch (e) {
      if (kDebugMode) {
        print('Unable to get chat response: $e\n $responseData');
      }
    } 

  }

} // ApiChatGPT
