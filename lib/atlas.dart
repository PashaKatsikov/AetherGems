import 'dart:ui' as ui;

import 'package:flutter/services.dart';

class Pic {
  static const logo = 'assets/Aether_Gems_additional_assets/Aether_Title_Mark.webp';
  static const loadH = 'assets/Aether_Gems_additional_assets/Aether_Boot_Wide.webp';
  static const loadV = 'assets/Aether_Gems_additional_assets/Aether_Boot_Tall.webp';

  static const fruits1 = 'assets/Aether_Gems_gameplay_assets/Aether_Fruits_Set_1_asset.webp';
  static const fruits2 = 'assets/Aether_Gems_gameplay_assets/Aether_Fruits_Set_2_asset.webp';
  static const specials = 'assets/Aether_Gems_gameplay_assets/Aether_Crystals_Set_asset.webp';
  static const gems = 'assets/Aether_Gems_gameplay_assets/Special_Fruits_Set_asset.webp';
  static const bosses = 'assets/Aether_Gems_gameplay_assets/Mini_Bosses_Set_1_asset.webp';
  static const zeus = 'assets/Aether_Gems_gameplay_assets/Aether_Skyfather_asset.webp';
  static const artifacts = 'assets/Aether_Gems_gameplay_assets/Upgrade_Artifacts_Set_asset.webp';
  static const platforms = 'assets/Aether_Gems_gameplay_assets/Marble_Platforms_Set_asset.webp';
  static const columns = 'assets/Aether_Gems_gameplay_assets/Greek_Columns_Set_asset.webp';
  static const islands = 'assets/Aether_Gems_gameplay_assets/Sky_Islands_Set_asset.webp';
  static const clouds = 'assets/Aether_Gems_gameplay_assets/Aether_Skyline_Puffs_asset.webp';
  static const well = 'assets/Aether_Gems_gameplay_assets/Greek_Stone_Elements_Set_asset.webp';
  static const rubble = 'assets/Aether_Gems_gameplay_assets/Aether_Source_asset.webp';
  static const portal = 'assets/Aether_Gems_gameplay_assets/Olympian_Mechanical_Altar_asset.webp';
  static const altar = 'assets/Aether_Gems_gameplay_assets/Zone_Portal_asset.webp';
  static const bossRing = 'assets/Aether_Gems_gameplay_assets/Boss_Arena_asset.webp';
  static const bgOlympus = 'assets/Aether_Gems_gameplay_assets/Olympus_Background_asset.webp';
  static const bgTemples = 'assets/Aether_Gems_gameplay_assets/Aether_Storm_Background_asset.webp';
  static const bgStorm = 'assets/Aether_Gems_gameplay_assets/Ancient_Greek_Temples_Background_asset.webp';
  static const bgRealm = 'assets/Aether_Gems_gameplay_assets/Aether_Realm_Background_asset.webp';
  static const wrecks = 'assets/Aether_Gems_gameplay_assets/Destructible_Arena_Objects_Set_asset.webp';
  static const relics = 'assets/Aether_Gems_gameplay_assets/Golden_Relics_Set_asset.webp';
  static const statues = 'assets/Aether_Gems_gameplay_assets/Greek_Statues_Set_asset.webp';

  static const allSheets = <String>[
    logo,
    fruits1,
    fruits2,
    specials,
    gems,
    bosses,
    zeus,
    artifacts,
    platforms,
    columns,
    islands,
    clouds,
    well,
    rubble,
    portal,
    altar,
    bossRing,
    bgOlympus,
    bgTemples,
    bgStorm,
    bgRealm,
    wrecks,
    relics,
    statues,
  ];
}

class Slice {
  final String pic;
  final ui.Rect src;
  const Slice(this.pic, this.src);
}

