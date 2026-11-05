import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/api_client.dart';
import '../auth/user.dart';
import 'chat_repository.dart';
import 'models.dart';
import 'socket_service.dart';

class ChatProvider extends ChangeNotifier {
  static const messageBatchSize = 30;
  final ChatRepository _repo;
  final SocketService _socket;
  StreamSubscription<Message>? _sub;
  StreamSubscription<Message>? _notificationSub;
  StreamSubscription<MessageStatus>? _statusSub;
  StreamSubscription<void>? _connectedSub;

  ChatProvider(this._repo, this._socket) {
    _sub = _socket.messages.listen(_onMessage);
    _notificationSub = _socket.notifications.listen(_onNotification);
    _statusSub = _socket.statuses.listen(_onStatus);
    _connectedSub = _socket.connected.listen((_) => _syncCurrent());
  }

  List<Conversation> conversations = [];
  final Set<int> unreadConversationIds = {};
  List<User> users = [];
  List<NotificationItem> notifications = [];
  User? currentUser;
  Conversation? current;
  List<Message> messages = [];
  final Set<String> pendingClientMessageIds = {};
  String? error;
  int? selfUserId;
  bool loadingOlderMessages = false;
  bool hasOlderMessages = true;

  bool isUnread(int conversationId) =>
      unreadConversationIds.contains(conversationId);

  Future<void> start(String token, int userId) async {
    selfUserId = userId;
    _socket.connect(token);
    await Future.wait([loadConversations(), loadNotifications()]);
  }

  void stop() {
    _socket.disconnect();
    users = [];
    conversations = [];
    unreadConversationIds.clear();
    currentUser = null;
    selfUserId = null;
    current = null;
    messages = [];
    pendingClientMessageIds.clear();
  }

  Future<void> loadConversations() async {
    try {
      conversations = await _repo.conversations();
      error = null;
    } on ApiException catch (e) {
      error = e.message;
    }
    notifyListeners();
  }

  Future<void> loadUsers() async {
    try {
      users = await _repo.users();
      error = null;
    } on ApiException catch (e) {
      error = e.message;
    }

    notifyListeners();
  }

  Future<void> searchUsers(String search) async {
    try {
      users = await _repo.searchUsers(search);
      error = null;
    } on ApiException catch (e) {
      error = e.message;
    }
    notifyListeners();
  }

  Future<void> loadNotifications() async {
    try {
      notifications = await _repo.notifications();
      error = null;
    } on ApiException catch (e) {
      error = e.message;
    }
    notifyListeners();
  }

  void updateLocalUser(User user) {
    currentUser = currentUser?.id == user.id ? user : currentUser;
    users = [
      for (final item in users) item.id == user.id ? user : item,
    ];
    conversations = [
      for (final conversation in conversations)
        conversation.userId == user.id
            ? Conversation(
                id: conversation.id,
                userId: conversation.userId,
                username: user.username,
                displayName: user.displayName,
                avatarUrl: user.avatarUrl,
                latestContent: conversation.latestContent,
                latestUserId: conversation.latestUserId,
                latestUsername: conversation.latestUsername,
                latestDisplayName: conversation.latestDisplayName,
                latestCreatedAt: conversation.latestCreatedAt,
              )
            : conversation,
    ];
    messages = [
      for (final message in messages)
        message.userId == user.id
            ? Message(
                id: message.id,
                conversationId: message.conversationId,
                userId: message.userId,
                username: user.username,
                displayName: user.displayName,
                avatarUrl: user.avatarUrl,
                clientMessageId: message.clientMessageId,
                content: message.content,
                createdAt: message.createdAt,
                status: message.status,
              )
            : message,
    ];
    notifyListeners();
  }

  Future<void> markNotificationRead(NotificationItem item) async {
    await _repo.markNotificationRead(item.id);
    notifications.removeWhere((n) => n.id == item.id);
    notifyListeners();
  }

  Future<void> markAllNotificationsRead() async {
    await _repo.markAllNotificationsRead();
    notifications = [];
    notifyListeners();
  }

  Future<void> requestFriend(User user) async {
    await _repo.requestFriend(user.id);
    await Future.wait([loadUsers(), loadNotifications()]);
  }

  Future<void> respondFriend(User user, bool accept) async {
    await _repo.respondFriend(user.id, accept);
    await Future.wait([loadUsers(), loadNotifications()]);
  }

  Future<void> setMuted(User user, bool muted) async {
    await _repo.setMuted(user.id, muted);
    await loadUsers();
  }

  Future<void> setBlocked(User user, bool blocked) async {
    await _repo.setBlocked(user.id, blocked);
    await loadUsers();
  }

  Future<User> loadProfile(int userId) => _repo.profile(userId);

