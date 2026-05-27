import 'package:file_bridge/app.dart';
import 'package:file_bridge/core/storage/config_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
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
