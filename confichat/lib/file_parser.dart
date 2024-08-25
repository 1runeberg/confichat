/*
 * Copyright 2024 Rune Berg (http://runeberg.io | https://github.com/1runeberg)
 * Licensed under Apache 2.0 (https://www.apache.org/licenses/LICENSE-2.0)
 * SPDX-License-Identifier: Apache-2.0
 */

import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:pdfrx/pdfrx.dart';


enum ParserFileType {
    image,
    documentText,
    documentBinary,
    code,
    unknown,
  }


class ImageFile {
  final String base64;
  final String ext;

  ImageFile(this.base64, this.ext);
}

class FileParser {

  static const List<String> imageFormats = [
        'jpg', 'jpeg', 'png', 'gif', 'bmp', 'tiff', 'webp', 'svg',
      ];

  static const List<String> documentTextFormats = [
        'txt', 'csv', 'md', 
      ];

  static const List<String> documentBinaryFormats = [
        'pdf'
      ];

  static const List<String> codeFormats = [
        'js', 'jsx', 'ts', 'tsx', 'html', 'css', 'scss', 'json', 
        'xml', 'yml', 'yaml', 'c', 'cpp', 'h', 'hpp', 'java', 'py', 
        'rb', 'php', 'go', 'rs', 'swift', 'kt', 'kts', 'sh', 'bash', 
        'bat', 'ps1', 'sql', 'r', 'pl', 'lua',
      ];

  static ParserFileType getFileType(String filename) {

    final parts = filename.split('.');
    if (parts.length < 2) {
      return ParserFileType.unknown;
    }

    final extension = parts.last.toLowerCase();
    if (imageFormats.contains(extension)) {
      return ParserFileType.image;
    } else if (documentTextFormats.contains(extension)) {
      return ParserFileType.documentText;
    } else if (documentBinaryFormats.contains(extension)) {
      return ParserFileType.documentBinary;
    } else if (codeFormats.contains(extension)) {
      return ParserFileType.code;
    } 
      
    return ParserFileType.unknown;
  }

  static String getImageExtension(String filename){

    final parts = filename.split('.');
    if (parts.length < 2) {
      return '';
    }

    final extension = parts.last.toLowerCase();
    if(imageFormats.contains(extension)){
      if(extension == 'jpg' || extension == 'jpeg' ) {
          return 'jpeg';
      }

      return extension;
    }

    return '';
  }

  static Future<void> processImages({
    required File file,
    required List<ImageFile> outImages,
  }) async {
    List<int> imageBytes = file.readAsBytesSync();
    ImageFile imageFile = ImageFile(base64Encode(imageBytes), getImageExtension(file.path));
    
    if(imageFile.ext.isNotEmpty && imageFile.base64.isNotEmpty){
      outImages.add(imageFile);
    }
  }

  static Future<void> processTextDocuments({
    required File file,
    required Map<String,String> outDocuments,
  }) async {
    String docContent = file.readAsStringSync(encoding: utf8);
    outDocuments[path.basename(file.path)] = docContent;
  }

  static Future<void> processCode({
    required File file,
    required Map<String,String> outCodeFiles,
  }) async {
    String codeContent = file.readAsStringSync(encoding: utf8);
    outCodeFiles[path.basename(file.path)] = codeContent;
  }

  static Future<void> processBinaryDocuments({
    required File file,
    required BuildContext context,
    required Map<String,String> outDocuments,
  }) async {

    try {
      // Process pdf files
      if(file.path.endsWith('.pdf')){ await processPDFDocuments(file: file, outDocuments: outDocuments); }

    } catch (error) {
      if (kDebugMode) { print('Error parsing documents: $error\n');  }
    } 

  }

  static Future<void> processPDFDocuments({
    required File file,
    required Map<String, String> outDocuments,
  }) async {

    final pdf = await PdfDocument.openFile(file.path);

    String docContent = '';
    for (int i = 0; i < pdf.pages.length; i++) {
      final page = pdf.pages[i];
      final text = await page.loadText();
      final String content = text.fullText;
      docContent += content;
    }

    outDocuments[path.basename(file.path)] = docContent;
  }

  static Future<void> processPlatformFiles({
    required List<PlatformFile> files,
    required BuildContext context,
    List<ImageFile>? outImages,
    Map<String, String>? outDocuments,
    Map<String, String>? outCodeFiles,
  }) async {

    // Freeze ui
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const ProcessingDialog(statusMessage: 'Parsing documents...');
      },
    );

    for (var file in files) {
      final extension = file.extension?.toLowerCase();

      if (extension != null) {
        File localFile = File(file.path!);

        // Process images
        if (outImages != null && getFileType(file.name) == ParserFileType.image) {
          await processImages(file: localFile, outImages: outImages);
        }

        // Process text documents
        if (outDocuments != null && getFileType(file.name) == ParserFileType.documentText) {
          await processTextDocuments(file: localFile, outDocuments: outDocuments);
        }

        // Process binary documents
        if (outDocuments != null && getFileType(file.name) == ParserFileType.documentBinary) {
          // ignore: use_build_context_synchronously
          await processBinaryDocuments(file: localFile, context: context, outDocuments: outDocuments);
        }

        // Process code
        if (outCodeFiles != null && getFileType(file.name) == ParserFileType.code) {
          await processCode(file: localFile, outCodeFiles: outCodeFiles);
        }
      }
    }
  
    // ignore: use_build_context_synchronously
    Navigator.of(context).pop();
  }

  static Future<void> processDroppedFiles({
    required DropDoneDetails details,
    required BuildContext context,
    List<ImageFile>? outImages,
    Map<String,String>? outDocuments,
    Map<String,String>? outCodeFiles,
  }) async {
    // Freeze ui
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const ProcessingDialog(statusMessage: 'Parsing documents...');
      },
    );

    for (final file in details.files) {
      File localFile = File(file.path);

      // Process images
      if (outImages != null && getFileType(file.name) == ParserFileType.image) {
        await processImages(file: localFile, outImages: outImages);
      }

      // Process text documents
      if (outDocuments != null && getFileType(file.name) == ParserFileType.documentText) {
        await processTextDocuments(file: localFile, outDocuments: outDocuments);
      }

      // Process binary documents
      if (outDocuments != null && getFileType(file.name) == ParserFileType.documentBinary) {
        // ignore: use_build_context_synchronously
        await processBinaryDocuments(file: localFile, context: context, outDocuments: outDocuments);
      }

      // Process code
      if (outCodeFiles != null && getFileType(file.name) == ParserFileType.code) {
        await processCode(file: localFile, outCodeFiles: outCodeFiles);
      }
    }

    // ignore: use_build_context_synchronously
    Navigator.of(context).pop();

  }

}

class ProcessingDialog extends StatelessWidget {
  final String statusMessage;

  const ProcessingDialog({super.key, required this.statusMessage});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16.0),
            Text(
              'Processing Files',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8.0),
            Text(statusMessage),
          ],
        ),
      ),
    );
  }
}

