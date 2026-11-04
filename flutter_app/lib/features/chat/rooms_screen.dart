import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_provider.dart';
import 'chat_provider.dart';
import 'chat_screen.dart';

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key});
  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  @override
  void initState() {
    super.initState();
    final token = context.read<AuthProvider>().token!;
    context.read<ChatProvider>().start(token);
  }

  Future<void> _newRoom() async {
    final c = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New room'),
        content: TextField(controller: c, autofocus: true, decoration: const InputDecoration(labelText: 'Name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, c.text), child: const Text('Create')),
        ],
      ),
    );
    if (name != null && mounted) context.read<ChatProvider>().createRoom(name);
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text('Rooms · ${context.read<AuthProvider>().user?.username ?? ''}'),
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
      floatingActionButton: FloatingActionButton(onPressed: _newRoom, child: const Icon(Icons.add)),
      body: Column(
        children: [
          if (chat.error != null) Padding(padding: const EdgeInsets.all(8), child: Text(chat.error!)),
          Expanded(
            child: RefreshIndicator(
              onRefresh: chat.loadRooms,
              child: ListView(
                children: [
                  for (final r in chat.rooms)
                    ListTile(
                      leading: const Icon(Icons.tag),
                      title: Text(r.name),
                      onTap: () {
                        chat.openRoom(r);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen()))
                            .then((_) => chat.closeRoom());
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
