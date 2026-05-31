import 'dart:async';

import '../cat_bomber_game.dart';
import 'websocket_client.dart';

/// Real-time co-op sync (host-authoritative).
///
/// - The host (player_1) simulates the world and broadcasts `snapshot`s.
/// - The client (player_2) sends its cat `state` and bomb-place `event`s, and
///   renders the host's snapshots.
/// - Both sides apply `game_end`.
///
/// Send rate is 15 Hz (spec: 10–20 packets/sec); rendering runs at device FPS
/// and the partner cat is interpolated toward the latest received pose.
class OnlineSync {
  final CatBomberGame game;
  final GameSocket socket;
  final String myPlayerId;
  final String roomId;

  static const double _sendInterval = 1 / 15;

  StreamSubscription<Map<String, dynamic>>? _sub;
  double _acc = 0;
  int _seq = 0;

  OnlineSync({
    required this.game,
    required this.socket,
    required this.myPlayerId,
    required this.roomId,
  });

  void start() {
    _sub = socket.messages.listen(_onMessage);
  }

  void _onMessage(Map<String, dynamic> m) {
    switch (m['type']) {
      case 'state':
        // Host applies the client cat's pose to the companion.
        if (game.isHost && m['fromPlayerId'] != myPlayerId) {
          game.companion?.applyNetwork(
            (m['x'] as num).toDouble(),
            (m['y'] as num).toDouble(),
            m['dir'] as String? ?? 'down',
            m['alive'] == true,
          );
        }
        break;
      case 'event':
        if (m['event'] == 'place_bomb' && game.isHost) {
          game.placeBombForRemote();
        }
        break;
      case 'snapshot':
        if (game.isClient) game.applySnapshot(m);
        break;
      case 'game_end':
        final win = m['result'] == 'win';
        game.handleRemoteEnd(
          win,
          ((m['timeSeconds'] ?? 0) as num).toInt(),
          ((m['stars'] ?? 0) as num).toInt(),
        );
        break;
    }
  }

  void update(double dt) {
    _acc += dt;
    if (_acc < _sendInterval) return;
    _acc = 0;
    if (game.isClient) {
      _sendState();
    } else if (game.isHost) {
      _sendSnapshot();
    }
  }

  void _sendState() {
    final c = game.localCat;
    socket.send({
      'type': 'state',
      'fromPlayerId': myPlayerId,
      'roomId': roomId,
      'seq': _seq++,
      'x': c.position.x,
      'y': c.position.y,
      'dir': c.facing.name,
      'alive': c.alive,
    });
  }

  void _sendSnapshot() {
    final snap = game.buildSnapshot();
    snap['roomId'] = roomId;
    snap['fromPlayerId'] = myPlayerId;
    socket.send(snap);
  }

  void sendPlaceBomb() {
    socket.send({
      'type': 'event',
      'event': 'place_bomb',
      'fromPlayerId': myPlayerId,
      'roomId': roomId,
    });
  }

  void sendGameEnd({
    required bool win,
    required int seconds,
    required int stars,
  }) {
    socket.send({
      'type': 'game_end',
      'result': win ? 'win' : 'lose',
      'reason': win ? 'cats_met' : 'cat_defeated',
      'timeSeconds': seconds,
      'stars': stars,
      'roomId': roomId,
    });
  }

  void dispose() {
    _sub?.cancel();
  }
}
