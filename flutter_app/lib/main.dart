import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/api_client.dart';
import 'core/theme_settings.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/auth_repository.dart';
import 'features/auth/login_screen.dart';
import 'features/chat/chat_provider.dart';
import 'features/chat/chat_repository.dart';
import 'features/chat/conversations_screen.dart';
import 'features/chat/socket_service.dart';

void main() {
  // Composition root: the only place where modules are wired together.
  final api = ApiClient();
  final socket = SocketService();
  final theme = ThemeSettings()..load();

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(
          create: (_) => AuthProvider(AuthRepository(api), api)..init()),
      ChangeNotifierProvider(
          create: (_) => ChatProvider(ChatRepository(api), socket)),
      ChangeNotifierProvider.value(value: theme),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = context.watch<ThemeSettings>();
    return MaterialApp(
      title: 'Chat',
      theme: theme.lightTheme,
      darkTheme: theme.darkTheme,
      themeMode: theme.mode,
      home: auth.initializing
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : auth.isLoggedIn
              ? const ConversationsScreen()
              : const LoginScreen(),
    );
  }
}
