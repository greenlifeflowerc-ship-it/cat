Flutter rendering note:
V3 studio polish: saturated colors, pixel rim light, crisp outline, contact shadow, and Flutter-ready folder structure.
Use FilterQuality.none for pixel art.
Example:
Image.asset('assets/game/characters/male_cat/frames/idle_front.png', filterQuality: FilterQuality.none)

Recommended game logic sizes:
- virtual screen: 480x270 or 960x540
- visual tile: use generated tile_size from maps JSON
- keep motion grid-based for Bomberman-style gameplay
