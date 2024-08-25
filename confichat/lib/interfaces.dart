/*
 * Copyright 2024 Rune Berg (http://runeberg.io | https://github.com/1runeberg)
 * Licensed under Apache 2.0 (https://www.apache.org/licenses/LICENSE-2.0)
 * SPDX-License-Identifier: Apache-2.0
 */

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:confichat/app_data.dart';

typedef CallbackPassVoidReturnInt = int Function();
typedef CallbackPassIntReturnVoid = Function(int);
typedef CallbackPassIntReturnBool = bool Function(int);
typedef CallbackPassIntStringReturnVoid = Function(int, String);
typedef CallbackPassIntChunkReturnVoid = Function(int, StreamChunk);
typedef CallbackPassDynReturnVoid = Function(dynamic);
typedef CallbackPassIntDynReturnVoid = Function(int, dynamic);


class StreamChunk{
  final String content;

  StreamChunk(this.content);
}

abstract class LlmApi {
  final AiProvider aiProvider; 

  LlmApi(this.aiProvider);

  // Public vars
  String scheme = 'https';
  String host = 'localhost';
  int port = 443; 
  String path = '/api';
  String apiKey = '';

  double defaultTemperature = 1.0;
  double defaultProbability = 0.5;
  int defaultMaxTokens = 256;
  List<String>  defaultStopSequences = [];

  double temperature = 1.0;
  double probability = 0.5;
  int maxTokens = 256;
  List<String> stopSequences = [];

  String systemPrompt = '';
  String summaryPrompt = 'Create a title or subject heading of our conversation so far in one sentence, with a maximum of 100 characters. Only use alphanumeric characters, spaces, and dashes when appropriate. Do not add any special characters specially a period, slash, colon, quotes, and do not add any comments, just the title/subject heading as requested.';
  
  bool isProcessing = false;
  String responseData = 'No data';

  // Abstract functions
  Future<void> loadSettings();
  Future<void> getModels(List<ModelItem> outModels);
  Future<void> getCachedMessagesInModel(List<dynamic> outCachedMessages, String modelId);
  Future<void> loadModelToMemory(String modelId);
  Future<void> getModelInfo(ModelInfo outModelInfo, String modelId);
  Future<void> deleteModel(String modelId);
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
  });

  // Concrete functions
  Uri getUri(String endpoint){
    final String apiCall = path + endpoint;

    return Uri(
      scheme: scheme,
      host: host,
      port: port,
      path: apiCall  
    );

  }

  void applyDocumentContext({
    required List<Map<String, dynamic>> messages,
    Map<String, String>? documents,
    Map<String, String>? codeFiles,
  }) {
    
    var entry = messages.last;
    if (entry.containsKey('role') && 
        entry['role'] == 'user' &&
        entry.containsKey('content') &&
        entry['content'] != null &&
        entry['content'].toString().isNotEmpty) {

        String combinedDocuments = '';
        if (documents != null && documents.isNotEmpty) {
          // Combine all documents with filenames
          combinedDocuments = documents.entries
              .map((doc) => '\n\n\nFilename: ${doc.key}\n\n${doc.value}')
              .join();
        }

        String combinedCodeFiles = '';
        if (codeFiles != null && codeFiles.isNotEmpty) {
          // Combine all code files with filenames
          combinedCodeFiles = codeFiles.entries
              .map((code) => '\n\n\nFilename: ${code.key}\n\n```\n${code.value}\n```')
              .join();
        }

        String allDocuments = '';
        if( combinedDocuments.isNotEmpty)
        {
          allDocuments = AppData.promptDocs + combinedDocuments;
          if( combinedCodeFiles.isNotEmpty) {
            allDocuments += '${AppData.promptDocs}$combinedDocuments\n\n\n${AppData.promptCode}$combinedCodeFiles';
          }

          entry['content'] += allDocuments;
        } else if ( combinedCodeFiles.isNotEmpty) {
          allDocuments += '${AppData.promptDocs}$combinedDocuments\n\n\n${AppData.promptCode}$combinedCodeFiles';
          entry['content'] += allDocuments;
        }
                    
      }

  }

  Future<void> postData({ required Uri url, required Map<String, String> requestHeaders, String? requestPayload }) async {
    try {
      // Send POST
      final response = await http.post(url, headers: requestHeaders, body: requestPayload);
      isProcessing = true;

      // Check the response status
      if (response.statusCode == 200) {
          responseData = response.body;
        } else {
            responseData = 'Failed to load data: ${response.statusCode}';
        }

    } catch (e) {
        responseData = 'Error: $e\n' 'URL: $url\n' 'Payload: $requestPayload';
    } finally {
      isProcessing = false;
    }

  }

  Future<void> getData({ required Uri url, Map<String, String>? requestHeaders }) async {
    try {
      // Send GET
      final response = await http.get(url, headers: requestHeaders ?? {} );
      isProcessing = true;

      // Check the response status
      if (response.statusCode == 200) {
          responseData = response.body;
        } else {
            responseData = 'Failed to load data: ${response.statusCode}';
        }

    } catch (e) {
        responseData = 'Error: $e\n' 'URL: $url\n';
    } finally {
      isProcessing = false;
    }

  }

  Future<void> deleteData({ required Uri url, required Map<String, String> requestHeaders, String? requestPayload }) async {
    try {
      // Send POST
      final response = await http.delete(url, headers: requestHeaders, body: requestPayload);
      isProcessing = true;

      // Check the response status
      if (response.statusCode == 200) {
          responseData = response.body;
        } else {
            responseData = 'Failed to delete data: ${response.statusCode}';
        }

    } catch (e) {
        responseData = 'Error: $e\n' 'URL: $url\n' 'Payload: $requestPayload';
    } finally {
      isProcessing = false;
    }

  }

  Future<void> requestData({ 
      required Uri url, 
      required Map<String, String> requestHeaders, 
      String? requestPayload, 
      CallbackPassVoidReturnInt? onStreamRequestSuccess,
      CallbackPassIntStringReturnVoid? onStreamChunkReceived,
      CallbackPassIntReturnVoid? onStreamComplete,
      CallbackPassDynReturnVoid? onStreamRequestError,
      CallbackPassDynReturnVoid? onStreamingError
    }) async {
    // Send the request and headers
    final request = http.Request('POST', url)
      ..headers.addAll(requestHeaders);

    // Add payload, if any
    if (requestPayload != null) {
      request.body = requestPayload;
    }

    // Send request and await streamed response
    final response = await request.send();

    // Check the status of the response
    if (response.statusCode == 200) {

      // Handle callback if any
      int indexPayload = 0;
      if(onStreamRequestSuccess != null) { indexPayload = onStreamRequestSuccess();  }

      // Listen for json object stream from api
      response.stream.transform(utf8.decoder).listen((chunk) {

          // Handle callback (if any)
          if(onStreamChunkReceived != null) { onStreamChunkReceived(indexPayload, chunk); }

      }, onDone: () { 

          if(onStreamComplete != null) { onStreamComplete(indexPayload); }

      }, onError: (error) {

          if (kDebugMode) {print('Streamed data request failed with error: $error');}
          if(onStreamingError != null) { onStreamingError(error);  }
      });

    } else {
      if (kDebugMode) {print('Streamed data request failed with status: ${response.statusCode}');}
      if(onStreamRequestError != null) { onStreamRequestError(response.statusCode);  }
    }
  } // requestData

} // LlmApi

