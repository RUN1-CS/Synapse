import '../../core/config.dart';

class User {
  final int id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final String friendStatus;
  final bool muted;
  final bool blocked;
  final bool blockedByUser;
  User({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.friendStatus = 'none',
    this.muted = false,
    this.blocked = false,
    this.blockedByUser = false,
  });

  factory User.fromJson(Map<String, dynamic> j) => User(
        id: j['id'] is int
            ? j['id']
            : int.tryParse(j['id']?.toString() ?? '') ?? 0,
        username: j['username']?.toString() ?? '',
        displayName: j['displayName']?.toString() ??
            j['display_name']?.toString() ??
            j['username']?.toString() ??
            '',
        avatarUrl: _absoluteUrl(j['avatarUrl'] ?? j['avatar_url']),
        friendStatus: j['friendStatus']?.toString() ?? 'none',
        muted: j['muted'] == true,
        blocked: j['blocked'] == true,
        blockedByUser: j['blockedByUser'] == true,
      );

  static String? _absoluteUrl(dynamic value) {
    final path = value?.toString();
    if (path == null || path.isEmpty) return null;
    return path.startsWith('http') ? path : '${Config.baseUrl}$path';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'displayName': displayName,
        'avatarUrl': avatarUrl,
        'friendStatus': friendStatus,
      };
}
