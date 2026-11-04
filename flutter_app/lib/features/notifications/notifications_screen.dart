import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../chat/chat_provider.dart';
import '../profile/profile_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ChatProvider>().loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: RefreshIndicator(
        onRefresh: chat.loadNotifications,
        child: ListView(
          children: [
            if (chat.notifications.isEmpty)
              const ListTile(title: Text('No unread notifications')),
            for (final item in chat.notifications)
              ListTile(
                leading: CircleAvatar(
                  backgroundImage: item.actor.avatarUrl == null
                      ? null
                      : NetworkImage(item.actor.avatarUrl!),
                  child: item.actor.avatarUrl == null
                      ? Text(item.actor.displayName[0].toUpperCase())
                      : null,
                ),
                title: Text(item.type == 'friend_request'
                    ? '${item.actor.displayName} sent you a friend request'
                    : '${item.actor.displayName} sent you a message'),
                onTap: () async {
                  await chat.markNotificationRead(item);
                  if (!context.mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfileScreen(user: item.actor),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
