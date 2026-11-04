import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_provider.dart';
import '../chat/chat_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    context.read<ChatProvider>().stop();
    await context.read<AuthProvider>().logout();
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Text(
                  user?.username.isNotEmpty == true
                      ? user!.username[0].toUpperCase()
                      : '?',
                ),
              ),
              title: Text(user?.username ?? 'Account'),
              subtitle: const Text('Signed-in account'),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Account',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Log out'),
              onTap: () => _logout(context),
            ),
          ),
        ],
      ),
    );
  }
}
