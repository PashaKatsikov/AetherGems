import 'package:audioplayers/audioplayers.dart';

class Sfx {
  static const click = 'Aether_Gems_sounds_assets/AetherGems_Button_Click.mp3';
  static const open = 'Aether_Gems_sounds_assets/AetherGems_Menu_Open.mp3';
  static const close = 'Aether_Gems_sounds_assets/AetherGems_Menu_Close.mp3';
  static const reward = 'Aether_Gems_sounds_assets/AetherGems_Reward_Received.mp3';
  static const win = 'Aether_Gems_sounds_assets/AetherGems_Level_Complete.mp3';
  static const lose = 'Aether_Gems_sounds_assets/Defeat_asset.mp3';
  static const launch = 'Aether_Gems_sounds_assets/Lightning_Launch_asset.mp3';
  static const arc = 'Aether_Gems_sounds_assets/AetherGems_Electric_Arc.mp3';
  static const chain = 'Aether_Gems_sounds_assets/AetherGems_Chain_Reaction.mp3';
  static const altar = 'Aether_Gems_sounds_assets/Altar_Activation_asset.mp3';
  static const crystal = 'Aether_Gems_sounds_assets/Crystal_Activation_asset.mp3';
  static const portal = 'Aether_Gems_sounds_assets/Portal_Open_asset.mp3';
  static const barrier = 'Aether_Gems_sounds_assets/Barrier_Destroy_asset.mp3';
  static const reflect = 'Aether_Gems_sounds_assets/Reflector_Energy_Pass_asset.mp3';
  static const zeus = 'Aether_Gems_sounds_assets/Zeus_Ability_asset.mp3';
  static const poseidon = 'Aether_Gems_sounds_assets/Poseidon_Ability_asset.mp3';
  static const athena = 'Aether_Gems_sounds_assets/Athena_Ability_asset.mp3';
  static const hades = 'Aether_Gems_sounds_assets/Hades_Ability_asset.mp3';
  static const wind = 'Aether_Gems_sounds_assets/Olympus_Wind_asset.mp3';
  static const thunder = 'Aether_Gems_sounds_assets/Thunder_Rumble_asset.mp3';
}

class AudioHub {
  AudioHub();

  bool sound = true;
  bool music = true;

  final _pool = <AudioPlayer>[];
  AudioPlayer? _wind;
  int _cursor = 0;

  Future<void> warm() async {
    for (var i = 0; i < 6; i++) {
      _pool.add(AudioPlayer());
    }
    _wind = AudioPlayer();
    await _wind!.setReleaseMode(ReleaseMode.loop);
    await _wind!.setVolume(0.28);
  }

  Future<void> play(String file, {double vol = 1}) async {
    if (!sound || _pool.isEmpty) return;
    final p = _pool[_cursor % _pool.length];
    _cursor++;
    try {
      await p.stop();
      await p.setVolume(vol);
      await p.play(AssetSource(file));
    } catch (_) {}
  }

  Future<void> click() => play(Sfx.click, vol: 0.7);
  Future<void> open() => play(Sfx.open, vol: 0.75);
  Future<void> close() => play(Sfx.close, vol: 0.75);

  Future<void> startWind() async {
    if (!music || _wind == null) return;
    try {
      await _wind!.play(AssetSource(Sfx.wind));
    } catch (_) {}
  }

  Future<void> stopWind() async {
    try {
      await _wind?.stop();
    } catch (_) {}
  }

  Future<void> syncMusic() async {
    if (music) {
      await startWind();
    } else {
      await stopWind();
    }
  }

  Future<void> dispose() async {
    await stopWind();
    for (final p in _pool) {
      await p.dispose();
    }
    await _wind?.dispose();
  }
}
