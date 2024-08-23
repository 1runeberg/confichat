/*
 * Copyright 2024 Rune Berg (http://runeberg.io | https://github.com/1runeberg)
 * Licensed under Apache 2.0 (https://www.apache.org/licenses/LICENSE-2.0)
 * SPDX-License-Identifier: Apache-2.0
 */

import 'dart:convert';

import 'package:confichat/file_parser.dart';
import 'package:flutter/foundation.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';

import 'dart:io';
import 'package:confichat/app_data.dart';


class PersistentStorage {

  // Clean up model name - truncate from colon
  static String cleanupModelName(String input) {
    int colonIndex = input.indexOf(':');
    
    if (colonIndex != -1) {
      return input.substring(0, colonIndex);
    }

    return input; // Return the original string if no colon is found
  }

  // Create a chat session file in json format
  static Future<void> saveFile(Directory dir, String modelName, String fileName, String content, String encryptionIV) async {
    // Create directory if it doesn't exist
    String folder = cleanupModelName(modelName);
    final directory = Directory('${dir.path}/$folder');
    await directory.create(recursive: true);
    
    // Save file
    final file = File('${directory.path}/${AppData.appFilenameBookend}$fileName${AppData.appFilenameBookend}.json');

    // Construct the data map according to the specified structure
    List<String> filteredStopSequences = AppData.instance.api.stopSequences.where((s) => s.trim().isNotEmpty).toList();
    final data = {
      'model': modelName,
      'createdDate': DateTime.now().toIso8601String(),
      'options': {
        'temperature': AppData.instance.api.temperature,
        'probability': AppData.instance.api.probability,
        'maxTokens': AppData.instance.api.maxTokens,
        'stopSequences': filteredStopSequences,
        'systemPrompt': AppData.instance.api.systemPrompt,
        'encryptionIV': encryptionIV,
      },
      'messages': content,
    };

    final jsonString = jsonEncode(data);
    await file.writeAsString(jsonString);
  }

  static void setAppData(dynamic jsonData) {
    final options = jsonData['options'];
    AppData.instance.api.temperature = options['temperature'] ?? AppData.instance.api.temperature;
    AppData.instance.api.probability = options['probability'] ?? AppData.instance.api.probability;
    AppData.instance.api.maxTokens = options['maxTokens'] ?? AppData.instance.api.maxTokens;
    AppData.instance.api.stopSequences = List<String>.from(options['stopSequences'] ?? []);
    AppData.instance.api.systemPrompt = options['systemPrompt'] ?? AppData.instance.api.systemPrompt;
  }


  // Check if file is encrypted
  static String isFileEncrypted(dynamic jsonData)  {
   try {
      // Decode json and extract metadata
      final options = jsonData['options'];
      final encryptionIV = options['encryptionIV'] ?? '';

      return encryptionIV as String;

    } catch (e) {
      if (kDebugMode) {print('Error checking encryption $e');}
      return '';
    }    
  }

  static Future<EncryptionPayload> getEncryptionPayload(Directory dir, String modelName, String fileName) async {

    try {

     // Read the file from disk
      String folder = cleanupModelName(modelName);
      final file = File('${dir.path}/$folder/${AppData.appFilenameBookend}$fileName${AppData.appFilenameBookend}.json');
      final fileContent = await file.readAsString();

      // Decode json and extract metadata
      final jsonData = jsonDecode(fileContent);
      final options = jsonData['options'];
      final messages = jsonData['messages'];
      final encryptionIV = options['encryptionIV'] ?? '';

      // Check for encryption IV which indicates this session has been encrypted
      if(encryptionIV == null || messages == null || messages.isEmpty) { return EncryptionPayload('', '');}

      // Retrieve first message
      List<Map<String, dynamic>> chatData = List<Map<String, dynamic>>.from(jsonDecode(messages));
      String firstUserMessage = '';
      for (var message in chatData) {
        if (message.containsKey('role') && message['role'] == 'user') {
          firstUserMessage = message['content'] as String;
          break;
        }
      }

      // No message found
      if(firstUserMessage.isEmpty) { return EncryptionPayload('', '');}

      return EncryptionPayload(encryptionIV as String, firstUserMessage) ;

    } catch (e) {
      if (kDebugMode) {print('Error reading encryptionIV: $e');}
    }

    return EncryptionPayload('', '');

  }

