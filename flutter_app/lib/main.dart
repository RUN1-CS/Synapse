import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/api_client.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/auth_repository.dart';
import 'features/auth/login_screen.dart';
import 'features/chat/chat_provider.dart';
import 'features/chat/chat_repository.dart';
import 'features/chat/rooms_screen.dart';
import 'features/chat/socket_service.dart';

void main() {
  // Composition root: the only place where modules are wired together.
  final api = ApiClient();
  final socket = SocketService();

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider(AuthRepository(api), api)..init()),
      ChangeNotifierProvider(create: (_) => ChatProvider(ChatRepository(api), socket)),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return MaterialApp(
      title: 'Chat',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: auth.initializing
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : auth.isLoggedIn
              ? const RoomsScreen()
              : const LoginScreen(),
    );
  }
}