class Spr {
  static const fig = Slice(Pic.fruits1, ui.Rect.fromLTWH(70, 112, 333, 419));
  static const pear = Slice(Pic.fruits1, ui.Rect.fromLTWH(462, 90, 299, 449));
  static const plum = Slice(Pic.fruits1, ui.Rect.fromLTWH(810, 134, 301, 395));
  static const cherries = Slice(Pic.fruits1, ui.Rect.fromLTWH(1164, 108, 359, 427));

  static const apple = Slice(Pic.fruits2, ui.Rect.fromLTWH(74, 140, 333, 391));
  static const pomegranate = Slice(Pic.fruits2, ui.Rect.fromLTWH(446, 152, 329, 387));
  static const grapes = Slice(Pic.fruits2, ui.Rect.fromLTWH(824, 110, 311, 433));
  static const peach = Slice(Pic.fruits2, ui.Rect.fromLTWH(1172, 158, 363, 373));

  static const boom = Slice(Pic.specials, ui.Rect.fromLTWH(58, 136, 357, 405));
  static const ice = Slice(Pic.specials, ui.Rect.fromLTWH(454, 102, 309, 441));
  static const magnet = Slice(Pic.specials, ui.Rect.fromLTWH(810, 120, 329, 397));
  static const volt = Slice(Pic.specials, ui.Rect.fromLTWH(1162, 140, 365, 399));

  static const gemBlue = Slice(Pic.gems, ui.Rect.fromLTWH(38, 24, 353, 615));
  static const gemGold = Slice(Pic.gems, ui.Rect.fromLTWH(420, 26, 349, 613));
  static const gemPurple = Slice(Pic.gems, ui.Rect.fromLTWH(810, 28, 353, 615));
  static const gemTeal = Slice(Pic.gems, ui.Rect.fromLTWH(1206, 28, 345, 617));

  static const cyclops = Slice(Pic.bosses, ui.Rect.fromLTWH(10, 150, 459, 471));
  static const minotaur = Slice(Pic.bosses, ui.Rect.fromLTWH(406, 28, 407, 369));
  static const griffin = Slice(Pic.bosses, ui.Rect.fromLTWH(746, 176, 385, 481));
  static const golem = Slice(Pic.bosses, ui.Rect.fromLTWH(1152, 34, 391, 401));

  static const zeus = Slice(Pic.zeus, ui.Rect.fromLTWH(456, 6, 609, 659));

  static const pendant = Slice(Pic.artifacts, ui.Rect.fromLTWH(85, 17, 341, 334));
  static const crown = Slice(Pic.artifacts, ui.Rect.fromLTWH(527, 16, 479, 337));
  static const orb = Slice(Pic.artifacts, ui.Rect.fromLTWH(126, 394, 259, 318));
  static const wings = Slice(Pic.artifacts, ui.Rect.fromLTWH(556, 394, 420, 318));

  static const platRound = Slice(Pic.platforms, ui.Rect.fromLTWH(172, 2, 499, 327));
  static const platSquare = Slice(Pic.platforms, ui.Rect.fromLTWH(800, 12, 539, 343));
  static const platOctagon = Slice(Pic.platforms, ui.Rect.fromLTWH(198, 330, 461, 325));
  static const platCrack = Slice(Pic.platforms, ui.Rect.fromLTWH(828, 350, 525, 309));

  static const col0 = Slice(Pic.columns, ui.Rect.fromLTWH(76, 14, 307, 623));
  static const col1 = Slice(Pic.columns, ui.Rect.fromLTWH(470, 20, 285, 617));
  static const col2 = Slice(Pic.columns, ui.Rect.fromLTWH(840, 14, 275, 623));
  static const col3 = Slice(Pic.columns, ui.Rect.fromLTWH(1222, 14, 285, 627));

  static const island0 = Slice(Pic.islands, ui.Rect.fromLTWH(330, 12, 343, 323));
  static const island1 = Slice(Pic.islands, ui.Rect.fromLTWH(878, 18, 355, 339));
  static const island2 = Slice(Pic.islands, ui.Rect.fromLTWH(316, 350, 343, 311));
  static const island3 = Slice(Pic.islands, ui.Rect.fromLTWH(876, 336, 355, 329));

