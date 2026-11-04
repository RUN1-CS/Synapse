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

  ChatProvider(this._repo, this._socket) {
    _sub = _socket.messages.listen(_onMessage);
  }

  List<User> users = [];
  User? currentUser;
  Conversation? current;
  List<Message> messages = [];
  String? error;

  Future<void> start(String token) async {
    _socket.connect(token);
    await loadUsers();
  }

  void stop() {
    _socket.disconnect();
    users = [];
    currentUser = null;
    current = null;
    messages = [];
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

  Future<bool> openConversation(User user) async {
    try {
      currentUser = user;
      messages = [];
      current = await _repo.conversationFor(user);
      _socket.joinConversation(current!.id);
      notifyListeners();
      final history = await _repo.messages(current!.id);
      final known = history.map((m) => m.id).toSet();
      messages = [...history, ...messages.where((m) => !known.contains(m.id))];
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
    if (m.conversationId != current?.id || messages.any((x) => x.id == m.id))
      return;
    messages = [...messages, m];
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
