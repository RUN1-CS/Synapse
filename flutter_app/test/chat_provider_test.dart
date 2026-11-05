import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/core/api_client.dart';
import 'package:chat_app/features/auth/user.dart';
import 'package:chat_app/features/chat/chat_provider.dart';
import 'package:chat_app/features/chat/chat_repository.dart';
import 'package:chat_app/features/chat/models.dart';
import 'package:chat_app/features/chat/socket_service.dart';

class FakeRepository extends ChatRepository {
  FakeRepository() : super(ApiClient());

  final requestedLimits = <int?>[];
  final requestedBefores = <int?>[];

  final conversation = Conversation(
    id: 7,
    userId: 2,
    username: 'bob',
    displayName: 'Bob',
  );

  @override
  Future<List<Conversation>> conversations() async => [conversation];

  @override
  Future<List<NotificationItem>> notifications() async => [];

  @override
  Future<Conversation> conversationFor(User user) async => conversation;

  @override
  Future<void> markConversationNotificationsRead(int conversationId) async {}

  @override
  Future<List<Message>> messages(int conversationId,
      {int? limit, int? before, int? after}) async {
    requestedLimits.add(limit);
    requestedBefores.add(before);
    if (before != null) {
      return [_message(0, 'older', 'sent')];
    }
    if (after != null) {
      return [_message(2, 'recovered', 'sent')];
    }
    return [_message(1, 'existing', 'delivered')];
  }

  Message _message(int id, String content, String status) => Message(
        id: id,
        conversationId: 7,
        userId: 2,
        username: 'bob',
        displayName: 'Bob',
        content: content,
        createdAt: DateTime.utc(2026, 11, 4, 18, id),
        status: status,
      );
}

class FakeSocket extends SocketService {
  final messageController = StreamController<Message>.broadcast();
  final notificationController = StreamController<Message>.broadcast();
  final statusController = StreamController<MessageStatus>.broadcast();
  final connectedController = StreamController<void>.broadcast();
  final sent = <Map<String, dynamic>>[];
  final read = <Map<String, dynamic>>[];

  @override
  Stream<Message> get messages => messageController.stream;
  @override
  Stream<Message> get notifications => notificationController.stream;
  @override
  Stream<MessageStatus> get statuses => statusController.stream;
  @override
  Stream<void> get connected => connectedController.stream;

  @override
  void connect(String token) {}

  @override
  String send(int conversationId, String content) {
    final id = 'client-test-id';
    sent.add({
      'conversationId': conversationId,
      'content': content,
      'clientMessageId': id,
    });
    return id;
  }

  @override
  void markRead(int conversationId, int messageId) {
    read.add({'conversationId': conversationId, 'messageId': messageId});
  }

  @override
  void markDelivered(int messageId) {}

  @override
  void joinConversation(int id) {}

  @override
  void leaveConversation(int id) {}

  @override
  void disconnect() {}

  @override
  void dispose() {
    messageController.close();
    notificationController.close();
    statusController.close();
    connectedController.close();
  }
}

void main() {
  late FakeRepository repository;
  late FakeSocket socket;
  late ChatProvider provider;

  setUp(() async {
    repository = FakeRepository();
    socket = FakeSocket();
    provider = ChatProvider(repository, socket);
    await provider.openConversation(
      User(id: 2, username: 'bob', displayName: 'Bob'),
    );
  });

  tearDown(() {
    provider.dispose();
  });

  test('send creates an optimistic pending message', () {
    provider.selfUserId = 1;
    provider.send('  hello  ');

    expect(provider.messages.last.content, 'hello');
    expect(provider.messages.last.status, 'pending');
    expect(provider.messages.last.clientMessageId, 'client-test-id');
    expect(provider.pendingClientMessageIds, contains('client-test-id'));
    expect(socket.sent.single['content'], 'hello');
  });

  test('persisted websocket event replaces its optimistic message', () async {
    provider.selfUserId = 1;
    provider.send('hello');
    socket.messageController.add(Message(
      id: 99,
      conversationId: 7,
      userId: 1,
      username: 'alice',
      displayName: 'Alice',
      clientMessageId: 'client-test-id',
      content: 'hello',
      createdAt: DateTime.utc(2026, 11, 4, 18),
      status: 'sent',
    ));
    await Future<void>.delayed(Duration.zero);

    expect(provider.messages, hasLength(2));
    expect(provider.messages.last.id, 99);
    expect(provider.messages.last.status, 'sent');
    expect(provider.pendingClientMessageIds, isEmpty);
  });

  test('reconnect synchronization appends messages after the latest ID',
      () async {
    socket.connectedController.add(null);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(provider.messages.map((message) => message.id), [1, 2]);
    expect(socket.read.last, {'conversationId': 7, 'messageId': 2});
  });

  test('older history loads in another ten-message batch', () async {
    provider.hasOlderMessages = true;
    await provider.loadOlderMessages();

    expect(provider.messages.map((message) => message.id), [0, 1]);
    expect(repository.requestedLimits, [10, 10]);
    expect(repository.requestedBefores, [null, 1]);
  });
}