  // Retrieve encrypted chat session file
  static Future<String> readJsonFile(Directory dir, String modelName, String fileName) async {
    try {
      // Read the file from disk
      String folder = cleanupModelName(modelName);
      final file = File('${dir.path}/$folder/${AppData.appFilenameBookend}$fileName${AppData.appFilenameBookend}.json');
      final fileContent = await file.readAsString();

      return fileContent;

    } catch (e) {
      if (kDebugMode) {print('Error reading json file: $e');}
      return '';
    }
  }


  // Retrieve chat session file
  static Future<String> readFile(Directory dir, String modelName, String fileName) async {
    try {
      // Read the file from disk
      String folder = cleanupModelName(modelName);
      final file = File('${dir.path}/$folder/${AppData.appFilenameBookend}$fileName${AppData.appFilenameBookend}.json');
      final fileContent = await file.readAsString();

      // Decode json and extract metadata
      final jsonData = jsonDecode(fileContent);
      final options = jsonData['options'];
      AppData.instance.api.temperature = options['temperature'] ?? AppData.instance.api.temperature;
      AppData.instance.api.probability = options['probability'] ?? AppData.instance.api.probability;
      AppData.instance.api.maxTokens = options['maxTokens'] ?? AppData.instance.api.maxTokens;
      AppData.instance.api.stopSequences = List<String>.from(options['stopSequences'] ?? []);
      AppData.instance.api.systemPrompt = options['systemPrompt'] ?? AppData.instance.api.systemPrompt;

      // Return the messages array
      return jsonData['messages'];

    } catch (e) {
      if (kDebugMode) {print('Error retrieving chat message: $e');}
      return '';
    }
  }

  // Delete chat session file
  static Future<void> deleteFile(Directory dir, String modelName, String fileName) async {
    try {
      String folder = cleanupModelName(modelName);
      final file = File('${dir.path}/$folder/${AppData.appFilenameBookend}$fileName${AppData.appFilenameBookend}.json');
      if (await file.exists()) { await file.delete(); }

    } catch (e) {
      if (kDebugMode) {print('Error deleting chat message: $e');}
    }
  }

  // Rename file
  static Future<void> renameFile(Directory dir, String modelName, String currentFilename, String newFilename) async {
    try {
      String folder = cleanupModelName(modelName);
      final oldFile = File('${dir.path}/$folder/${AppData.appFilenameBookend}$currentFilename${AppData.appFilenameBookend}.json');
      await oldFile.rename('${dir.path}/$folder/${AppData.appFilenameBookend}$newFilename${AppData.appFilenameBookend}.json');

    } catch (e) {
      if (kDebugMode) { print('Error renaming file: $e'); }
    }
  }

  // Get all chat sessions
  static Future<void> getJsonFilenames({
    required List<String> filenames,
    required Directory directory,
    required String modelName,
    required bool withExtension,
  }) async {
    // Use modelName as folder/subpath
    String folder = cleanupModelName(modelName);

    // Construct the full path to the target subdirectory
    final Directory targetDirectory = Directory('${directory.path}/$folder');

    // Check if the directory exists
    if (await targetDirectory.exists()) {
      // List all files in the directory
      await for (FileSystemEntity entity in targetDirectory.list(recursive: false)) {
        if (entity is File && entity.path.endsWith('${AppData.appFilenameBookend}.json')) {
          String filename = entity.uri.pathSegments.last;

          // Check if the filename starts with bookend
          if (filename.startsWith(AppData.appFilenameBookend)) {

            if (!withExtension) {
              filename = filename.substring(0, filename.lastIndexOf('.'));
            }

            // Remove bookends
            filename = filename.substring((AppData.appFilenameBookend.length), filename.length - AppData.appFilenameBookend.length);
            filenames.add(filename);
          }
        }
      }
    } else {
      // Uncomment for debug
      //if (kDebugMode) { print('Directory does not exist: ${targetDirectory.path}'); }
    }
  }

