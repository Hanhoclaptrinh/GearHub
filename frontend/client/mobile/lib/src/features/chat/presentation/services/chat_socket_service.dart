import 'package:mobile/src/core/constants/api_constant.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class ChatSocketService {
  io.Socket? _socket;
  String? _token;

  bool get isConnected => _socket?.connected ?? false;

  void connect(String token) {
    if (_socket != null && _token == token) {
      if (!(_socket?.connected ?? false)) {
        _socket?.connect();
      }
      return;
    }

    disconnect();
    _token = token;
    _socket = io.io(
      '${ApiConstant.baseUrl}/chat',
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .enableReconnection()
          .setReconnectionAttempts(20)
          .setReconnectionDelay(800)
          .build(),
    );
    _socket?.connect();
  }

  void joinRoom(String roomId) {
    _socket?.emit('room:join', {'roomId': roomId});
  }

  void sendMessage({
    required String roomId,
    required String content,
    required String clientMessageId,
  }) {
    _socket?.emit('message:send', {
      'roomId': roomId,
      'content': content,
      'clientMessageId': clientMessageId,
    });
  }

  void markRead(String roomId) {
    _socket?.emit('messages:read', {'roomId': roomId});
  }

  void typingStart(String roomId) {
    _socket?.emit('typing:start', {'roomId': roomId});
  }

  void typingStop(String roomId) {
    _socket?.emit('typing:stop', {'roomId': roomId});
  }

  void on(String event, void Function(dynamic data) handler) {
    _socket?.off(event);
    _socket?.on(event, handler);
  }

  void off(String event) {
    _socket?.off(event);
  }

  void clearChatListeners() {
    for (final event in [
      'connect',
      'reconnect',
      'message:new',
      'message:chunk',
      'room:updated',
      'typing:start',
      'typing:stop',
      'messages:read',
      'room:closed',
      'exception',
    ]) {
      _socket?.off(event);
    }
  }

  void disconnect() {
    clearChatListeners();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _token = null;
  }
}
