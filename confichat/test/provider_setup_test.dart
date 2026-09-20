import 'package:confichat/app_data.dart';
import 'package:confichat/app_localizations.dart';
import 'package:confichat/region_util.dart';
import 'package:confichat/ui_provider_setup.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('io.confichat/storefront');

  Future<void> setStorefront(WidgetTester tester, String? countryCode) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (call) async {
        expect(call.method, 'countryCode');
        return countryCode;
      },
    );
    await RegionUtil.refreshStorefront();
  }

  Future<void> showDialog(WidgetTester tester, VoidCallback onOpenSettings) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: [AppLocalizations.delegate],
      home: Scaffold(
        body: ProviderSetupDialog(
          appData: AppData.instance,
          onOpenSettings: onOpenSettings,
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('US storefront shows provider links and settings access', (tester) async {
    await setStorefront(tester, 'USA');
    var settingsOpened = false;
    await showDialog(tester, () => settingsOpened = true);

    expect(RegionUtil.canShowProviderLinks, isTrue);
    expect(find.text('OpenAI'), findsOneWidget);
    expect(find.text('Anthropic'), findsOneWidget);
    await tester.tap(find.text('Open Settings'));
    expect(settingsOpened, isTrue);
  });

  testWidgets('non-US storefront keeps settings but hides provider links', (tester) async {
    await setStorefront(tester, 'FRA');
    var settingsOpened = false;
    await showDialog(tester, () => settingsOpened = true);

    expect(RegionUtil.canShowProviderLinks, isFalse);
    expect(find.text('OpenAI'), findsNothing);
    expect(find.text('Anthropic'), findsNothing);
    expect(find.textContaining('Already have an OpenAI or Anthropic API key'), findsOneWidget);
    await tester.tap(find.text('Open Settings'));
    expect(settingsOpened, isTrue);
  });

  testWidgets('unavailable storefront fails closed without blocking settings', (tester) async {
    await setStorefront(tester, null);
    await showDialog(tester, () {});

    expect(RegionUtil.canShowProviderLinks, isFalse);
    expect(find.text('OpenAI'), findsNothing);
    expect(find.text('Open Settings'), findsOneWidget);
  });

  testWidgets('storefront lookup failure clears a previous US result', (tester) async {
    await setStorefront(tester, 'USA');
    expect(RegionUtil.canShowProviderLinks, isTrue);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (call) async => throw PlatformException(code: 'storefront_unavailable'),
    );

    await RegionUtil.refreshStorefront();
    await showDialog(tester, () {});

    expect(RegionUtil.canShowProviderLinks, isFalse);
    expect(find.text('OpenAI'), findsNothing);
    expect(find.text('Open Settings'), findsOneWidget);
  });
}
