import 'package:shared_preferences/shared_preferences.dart';

class SaveFile {
  int crystals = 0;
  int rare = 0;
  int power = 0;
  int chain = 0;
  int magnet = 0;
  int energy = 0;
  int zoneUnlocked = 1;
  int bestChain = 0;
  int runs = 0;
  bool tutorial = false;
  bool sound = true;
  bool music = true;
  bool rumble = true;
  final Set<String> gods = {'zeus'};

  int get chainBase => 3 + chain;
  int get charges => 4 + energy;
  double get radius => 168 + magnet * 14 + chain * 6;
  int get dmg => 1 + power;

  int cost(int level) => 35 * (level + 1) * (level + 1) + 20;

  Future<void> write() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('crystals', crystals);
    await p.setInt('rare', rare);
    await p.setInt('power', power);
    await p.setInt('chain', chain);
    await p.setInt('magnet', magnet);
    await p.setInt('energy', energy);
    await p.setInt('zoneUnlocked', zoneUnlocked);
    await p.setInt('bestChain', bestChain);
    await p.setInt('runs', runs);
    await p.setBool('tutorial', tutorial);
    await p.setBool('sound', sound);
    await p.setBool('music', music);
    await p.setBool('rumble', rumble);
    await p.setStringList('gods', gods.toList());
  }

  static Future<SaveFile> read() async {
    final p = await SharedPreferences.getInstance();
    final s = SaveFile();
    s.crystals = p.getInt('crystals') ?? 0;
    s.rare = p.getInt('rare') ?? 0;
    s.power = p.getInt('power') ?? 0;
    s.chain = p.getInt('chain') ?? 0;
    s.magnet = p.getInt('magnet') ?? 0;
    s.energy = p.getInt('energy') ?? 0;
    s.zoneUnlocked = p.getInt('zoneUnlocked') ?? 1;
    s.bestChain = p.getInt('bestChain') ?? 0;
    s.runs = p.getInt('runs') ?? 0;
    s.tutorial = p.getBool('tutorial') ?? false;
    s.sound = p.getBool('sound') ?? true;
    s.music = p.getBool('music') ?? true;
    s.rumble = p.getBool('rumble') ?? true;
    final g = p.getStringList('gods');
    if (g != null) {
      s.gods
        ..clear()
        ..addAll(g);
    }
    if (s.gods.isEmpty) s.gods.add('zeus');
    return s;
  }
}
