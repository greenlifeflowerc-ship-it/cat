import 'dart:async';

import 'package:flutter/material.dart';

import '../game/cat_bomber_game.dart';
import '../game/networking/network_config.dart';
import '../game/networking/network_messages.dart';
import '../game/networking/websocket_client.dart';
import '../services/save_service.dart';
import 'game_screen.dart';
import 'widgets/pixel_button.dart';

/// Online lobby: connects to the configured WebSocket server, then lets the
/// player create or join a co-op room. On a successful room_state the match
/// starts. Falls back to a local fake socket for development if the real server
/// is unreachable.
class OnlineLobbyScreen extends StatefulWidget {
  const OnlineLobbyScreen({super.key});

  @override
  State<OnlineLobbyScreen> createState() => _OnlineLobbyScreenState();
}

class _OnlineLobbyScreenState extends State<OnlineLobbyScreen> {
  GameSocket? _socket;
  ConnectionStatus _status = ConnectionStatus.disconnected;
  String _log = '';
  final _codeCtrl = TextEditingController();
  StreamSubscription? _msgSub;
  StreamSubscription? _statusSub;

  void _append(String s) => setState(() => _log = '$s\n$_log');

  Future<void> _connect({bool fake = false}) async {
    await _teardown();
    final socket = fake ? FakeWebSocketClient() : WebSocketClient();
    _socket = socket;
    _statusSub = socket.statusStream.listen((s) {
      setState(() => _status = s);
      _append('status: ${s.name}');
    });
    _msgSub = socket.messages.listen(_onMessage);
    _append('connecting to ${fake ? "local dev socket" : NetworkConfig.defaultUrl}');
    await socket.connect();
    setState(() => _status = socket.status);
    if (socket.status == ConnectionStatus.connected) {
      socket.send(ClientMessages.hello(
        clientVersion: '1.0.0',
        playerName: SaveService.instance.lastPlayerName,
        deviceId: 'device-local',
      ));
    } else {
      _append('could not reach server — try Dev Socket to test the flow');
    }
  }

  void _onMessage(Map<String, dynamic> msg) {
    _append('recv: ${msg['type']}');
    if (msg['type'] == ServerMessageType.roomState) {
      _startMatch();
    }
  }

  void _startMatch() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const GameScreen(
          mode: GameMode.onlineClient,
          levelIndex: 1,
        ),
      ),
    );
  }

  void _createRoom() {
    _socket?.send(ClientMessages.createRoom(mode: 'coop', levelId: 'level_01'));
  }

  void _joinRoom() {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    _socket?.send(ClientMessages.joinRoom(code));
  }

  Future<void> _teardown() async {
    await _msgSub?.cancel();
    await _statusSub?.cancel();
    await _socket?.close();
    _socket = null;
  }

  @override
  void dispose() {
    _teardown();
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connected = _status == ConnectionStatus.connected;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Online Co-op'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Image.asset(
              connected
                  ? 'assets/game/ui/online_signal_good.png'
                  : 'assets/game/ui/online_signal_bad.png',
              width: 28,
              filterQuality: FilterQuality.none,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Server: ${NetworkConfig.defaultUrl}',
                style: const TextStyle(color: Colors.white54, fontSize: 11)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                PixelButton(
                    label: 'CONNECT',
                    width: 160,
                    icon: Icons.wifi,
                    onTap: () => _connect()),
                PixelButton(
                    label: 'DEV SOCKET',
                    width: 160,
                    color: const Color(0xFF8a8a8a),
                    icon: Icons.bug_report,
                    onTap: () => _connect(fake: true)),
                PixelButton(
                    label: 'CREATE ROOM',
                    width: 160,
                    color: const Color(0xFF6fa8ff),
                    onTap: connected ? _createRoom : null),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 300,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _codeCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Room code',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PixelButton(
                      label: 'JOIN',
                      width: 90,
                      onTap: connected ? _joinRoom : null),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: SingleChildScrollView(
                  child: Text(_log,
                      style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 11,
                          fontFamily: 'monospace')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
