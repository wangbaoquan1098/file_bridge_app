import 'package:file_bridge/app.dart';
import 'package:file_bridge/core/config/app_config_controller.dart';
import 'package:file_bridge/core/storage/config_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('normalizes server url to origin only', () {
    expect(
      normalizeServerUrl('39.101.139.208:8787/api/health'),
      'http://39.101.139.208:8787',
    );
    expect(
      normalizeServerUrl('http://39.101.139.208:8787/api/health'),
      'http://39.101.139.208:8787',
    );
    expect(
      normalizeServerUrl('http://39.101.139.208:8787/'),
      'http://39.101.139.208:8787',
    );
  });

  testWidgets('shows settings page when config is missing', (tester) async {
    PackageInfo.setMockInitialValues(
      appName: 'FileBridge',
      packageName: 'com.zyjzbd.filebridge',
      version: '1.2.3',
      buildNumber: '9',
      buildSignature: '',
      installerStore: null,
    );
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: const FileBridgeApp(),
      ),
    );

    await tester.pump();

    expect(find.text('设置 FileBridge'), findsOneWidget);
    expect(find.text('服务器地址'), findsOneWidget);
    expect(find.text('版本 1.2.3'), findsOneWidget);
  });

  testWidgets('uses persisted dark mode preference', (tester) async {
    PackageInfo.setMockInitialValues(
      appName: 'FileBridge',
      packageName: 'com.zyjzbd.filebridge',
      version: '1.2.3',
      buildNumber: '9',
      buildSignature: '',
      installerStore: null,
    );
    SharedPreferences.setMockInitialValues({'darkModeEnabled': true});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: const FileBridgeApp(),
      ),
    );

    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
    expect(find.text('深色模式'), findsOneWidget);
  });
}
