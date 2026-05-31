# Cat Bomber server

WebSocket co-op server for **Cat Bomber: Paw Rescue**. Upload this `server/`
folder to your AWS Mumbai instance and run it.

## Files to upload

Only two files are required:

- `server.js`  — the server
- `package.json` — dependency list (the `ws` package)

(`node_modules/` is generated on the server by `npm install`; don't upload it.)

## Deploy on the AWS Mumbai instance (13.201.118.98)

1. Install Node 18+ (once):
   ```bash
   curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
   sudo apt-get install -y nodejs
   ```

2. Copy the folder up (from your machine):
   ```bash
   scp -r server ubuntu@13.201.118.98:~/cat-bomber-server
   ```

3. Install and run:
   ```bash
   cd ~/cat-bomber-server
   npm install
   node server.js
   ```
   You should see:
   `Cat Bomber server listening on ws://0.0.0.0:8080/ws`

4. Keep it running after logout (recommended — use pm2):
   ```bash
   sudo npm install -g pm2
   pm2 start server.js --name cat-bomber
   pm2 save && pm2 startup
   ```

## Open the port

In the EC2 **Security Group**, add an inbound rule:

- Type: Custom TCP, Port: **8080**, Source: `0.0.0.0/0` (and `::/0` for IPv6).

This matches the client's `NetworkConfig` (`ws://13.201.118.98:8080/ws`). If you
prefer a different port, set it on the server with `PORT=9000 node server.js`
**and** change `websocketPort` in
`lib/game/networking/network_config.dart` — that's the only place to change it.

## Verify

```bash
curl http://13.201.118.98:8080/health      # -> ok
```

In the app: Online Co-op → **CONNECT** → **CREATE ROOM** on one device, then
**JOIN** with the 4-letter room code on the other.

## Protocol

Implements the spec's JSON messages:

- client → server: `hello`, `create_room`, `join_room`, `input`, `state`,
  `game_end`
- server → client: `room_state`, `snapshot` (20 Hz), `game_end`, `error`,
  `hello_ack`

The server is a **semi-authoritative relay**: it owns room membership and player
assignment (`player_1` = male_cat, `player_2` = female_cat), relays each
player's input/state to their partner, broadcasts snapshots, and enforces the
15-second reconnect grace window on disconnect.
