import 'dart:io';

import 'package:confichat/file_parser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdfrx/pdfrx.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('imports text from multiple PDF pages and tolerates a blank page', () async {
    final pdfiumPath = Platform.environment['PDFIUM_PATH'] ??
        'build/native_assets/macos/libpdfium.dylib';
    expect(File(pdfiumPath).existsSync(), isTrue,
        reason: 'Build the macOS app first or set PDFIUM_PATH to libpdfium.dylib');
    Pdfrx.pdfiumModulePath = File(pdfiumPath).absolute.path;
    final file = File('test/fixtures/multipage_text.pdf');
    expect(file.existsSync(), isTrue);
    final documents = <String, String>{};

    await FileParser.processPDFDocuments(file: file, outDocuments: documents);

    expect(documents.keys, contains('multipage_text.pdf'));
    expect(documents['multipage_text.pdf'], contains('First page regression text'));
    expect(documents['multipage_text.pdf'], contains('Final page regression text'));
  });
}
