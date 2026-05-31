import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as ws_status;

import 'network_config.dart';

enum ConnectionStatus { disconnected, connecting, connected, failed }

/// Modular WebSocket transport. The gameplay/sync layer talks to this through
/// [messages] and [send]; it knows nothing about the underlying socket, which
/// makes it easy to swap in [FakeWebSocketClient] for offline development.
abstract class GameSocket {
  ConnectionStatus get status;
  Stream<Map<String, dynamic>> get messages;
  Stream<ConnectionStatus> get statusStream;

  Future<void> connect();
  void send(Map<String, dynamic> message);
  Future<void> close();
}

class WebSocketClient implements GameSocket {
  final String url;
  WebSocketChannel? _channel;

  final _messages = StreamController<Map<String, dynamic>>.broadcast();
  final _statusCtrl = StreamController<ConnectionStatus>.broadcast();
  ConnectionStatus _status = ConnectionStatus.disconnected;

  WebSocketClient({String? url}) : url = url ?? NetworkConfig.defaultUrl;

  @override
  ConnectionStatus get status => _status;
  @override
  Stream<Map<String, dynamic>> get messages => _messages.stream;
  @override
  Stream<ConnectionStatus> get statusStream => _statusCtrl.stream;

  void _setStatus(ConnectionStatus s) {
    _status = s;
    if (!_statusCtrl.isClosed) _statusCtrl.add(s);
  }

  @override
  Future<void> connect() async {
    _setStatus(ConnectionStatus.connecting);
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      await _channel!.ready;
      _setStatus(ConnectionStatus.connected);
      _channel!.stream.listen(
        (data) {
          try {
            final decoded = jsonDecode(data as String);
            if (decoded is Map<String, dynamic>) _messages.add(decoded);
          } catch (_) {
            // Ignore malformed frames.
          }
        },
        onError: (_) => _setStatus(ConnectionStatus.failed),
        onDone: () => _setStatus(ConnectionStatus.disconnected),
      );
    } catch (_) {
      _setStatus(ConnectionStatus.failed);
    }
  }

  @override
  void send(Map<String, dynamic> message) {
    final ch = _channel;
    if (ch != null && _status == ConnectionStatus.connected) {
      ch.sink.add(jsonEncode(message));
    }
  }

  @override
  Future<void> close() async {
    await _channel?.sink.close(ws_status.goingAway);
    _setStatus(ConnectionStatus.disconnected);
    await _messages.close();
    await _statusCtrl.close();
  }
}

/// Local stand-in used when the real server is unavailable. Echoes a room_state
/// so the lobby flow can be exercised without a backend.
class FakeWebSocketClient implements GameSocket {
  final _messages = StreamController<Map<String, dynamic>>.broadcast();
  final _statusCtrl = StreamController<ConnectionStatus>.broadcast();
  ConnectionStatus _status = ConnectionStatus.disconnected;

  @override
  ConnectionStatus get status => _status;
  @override
  Stream<Map<String, dynamic>> get messages => _messages.stream;
  @override
  Stream<ConnectionStatus> get statusStream => _statusCtrl.stream;

  @override
  Future<void> connect() async {
    _status = ConnectionStatus.connected;
    _statusCtrl.add(_status);
  }

  @override
  void send(Map<String, dynamic> message) {
    if (message['type'] == 'create_room' || message['type'] == 'join_room') {
      _messages.add({
        'type': 'room_state',
        'roomId': 'room_local',
        'roomCode': 'LOCL',
        'players': [
          {'playerId': 'player_1', 'character': 'male_cat', 'ready': true},
          {'playerId': 'player_2', 'character': 'female_cat', 'ready': true},
        ],
      });
    }
  }

  @override
  Future<void> close() async {
    _status = ConnectionStatus.disconnected;
    await _messages.close();
    await _statusCtrl.close();
  }
}