  static const cloud0 = Slice(Pic.clouds, ui.Rect.fromLTWH(144, 16, 551, 295));
  static const cloud1 = Slice(Pic.clouds, ui.Rect.fromLTWH(774, 20, 663, 285));
  static const cloud2 = Slice(Pic.clouds, ui.Rect.fromLTWH(104, 326, 611, 315));
  static const cloud3 = Slice(Pic.clouds, ui.Rect.fromLTWH(806, 370, 609, 271));

  static const well = Slice(Pic.well, ui.Rect.fromLTWH(494, 22, 601, 619));
  static const portal = Slice(Pic.portal, ui.Rect.fromLTWH(420, 22, 755, 621));
  static const altar = Slice(Pic.altar, ui.Rect.fromLTWH(430, 16, 707, 637));
  static const bossRing = Slice(Pic.bossRing, ui.Rect.fromLTWH(216, 10, 1119, 635));

  static const box = Slice(Pic.rubble, ui.Rect.fromLTWH(44, 86, 439, 457));
  static const fallen = Slice(Pic.rubble, ui.Rect.fromLTWH(630, 26, 435, 317));
  static const slab = Slice(Pic.rubble, ui.Rect.fromLTWH(486, 302, 569, 357));
  static const capital = Slice(Pic.rubble, ui.Rect.fromLTWH(1104, 198, 417, 391));

  static const amphora = Slice(Pic.wrecks, ui.Rect.fromLTWH(62, 82, 319, 459));
  static const stump = Slice(Pic.wrecks, ui.Rect.fromLTWH(400, 112, 351, 435));
  static const shrine = Slice(Pic.wrecks, ui.Rect.fromLTWH(792, 84, 369, 475));
  static const barrier = Slice(Pic.wrecks, ui.Rect.fromLTWH(1224, 102, 277, 441));

  static const relicZeus = Slice(Pic.relics, ui.Rect.fromLTWH(52, 38, 405, 341));
  static const relicSun = Slice(Pic.relics, ui.Rect.fromLTWH(392, 276, 405, 355));
  static const relicLaurel = Slice(Pic.relics, ui.Rect.fromLTWH(786, 18, 369, 343));
  static const relicCrown = Slice(Pic.relics, ui.Rect.fromLTWH(1138, 292, 405, 333));

  static const statueZeus = Slice(Pic.statues, ui.Rect.fromLTWH(38, 8, 353, 647));
  static const statueAthena = Slice(Pic.statues, ui.Rect.fromLTWH(474, 20, 255, 621));
  static const statuePoseidon = Slice(Pic.statues, ui.Rect.fromLTWH(812, 22, 317, 633));
  static const statueHades = Slice(Pic.statues, ui.Rect.fromLTWH(1258, 54, 289, 601));

  static const platforms = [platRound, platSquare, platOctagon, platCrack];
  static const columns = [col0, col1, col2, col3];
  static const islands = [island0, island1, island2, island3];
  static const clouds = [cloud0, cloud1, cloud2, cloud3];
  static const bosses = [cyclops, minotaur, griffin, golem];
  static const gemFaces = [gemBlue, gemGold, gemPurple, gemTeal];
}

class Atlas {
  Atlas(this.img);

  final Map<String, ui.Image> img;

  ui.Image operator [](String path) => img[path]!;

  ui.Image of(Slice s) => img[s.pic]!;

  static Future<ui.Image> decode(String path, {int? width}) async {
    final data = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    return (await codec.getNextFrame()).image;
  }

  static Future<Atlas> load(void Function(double) onProgress) async {
    final map = <String, ui.Image>{};
    for (var i = 0; i < Pic.allSheets.length; i++) {
      final path = Pic.allSheets[i];
      final bg = path.contains('Background');
      map[path] = await decode(path, width: bg ? 1600 : null);
      onProgress((i + 1) / (Pic.allSheets.length + 1));
    }
    return Atlas(map);
  }
}
