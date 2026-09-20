import 'dart:convert';
import 'dart:io';

import 'package:confichat/api_anthropic.dart';
import 'package:confichat/api_gemini.dart';
import 'package:confichat/api_llamacpp.dart';
import 'package:confichat/api_ollama.dart';
import 'package:confichat/api_openai.dart';
import 'package:confichat/app_data.dart';
import 'package:confichat/factories.dart';
import 'package:confichat/interfaces.dart';
import 'package:confichat/provider_validator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  final providers = <AiProvider, LlmApi>{
    AiProvider.ollama: ApiOllama(),
    AiProvider.llamacpp: ApiLlamaCpp(),
    AiProvider.openai: ApiChatGPT(),
    AiProvider.anthropic: ApiAnthropic(),
    AiProvider.gemini: ApiGemini(),
  };

  setUp(() async {
    root = await Directory.systemTemp.createTemp('confichat-provider-test-');
    AppData.instance.rootPath = root.path;
    for (final api in providers.values) {
      api.apiKey = '';
    }
    ApiOllama()
      ..scheme = 'http'
      ..host = 'localhost'
      ..port = 11434
      ..path = '/api';
    ApiLlamaCpp()
      ..scheme = 'http'
      ..host = 'localhost'
      ..port = 8080
      ..path = '/v1';
  });

  tearDown(() async {
    AppData.instance.rootPath = '';
    await root.delete(recursive: true);
  });

  test('factory identifies every provider without changing existing IDs', () {
    for (final entry in providers.entries) {
      expect(LlmApiFactory.create(entry.key.name), same(entry.value));
      expect(entry.value.aiProvider, entry.key);
    }
    expect(AiProvider.values.map((provider) => provider.id), [0, 1, 2, 3, 4]);
  });

  test('providers load only their own saved settings', () async {
    final settingsFile = File(
        '${root.path}/${AppData.appStoragePath}/${AppData.appSettingsFile}');
    await settingsFile.create(recursive: true);
    await settingsFile.writeAsString(jsonEncode({
      'Ollama': {
        'scheme': 'http',
        'host': 'ollama.test',
        'port': 11434,
        'path': '/api'
      },
      'LlamaCpp': {
        'scheme': 'http',
        'host': 'llama.test',
        'port': 8080,
        'path': '/v1',
        'apikey': 'llama-test-key',
      },
      'OpenAI': {'apikey': 'openai-test-key'},
      'Anthropic': {'apikey': 'anthropic-test-key'},
      'Gemini': {'apikey': 'gemini-test-key'},
    }));

    for (final api in providers.values) {
      await api.loadSettings();
    }

    expect(ApiOllama().host, 'ollama.test');
    expect(ApiLlamaCpp().host, 'llama.test');
    expect(ApiLlamaCpp().apiKey, 'llama-test-key');
    expect(ApiChatGPT().apiKey, 'openai-test-key');
    expect(ApiAnthropic().apiKey, 'anthropic-test-key');
    expect(ApiGemini().apiKey, 'gemini-test-key');
    expect(ApiChatGPT().getUri('/models').host, 'api.openai.com');
    expect(ApiGemini().getUri('/models').toString(),
        'https://generativelanguage.googleapis.com/v1beta/openai/models');
  });

  test('provider setup detects a configured Gemini key', () async {
    final settingsFile = File(
        '${root.path}/${AppData.appStoragePath}/${AppData.appSettingsFile}');
    await settingsFile.create(recursive: true);
    await settingsFile.writeAsString(jsonEncode({
      'Gemini': {'apikey': 'gemini-test-key'},
    }));

    expect(await ProviderValidator.checkApiKeyConfigured(AppData.instance),
        AiProvider.gemini);
  });

  for (final provider in [
    AiProvider.openai,
    AiProvider.gemini,
    AiProvider.llamacpp
  ]) {
    test('${provider.name} lists models through the OpenAI-compatible endpoint',
        () async {
      final api = providers[provider]!;
      api.apiKey = 'test-key';
      final expectedHost = provider == AiProvider.openai
          ? 'api.openai.com'
          : provider == AiProvider.gemini
              ? 'generativelanguage.googleapis.com'
              : 'llama.test';
      if (provider == AiProvider.llamacpp) api.host = expectedHost;

      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.host, expectedHost);
        expect(
            request.url.path,
            provider == AiProvider.gemini
                ? '/v1beta/openai/models'
                : '/v1/models');
        expect(request.headers['authorization'], 'Bearer test-key');
        return http.Response(
            jsonEncode({
              'data': [
                {'id': 'model-one'},
                {'id': 'model-two'}
              ],
            }),
            200);
      });

      final models = <ModelItem>[];
      await http.runWithClient(() => api.getModels(models), () => client);
      expect(models.map((model) => model.id), ['model-one', 'model-two']);
      expect(models.map((model) => model.name), ['model-one', 'model-two']);
    });
  }

  test('Ollama lists models from its tags endpoint', () async {
    final api = ApiOllama();
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/api/tags');
      return http.Response(
          jsonEncode({
            'models': [
              {'name': 'first'},
              {'name': 'second'}
            ],
          }),
          200);
    });

    final models = <ModelItem>[];
    await http.runWithClient(() => api.getModels(models), () => client);
    expect(models.map((model) => model.id), ['second', 'first']);
  });

  test('Anthropic lists every page with its API headers', () async {
    final api = ApiAnthropic()..apiKey = 'test-key';
    var requests = 0;
    final client = MockClient((request) async {
      requests++;
      expect(request.method, 'GET');
      expect(request.url.toString(),
          startsWith('https://api.anthropic.com/v1/models?'));
      expect(request.url.queryParameters['limit'], '1000');
      expect(request.headers['x-api-key'], 'test-key');
      expect(request.headers['anthropic-version'], ApiAnthropic.version);
      if (requests == 1) {
        expect(request.url.queryParameters['after_id'], isNull);
        return http.Response(
            jsonEncode({
              'data': [
                {'id': 'claude-new'}
              ],
              'has_more': true,
              'last_id': 'claude-new',
            }),
            200);
      }
      expect(request.url.queryParameters['after_id'], 'claude-new');
      return http.Response(
          jsonEncode({
            'data': [
              {'id': 'claude-older'}
            ],
            'has_more': false,
          }),
          200);
    });

    final models = <ModelItem>[];
    await http.runWithClient(() => api.getModels(models), () => client);
    expect(requests, 2);
    expect(models.map((model) => model.id), ['claude-new', 'claude-older']);
  });

  test('Anthropic does not expose a partial list after an API error', () async {
    final api = ApiAnthropic()..apiKey = 'test-key';
    final client = MockClient((request) async {
      if (request.url.queryParameters['after_id'] != null) {
        return http.Response('{"error":"unauthorized"}', 401);
      }
      return http.Response(
          jsonEncode({
            'data': [
              {'id': 'claude-first'}
            ],
            'has_more': true,
            'last_id': 'claude-first',
          }),
          200);
    });

    final models = <ModelItem>[];
    await http.runWithClient(() => api.getModels(models), () => client);
    expect(models, isEmpty);
  });

  test('Anthropic skips model listing without a key', () async {
    final client = MockClient((_) async {
      fail('No request should be made without a key');
    });
    final models = <ModelItem>[];
    await http.runWithClient(
        () => ApiAnthropic().getModels(models), () => client);
    expect(models, isEmpty);
  });
}
