import 'dart:math';

import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'atlas.dart';
import 'audio.dart';
import 'game/sim.dart';
import 'save.dart';
import 'ui/hub.dart';
import 'ui/legal.dart';
import 'ui/play.dart';

enum Screen {
  menu,
  world,
  run,
  play,
  blessing,
  victory,
  defeat,
  upgrades,
  abilities,
  settings,
  tutorial,
  legal,
}

class Store extends InheritedNotifier<Bag> {
  const Store({super.key, required Bag bag, required super.child}) : super(notifier: bag);

  static Bag of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<Store>()!.notifier!;
  }
}

class Bag extends ChangeNotifier {
  Bag(this.atlas, this.save, this.audio) {
    const shot = String.fromEnvironment('SHOT');
    if (shot == 'world') page = Screen.world;
    if (shot == 'settings') page = Screen.settings;
    if (shot == 'upgrades') page = Screen.upgrades;
    if (shot == 'abilities') page = Screen.abilities;
    if (shot == 'tutorial') page = Screen.tutorial;
    if (shot == 'run') {
      pickZone = 0;
      page = Screen.run;
    }
    if (shot == 'play') {
      save.tutorial = true;
      Future<void>.microtask(() => startRun(0));
    }
  }

  final Atlas atlas;
  final SaveFile save;
  final AudioHub audio;

  Screen page = Screen.menu;
  Screen settingsReturn = Screen.menu;
  Screen? legalBack;
  String legalUrl = '';
  String legalTitle = '';
  bool legalPrivacy = false;

  int pickZone = 0;
  RunState? run;
  Sim? sim;
  List<Blessing> offer = [];
  String god = 'zeus';

  void go(Screen p) {
    page = p;
    notifyListeners();
  }

  void openSettings() {
    settingsReturn = page;
    audio.open();
    go(Screen.settings);
  }

  void openLegal(String title, String url, {bool privacy = false}) {
    legalTitle = title;
    legalUrl = url;
    legalPrivacy = privacy;
    legalBack = page;
    audio.open();
    go(Screen.legal);
  }

  void closeLegal() {
    audio.close();
    go(legalBack ?? Screen.settings);
  }

  void startRun(int zone) {
    save.runs++;
    run = RunState(zone, DateTime.now().millisecondsSinceEpoch);
    pickZone = zone;
    god = save.gods.contains('zeus') ? 'zeus' : save.gods.first;
    save.write();
    _enterStage();
  }

  void _enterStage() {
    final r = run!;
    sim = Sim(save, r, r.seed + r.stage * 9176 + r.zone * 131);
    sim!.boot();
    WakelockPlus.enable();
    go(Screen.play);
  }

  void nextAfterWin() {
    final r = run!;
    r.gems += sim!.gathered;
    r.rare += sim!.rareGot;
    if (sim!.longest > r.longest) r.longest = sim!.longest;
    if (r.longest > save.bestChain) save.bestChain = r.longest;
    save.crystals += sim!.gathered;
    save.rare += sim!.rareGot;
    if (r.isBoss) {
      if (save.zoneUnlocked < r.zone + 2) save.zoneUnlocked = r.zone + 2;
      if (save.zoneUnlocked > 4) save.zoneUnlocked = 4;
      save.write();
      go(Screen.victory);
      return;
    }
    save.write();
    offer = Catalog.roll(Random(r.seed + r.stage * 44), r.bless);
    go(Screen.blessing);
  }

  void pickBless(Blessing b) {
    run!.bless.add(b);
    run!.stage++;
    _enterStage();
  }

  void finishZone() {
    WakelockPlus.disable();
    go(Screen.world);
  }

  void fail() {
    save.crystals += sim!.gathered;
    save.rare += sim!.rareGot;
    if (sim!.longest > save.bestChain) save.bestChain = sim!.longest;
    save.write();
    WakelockPlus.disable();
    go(Screen.defeat);
  }

  void refresh() => notifyListeners();

  void retry() {
    startRun(pickZone);
  }

  bool get canLeave => page != Screen.menu;

  void back() {
    switch (page) {
      case Screen.menu:
        break;
      case Screen.world:
        go(Screen.menu);
        break;
      case Screen.run:
        go(Screen.world);
        break;
      case Screen.play:
        if (sim != null && !sim!.paused) {
          sim!.paused = true;
          sim!.poke();
        }
        break;
      case Screen.blessing:
        break;
      case Screen.victory:
        finishZone();
        break;
      case Screen.defeat:
        run = null;
        sim = null;
        go(Screen.menu);
        break;
      case Screen.upgrades:
      case Screen.abilities:
        go(Screen.menu);
        break;
      case Screen.settings:
        audio.close();
        go(settingsReturn);
        break;
      case Screen.tutorial:
        audio.close();
        if (run != null && sim != null) {
          save.tutorial = true;
          save.write();
          go(Screen.play);
        } else {
          go(Screen.menu);
        }
        break;
      case Screen.legal:
        closeLegal();
        break;
    }
  }
}

class Shell extends StatelessWidget {
  const Shell({super.key});

  @override
  Widget build(BuildContext context) {
    final bag = Store.of(context);
    return PopScope(
      canPop: !bag.canLeave,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) bag.back();
      },
      child: Material(
        type: MaterialType.transparency,
        child: _page(bag),
      ),
    );
  }

  Widget _page(Bag bag) {
    switch (bag.page) {
      case Screen.menu:
        return const MenuPage();
      case Screen.world:
        return const WorldPage();
      case Screen.run:
        return const RunPage();
      case Screen.play:
        return const PlayPage();
      case Screen.blessing:
        return const BlessingPage();
      case Screen.victory:
        return const VictoryPage();
      case Screen.defeat:
        return const DefeatPage();
      case Screen.upgrades:
        return const UpgradesPage();
      case Screen.abilities:
        return const AbilitiesPage();
      case Screen.settings:
        return const SettingsPage();
      case Screen.tutorial:
        return const TutorialPage();
      case Screen.legal:
        return const LegalPage();
    }
  }
}