  static void checkForDocuments(List<String> outDocuments, List<String> outCodeFiles, String inText) {
    // Use a StringBuffer to accumulate characters until a newline is encountered
    StringBuffer buffer = StringBuffer();
    for (int i = 0; i < inText.length; i++) {
      String ch = inText[i];
      if (ch == '\n') {
        // Process the accumulated line
        String line = buffer.toString().trim();
        buffer.clear();

        // Check if the line starts with 'Filename: '
        if (line.startsWith('Filename: ')) {
          // Extract the filename from the line
          String filename = line.substring('Filename: '.length).trim();

          // Determine the file type using the FileParser's getFileType method
          ParserFileType fileType = FileParser.getFileType(filename);

          // Add the filename to the appropriate list based on the file type
          if (fileType == ParserFileType.documentText || fileType == ParserFileType.documentBinary) {
            outDocuments.add(filename);
          } else if (fileType == ParserFileType.code) {
            outCodeFiles.add(filename);
          }
        }
      } else {
        // Accumulate characters until a newline is encountered
        buffer.write(ch);
      }
    }

    // Process the last line if it doesn't end with a newline
    if (buffer.isNotEmpty) {
      String line = buffer.toString().trim();
      if (line.startsWith('Filename: ')) {
        String filename = line.substring('Filename: '.length).trim();
        ParserFileType fileType = FileParser.getFileType(filename);
        if (fileType == ParserFileType.documentText || fileType == ParserFileType.documentBinary) {
          outDocuments.add(filename);
        } else if (fileType == ParserFileType.code) {
          outCodeFiles.add(filename);
        }
      }
    }
  }

}

class CryptoUtils {

static bool testKey({
    required EncryptionPayload encryptionPayload,
    required String userKey,
  }) {
    try{
      String decrypted = decryptString(
        base64IV: encryptionPayload.base64IV, 
        userKey: userKey, 
        encryptedData: encryptionPayload.encryptedData);
      return decrypted.isNotEmpty;
    } catch (e)
    {
      return false;
    }
  }

static String encryptStringIV({
    required String base64IV,
    required String userKey,
    required String data,
  }) {
    final iv = encrypt.IV.fromBase64(base64IV);
    return encryptString(iv: iv, userKey: userKey, data: data);
  }

  static String encryptString({
    required encrypt.IV iv,
    required String userKey,
    required String data,
  }) {
    try {     
      // Convert the user key to a 32-byte key using SHA-256 hash
      final userKeyBytes = sha256.convert(utf8.encode(userKey)).bytes;
      final key = encrypt.Key(Uint8List.fromList(userKeyBytes));

      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
      final encrypted = encrypter.encrypt(data, iv: iv);

      // Combine IV and encrypted data
      final combined = iv.bytes + encrypted.bytes;
      final outBase64Data = base64.encode(combined);

      return outBase64Data;
    } catch (e) {
        throw Exception('Encryption failed: $e');
    }

  }

  static String decryptString({
    required String base64IV,
    required String userKey,
    required String encryptedData,
  }) {
    try {
      // Convert the user key to a 32-byte key using SHA-256 hash
      final userKeyBytes = sha256.convert(utf8.encode(userKey)).bytes;
      final key = encrypt.Key(Uint8List.fromList(userKeyBytes));

      // Decode base64 combined data
      final combined = base64.decode(encryptedData);
      
      // Extract IV and encrypted data
      final iv = encrypt.IV.fromBase64(base64IV);
      final encryptedBytes = combined.sublist(16);

      // Decrypt
      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
      final decrypted = encrypter.decrypt(encrypt.Encrypted(encryptedBytes), iv: iv);

      return decrypted;
    } catch (e) {
      // Handle or rethrow the exception as needed
      throw Exception('Decryption failed: $e');
    }

  }

  static void encryptChatDataWithIV({
    required String base64IV,
    required String userKey,
    required List<Map<String, dynamic>> chatData,
  }) {
    final iv = encrypt.IV.fromBase64(base64IV);
    encryptChatData(iv: iv, userKey: userKey, chatData: chatData);
  }


