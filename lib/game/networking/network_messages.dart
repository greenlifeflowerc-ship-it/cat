/// Typed helpers for the JSON WebSocket protocol (section 9). Kept as plain
/// maps so the transport stays trivial and forward-compatible.
class ClientMessages {
  static Map<String, dynamic> hello({
    required String clientVersion,
    required String playerName,
    required String deviceId,
  }) =>
      {
        'type': 'hello',
        'clientVersion': clientVersion,
        'playerName': playerName,
        'deviceId': deviceId,
      };

  static Map<String, dynamic> createRoom({
    required String mode,
    required String levelId,
  }) =>
      {'type': 'create_room', 'mode': mode, 'levelId': levelId};

  static Map<String, dynamic> joinRoom(String roomCode) =>
      {'type': 'join_room', 'roomCode': roomCode};

  static Map<String, dynamic> input({
    required int seq,
    required String roomId,
    required String playerId,
    required bool up,
    required bool down,
    required bool left,
    required bool right,
    required bool placeBomb,
    required bool kickBomb,
    required int timestamp,
  }) =>
      {
        'type': 'input',
        'seq': seq,
        'roomId': roomId,
        'playerId': playerId,
        'up': up,
        'down': down,
        'left': left,
        'right': right,
        'placeBomb': placeBomb,
        'kickBomb': kickBomb,
        'timestamp': timestamp,
      };
}

/// Server -> client message type discriminators.
class ServerMessageType {
  static const roomState = 'room_state';
  static const snapshot = 'snapshot';
  static const gameEnd = 'game_end';
  static const error = 'error';
}
