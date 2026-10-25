import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/ui_provider.dart';
import 'providers/users_provider.dart';
import 'services/api_service.dart';
import 'services/sound_service.dart';
import 'services/storage_service.dart';
import 'views/main_layout.dart';
import 'widgets/auth/login_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage
  final storage = await StorageService.getInstance();

  // Initialize REST API & Sound services
  final api = ApiService();
  await api.init(storage);

  final sound = SoundService();
  await sound.init(storage);

  // Initialize providers
  final uiProvider = UiProvider();
  uiProvider.init(storage);

  final usersProvider = UsersProvider();
  final authProvider = AuthProvider();
  authProvider.updateDependencies(usersProvider);

  final chatProvider = ChatProvider();
  chatProvider.updateDependencies(authProvider, usersProvider);

  // Attempt initial session restore if token is persisted
  await authProvider.initAuth();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<UiProvider>.value(value: uiProvider),
        ChangeNotifierProvider<UsersProvider>.value(value: usersProvider),
        ChangeNotifierProxyProvider<UsersProvider, AuthProvider>(
          create: (_) => authProvider,
          update: (_, users, auth) => (auth ?? authProvider)..updateDependencies(users),
        ),
        ChangeNotifierProxyProvider2<AuthProvider, UsersProvider, ChatProvider>(
          create: (_) => chatProvider,
          update: (_, auth, users, chat) => (chat ?? chatProvider)..updateDependencies(auth, users),
        ),
      ],
      child: const MattergramApp(),
    ),
  );
}

class MattergramApp extends StatelessWidget {
  const MattergramApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ui = context.watch<UiProvider>();
    final theme = ui.currentTheme;
    final isDark = ui.isDarkMode;

    // Apply system overlay style according to theme
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: theme.sidebar,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );

    return MaterialApp(
      title: 'Mattergram',
      debugShowCheckedModeBanner: false,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        scaffoldBackgroundColor: theme.bg,
        colorScheme: ColorScheme.light(
          primary: theme.accent,
          surface: theme.sidebar,
          onSurface: theme.text,
        ),
        dividerColor: theme.border,
        dialogTheme: DialogThemeData(backgroundColor: theme.sidebar),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: theme.bg,
        colorScheme: ColorScheme.dark(
          primary: theme.accent,
          surface: theme.sidebar,
          onSurface: theme.text,
        ),
        dividerColor: theme.border,
        dialogTheme: DialogThemeData(backgroundColor: theme.sidebar),
      ),
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isLoading && !auth.isAuthenticated) {
            return Scaffold(
              backgroundColor: theme.bg,
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1C58D9), Color(0xFF0058CC)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1C58D9).withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.forum_rounded, color: Colors.white, size: 32),
                      ),
                    ),
                    const SizedBox(height: 20),
                    CircularProgressIndicator(color: theme.accent, strokeWidth: 2.5),
                  ],
                ),
              ),
            );
          }

          if (auth.isAuthenticated) {
            return const MainLayout();
          }

          return const LoginView();
        },
      ),
    );
  }
}