  static String encryptChatDataGenerateIV({
    required String userKey,
    required List<Map<String, dynamic>> chatData,
  }) {

    // Define an initialization vector (IV)
    final iv = encrypt.IV.fromLength(16);
    final base64IV = iv.base64;

    encryptChatData(iv: iv, userKey: userKey, chatData: chatData);
    return base64IV;
  }

   static void encryptChatData({
    required encrypt.IV iv,
    required String userKey,
    required List<Map<String, dynamic>> chatData,
  }) {

    for (var entry in chatData) {
      // Encrypt content
      if (entry['content'] != null) {
        final encryptedContent = CryptoUtils.encryptString(
          iv: iv,
          userKey: userKey,
          data: entry['content'],
        );
        entry['content'] = encryptedContent;
      }

      // Encrypt images if they exist
      if (entry['images'] != null && entry['images'] is List) {
        entry['images'] = (entry['images'] as List).map((image) {
          if (image is String) {
            final encryptedImage = CryptoUtils.encryptString(
              iv: iv,
              userKey: userKey,
              data: image,
            );
            return encryptedImage;
          } else {
            if (kDebugMode) { print('Warning: Non-string image data encountered');   }
            return null;
          }
        }).whereType<String>().toList();
      }
    }

  }

  static void decryptChatData({
    required String base64IV,
    required String userKey,
    required List<Map<String, dynamic>> chatData,
  }) {

    for (var entry in chatData) {
      // Decrypt content
      if (entry['content'] != null) {
        final decryptedContent = CryptoUtils.decryptString(
          base64IV: base64IV,
          userKey: userKey,
          encryptedData: entry['content']!,
        );
        entry['content'] = decryptedContent;
      }

    // Decrypt images if they exist
    if (entry['images'] != null && entry['images'] is List) {
      entry['images'] = (entry['images'] as List).map((encryptedImage) {
        if (encryptedImage is String) {
          try {
            final decryptedImage = CryptoUtils.decryptString(
              base64IV: base64IV,
              userKey: userKey,
              encryptedData: encryptedImage,
            );
            return decryptedImage;
          } catch (e) {
            if (kDebugMode) { print('Error decrypting image: $e'); }
            return null;
          }
        } else {
          if (kDebugMode) { print('Warning: Non-string encrypted image data encountered'); }
          return null;
        }
      }).whereType<String>().toList();
    }
    }
  }

  static void decryptToChatData({
    required String base64IV,
    required String userKey,
    required dynamic jsonData,
    required List<Map<String, dynamic>> chatData,
  }) {

    final List<Map<String, dynamic>> encryptedData = List<Map<String, dynamic>>.from(jsonDecode(jsonData));

    if(encryptedData.isEmpty) { return; }

    chatData.clear();
    for (var entry in encryptedData) {

      String decryptedContent = '';
      // Decrypt content
      if (entry['content'] != null) {
          decryptedContent = CryptoUtils.decryptString(
          base64IV: base64IV,
          userKey: userKey,
          encryptedData: entry['content']!,
        );
      }

      // Decrypt images if they exist
      List<String> decryptedImages = [];
        if (entry['images'] != null && entry['images'] is List) {
          decryptedImages = (entry['images'] as List).map((encryptedImage) {
            if (encryptedImage is String) {
              try {
                return CryptoUtils.decryptString(
                  base64IV: base64IV,
                  userKey: userKey,
                  encryptedData: encryptedImage,
                );
              } catch (e) {
                if (kDebugMode) {
                  print('Error decrypting image: $e');
                }
                return null; // Return null to filter out failed decryptions
              }
            } else {
              if (kDebugMode) {
                print('Warning: Non-string encrypted image data encountered');
              }
              return null; // Return null for non-string values
            }
          }).whereType<String>().toList(); // Filter out null values
        }

      // Add entry to chat data
      chatData.add( {
        "role": entry['role'] ?? '',
        "content": decryptedContent,
        "images": decryptedImages 
      });

    }
  }

}

