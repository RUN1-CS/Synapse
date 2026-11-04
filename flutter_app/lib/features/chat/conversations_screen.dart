import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_provider.dart';
import 'chat_provider.dart';
import 'chat_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});
  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ChatProvider>().start(context.read<AuthProvider>().token!);
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Messages · ${context.read<AuthProvider>().user?.username ?? ''}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<ChatProvider>().stop();
              context.read<AuthProvider>().logout();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (chat.error != null)
            Padding(padding: const EdgeInsets.all(8), child: Text(chat.error!)),
          Expanded(
            child: RefreshIndicator(
              onRefresh: chat.loadUsers,
              child: ListView(
                children: [
                  for (final user in chat.users)
                    ListTile(
                      leading: CircleAvatar(
                          child: Text(user.username[0].toUpperCase())),
                      title: Text(user.username),
                      subtitle: const Text('Direct message'),
                      onTap: () async {
                        if (!await chat.openConversation(user)) return;
                        if (!context.mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ChatScreen()),
                        ).then((_) => chat.closeConversation());
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
