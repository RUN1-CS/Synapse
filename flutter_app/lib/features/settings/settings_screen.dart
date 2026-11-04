import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../auth/auth_provider.dart';
import '../chat/chat_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _displayName;

  @override
  void initState() {
    super.initState();
    _displayName = TextEditingController(
        text: context.read<AuthProvider>().user?.displayName ?? '');
  }

  @override
  void dispose() {
    _displayName.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final auth = context.read<AuthProvider>();
    await auth.updateDisplayName(_displayName.text);
    if (!mounted || auth.error != null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Display name updated')),
    );
  }

  Future<void> _pickAvatar() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null || !mounted) return;
    final auth = context.read<AuthProvider>();
    await auth.updateAvatar(await file.readAsBytes(), file.name);
  }

  Future<void> _logout() async {
    context.read<ChatProvider>().stop();
    await context.read<AuthProvider>().logout();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final displayName = user?.displayName ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: user?.avatarUrl == null
                    ? null
                    : NetworkImage(user!.avatarUrl!),
                child: user?.avatarUrl == null
                    ? Text(displayName.isNotEmpty
                        ? displayName[0].toUpperCase()
                        : '?')
                    : null,
              ),
              title: Text(displayName.isEmpty ? 'Account' : displayName),
              subtitle: Text('@${user?.username ?? ''}'),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Profile picture'),
              subtitle: const Text('Choose an image others will see.'),
              onTap: auth.busy ? null : _pickAvatar,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _displayName,
            maxLength: 64,
            decoration: const InputDecoration(
              labelText: 'Display name',
              helperText: 'This is the name other people see.',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: auth.busy ? null : _save,
            child: const Text('Save display name'),
          ),
          if (auth.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(auth.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          const SizedBox(height: 24),
          const Text('Account', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Log out'),
              onTap: _logout,
            ),
          ),
        ],
      ),
    );
  }
}
