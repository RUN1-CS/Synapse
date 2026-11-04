import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/api_client.dart';
import '../auth/user.dart';
import 'chat_repository.dart';
import 'models.dart';
import 'socket_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatRepository _repo;
  final SocketService _socket;
  StreamSubscription<Message>? _sub;
  StreamSubscription<Message>? _notificationSub;

  ChatProvider(this._repo, this._socket) {
    _sub = _socket.messages.listen(_onMessage);
    _notificationSub = _socket.notifications.listen(_onNotification);
  }

  List<Conversation> conversations = [];
  final Set<int> unreadConversationIds = {};
  List<User> users = [];
  List<NotificationItem> notifications = [];
  User? currentUser;
  Conversation? current;
  List<Message> messages = [];
  String? error;

  bool isUnread(int conversationId) =>
      unreadConversationIds.contains(conversationId);

  Future<void> start(String token) async {
    _socket.connect(token);
    await Future.wait([loadConversations(), loadNotifications()]);
  }

  void stop() {
    _socket.disconnect();
    users = [];
    conversations = [];
    unreadConversationIds.clear();
    currentUser = null;
    current = null;
    messages = [];
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

  Future<void> markNotificationRead(NotificationItem item) async {
    await _repo.markNotificationRead(item.id);
    notifications.removeWhere((n) => n.id == item.id);
    notifyListeners();
  }

  Future<void> requestFriend(User user) async {
    await _repo.requestFriend(user.id);
    await loadUsers();
  }

  Future<void> respondFriend(User user, bool accept) async {
    await _repo.respondFriend(user.id, accept);
    await loadUsers();
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
      current = await _repo.conversationFor(user);
      unreadConversationIds.remove(current!.id);
      _socket.joinConversation(current!.id);
      notifyListeners();
      final history = await _repo.messages(current!.id);
      final known = history.map((m) => m.id).toSet();
      messages = [...history, ...messages.where((m) => !known.contains(m.id))];
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
  }

  void send(String text) {
    if (current == null || text.trim().isEmpty) return;
    _socket.send(current!.id, text.trim());
  }

  void _onMessage(Message m) {
    _updateConversation(m);
    if (m.conversationId != current?.id || messages.any((x) => x.id == m.id))
      return;
    messages = [...messages, m];
    notifyListeners();
  }

  void _onNotification(Message m) {
    _updateConversation(m);
    if (m.conversationId != current?.id) {
      unreadConversationIds.add(m.conversationId);
      notifyListeners();
    }
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
    _socket.dispose();
    super.dispose();
  }
}
