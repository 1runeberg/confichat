/*
 * Copyright 2024-25 Rune Berg (http://runeberg.io | https://github.com/1runeberg)
 * Licensed under Apache 2.0 (https://www.apache.org/licenses/LICENSE-2.0)
 * SPDX-License-Identifier: Apache-2.0
 */

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'interfaces.dart';

import 'package:confichat/app_data.dart';

class ApiOllama extends LlmApi{

  static final ApiOllama _instance = ApiOllama._internal();
  static ApiOllama get instance => _instance;

  // Factory constructor
  factory ApiOllama() {
    return _instance;
  }

  ApiOllama._internal() : super(AiProvider.ollama) {
      scheme = 'http';
      host = 'localhost';
      port = 11434; 
      path = '/api';

      defaultTemperature = 1.0;
      defaultProbability = 1.0;
      defaultMaxTokens = 2048;
      defaultStopSequences = [];

      temperature = 1.0;
      probability = 1.0;
      maxTokens = 2048;
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

      if (settings.containsKey(AiProvider.ollama.name)) {

        // Override values in memory from disk
        scheme = settings[AiProvider.ollama.name]['scheme'] ?? 'http';
        host = settings[AiProvider.ollama.name]['host'] ?? 'localhost';
        port = settings[AiProvider.ollama.name]['port'] ?? 11434;
        path = settings[AiProvider.ollama.name]['path'] ?? '/api';

      }
    } 
  }

  @override
  Future<void> getModels(List<ModelItem> outModels) async  {

    try {
      // Retrieve active models for provider
      await getData(url: getUri('/tags'));

      // Decode response
      Map<String, dynamic> jsonData = jsonDecode(responseData);
      List<dynamic> apiModels = jsonData['models'];
      
      // Process list of models
      for (var apiModel in apiModels) {
        outModels.insert(0, ModelItem(apiModel['name'], apiModel['name']));
      }

    } catch (e) {
       if (kDebugMode) {print('Unable to retrieve models ($host): $e\n $responseData');}
    } 
  } 

  @override
  Future<void> getCachedMessagesInModel(List<dynamic> outCachedMessages, String modelId) async {

    try {
      // Retrieve model info
      await postData(
        url: getUri('/show'),
        requestHeaders: AppData.headerJson,
        requestPayload: jsonEncode({'name': modelId, 'format': 'json', 'stream': false}),
      );

      // Decode response
      Map<String, dynamic> jsonData = jsonDecode(responseData);

      // Set chat history to cached messages
      if (jsonData.containsKey('messages')) {
        List<dynamic> messages = jsonData['messages'];
        outCachedMessages.addAll(messages);  
      }
      
    } catch (e) {
         if (kDebugMode) {print('Unable to retrieve model info($host): $e\n $responseData');}
    }
  }

  @override
  Future<void> loadModelToMemory(String modelId) async {
    try {
      await postData(
        url: getUri('/generate'),
        requestHeaders: AppData.headerJson,
        requestPayload: jsonEncode({
          'model': modelId,
          'stream': false
        }));

    } catch (e) {
       if (kDebugMode) {print('Unable to load model $modelId to memory: $e\n $responseData');}
    }
  }

  @override
  Future<void> getModelInfo(ModelInfo outModelInfo, String modelId) async {

    try {

      // Send api request
      await postData(
        url: getUri('/show'),
        requestHeaders: AppData.headerJson,
        requestPayload: jsonEncode({'name': modelId, 'format': 'json', 'stream': false}),
      );

      // Decode response
      Map<String, dynamic> jsonData = jsonDecode(responseData);

      if (jsonData.containsKey('details')) {
        Map<String, dynamic> details = jsonData['details'];

        outModelInfo.parameterSize = details['parameter_size'] ?? '';
        outModelInfo.parentModel = details['parent_model'] ?? '';
        outModelInfo.quantizationLevel = details['quantization_level'] ?? '';        
      }

      if (jsonData.containsKey('model_info')) {
        Map<String, dynamic> modelInfo = jsonData['model_info'];

        outModelInfo.rootModel = modelInfo['general.basename'] ?? '';
        outModelInfo.languages = modelInfo['general.languages'].toString();
      }

      if (jsonData.containsKey('modified_at')) {
        outModelInfo.createdOn =  jsonData['modified_at'] ?? '';

        if ( outModelInfo.createdOn.isNotEmpty ){
          DateTime dateTime = DateTime.parse(outModelInfo.createdOn);
          DateTime utcDateTime = dateTime.toUtc();
          String formattedDate = DateFormat('yyyy-MMM-dd HH:mm:ss').format(utcDateTime);
          outModelInfo.createdOn = '$formattedDate (UTC)';
        }
      }

      if (jsonData.containsKey('system')) {
        outModelInfo.systemPrompt = jsonData['system'] ?? '';
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
    try {
      // Retrieve active models for provider
      await deleteData(
        url: AppData.instance.api.getUri('/delete'),
        requestHeaders: AppData.headerJson,
        requestPayload: jsonEncode({'name': modelId, 'format': 'json', 'stream': false}),
      );

      } catch (e) {
        // Catch and handle the FormatException
        if (kDebugMode) { print('Unable to delete model: $e\n ${AppData.instance.api.responseData}'); }
    } 
  }

  @override
  // ignore: unused_element
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

        // Process messages to extract images
        List<Map<String, dynamic>> processedMessages = messages.map((message) {
          // Check for images in the message
          if (message['images'] != null) {
            // If images exist, extract the base64 values
            List<String> base64Images = [];
            var images = message['images'] as List<Map<String, String>>;

            for (var image in images) {
              base64Images.add(image['base64'] ?? '');
            }

            // Create a new message with extracted base64 images
            return {
              "role": message['role'],
              "content": message['content'],
              "images": base64Images, // Use only base64 images
            };
          }
          return message; // Return the message as is if no images
        }).toList();


        // Assemble request
        final request = http.Request('POST', getUri('/chat'))
          ..headers.addAll(AppData.headerJson);

        Map<String, dynamic> summaryRequest = {}; 
        if(getSummary)
        {
            summaryRequest = {
              "role": 'user',
              "content": summaryPrompt,
            };
        }

        request.body = jsonEncode({
              'model': modelId,
              'messages': [ 
                ...processedMessages, 
                if (getSummary) summaryRequest,
              ],
              'options': {
                'temperature': temperature,
                'top_p': probability,
                'num_predict': maxTokens,
                if (filteredStopSequences.isNotEmpty) 'stop': filteredStopSequences,
              },
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
          streamSub = response.stream.transform(utf8.decoder).listen((chunk) {

              // Check if user requested a cancel
              bool cancelRequested = onStreamCancel != null;
              if(cancelRequested){ cancelRequested = onStreamCancel(indexPayload); }
              if(cancelRequested){
                if(onStreamComplete != null) { onStreamComplete(indexPayload); }
                          streamSub?.cancel();
                          return;
              }

              // Handle callback (if any)
              if(onStreamChunkReceived != null) 
              { 
                // Uncomment for testing
                //print(chunk);

                // Decode response
                final Map<String, dynamic> jsonResponse = jsonDecode(chunk);

                if (jsonResponse.containsKey('message')) {
                  Map<String, dynamic> message = jsonResponse['message'];

                  // Parse api chunk and convert to app format
                  if (message.containsKey('content')) {
                      onStreamChunkReceived(indexPayload, StreamChunk(message['content'])); 
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
          if (kDebugMode) {print('Streamed data request failed with status: ${response.statusCode}');}
          if(onStreamRequestError != null) { onStreamRequestError(response.statusCode);  }
        } 

      } catch (e) {
        final String errorMessage = 'Unable to get chat response: $e\n $responseData';
        ShowErrorDialog(title: '${AiProvider.ollama.name}: Fatal error' , content: errorMessage);
      } 

  }

} // ApiOllama