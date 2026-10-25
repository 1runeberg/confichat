import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:confichat/api_ollama.dart';
import 'package:confichat/app_data.dart';
import 'package:confichat/language_config.dart';
import 'package:confichat/locale_provider.dart';
import 'package:confichat/main.dart';
import 'package:confichat/themes.dart';
import 'package:confichat/ui_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('startup keeps the interface usable while the saved server is down',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1024, 1024));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final appData = AppData.instance;
    final root = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('confichat-startup-')))!;
    appData.rootPath = root.path;
    final settings = File(
        '${root.path}/${AppData.appStoragePath}/${AppData.appSettingsFile}');
    await tester.runAsync(() async {
      await settings.create(recursive: true);
      await settings.writeAsString(jsonEncode({
        'app': {'selectedDefaultProvider': 'Ollama', 'selectedLanguage': 'en'},
      }));
    });
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('desktop_window'),
      (_) async => null,
    );
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('io.confichat/storefront'),
      (_) async => null,
    );
    await tester.runAsync(() => LanguageConfig().ensureInitialized());

    final pending = Completer<http.Response>();
    var requests = 0;
    final modelProvider = ModelProvider();
    final selectedModelProvider = SelectedModelProvider();
    final client = MockClient((request) {
      requests++;
      return pending.future;
    });

    try {
      await http.runWithClient(() async {
        await tester.pumpWidget(MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => LocaleProvider()),
            ChangeNotifierProvider.value(value: modelProvider),
            ChangeNotifierProvider.value(value: selectedModelProvider),
          ],
          child: const ConfiChat(),
        ));
        for (var attempt = 0; attempt < 20 && requests == 0; attempt++) {
          await tester.runAsync(() async {
            await Future<void>.delayed(const Duration(milliseconds: 10));
          });
          await tester.pump();
        }

        expect(find.byType(CCAppBar), findsOneWidget);
        expect(find.byIcon(Icons.menu), findsOneWidget);
        expect(requests, greaterThan(0));
        expect(appData.api.aiProvider, AiProvider.ollama);

        final initialRequests = requests;
        await tester.pump(const Duration(seconds: 3));
        expect(requests, initialRequests);

        // Settings remain accessible while the server hasn't responded
        await tester.tap(find.byIcon(Icons.menu));
        await tester.pumpAndSettle();
        expect(tester.state<ScaffoldState>(find.byType(Scaffold).first).isDrawerOpen,
            isTrue);
        expect(tester.takeException(), isNull);

        pending.complete(http.Response(
            '{"models": [{"name": "restored-model"}]}', 200));
        for (var attempt = 0;
            attempt < 20 && selectedModelProvider.selectedModel == null;
            attempt++) {
          await tester.runAsync(() async {
            await Future<void>.delayed(const Duration(milliseconds: 10));
          });
          await tester.pump();
        }
        expect(selectedModelProvider.selectedModel?.name, 'restored-model');
        await tester.pumpAndSettle();
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      }, () => client);
    } finally {
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('desktop_window'), null);
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('io.confichat/storefront'), null);
      modelProvider.dispose();
      selectedModelProvider.dispose();
      appData.rootPath = '';
      ApiOllama().host = 'localhost';
      await tester.runAsync(() => root.delete(recursive: true));
    }
  });
}
