DateTime _parseDate(dynamic value) {
  if (value is DateTime) return value.toLocal();
  final parsed = DateTime.tryParse(value?.toString() ?? '');
  return parsed?.toLocal() ?? DateTime.now();
}

int _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

class Conversation {
  final int id;
  final int userId;
  final String username;
  final String? latestContent;
  final int? latestUserId;
  final String? latestUsername;
  final DateTime? latestCreatedAt;

  Conversation({
    required this.id,
    required this.userId,
    required this.username,
    this.latestContent,
    this.latestUserId,
    this.latestUsername,
    this.latestCreatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> j) => Conversation(
        id: _parseInt(j['id']),
        userId: _parseInt(j['userId']),
        username: '${j['username']}',
        latestContent: j['latestContent'],
        latestUserId:
            j['latestUserId'] == null ? null : _parseInt(j['latestUserId']),
        latestUsername: j['latestUsername']?.toString(),
        latestCreatedAt: j['latestCreatedAt'] == null
            ? null
            : _parseDate(j['latestCreatedAt']),
      );
}

class Message {
  final int id;
  final int conversationId;
  final int userId;
  final String username;
  final String content;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.conversationId,
    required this.userId,
    required this.username,
    required this.content,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> j) => Message(
        id: _parseInt(j['id']), // BIGSERIAL arrives as a string
        conversationId: _parseInt(j['conversationId']),
        userId: _parseInt(j['userId']),
        username: '${j['username']}',
        content: '${j['content']}',
        createdAt: _parseDate(j['createdAt']),
      );
}
