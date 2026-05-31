import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// What occupies a logical tile when a level starts.
enum CellType { floor, wall, breakable, hazard, goal, spawnMale, spawnFemale }

/// Parsed, immutable description of one level loaded from
/// assets/game/maps/levels/level_XX.json.
class LevelData {
  final String id;
  final String name;
  final int cols;
  final int rows;
  final int sourceTileSize;
  final List<List<CellType>> grid; // [row][col]
  final (int, int) maleStart;
  final (int, int) femaleStart;
  final (int, int) meetingGoal;

  // Recommended themed art (paths relative to assets/game/).
  final String floorAsset;
  final String wallAsset;
  final String breakableAsset;
  final String goalAsset;

  const LevelData({
    required this.id,
    required this.name,
    required this.cols,
    required this.rows,
    required this.sourceTileSize,
    required this.grid,
    required this.maleStart,
    required this.femaleStart,
    required this.meetingGoal,
    required this.floorAsset,
    required this.wallAsset,
    required this.breakableAsset,
    required this.goalAsset,
  });

  CellType cellAt(int col, int row) {
    if (row < 0 || row >= rows || col < 0 || col >= cols) return CellType.wall;
    return grid[row][col];
  }

  static CellType _fromChar(String c) {
    switch (c) {
      case '#':
        return CellType.wall;
      case 'B':
        return CellType.breakable;
      case '1':
        return CellType.spawnMale;
      case '2':
        return CellType.spawnFemale;
      case 'M':
        return CellType.goal;
      case 'H':
        return CellType.hazard;
      default:
        return CellType.floor;
    }
  }

  factory LevelData.fromJson(Map<String, dynamic> json) {
    final layout = (json['layout'] as List).cast<String>();
    final gridSize = (json['grid_size'] as List).cast<num>();
    final cols = gridSize[0].toInt();
    final rows = gridSize[1].toInt();

    final grid = <List<CellType>>[];
    for (final line in layout) {
      final row = <CellType>[];
      for (var x = 0; x < cols; x++) {
        final ch = x < line.length ? line[x] : '.';
        row.add(_fromChar(ch));
      }
      grid.add(row);
    }

    (int, int) pair(String key) {
      final p = (json[key] as List).cast<num>();
      return (p[0].toInt(), p[1].toInt());
    }

    final rec = (json['recommended_assets'] as Map?)?.cast<String, dynamic>() ??
        const {};

    return LevelData(
      id: json['id'] as String,
      name: json['name'] as String,
      cols: cols,
      rows: rows,
      sourceTileSize: (json['tile_size'] as num?)?.toInt() ?? 128,
      grid: grid,
      maleStart: pair('spawn_male'),
      femaleStart: pair('spawn_female'),
      meetingGoal: pair('meeting_goal'),
      floorAsset: rec['floor'] as String? ?? 'tiles/grass_floor.png',
      wallAsset: rec['solid_wall'] as String? ?? 'blocks/solid_stone_wall.png',
      breakableAsset:
          rec['breakable_block'] as String? ?? 'blocks/breakable_crate.png',
      goalAsset: rec['meeting_goal'] as String? ?? 'objects/meeting_goal_tile.png',
    );
  }
}

class LevelLoader {
  /// level index is 1-based (1..10).
  static Future<LevelData> load(int index) async {
    final id = index.toString().padLeft(2, '0');
    final raw =
        await rootBundle.loadString('assets/game/maps/levels/level_$id.json');
    return LevelData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}
