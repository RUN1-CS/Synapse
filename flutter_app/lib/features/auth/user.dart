import '../../core/config.dart';

class User {
  final int id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  User({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
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
      };
}
