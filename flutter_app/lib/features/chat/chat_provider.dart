import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/api_client.dart';
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

  List<Room> rooms = [];
  Room? current;
  List<Message> messages = [];
  String? error;

  Future<void> start(String token) async {
    _socket.connect(token);
    await loadRooms();
  }

  void stop() {
    _socket.disconnect();
    rooms = [];
    current = null;
    messages = [];
  }

  Future<void> loadRooms() async {
    try {
      rooms = await _repo.rooms();
      error = null;
    } on ApiException catch (e) {
      error = e.message;
    }
    notifyListeners();
  }

  Future<void> createRoom(String name) async {
    try {
      await _repo.createRoom(name);
      await loadRooms();
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
    }
  }

  Future<void> openRoom(Room room) async {
    current = room;
    messages = [];
    _socket.joinRoom(room.id); // join first so nothing is missed while history loads
    notifyListeners();
    final history = await _repo.messages(room.id);
    final known = history.map((m) => m.id).toSet();
    messages = [...history, ...messages.where((m) => !known.contains(m.id))];
    notifyListeners();
  }

  void closeRoom() {
    if (current != null) _socket.leaveRoom(current!.id);
    current = null;
    messages = [];
  }

  void send(String text) {
    if (current == null || text.trim().isEmpty) return;
    _socket.send(current!.id, text.trim());
  }

  void _onMessage(Message m) {
    if (m.roomId != current?.id || messages.any((x) => x.id == m.id)) return;
    messages = [...messages, m];
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
