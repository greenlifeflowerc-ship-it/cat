/// Static metadata for the 10 stages: display name, themed enemy roster and
/// stage-select icon. Enemy spawns are derived here because the level JSON
/// files only contain the tile layout.
class StageInfo {
  final int index; // 1-based
  final String name;
  final String iconAsset;
  final List<String> enemyTypes;

  const StageInfo({
    required this.index,
    required this.name,
    required this.iconAsset,
    required this.enemyTypes,
  });
}

class LevelRegistry {
  static const List<StageInfo> stages = [
    StageInfo(
      index: 1,
      name: 'Grass Garden',
      iconAsset: 'stage_icons/stage_1_grass_icon.png',
      enemyTypes: ['slime'],
    ),
    StageInfo(
      index: 2,
      name: 'Desert Ruins',
      iconAsset: 'stage_icons/stage_2_desert_icon.png',
      enemyTypes: ['slime', 'bat'],
    ),
    StageInfo(
      index: 3,
      name: 'Ice Cavern',
      iconAsset: 'stage_icons/stage_3_ice_icon.png',
      enemyTypes: ['ice_turtle', 'slime'],
    ),
    StageInfo(
      index: 4,
      name: 'Forest Maze',
      iconAsset: 'stage_icons/stage_4_forest_icon.png',
      enemyTypes: ['bat', 'slime'],
    ),
    StageInfo(
      index: 5,
      name: 'Dark Dungeon',
      iconAsset: 'stage_icons/stage_5_dungeon_icon.png',
      enemyTypes: ['ghost', 'robot'],
    ),
    StageInfo(
      index: 6,
      name: 'Lava Core',
      iconAsset: 'stage_icons/stage_6_lava_icon.png',
      enemyTypes: ['fire_bug', 'robot'],
    ),
    StageInfo(
      index: 7,
      name: 'Water Temple',
      iconAsset: 'stage_icons/stage_7_water_icon.png',
      enemyTypes: ['bat', 'ghost'],
    ),
    StageInfo(
      index: 8,
      name: 'Factory Grid',
      iconAsset: 'stage_icons/stage_8_factory_icon.png',
      enemyTypes: ['robot', 'fire_bug'],
    ),
    StageInfo(
      index: 9,
      name: 'Sky Bridge',
      iconAsset: 'stage_icons/stage_9_sky_icon.png',
      enemyTypes: ['bat', 'ghost', 'ice_turtle'],
    ),
    StageInfo(
      index: 10,
      name: 'Final Castle',
      iconAsset: 'stage_icons/stage_10_final_castle_icon.png',
      enemyTypes: ['robot', 'ghost', 'fire_bug', 'ice_turtle'],
    ),
  ];

  static StageInfo byIndex(int index) => stages[index - 1];
}