  Future<bool> openConversation(User user) async {
    try {
      currentUser = user;
      messages = [];
      loadingOlderMessages = false;
      hasOlderMessages = true;
      current = await _repo.conversationFor(user);
      unreadConversationIds.remove(current!.id);
      await _repo.markConversationNotificationsRead(current!.id);
      notifications.removeWhere((item) => item.conversationId == current!.id);
      _socket.joinConversation(current!.id);
      notifyListeners();
      final history = await _repo.messages(
        current!.id,
        limit: messageBatchSize,
      );
      hasOlderMessages = history.length == messageBatchSize;
      final known = history.map((m) => m.id).toSet();
      messages = [...history, ...messages.where((m) => !known.contains(m.id))];
      for (final message in history) {
        _socket.markDelivered(message.id);
      }
      if (messages.isNotEmpty) {
        _socket.markRead(current!.id, messages.last.id);
      }
      await loadConversations();
      error = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      current = null;
      currentUser = null;
      error = e.message;
    }
    notifyListeners();
    return false;
  }

  void closeConversation() {
    if (current != null) _socket.leaveConversation(current!.id);
    current = null;
    currentUser = null;
    messages = [];
    loadingOlderMessages = false;
    hasOlderMessages = true;
  }

  Future<void> loadOlderMessages() async {
    if (current == null ||
        messages.isEmpty ||
        loadingOlderMessages ||
        !hasOlderMessages) {
      return;
    }
    loadingOlderMessages = true;
    notifyListeners();
    try {
      final older = await _repo.messages(
        current!.id,
        limit: messageBatchSize,
        before: messages.first.id,
      );
      final known = messages.map((message) => message.id).toSet();
      messages = [
        ...older.where((message) => !known.contains(message.id)),
        ...messages,
      ];
      hasOlderMessages = older.length == messageBatchSize;
    } on ApiException catch (e) {
      error = e.message;
    } finally {
      loadingOlderMessages = false;
      notifyListeners();
    }
  }

  void send(String text) {
    if (current == null || text.trim().isEmpty) return;
    final content = text.trim();
    final clientMessageId = _socket.send(current!.id, content);
    pendingClientMessageIds.add(clientMessageId);
    messages = [
      ...messages,
      Message(
        id: -DateTime.now().microsecondsSinceEpoch,
        conversationId: current!.id,
        userId: selfUserId ?? -1,
        username: '',
        displayName: 'You',
        content: content,
        createdAt: DateTime.now(),
        clientMessageId: clientMessageId,
        status: 'pending',
      ),
    ];
    notifyListeners();
  }

  Future<void> _syncCurrent() async {
    if (current == null) return;
    _socket.joinConversation(current!.id);
    final lastId = messages.isEmpty ? null : messages.last.id;
    final incoming = await _repo.messages(current!.id, after: lastId);
    final known = messages.map((m) => m.id).toSet();
    messages = [
      ...messages,
      ...incoming.where((m) => !known.contains(m.id)),
    ];
    for (final message in incoming) {
      _socket.markDelivered(message.id);
    }
    if (messages.isNotEmpty) _socket.markRead(current!.id, messages.last.id);
    notifyListeners();
  }

  void _onMessage(Message m) {
    _updateConversation(m);
    final optimistic = m.clientMessageId == null
        ? -1
        : messages.indexWhere((x) => x.clientMessageId == m.clientMessageId);
    if (optimistic >= 0) {
      messages[optimistic] = m;
      pendingClientMessageIds.remove(m.clientMessageId);
      notifyListeners();
      return;
    }
    if (m.conversationId != current?.id ||
        messages.any((x) =>
            x.id == m.id ||
            (m.clientMessageId != null &&
                x.clientMessageId == m.clientMessageId))) return;
    messages = [...messages, m];
    if (m.conversationId == current?.id) {
      _socket.markRead(m.conversationId, m.id);
    }
    notifyListeners();
  }

  void _onStatus(MessageStatus status) {
    final index = messages.indexWhere((m) => m.id == status.messageId);
    if (index < 0) return;
    final old = messages[index];
    messages[index] = Message(
      id: old.id,
      conversationId: old.conversationId,
      userId: old.userId,
      username: old.username,
      displayName: old.displayName,
      avatarUrl: old.avatarUrl,
      clientMessageId: old.clientMessageId,
      content: old.content,
      createdAt: old.createdAt,
      status: status.status,
    );
    notifyListeners();
  }

  void _onNotification(Message m) {
    _updateConversation(m);
    if (m.conversationId != current?.id) {
      unreadConversationIds.add(m.conversationId);
    }
    loadNotifications();
  }

  void _updateConversation(Message m) {
    final index = conversations.indexWhere((c) => c.id == m.conversationId);
    if (index >= 0) {
      conversations[index] = Conversation(
        id: conversations[index].id,
        userId: conversations[index].userId,
        username: conversations[index].username,
        displayName: conversations[index].displayName,
        avatarUrl: conversations[index].avatarUrl,
        latestContent: m.content,
        latestUserId: m.userId,
        latestUsername: m.username,
        latestDisplayName: m.displayName,
        latestCreatedAt: m.createdAt,
      );
      conversations.sort((a, b) => (b.latestCreatedAt ?? DateTime(0))
          .compareTo(a.latestCreatedAt ?? DateTime(0)));
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _notificationSub?.cancel();
    _statusSub?.cancel();
    _connectedSub?.cancel();
    _socket.dispose();
    super.dispose();
  }
}
