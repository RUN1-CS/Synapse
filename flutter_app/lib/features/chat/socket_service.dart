import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../core/config.dart';
import 'models.dart';

/// Owns the websocket. Knows nothing about UI or state management.
class SocketService {
  io.Socket? _socket;
  final _controller = StreamController<Message>.broadcast();
  final _notificationController = StreamController<Message>.broadcast();

  Stream<Message> get messages => _controller.stream;
  Stream<Message> get notifications => _notificationController.stream;

  void connect(String token) {
    disconnect();
    _socket = io.io(
      Config.baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .build(),
    );
    _socket!.on('new_message', (data) {
      try {
        _controller.add(Message.fromJson(Map<String, dynamic>.from(data)));
      } on FormatException catch (e) {
        debugPrint('Ignoring malformed message event: $e');
      }
    });
    _socket!.on('message_notification', (data) {
      try {
        _notificationController
            .add(Message.fromJson(Map<String, dynamic>.from(data)));
      } on FormatException catch (e) {
        debugPrint('Ignoring malformed notification event: $e');
      }
    });
    _socket!.connect();
  }

  void joinConversation(int id) => _socket?.emit('join_conversation', id);
  void leaveConversation(int id) => _socket?.emit('leave_conversation', id);
  void send(int conversationId, String content) => _socket?.emit(
      'send_message', {'conversationId': conversationId, 'content': content});

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }

  void dispose() {
    _controller.close();
    _notificationController.close();
  }
}
