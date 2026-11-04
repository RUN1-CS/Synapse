import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../auth/auth_provider.dart';
import '../chat/chat_provider.dart';
import '../../core/theme_settings.dart';
import '../profile/profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _displayName;
  late final TextEditingController _bio;
  late final TextEditingController _currentPassword;
  late final TextEditingController _newPassword;
  late final TextEditingController _confirmPassword;
  final Map<String, TextEditingController> _colors = {};

  @override
  void initState() {
    super.initState();
    _displayName = TextEditingController(
        text: context.read<AuthProvider>().user?.displayName ?? '');
    _bio = TextEditingController(
        text: context.read<AuthProvider>().user?.bio ?? '');
    _currentPassword = TextEditingController();
    _newPassword = TextEditingController();
    _confirmPassword = TextEditingController();
    final theme = context.read<ThemeSettings>();
    for (final entry in {
      'primary': theme.primary,
      'secondary': theme.secondary,
      'background': theme.background,
      'surface': theme.surface,
      'error': theme.error,
    }.entries) {
      _colors[entry.key] = TextEditingController(text: _hex(entry.value));
    }
  }

  @override
  void dispose() {
    _displayName.dispose();
    _bio.dispose();
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    for (final controller in _colors.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _hex(Color color) =>
      '#${color.toARGB32().toRadixString(16).padLeft(8, '0')}';

  Future<void> _setColor(String name) async {
    final raw = _colors[name]!.text.trim().replaceFirst('#', '');
    final normalized = raw.length == 6 ? 'ff$raw' : raw;
    final value = int.tryParse(normalized, radix: 16);
    if (value == null || normalized.length != 8) return;
    await context.read<ThemeSettings>().setColor(name, Color(value));
  }

  Future<void> _save() async {
    final auth = context.read<AuthProvider>();
    await auth.updateDisplayName(_displayName.text);
    await auth.updateBio(_bio.text);
    if (!mounted || auth.error != null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated')),
    );
  }

  Future<void> _pickAvatar() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null || !mounted) return;
    final auth = context.read<AuthProvider>();
    await auth.updateAvatar(await file.readAsBytes(), file.name);
  }

  Future<void> _changePassword() async {
    if (_newPassword.text != _confirmPassword.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New passwords do not match')),
      );
      return;
    }
    final auth = context.read<AuthProvider>();
    await auth.changePassword(_currentPassword.text, _newPassword.text);
    if (!mounted || auth.error != null) return;
    _currentPassword.clear();
    _newPassword.clear();
    _confirmPassword.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password changed')),
    );
  }

  Future<void> _logout() async {
    context.read<ChatProvider>().stop();
    await context.read<AuthProvider>().logout();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _showSessions() async {
    final auth = context.read<AuthProvider>();
    var sessions = await auth.sessions();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setState) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(16),
            children: [
              Text('Active sessions',
                  style: Theme.of(context).textTheme.titleLarge),
              for (final session in sessions)
                ListTile(
                  leading: Icon(session.current
                      ? Icons.phone_android
                      : Icons.devices),
                  title: Text(session.current ? 'This device' : 'Other device'),
                  subtitle: Text(
                      '${session.userAgent ?? 'Unknown client'}\nLast active: ${session.lastUsedAt}'),
                  isThreeLine: true,
                  trailing: session.current
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.logout),
                          tooltip: 'Log out device',
                          onPressed: () async {
                            await auth.revokeSession(session.id);
                            sessions = await auth.sessions();
                            setState(() {});
                          },
                        ),
                ),
              OutlinedButton(
                onPressed: () async {
                  Navigator.pop(sheetContext);
                  await auth.logoutAll();
                },
                child: const Text('Log out all devices'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final displayName = user?.displayName ?? '';
    final theme = context.watch<ThemeSettings>();
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
              onTap: user == null
                  ? null
                  : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                ProfileScreen(user: user, ownProfile: true)),
                      ),
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
          const SizedBox(height: 8),
          TextField(
            controller: _bio,
            maxLength: 500,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Bio',
              border: OutlineInputBorder(),
            ),
          ),
          if (auth.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(auth.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          const SizedBox(height: 24),
          const Text('Security', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _showSessions,
            icon: const Icon(Icons.devices),
            label: const Text('Manage active sessions'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _currentPassword,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Current password',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _newPassword,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'New password',
              helperText: 'At least 6 characters',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _confirmPassword,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Confirm new password',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: auth.busy ? null : _changePassword,
            child: const Text('Change password'),
          ),
          const SizedBox(height: 24),
          const Text('Appearance',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text('Light mode'),
                    icon: Icon(Icons.light_mode),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text('Dark mode'),
                    icon: Icon(Icons.dark_mode),
                  ),
                ],
                selected: {theme.mode},
                onSelectionChanged: (values) => theme.setMode(values.first),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: theme.applyLightPreset,
                  child: const Text('Light preset'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: theme.applyDarkPreset,
                  child: const Text('Dark preset'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final entry in {
            'primary': 'Primary',
            'secondary': 'Secondary',
            'background': 'Background',
            'surface': 'Surface',
            'error': 'Error',
          }.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(
                controller: _colors[entry.key],
                onSubmitted: (_) => _setColor(entry.key),
                decoration: InputDecoration(
                  labelText: entry.value,
                  helperText: '#RRGGBB or #AARRGGBB',
                  prefixIcon:
                      Icon(Icons.palette, color: _colorFor(theme, entry.key)),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: () => _setColor(entry.key),
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
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

  Color _colorFor(ThemeSettings theme, String name) {
    switch (name) {
      case 'primary':
        return theme.primary;
      case 'secondary':
        return theme.secondary;
      case 'background':
        return theme.background;
      case 'surface':
        return theme.surface;
      default:
        return theme.error;
    }
  }
}
