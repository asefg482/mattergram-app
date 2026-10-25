import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'package:mattergram/main.dart';
import 'package:mattergram/providers/auth_provider.dart';
import 'package:mattergram/providers/chat_provider.dart';
import 'package:mattergram/providers/ui_provider.dart';
import 'package:mattergram/providers/users_provider.dart';
import 'package:mattergram/services/storage_service.dart';
import 'package:mattergram/utils/themes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Themes preset contains classic-dark', () {
    final theme = getThemeById('classic-dark');
    expect(theme.name, 'Telegram Dark');
    expect(theme.isDark, isTrue);
    expect(themePresets.length, greaterThanOrEqualTo(7));
  });

  testWidgets('App renders login screen when unauthenticated', (WidgetTester tester) async {
    final storage = await StorageService.getInstance();
    final uiProvider = UiProvider();
    uiProvider.init(storage);

    final usersProvider = UsersProvider();
    final authProvider = AuthProvider();
    authProvider.updateDependencies(usersProvider);

    final chatProvider = ChatProvider();
    chatProvider.updateDependencies(authProvider, usersProvider);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<UiProvider>.value(value: uiProvider),
          ChangeNotifierProvider<UsersProvider>.value(value: usersProvider),
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<ChatProvider>.value(value: chatProvider),
        ],
        child: const MattergramApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Login Screen components
    expect(find.text('LOG IN'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2)); // username & password
  });
}
