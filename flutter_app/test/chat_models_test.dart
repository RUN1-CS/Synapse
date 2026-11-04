import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/features/chat/models.dart';

void main() {
  test('Message parses nullable fields and numeric string IDs', () {
    final message = Message.fromJson({
      'id': '42',
      'conversationId': '7',
      'userId': 3,
      'username': 'alice',
      'displayName': 'Alice',
      'content': 'hello',
      'createdAt': '2026-11-04T18:00:00Z',
      'status': 'delivered',
    });

    expect(message.id, 42);
    expect(message.conversationId, 7);
    expect(message.userId, 3);
    expect(message.clientMessageId, isNull);
    expect(message.status, 'delivered');
    expect(message.createdAt.toUtc().year, 2026);
  });

  test('MessageStatus defaults missing status to sent', () {
    final status = MessageStatus.fromJson({
      'messageId': '42',
      'conversationId': '7',
    });

    expect(status.messageId, 42);
    expect(status.conversationId, 7);
    expect(status.status, 'sent');
  });
}
