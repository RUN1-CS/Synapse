import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../auth/user.dart';
import '../chat/chat_provider.dart';

class ProfileScreen extends StatefulWidget {
  final User user;
  final bool ownProfile;
  const ProfileScreen({super.key, required this.user, this.ownProfile = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late User _user;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    if (!widget.ownProfile) _refresh();
  }

  Future<void> _refresh() async {
    try {
      final user = await context.read<ChatProvider>().loadProfile(_user.id);
      if (mounted) setState(() => _user = user);
    } on ApiException {
      // Keep the profile passed by the caller if a refresh is unavailable.
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    await action();
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.read<ChatProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundImage:
                  _user.avatarUrl == null ? null : NetworkImage(_user.avatarUrl!),
              child: _user.avatarUrl == null
                  ? Text(
                      _user.displayName.isEmpty
                          ? '?'
                          : _user.displayName[0].toUpperCase(),
                      style: const TextStyle(fontSize: 32),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(_user.displayName,
                style: Theme.of(context).textTheme.headlineSmall),
          ),
          Center(child: Text('@${_user.username}')),
          const SizedBox(height: 24),
          Text(_user.bio.isEmpty ? 'No bio yet.' : _user.bio),
          if (!widget.ownProfile) ...[
            const SizedBox(height: 24),
            Text(_statusLabel),
            const SizedBox(height: 8),
            if (_user.friendStatus == 'none')
              FilledButton(
                onPressed: () => _run(() => chat.requestFriend(_user)),
                child: const Text('Add friend'),
              ),
            if (_user.friendStatus == 'incoming')
              FilledButton(
                onPressed: () => _run(() => chat.respondFriend(_user, true)),
                child: const Text('Accept friend request'),
              ),
            if (_user.friendStatus == 'accepted')
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () =>
                        _run(() => chat.setMuted(_user, !_user.muted)),
                    child: Text(_user.muted ? 'Unmute' : 'Mute'),
                  ),
                  OutlinedButton(
                    onPressed: () =>
                        _run(() => chat.setBlocked(_user, !_user.blocked)),
                    child: Text(_user.blocked ? 'Unblock' : 'Block'),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }

  String get _statusLabel {
    if (_user.blocked) return 'Blocked';
    if (_user.blockedByUser) return 'You are blocked';
    switch (_user.friendStatus) {
      case 'accepted':
        return 'Friend';
      case 'incoming':
        return 'Friend request received';
      case 'outgoing':
        return 'Friend request sent';
      default:
        return 'Not a friend';
    }
  }
}
