import 'package:aethergems/game/draw.dart';
import 'package:aethergems/game/sim.dart';
import 'package:aethergems/save.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void autoPlay(Sim sim, {int limit = 24000}) {
  var steps = 0;
  while (!sim.won && !sim.lost && steps < limit) {
    sim.step(0.016);
    steps++;
    if (sim.busy || sim.charges <= 0) continue;
    var bestN = -1;
    Fruit? best;
    for (final f in sim.fruits) {
      if (f.dead) continue;
      final n = sim.previewChain(f);
      if (n > bestN) {
        bestN = n;
        best = f;
      }
    }
    if (best != null) {
      sim.fireAt(best.p);
    } else if (sim.boss != null && sim.boss!.hp > 0) {
      sim.fireAt(sim.boss!.p);
    }
  }
}

void main() {
  test('world and screen mapping stay invertible', () {
    final layout = FieldLayout(const Size(2340, 1080));
    const world = Offset(450, 260);
    final back = layout.toWorld(layout.toScreen(world));
    expect((back - world).distance, lessThan(0.6));
  });

  test('first court is winnable', () {
    final save = SaveFile();
    final run = RunState(0, 1);
    var wins = 0;
    for (var seed = 1; seed <= 12; seed++) {
      final sim = Sim(save, run, seed * 97);
      sim.boot();
      autoPlay(sim);
      if (sim.won) wins++;
    }
    expect(wins, greaterThanOrEqualTo(9));
  });

  test('first boss is winnable', () {
    final save = SaveFile();
    final run = RunState(0, 2)..stage = 5;
    var wins = 0;
    for (var seed = 1; seed <= 8; seed++) {
      final sim = Sim(save, run, 500 + seed * 31);
      sim.boot();
      autoPlay(sim);
      if (sim.won) wins++;
    }
    expect(wins, greaterThanOrEqualTo(5));
  });

  test('later courts still resolve', () {
    final save = SaveFile();
    save.chain = 1;
    save.energy = 1;
    var done = 0;
    for (var zone = 0; zone < 4; zone++) {
      for (final stage in [2, 5]) {
        final run = RunState(zone, 9)..stage = stage;
        final sim = Sim(save, run, 800 + zone * 40 + stage);
        sim.boot();
        autoPlay(sim);
        expect(sim.won || sim.lost, isTrue);
        done++;
      }
    }
    expect(done, 8);
  });

  test('physics does not explode at the origin', () {
    final sim = Sim(SaveFile(), RunState(0, 3), 3);
    sim.boot();
    for (final f in sim.fruits) {
      f.p = const Offset(Sim.W * 0.5, Sim.H * 0.52);
      f.v = Offset.zero;
    }
    expect(() {
      for (var i = 0; i < 120; i++) {
        sim.step(0.016);
      }
    }, returnsNormally);
  });
}
