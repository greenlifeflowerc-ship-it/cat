'use strict';

/**
 * Cat Bomber: Paw Rescue — co-op WebSocket server.
 *
 * Implements the JSON protocol from the build spec (section 9):
 *   client -> server : hello, create_room, join_room, input, state, game_end
 *   server -> client : room_state, snapshot, game_end, error
 *
 * Model: semi-authoritative relay. The server owns room membership and player
 * assignment (player_1 = male_cat, player_2 = female_cat), relays each player's
 * input/state to their partner, and broadcasts a snapshot of the latest known
 * player states at a fixed tick rate. Game simulation (bombs/enemies) stays on
 * the clients; the server keeps both peers in sync and authoritative over the
 * lobby and win/lose signalling.
 *
 * Config: listens on PORT (default 8080) at path WS_PATH (default /ws) so it
 * matches the client's NetworkConfig out of the box.
 */

const http = require('http');
const { WebSocketServer } = require('ws');

const PORT = parseInt(process.env.PORT || '8080', 10);
const WS_PATH = process.env.WS_PATH || '/ws';
const TICK_RATE = 20; // snapshots per second

/** roomId -> room */
const rooms = new Map();
let roomSeq = 0;
let tickSeq = 0;

function now() {
  return Date.now();
}

function makeRoomCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let code;
  do {
    code = '';
    for (let i = 0; i < 4; i++) {
      code += chars[Math.floor(Math.random() * chars.length)];
    }
  } while ([...rooms.values()].some((r) => r.code === code));
  return code;
}

function send(ws, obj) {
  if (ws.readyState === ws.OPEN) {
    ws.send(JSON.stringify(obj));
  }
}

function roomStateMessage(room) {
  return {
    type: 'room_state',
    roomId: room.id,
    roomCode: room.code,
    players: room.players.map((p) => ({
      playerId: p.playerId,
      character: p.character,
      ready: p.ready,
    })),
  };
}

function broadcast(room, obj, exceptWs) {
  for (const p of room.players) {
    if (p.ws !== exceptWs) send(p.ws, obj);
  }
}

function createRoom(host, levelId) {
  const id = `room_${++roomSeq}`;
  const room = {
    id,
    code: makeRoomCode(),
    levelId: levelId || 'level_01',
    players: [],
    started: false,
    pauseTimer: null,
  };
  rooms.set(id, room);
  addPlayer(room, host);
  return room;
}

function addPlayer(room, client) {
  const index = room.players.length; // 0 or 1
  const playerId = index === 0 ? 'player_1' : 'player_2';
  const character = index === 0 ? 'male_cat' : 'female_cat';
  client.playerId = playerId;
  client.character = character;
  client.roomId = room.id;
  client.ready = true;
  client.lastState = null;
  room.players.push(client);
  return playerId;
}

function removeFromRoom(client) {
  const room = rooms.get(client.roomId);
  if (!room) return;
  room.players = room.players.filter((p) => p !== client);
  if (room.players.length === 0) {
    rooms.delete(room.id);
    return;
  }
  // Partner disconnected: tell the remaining player and start a 15s grace
  // window (spec section 18).
  broadcast(room, {
    type: 'error',
    code: 'partner_disconnected',
    message: 'Partner disconnected. Waiting 15s for reconnect…',
  });
  if (room.pauseTimer) clearTimeout(room.pauseTimer);
  room.pauseTimer = setTimeout(() => {
    if (room.players.length < 2) {
      broadcast(room, {
        type: 'game_end',
        result: 'lose',
        reason: 'partner_left',
        timeSeconds: 0,
        stars: 0,
      });
    }
  }, 15000);
}

function snapshot(room) {
  return {
    type: 'snapshot',
    tick: tickSeq,
    serverTime: now(),
    players: room.players
      .filter((p) => p.lastState)
      .map((p) => ({ id: p.playerId, ...p.lastState })),
  };
}

const server = http.createServer((req, res) => {
  // Simple health check for load balancers / manual curl.
  if (req.url === '/health') {
    res.writeHead(200, { 'Content-Type': 'text/plain' });
    res.end('ok');
    return;
  }
  res.writeHead(426, { 'Content-Type': 'text/plain' });
  res.end('Upgrade Required');
});

const wss = new WebSocketServer({ server, path: WS_PATH });

wss.on('connection', (ws) => {
  ws.isAlive = true;
  ws.on('pong', () => (ws.isAlive = true));

  ws.on('message', (raw) => {
    let msg;
    try {
      msg = JSON.parse(raw.toString());
    } catch (_) {
      return;
    }
    handleMessage(ws, msg);
  });

  ws.on('close', () => removeFromRoom(ws));
  ws.on('error', () => removeFromRoom(ws));
});

function handleMessage(ws, msg) {
  switch (msg.type) {
    case 'hello': {
      ws.playerName = msg.playerName || 'Player';
      ws.deviceId = msg.deviceId || '';
      send(ws, { type: 'hello_ack', serverTime: now() });
      break;
    }

    case 'create_room': {
      const room = createRoom(ws, msg.levelId);
      send(ws, roomStateMessage(room));
      break;
    }

    case 'join_room': {
      const code = (msg.roomCode || '').toUpperCase();
      const room = [...rooms.values()].find((r) => r.code === code);
      if (!room) {
        send(ws, { type: 'error', code: 'no_room', message: 'Room not found' });
        return;
      }
      if (room.players.length >= 2) {
        send(ws, { type: 'error', code: 'room_full', message: 'Room is full' });
        return;
      }
      if (room.pauseTimer) {
        clearTimeout(room.pauseTimer);
        room.pauseTimer = null;
      }
      addPlayer(room, ws);
      // Both players present -> notify everyone and start.
      broadcast(room, roomStateMessage(room));
      room.started = true;
      break;
    }

    case 'input': {
      // Relay raw input to the partner for responsiveness.
      relayToPartner(ws, msg);
      break;
    }

    case 'state': {
      // Authoritative-lite: remember the sender's latest position/state and
      // relay it. Expected shape: { x, y, dir, alive, bombsAvailable, ... }.
      ws.lastState = {
        x: msg.x,
        y: msg.y,
        dir: msg.dir,
        alive: msg.alive,
        speed: msg.speed,
        bombsAvailable: msg.bombsAvailable,
        bombRange: msg.bombRange,
      };
      relayToPartner(ws, msg);
      break;
    }

    case 'game_end': {
      // Either client can declare the cooperative result; relay to the room.
      const room = rooms.get(ws.roomId);
      if (room) broadcast(room, msg);
      break;
    }

    default:
      send(ws, { type: 'error', code: 'unknown_type', message: msg.type });
  }
}

function relayToPartner(ws, msg) {
  const room = rooms.get(ws.roomId);
  if (!room) return;
  const stamped = { ...msg, fromPlayerId: ws.playerId };
  for (const p of room.players) {
    if (p !== ws) send(p.ws ? p.ws : p, stamped);
  }
}

// Snapshot broadcaster.
setInterval(() => {
  tickSeq++;
  for (const room of rooms.values()) {
    if (room.players.length === 0) continue;
    broadcast(room, snapshot(room));
  }
}, 1000 / TICK_RATE);

// Heartbeat: drop dead sockets.
setInterval(() => {
  for (const ws of wss.clients) {
    if (!ws.isAlive) {
      ws.terminate();
      continue;
    }
    ws.isAlive = false;
    ws.ping();
  }
}, 30000);

server.listen(PORT, () => {
  console.log(`Cat Bomber server listening on ws://0.0.0.0:${PORT}${WS_PATH}`);
});
