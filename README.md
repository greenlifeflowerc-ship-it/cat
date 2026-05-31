# Cat Bomber: Paw Rescue

A 2D pixel-art cooperative Bomberman-style game built in **Flutter + Flame**,
implementing the Cat Bomber build specification. Two cats start in opposite
corners of a maze, bomb their way through breakable blocks and enemies, and win
by **meeting each other**.

## Run

The game is landscape-only and forces immersive fullscreen at startup.

```bash
flutter pub get

# Android (recommended target)
flutter run -d android

# Desktop / Web (great for quick testing with keyboard)
flutter run -d chrome
flutter run -d windows
```

### Controls

| Action          | Keyboard            | Touch                         |
|-----------------|---------------------|-------------------------------|
| Move            | Arrow keys / WASD   | D-pad (bottom-left)           |
| Place bomb      | Space               | Bomb button (bottom-right)    |
| Remote detonate | E                   | Round button (bottom-right)   |
| Pause           | —                   | Pause icon (top-right)        |

## What's implemented

- **Landscape lock + immersive fullscreen** (`lib/main.dart`).
- **Flame game** with fixed-resolution camera scaling and crisp
  nearest-neighbour pixel art (`lib/game/cat_bomber_game.dart`).
- **Level loader** that reads the real `assets/game/maps/levels/level_XX.json`
  files, plus a registry of all **10 themed stages** with progression unlock and
  star ratings (`lib/game/levels/`).
- **Two cats**: the Male Cat is player-controlled; the Female Cat is an AI
  companion that uses BFS pathfinding to reach the Male Cat, avoids bomb blast
  zones, and bombs through breakable blocks when its path is blocked
  (`aiDirectionFor` in `cat_bomber_game.dart`).
- **Bombs & explosions**: cross-shaped blasts, wall blocking, breakable-block
  destruction, hidden power-up drops, chain reactions, kicking, and remote
  detonation.
- **Enemies**: slime, bat, robot, ghost, fire_bug, ice_turtle — each with
  type-specific behaviour and animations.
- **Power-ups**: all 15 spec types, with the impactful ones wired to player
  stats (`lib/game/components/powerup_component.dart`).
- **Win/lose** rules, HUD (hearts/bombs/range/timer/score), pause menu, and
  win/lose result screen with stars.
- **Menus**: main menu → mode select → level select / online lobby, plus
  settings (`lib/ui/`).
- **Save data** via `shared_preferences` (unlocked levels, stars, best times,
  settings).
- **Audio hooks** for every spec sound (`lib/services/audio_service.dart`).
  Drop matching clips in `assets/audio/` and register the folder to enable them;
  missing files are safely ignored.
- **Networking**: `NetworkConfig` with the provided AWS Mumbai server IP, a
  modular `GameSocket` abstraction (`WebSocketClient` + a `FakeWebSocketClient`
  for offline development), the full JSON message protocol, and an online lobby
  that connects, creates/joins rooms, and shows connection status.

## Assets

All art comes from the provided pack, copied verbatim into `assets/game/`
(snake_case names preserved). Level art is chosen per stage from each level
JSON's `recommended_assets`.

## Online co-op (real-time)

Fully wired, **host-authoritative**:

- The server assigns **player_1 = male cat (host)** and **player_2 = female cat
  (client)**, then sends `start`.
- The **host** simulates the authoritative world (both cats' stats, enemies,
  bombs, explosions, breakable blocks, power-ups, win/lose) and broadcasts a
  `snapshot` at 15 Hz.
- The **client** sends its cat `state` and bomb-place `event`s, predicts its own
  cat locally for responsiveness, and renders the host's snapshots (partner cat
  and world objects are interpolated).
- Win = the two cats meet; the host detects it and sends `game_end` to both.
  Disconnect triggers the 15-second reconnect grace window on the server.

Run the matching server from [`server/`](server) — it's a pure relay + lobby;
the host client does the simulation. Use **Dev Socket** in the lobby to launch a
match on a single device without a backend.

## Scope notes

- Hazard tiles (`H` in the layout) render as floor; the full hazard/puzzle
  object roster has assets and constants in place but only the core maze
  mechanics are simulated.

## Project layout

```
lib/
  main.dart, app.dart
  game/
    cat_bomber_game.dart      # main Flame game + systems
    core/constants.dart       # tuning, Direction
    game_assets.dart          # sprite/animation loading
    components/               # cats, bombs, explosions, enemies, blocks, ...
    levels/                   # level_data, loader, registry
    input/input_state.dart
    networking/               # config, messages, websocket client
  services/                   # save, audio
  ui/                         # menus, HUD, controls, overlays
assets/game/                  # the full provided art pack
```
