import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../core/config.dart';
import 'models.dart';

/// Owns the websocket. Knows nothing about UI or state management.
class SocketService {
  io.Socket? _socket;
  final _controller = StreamController<Message>.broadcast();
  final _notificationController = StreamController<Message>.broadcast();
  final _statusController = StreamController<MessageStatus>.broadcast();
  final _connectedController = StreamController<void>.broadcast();
  final Map<String, Map<String, dynamic>> _pendingMessages = {};

  Stream<Message> get messages => _controller.stream;
  Stream<Message> get notifications => _notificationController.stream;
  Stream<MessageStatus> get statuses => _statusController.stream;
  Stream<void> get connected => _connectedController.stream;

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
    _socket!.on('connect', (_) {
      _connectedController.add(null);
      for (final payload in _pendingMessages.values) {
        _socket?.emitWithAck('send_message', payload, ack: (response) {
          if (response is Map && response['ok'] == true) {
            _pendingMessages.remove(payload['clientMessageId']);
          }
        });
      }
    });
    void handleMessage(dynamic data) {
      try {
        final message = Message.fromJson(Map<String, dynamic>.from(data));
        _controller.add(message);
        _socket?.emit('message:delivered', {'messageId': message.id});
      } on FormatException catch (e) {
        debugPrint('Ignoring malformed message event: $e');
      }
    }

    _socket!.on('message:created', handleMessage);
    _socket!.on('message_notification', (data) {
      try {
        final message = Message.fromJson(Map<String, dynamic>.from(data));
        _notificationController.add(message);
        _socket?.emit('message:delivered', {'messageId': message.id});
      } on FormatException catch (e) {
        debugPrint('Ignoring malformed notification event: $e');
      }
    });
    for (final event in ['message:delivered', 'message:read']) {
      _socket!.on(event, (data) {
        try {
          _statusController
              .add(MessageStatus.fromJson(Map<String, dynamic>.from(data)));
        } on FormatException catch (e) {
          debugPrint('Ignoring malformed status event: $e');
        }
      });
    }
    _socket!.connect();
  }

  void joinConversation(int id) => _socket?.emit('join_conversation', id);
  void leaveConversation(int id) => _socket?.emit('leave_conversation', id);
  String send(int conversationId, String content) {
    final random = Random.secure();
    String hex(int value) => value.toRadixString(16).padLeft(8, '0');
    final clientMessageId = '${hex(random.nextInt(1 << 32))}-'
        '${hex(random.nextInt(1 << 32))}-4${hex(random.nextInt(1 << 28))}-'
        '${(8 + random.nextInt(4)).toRadixString(16)}${hex(random.nextInt(1 << 28))}-'
        '${hex(random.nextInt(1 << 32))}${hex(random.nextInt(1 << 32))}';
    final payload = {
      'conversationId': conversationId,
      'content': content,
      'clientMessageId': clientMessageId,
    };
    _pendingMessages[clientMessageId] = payload;
    _socket?.emitWithAck('send_message', payload, ack: (response) {
      if (response is Map && response['ok'] == true) {
        _pendingMessages.remove(clientMessageId);
      }
    });
    return clientMessageId;
  }

  void markRead(int conversationId, int messageId) =>
      _socket?.emit('message:read', {
        'conversationId': conversationId,
        'messageId': messageId,
      });

  void markDelivered(int messageId) =>
      _socket?.emit('message:delivered', {'messageId': messageId});

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }

  void dispose() {
    _controller.close();
    _notificationController.close();
    _statusController.close();
    _connectedController.close();
  }
}
