import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_provider.dart';
import '../auth/user.dart';
import 'chat_provider.dart';
import 'chat_screen.dart';
import '../settings/settings_screen.dart';

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
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
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
              onRefresh: chat.loadConversations,
              child: ListView(
                children: [
                  for (final conversation in chat.conversations)
                    ListTile(
                      tileColor: chat.isUnread(conversation.id)
                          ? Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withValues(alpha: 0.35)
                          : null,
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (chat.isUnread(conversation.id))
                            Container(
                              width: 9,
                              height: 9,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          CircleAvatar(
                            backgroundImage: conversation.avatarUrl == null
                                ? null
                                : NetworkImage(conversation.avatarUrl!),
                            child: conversation.avatarUrl == null
                                ? Text(
                                    conversation.displayName[0].toUpperCase())
                                : null,
                          ),
                        ],
                      ),
                      title: Text(
                        conversation.displayName,
                        style: chat.isUnread(conversation.id)
                            ? const TextStyle(fontWeight: FontWeight.bold)
                            : null,
                      ),
                      subtitle: Text(conversation.latestContent == null
                          ? 'Start a conversation'
                          : '${conversation.latestDisplayName}: ${conversation.latestContent}'),
                      onTap: () async {
                        if (!await chat.openConversation(User(
                            id: conversation.userId,
                            username: conversation.username,
                            displayName: conversation.displayName,
                            avatarUrl: conversation.avatarUrl))) {
                          return;
                        }
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _newConversation(context),
        child: const Icon(Icons.edit),
      ),
    );
  }

  Future<void> _newConversation(BuildContext context) async {
    final chat = context.read<ChatProvider>();
    final user = await showModalBottomSheet<User>(
      context: context,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final item in chat.users)
              ListTile(
                leading: CircleAvatar(
                  backgroundImage: item.avatarUrl == null
                      ? null
                      : NetworkImage(item.avatarUrl!),
                  child: item.avatarUrl == null
                      ? Text(item.displayName[0].toUpperCase())
                      : null,
                ),
                title: Text(item.displayName),
                onTap: () => Navigator.pop(context, item),
              ),
          ],
        ),
      ),
    );
    if (user == null || !await chat.openConversation(user) || !mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChatScreen()),
    ).then((_) => chat.closeConversation());
  }
}
