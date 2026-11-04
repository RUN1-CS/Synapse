import '../../core/config.dart';
import '../auth/user.dart';

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

String? _absoluteUrl(dynamic value) {
  final path = value?.toString();
  if (path == null || path.isEmpty) return null;
  return path.startsWith('http') ? path : '${Config.baseUrl}$path';
}

class Conversation {
  final int id;
  final int userId;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final String? latestContent;
  final int? latestUserId;
  final String? latestUsername;
  final String? latestDisplayName;
  final DateTime? latestCreatedAt;

  Conversation({
    required this.id,
    required this.userId,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.latestContent,
    this.latestUserId,
    this.latestUsername,
    this.latestDisplayName,
    this.latestCreatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> j) => Conversation(
        id: _parseInt(j['id']),
        userId: _parseInt(j['userId']),
        username: '${j['username']}',
        displayName: j['displayName']?.toString() ?? '${j['username']}',
        avatarUrl: _absoluteUrl(j['avatarUrl']),
        latestContent: j['latestContent'],
        latestUserId:
            j['latestUserId'] == null ? null : _parseInt(j['latestUserId']),
        latestUsername: j['latestUsername']?.toString(),
        latestDisplayName: j['latestDisplayName']?.toString() ??
            j['latestUsername']?.toString(),
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
  final String displayName;
  final String? avatarUrl;
  final String? clientMessageId;
  final String content;
  final DateTime createdAt;
  final String status;

  Message({
    required this.id,
    required this.conversationId,
    required this.userId,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.clientMessageId,
    required this.content,
    required this.createdAt,
    this.status = 'sent',
  });

  factory Message.fromJson(Map<String, dynamic> j) => Message(
        id: _parseInt(j['id']), // BIGSERIAL arrives as a string
        conversationId: _parseInt(j['conversationId']),
        userId: _parseInt(j['userId']),
        username: '${j['username']}',
        displayName: j['displayName']?.toString() ?? '${j['username']}',
        avatarUrl: _absoluteUrl(j['avatarUrl']),
        clientMessageId: j['clientMessageId']?.toString(),
        content: '${j['content']}',
        createdAt: _parseDate(j['createdAt']),
        status: j['status']?.toString() ?? 'sent',
      );
}

class MessageStatus {
  final int messageId;
  final int conversationId;
  final String status;
  MessageStatus({
    required this.messageId,
    required this.conversationId,
    required this.status,
  });
  factory MessageStatus.fromJson(Map<String, dynamic> json) => MessageStatus(
        messageId: _parseInt(json['messageId']),
        conversationId: _parseInt(json['conversationId']),
        status: json['status']?.toString() ?? 'sent',
      );
}

class NotificationItem {
  final int id;
  final String type;
  final User actor;
  final int? friendRequestId;
  NotificationItem({
    required this.id,
    required this.type,
    required this.actor,
    this.friendRequestId,
  });
  factory NotificationItem.fromJson(Map<String, dynamic> j) => NotificationItem(
        id: _parseInt(j['id']),
        type: '${j['type']}',
        actor: User.fromJson(j..['id'] = j['actorId']),
        friendRequestId: j['friendRequestId'] == null
            ? null
            : _parseInt(j['friendRequestId']),
      );
}
