/// Global tuning constants for Cat Bomber.
class GameConfig {
  /// Logical world size of one tile. Maps are 15x13 tiles.
  static const double tileSize = 32.0;

  static const int gridCols = 15;
  static const int gridRows = 13;

  // Bomb defaults (section 13 of the spec).
  static const double bombFuseSeconds = 2.5;
  static const int defaultBombRange = 2;
  static const int defaultBombCount = 1;

  // Explosion lifetime on screen.
  static const double explosionSeconds = 0.5;

  // Player movement, tiles per second.
  static const double baseMoveTilesPerSec = 4.0;
  static const double speedUpStep = 1.0;

  // Power-up drop chance when a breakable block is destroyed.
  static const double powerupDropChance = 0.28;

  static const int totalLevels = 10;
}

enum Direction { up, down, left, right }

Direction directionFromName(String? name) =>
    Direction.values.firstWhere((d) => d.name == name,
        orElse: () => Direction.down);

extension DirectionVec on Direction {
  /// Grid delta for this direction.
  (int, int) get delta => switch (this) {
        Direction.up => (0, -1),
        Direction.down => (0, 1),
        Direction.left => (-1, 0),
        Direction.right => (1, 0),
      };

  /// Asset suffix used by the sprite frames (front/back/left/right).
  String get faceWord => switch (this) {
        Direction.up => 'back',
        Direction.down => 'front',
        Direction.left => 'left',
        Direction.right => 'right',
      };
}
