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

import 'package:confichat/app_data.dart';


class ApiAnthropic extends LlmApi{

  static String version = '2023-06-01';
  static final ApiAnthropic _instance = ApiAnthropic._internal();
  static ApiAnthropic get instance => _instance;

  factory ApiAnthropic() {
    return _instance;
  }
  ApiAnthropic._internal() : super(AiProvider.anthropic) {

      scheme = 'https';
      host = 'api.anthropic.com';
      port = 443; 
      path = '/v1';

      defaultTemperature = 1.0;
      defaultProbability = 1.0;
      defaultMaxTokens = 1024;
      defaultStopSequences = [];

      temperature = 1.0;
      probability = 1.0;
      maxTokens = 1024;
      stopSequences = [];
  }

  bool isImageTypeSupported(String extension){
    const allowedExtensions = ['jpeg', 'png', 'gif', 'webp'];
    return allowedExtensions.contains(extension.toLowerCase());
  }

  // Implementations
  @override
  Future<void> loadSettings() async {
    final directory = AppData.instance.rootPath.isEmpty ? await getApplicationDocumentsDirectory() : Directory(AppData.instance.rootPath);
    final filePath ='${directory.path}/${AppData.appStoragePath}/${AppData.appSettingsFile}';

    if (await File(filePath).exists()) {
      final fileContent = await File(filePath).readAsString();
      final Map<String, dynamic> settings = json.decode(fileContent);

      if (settings.containsKey(AiProvider.anthropic.name)) {

        // Override values in memory from disk
        apiKey = settings[AiProvider.anthropic.name]['apikey'] ?? '';
      }
    } 
  }

  @override
  Future<void> getModels(List<ModelItem> outModels) async  {

    // As of this writing, there doesn't seem to be an api endpoint to grab model names
    outModels.add(ModelItem('claude-3-7-sonnet-20250219', 'claude-3-7-sonnet-20250219'));
    outModels.add(ModelItem('claude-3-5-sonnet-20241022', 'claude-3-5-sonnet-20241022'));
    outModels.add(ModelItem('claude-3-5-haiku-20241022', 'claude-3-5-haiku-20241022'));
    outModels.add(ModelItem('claude-3-opus-20240229', 'claude-3-opus-20240229'));
    outModels.add(ModelItem('claude-3-sonnet-20240229', 'claude-3-sonnet-20240229'));
    outModels.add(ModelItem('claude-3-haiku-20240307', 'claude-3-haiku-20240307'));
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
    // No function for this exists in Anthropic as of this writing
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

        // Assemble headers - this sequence seems to matter with Anthropic streaming
        Map<String, String> headers = {'anthropic-version': version};
        headers.addAll(AppData.headerJson);
        headers.addAll({'x-api-key': apiKey});

        // Parse message for sending to chatgpt
        List<Map<String, dynamic>> apiMessages = [];

        String systemPrompt = '';
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
            for (var imageFile in message['images']) {
              
              if(isImageTypeSupported(imageFile['ext'])){
                contentList.add({
                  "type": "image",
                  "source": { 
                      "type": "base64",
                      "media_type": "image/${imageFile['ext']}",
                      "data": imageFile['base64'],
                  }
                });
              }

            }
          }

          // Check for valid message         
          if(message.containsKey('role')) {

             // Check for system prompt
            if(message['role'] == 'system') {
              systemPrompt = message['content'];
            } else {
              // Add to message history
              apiMessages.add({
                "role": message['role'],
                "content":  contentList,
              });
            }
          }
        }

        // Add summary prompt
        if( getSummary ) {
          apiMessages.add({
              "role": 'user',
              "content": summaryPrompt,
            });
        }

        // Assemble request
        final request = http.Request('POST', getUri('/messages'))
          ..headers.addAll(headers);

        request.body = jsonEncode({
              'model': modelId,
              'messages': apiMessages,
              'temperature': temperature,
              'top_p': probability,
              'max_tokens': maxTokens,
               if (filteredStopSequences.isNotEmpty) 'stop_sequences': filteredStopSequences,
               if (systemPrompt.isNotEmpty) 'system': systemPrompt,
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
                if (jsonMap.containsKey('delta') && jsonMap['delta'].isNotEmpty) {
                  var delta = jsonMap['delta'];

                  // Extract the content
                  if (delta.containsKey('text')) {
                    String content = delta['text'];
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

}

class SseTransformer extends StreamTransformerBase<String, String> {
  
  @override
  Stream<String> bind(Stream<String> stream) {
    final controller = StreamController<String>();
    final buffer = StringBuffer();

    stream.listen((line) {

      // Uncomment for troubleshooting
      //print(line);

      if (line.startsWith('data: {"type":"content_block_delta')) {    // We're only interested with the content deltas
        buffer.write(line.substring(6));                              // Append line data to buffer, excluding the 'data: ' prefix
      } else if (line.isEmpty) {
        // Empty line indicates end of an event
        if (buffer.isNotEmpty) {
          final event = buffer.toString();
          if (event != '[DONE]') { controller.add(event); }
          buffer.clear();
        }
      }
    }, onDone: () {
      controller.close();
    }, onError: (error) {
      controller.addError(error);
    });

    return controller.stream;
  }

} 
