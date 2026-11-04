import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_provider.dart';
import '../auth/user.dart';
import 'chat_provider.dart';
import 'chat_screen.dart';
import '../settings/settings_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});
  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    context.read<ChatProvider>().start(
          auth.token!,
          auth.user!.id,
        );
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
            icon: Badge(
              isLabelVisible: chat.notifications.isNotEmpty,
              label: Text('${chat.notifications.length}'),
              child: const Icon(Icons.notifications),
            ),
            onPressed: () async {
              await chat.loadNotifications();
              if (!context.mounted) return;
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            tooltip: 'My profile',
            onPressed: () {
              final user = context.read<AuthProvider>().user;
              if (user != null) {
                Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ProfileScreen(user: user, ownProfile: true)));
              }
            },
          ),
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
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setState) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Search users',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) async {
                    if (value.trim().isEmpty) {
                      setState(() => chat.users = []);
                    } else {
                      await chat.searchUsers(value.trim());
                      setState(() {});
                    }
                  },
                ),
              ),
              Flexible(
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
                  subtitle: Text(_relationshipLabel(item)),
                  trailing: _relationshipAction(
                    item,
                    chat,
                    () => setState(() {}),
                    sheetContext,
                  ),
                  onTap: item.friendStatus == 'accepted' &&
                          !item.blocked &&
                          !item.blockedByUser
                      ? () => Navigator.pop(sheetContext, item)
                      : () {
                          Navigator.push(sheetContext, MaterialPageRoute(
                              builder: (_) => ProfileScreen(user: item)));
                        },
                ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (user == null || !await chat.openConversation(user) || !mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChatScreen()),
    ).then((_) => chat.closeConversation());
  }

  String _relationshipLabel(User user) {
    if (user.blocked) return 'Blocked';
    if (user.blockedByUser) return 'You are blocked';
    switch (user.friendStatus) {
      case 'accepted':
        return user.muted ? 'Muted' : 'Friend';
      case 'incoming':
        return 'Friend request received';
      case 'outgoing':
        return 'Friend request sent';
      default:
        return 'Not a friend';
    }
  }

  Widget? _relationshipAction(User user, ChatProvider chat,
      VoidCallback refresh, BuildContext sheetContext) {
    if (user.blockedByUser) return null;
    if (user.blocked) {
      return TextButton(
        onPressed: () async {
          await chat.setBlocked(user, false);
          refresh();
        },
        child: const Text('Unblock'),
      );
    }
    if (user.friendStatus == 'incoming') {
      return TextButton(
        onPressed: () async {
          await chat.respondFriend(user, true);
          refresh();
        },
        child: const Text('Accept'),
      );
    }
    if (user.friendStatus == 'outgoing') return const Text('Pending');
    if (user.friendStatus != 'accepted') {
      return TextButton(
        onPressed: () async {
          await chat.requestFriend(user);
          refresh();
        },
        child: const Text('Add'),
      );
    }
    return PopupMenuButton<String>(
      onSelected: (action) async {
        if (action == 'mute') await chat.setMuted(user, !user.muted);
        if (action == 'block') await chat.setBlocked(user, true);
        refresh();
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'mute',
          child:
              Text(user.muted ? 'Unmute notifications' : 'Mute notifications'),
        ),
        const PopupMenuItem(value: 'block', child: Text('Block user')),
      ],
    );
  }
}
