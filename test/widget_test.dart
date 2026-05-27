import 'package:file_bridge/app.dart';
import 'package:file_bridge/core/config/app_config_controller.dart';
import 'package:file_bridge/core/storage/config_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
  });
}
