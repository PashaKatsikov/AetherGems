import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../atlas.dart';
import '../save.dart';

enum FruitKind {
  fig,
  pear,
  plum,
  cherries,
  apple,
  pomegranate,
  grapes,
  peach,
  boom,
  ice,
  magnet,
  volt,
}

enum PropKind { column, wreck, barrier, reflector, altar, rubble }

enum Blessing { chain, radius, arc, magnet, slow, pulse }

class ZoneDef {
  const ZoneDef({
    required this.name,
    required this.blurb,
    required this.bg,
    required this.platform,
    required this.boss,
    required this.island,
    required this.cloud,
    required this.range,
  });

  final String name;
  final String blurb;
  final String bg;
  final Slice platform;
  final Slice boss;
  final Slice island;
  final Slice cloud;
  final String range;
}

const zones = [
  ZoneDef(
    name: 'Olympus Clouds',
    blurb: 'Marble courts above the first clouds.',
    bg: Pic.bgOlympus,
    platform: Spr.platRound,
    boss: Spr.cyclops,
    island: Spr.island0,
    cloud: Spr.cloud0,
    range: 'Arenas 1–6',
  ),
  ZoneDef(
    name: 'Temple Heights',
    blurb: 'Golden terraces of the high temples.',
    bg: Pic.bgTemples,
    platform: Spr.platSquare,
    boss: Spr.minotaur,
    island: Spr.island1,
    cloud: Spr.cloud1,
    range: 'Arenas 7–12',
  ),
  ZoneDef(
    name: 'Aether Storm',
    blurb: 'Lightning stitches floating sanctums together.',
    bg: Pic.bgStorm,
    platform: Spr.platOctagon,
    boss: Spr.griffin,
    island: Spr.island2,
    cloud: Spr.cloud2,
    range: 'Arenas 13–18',
  ),
  ZoneDef(
    name: 'Aether Realm',
    blurb: 'The crystal heart of Olympus itself.',
    bg: Pic.bgRealm,
    platform: Spr.platCrack,
    boss: Spr.golem,
    island: Spr.island3,
    cloud: Spr.cloud3,
    range: 'Arenas 19–24',
  ),
];

const bossNames = ['Stone Cyclops', 'Bronze Minotaur', 'Crystal Griffin', 'Storm Golem'];

Slice fruitSlice(FruitKind k) {
  switch (k) {
    case FruitKind.fig:
      return Spr.fig;
    case FruitKind.pear:
      return Spr.pear;
    case FruitKind.plum:
      return Spr.plum;
    case FruitKind.cherries:
      return Spr.cherries;
    case FruitKind.apple:
      return Spr.apple;
    case FruitKind.pomegranate:
      return Spr.pomegranate;
    case FruitKind.grapes:
      return Spr.grapes;
    case FruitKind.peach:
      return Spr.peach;
    case FruitKind.boom:
      return Spr.boom;
    case FruitKind.ice:
      return Spr.ice;
    case FruitKind.magnet:
      return Spr.magnet;
    case FruitKind.volt:
      return Spr.volt;
  }
}

Slice propSlice(PropKind k, int v) {
  switch (k) {
    case PropKind.column:
      return Spr.columns[v % 4];
    case PropKind.wreck:
      return [Spr.amphora, Spr.stump, Spr.shrine][v % 3];
    case PropKind.barrier:
      return Spr.barrier;
    case PropKind.reflector:
      return Spr.gemFaces[v % 4];
    case PropKind.altar:
      return Spr.altar;
    case PropKind.rubble:
      return [Spr.box, Spr.fallen, Spr.slab, Spr.capital][v % 4];
  }
}

class Fruit {
  Fruit(this.id, this.kind, this.p, this.v, this.r, this.phase);
  final int id;
  final FruitKind kind;
  Offset p;
  Offset v;
  double r;
  double phase;
  bool dead = false;
  double pop = 0;
  bool get special =>
      kind == FruitKind.boom || kind == FruitKind.ice || kind == FruitKind.magnet || kind == FruitKind.volt;
}

class Gem {
  Gem(this.p, this.face, this.worth, this.rare);
  Offset p;
  Offset v = Offset.zero;
  final int face;
  final int worth;
  final bool rare;
  double wait = 0.35;
  bool flying = false;
  double life = 0;
}

class Prop {
  Prop(this.kind, this.variant, this.p, this.r, {this.hp = 1, this.solid = true, this.mark = false});
  final PropKind kind;
  final int variant;
  Offset p;
  double r;
  int hp;
  bool solid;
  bool mark;
  bool gone = false;
}

class Boss {
  Boss(this.p, this.r, this.hp) : cap = hp;
  Offset p;
  double r;
  int hp;
  final int cap;
}

class BoltHop {
  BoltHop(this.a, this.b, this.tag);
  final Offset a;
  final Offset b;
  final String tag;
}

class Bolt {
  Bolt(this.hops);
  final List<BoltHop> hops;
  double t = 0;
  int shown = 0;
  bool done = false;
  int hits = 0;
}

class Spark {
  Spark(this.p, this.v, this.life, this.color);
  Offset p;
  Offset v;
  double life;
  final Color color;
}

class Floater {
  Floater(this.p, this.text, this.color);
  Offset p;
  final String text;
  final Color color;
  double t = 0;
}

class RunState {
  RunState(this.zone, this.seed);
  final int zone;
  final int seed;
  int stage = 0;
  int gems = 0;
  int rare = 0;
  int longest = 0;
  final List<Blessing> bless = [];
  bool get isBoss => stage == 5;
  bool get zoneClear => stage > 5;
}

class Sim extends ChangeNotifier {
  Sim(this.save, this.run, this.stageSeed);

  final SaveFile save;
  final RunState run;
  final int stageSeed;

  final fruits = <Fruit>[];
  final gems = <Gem>[];
  final props = <Prop>[];
  final sparks = <Spark>[];
  final floaters = <Floater>[];
  Boss? boss;
  Bolt? bolt;

  int charges = 4;
  int gathered = 0;
  int rareGot = 0;
  int longest = 0;
  bool won = false;
  bool lost = false;
  bool paused = false;
  double time = 0;
  double flash = 0;
  double shake = 0;
  String cue = '';
  int? hintId;
  String? buff;
  double buffT = 0;
  bool athenaOn = false;
  bool hadesOn = false;
  double slowMul = 1;
  double radiusMul = 1;
  int extraChain = 0;
  bool extraArc = false;
  bool autoMagnet = false;
  bool doublePulse = false;
  Offset? origin;

  static const W = 900.0;
  static const H = 520.0;

  late final Random _rng;
  int _fid = 1;

  int get maxChain {
    var n = save.chainBase + extraChain;
    for (final b in run.bless) {
      if (b == Blessing.chain) n += 1;
    }
    if (buff == 'zeus') n += 2;
    return n;
  }

  double get radius {
    var r = save.radius * radiusMul;
    for (final b in run.bless) {
      if (b == Blessing.radius) r += 46;
    }
    if (buff == 'poseidon') r *= 1.4;
    return r;
  }

  void boot() {
    _rng = Random(stageSeed);
    charges = save.charges + (run.stage == 5 ? 3 : 0);
    slowMul = 1;
    for (final b in run.bless) {
      if (b == Blessing.slow) slowMul *= 0.82;
      if (b == Blessing.magnet) autoMagnet = true;
      if (b == Blessing.arc) extraArc = true;
      if (b == Blessing.pulse) doublePulse = true;
    }
    _build();
    _retargetHint();
    notifyListeners();
  }

  bool inside(Offset p) {
    final n = Offset((p.dx - W * 0.5) / (W * 0.33), (p.dy - H * 0.56) / (H * 0.24));
    return n.distanceSquared <= 1;
  }

  Offset _clamp(Offset p) {
    var q = p;
    for (var i = 0; i < 6; i++) {
      final n = Offset((q.dx - W * 0.5) / (W * 0.33), (q.dy - H * 0.56) / (H * 0.24));
      if (n.distanceSquared <= 1) return q;
      final d = n.distance;
      if (d < 0.0001) return const Offset(W * 0.5, H * 0.56);
      q = Offset(W * 0.5 + n.dx / d * W * 0.33 * 0.98, H * 0.56 + n.dy / d * H * 0.24 * 0.98);
    }
    return q;
  }

  void _build() {
    final z = run.zone;
    final s = run.stage;
    final bossFight = s == 5;
    final nFruit = bossFight ? 5 + z : 5 + s + z;
    final speed = (48 + s * 14 + z * 16) * slowMul;

    final pool = <FruitKind>[
      FruitKind.fig,
      FruitKind.pear,
      FruitKind.plum,
      FruitKind.cherries,
    ];
    if (z >= 1 || s >= 2) {
      pool.addAll([FruitKind.apple, FruitKind.pomegranate, FruitKind.grapes, FruitKind.peach]);
    }
    final specials = <FruitKind>[FruitKind.boom, FruitKind.ice, FruitKind.magnet, FruitKind.volt];

    var specialN = 0;
    if (s >= 2) specialN = 1;
    if (s >= 4 || z >= 2) specialN = 2;
    if (bossFight) specialN = 1 + (z > 1 ? 1 : 0);

    for (var i = 0; i < nFruit; i++) {
      final kind = i < specialN ? specials[_rng.nextInt(specials.length)] : pool[_rng.nextInt(pool.length)];
      fruits.add(_spawnFruit(kind, speed));
    }

    final cols = s == 0 ? 1 : (s >= 3 ? 3 : 2);
    for (var i = 0; i < cols; i++) {
      props.add(Prop(PropKind.column, (z + i) % 4, _spot(90), 28));
    }

    if (s >= 1) {
      props.add(Prop(PropKind.wreck, s % 3, _spot(70), 22, hp: 1));
    }
    if (s >= 3 || z >= 1) {
      props.add(Prop(PropKind.rubble, s % 4, _spot(64), 20, solid: false));
    }
    if ((s >= 2 && z >= 1) || s >= 4) {
      props.add(Prop(PropKind.reflector, z % 4, _spot(36), 26, solid: false, mark: true));
    }
    if (s >= 4 || z >= 2) {
      props.add(Prop(PropKind.barrier, 0, _spot(32), 24, hp: 2, mark: true));
    }
    if (s == 3) {
      props.add(Prop(PropKind.altar, 0, Offset(W * 0.5, H * 0.22), 34, solid: false, mark: true, hp: 1));
    }

    if (bossFight) {
      boss = Boss(Offset(W * 0.5, H * 0.24), 64, 3 + z * 2);
    }

    origin = Offset(40, H * 0.42);
  }

  double sSpread() => (run.stage + run.zone * 0.6).clamp(0, 6);

  Fruit _spawnFruit(FruitKind kind, double speed) {
    Offset p;
    var guard = 0;
    final rx = W * (0.22 + sSpread() * 0.02);
    final ry = H * (0.16 + sSpread() * 0.015);
    do {
      p = Offset(W * 0.5 + (_rng.nextDouble() * 2 - 1) * rx, H * 0.56 + (_rng.nextDouble() * 2 - 1) * ry);
      guard++;
    } while (guard < 24 && (_crowded(p, 52) || !inside(p)));
    final ang = _rng.nextDouble() * pi * 2;
    final v = Offset(cos(ang), sin(ang)) * speed * (0.7 + _rng.nextDouble() * 0.6);
    final r = kind == FruitKind.cherries || kind == FruitKind.grapes ? 34.0 : 38.0;
    return Fruit(_fid++, kind, p, v, r, _rng.nextDouble() * pi * 2);
  }

  bool _crowded(Offset p, double d) {
    for (final f in fruits) {
      if ((f.p - p).distance < d) return true;
    }
    for (final pr in props) {
      if ((pr.p - p).distance < d) return true;
    }
    if (boss != null && (boss!.p - p).distance < d + 40) return true;
    return false;
  }

  Offset _spot(double clear) {
    Offset p;
    var g = 0;
    do {
      p = Offset(W * 0.38 + _rng.nextDouble() * W * 0.24, H * 0.46 + _rng.nextDouble() * H * 0.20);
      g++;
    } while (g < 18 && (_crowded(p, clear) || !inside(p)));
    return p;
  }

  void step(double dt) {
    if (paused || won || lost) {
      _tickFx(dt);
      notifyListeners();
      return;
    }
    time += dt;
    if (!won && !lost && time > 5 && _rng.nextDouble() < dt * 0.06) {
      if (cue.isEmpty) cue = 'thunder';
    }
    if (flash > 0) flash = max(0, flash - dt * 3.2);
    if (shake > 0) shake = max(0, shake - dt * 8);
    if (buffT > 0) {
      buffT -= dt;
      if (buffT <= 0) {
        buff = null;
        athenaOn = false;
        hadesOn = false;
        radiusMul = 1;
      }
    }

    final moving = bolt == null || bolt!.done;
    if (moving) {
      _physics(dt);
    } else {
      _physics(dt * 0.22);
    }

    if (bolt != null) _advanceBolt(dt);

    for (final g in gems) {
      g.life += dt;
      g.wait -= dt;
      if (g.wait <= 0 || autoMagnet || save.magnet > 0 && g.life > 0.18) {
        g.flying = true;
      }
      if (g.flying) {
        final home = Offset(W * 0.9, 36);
        final d = home - g.p;
        g.v = d / max(12, d.distance) * (420 + save.magnet * 80);
        g.p += g.v * dt;
        if ((g.p - home).distance < 28) {
          g.wait = -99;
        }
      }
    }
    final keep = <Gem>[];
    for (final g in gems) {
      if (g.wait == -99) {
        gathered += g.worth;
        if (g.rare) rareGot += 1;
      } else {
        keep.add(g);
      }
    }
    gems
      ..clear()
      ..addAll(keep);

    for (final f in fruits) {
      if (f.dead && f.pop < 1) f.pop = min(1, f.pop + dt * 3.4);
    }

    _tickFx(dt);
    _checkEnd();
    notifyListeners();
  }

  void _tickFx(double dt) {
    for (final s in sparks) {
      s.p += s.v * dt;
      s.v *= 0.96;
      s.life -= dt;
    }
    sparks.removeWhere((s) => s.life <= 0);
    for (final f in floaters) {
      f.t += dt;
      f.p += const Offset(0, -28) * dt;
    }
    floaters.removeWhere((f) => f.t > 1.1);
  }

  void _physics(double dt) {
    for (final f in fruits) {
      if (f.dead) continue;
      f.phase += dt * 2.2;
      f.p += f.v * dt;
      if (!inside(f.p)) {
        final c = Offset(W * 0.5, H * 0.52);
        final n = f.p - c;
        final dist = n.distance;
        if (dist < 0.0001) {
          f.p = Offset(W * 0.5 + 8, H * 0.56);
          continue;
        }
        final nn = n / dist;
        f.p = _clamp(f.p);
        final vn = f.v.dx * nn.dx + f.v.dy * nn.dy;
        if (vn > 0) f.v -= nn * vn * 1.8;
      }
      for (final pr in props) {
        if (pr.gone || !pr.solid) continue;
        final d = f.p - pr.p;
        final dist = d.distance;
        final minD = f.r + pr.r;
        if (dist < minD && dist > 0.1) {
          final n = d / dist;
          f.p = pr.p + n * minD;
          final vn = f.v.dx * n.dx + f.v.dy * n.dy;
          if (vn < 0) f.v -= n * vn * 1.7;
        }
      }
      if (boss != null) {
        final d = f.p - boss!.p;
        final dist = d.distance;
        final minD = f.r + boss!.r * 0.72;
        if (dist < minD && dist > 0.1) {
          final n = d / dist;
          f.p = boss!.p + n * minD;
          final vn = f.v.dx * n.dx + f.v.dy * n.dy;
          if (vn < 0) f.v -= n * vn * 1.6;
        }
      }
    }
    for (var i = 0; i < fruits.length; i++) {
      final a = fruits[i];
      if (a.dead) continue;
      for (var j = i + 1; j < fruits.length; j++) {
        final b = fruits[j];
        if (b.dead) continue;
        final d = b.p - a.p;
        final dist = d.distance;
        final minD = a.r + b.r;
        if (dist < minD && dist > 0.001) {
          final n = d / dist;
          final overlap = minD - dist;
          a.p -= n * overlap * 0.5;
          b.p += n * overlap * 0.5;
          final rel = a.v - b.v;
          final vn = rel.dx * n.dx + rel.dy * n.dy;
          if (vn > 0) continue;
          a.v -= n * vn;
          b.v += n * vn;
        }
      }
    }
  }

  Fruit? pick(Offset world) {
    Fruit? best;
    var bestD = 84.0;
    for (final f in fruits) {
      if (f.dead) continue;
      final d = (f.p - world).distance;
      if (d < bestD) {
        bestD = d;
        best = f;
      }
    }
    return best;
  }

  bool get busy => bolt != null && !bolt!.done;

  bool fireAt(Offset world) {
    if (busy || won || lost || paused) return false;
    if (charges <= 0) return false;
    final f = pick(world);
    if (f != null) {
      charges -= 1;
      bolt = Bolt(_plan(f));
      flash = 0.55;
      shake = 7;
      cue = 'launch';
      notifyListeners();
      return true;
    }
    if (boss != null && boss!.hp > 0 && (boss!.p - world).distance < boss!.r + 36) {
      charges -= 1;
      final from = origin ?? Offset(0, H * 0.4);
      bolt = Bolt([BoltHop(from, boss!.p, 'boss')]);
      flash = 0.45;
      shake = 6;
      cue = 'launch';
      notifyListeners();
      return true;
    }
    return false;
  }

  List<BoltHop> _plan(Fruit start) {
    final hops = <BoltHop>[];
    final used = <int>{};
    var from = origin ?? Offset(0, H * 0.4);
    var cur = start.p;
    var node = start;
    var left = maxChain;
    var i = 0;

    void hopTo(Offset to, String tag) {
      hops.add(BoltHop(from, to, tag));
      from = to;
    }

    hopTo(node.p, 'fruit:${node.id}');
    used.add(node.id);
    left--;
    i++;

    while (left > 0) {
      final nxt = _next(cur, used);
      if (nxt == null) {
        final pr = _nextProp(cur);
        if (pr != null && left > 0) {
          hopTo(pr.p, 'prop:${props.indexOf(pr)}');
          left--;
          cur = pr.p;
          if (pr.kind != PropKind.reflector) break;
          continue;
        }
        if (boss != null && boss!.hp > 0 && (boss!.p - cur).distance < radius + 70) {
          hopTo(boss!.p, 'boss');
        }
        break;
      }
      hopTo(nxt.p, 'fruit:${nxt.id}');
      used.add(nxt.id);
      cur = nxt.p;
      node = nxt;
      left--;
      i++;
      if (nxt.kind == FruitKind.volt) {
        final extra = _next(cur, used);
        if (extra != null && left > 0) {
          hops.add(BoltHop(cur, extra.p, 'fruit:${extra.id}'));
          used.add(extra.id);
          left--;
        }
      }
      if (extraArc && i % 4 == 0) {
        final extra = _next(cur, used);
        if (extra != null) {
          hops.add(BoltHop(cur, extra.p, 'arc:${extra.id}'));
        }
      }
    }
    if (run.isBoss && boss != null && boss!.hp > 0) {
      if (hops.isEmpty || hops.last.tag != 'boss') {
        if ((boss!.p - cur).distance < radius + 80) {
          hopTo(boss!.p, 'boss');
        }
      }
    }
    return hops;
  }

  Fruit? _next(Offset from, Set<int> used) {
    Fruit? best;
    var bestD = radius;
    for (final f in fruits) {
      if (f.dead || used.contains(f.id)) continue;
      final d = (f.p - from).distance;
      if (d < bestD) {
        bestD = d;
        best = f;
      }
    }
    return best;
  }

  Prop? _nextProp(Offset from) {
    Prop? best;
    var bestD = radius * 0.9;
    for (final p in props) {
      if (p.gone || !p.mark) continue;
      if (p.kind == PropKind.barrier && !hadesOn) {
        if (maxChain < 5) continue;
      }
      final d = (p.p - from).distance;
      if (d < bestD) {
        bestD = d;
        best = p;
      }
    }
    return best;
  }

  void _advanceBolt(double dt) {
    final b = bolt!;
    b.t += dt;
    final pace = 0.078;
    while (!b.done && b.shown < b.hops.length && b.t >= (b.shown + 1) * pace) {
      final hop = b.hops[b.shown];
      _resolve(hop);
      b.shown++;
      b.hits++;
      cue = hop.tag.startsWith('prop') ? 'reflect' : 'arc';
      if (b.shown == 3) cue = 'chain';
    }
    if (b.shown >= b.hops.length && b.t > b.hops.length * pace + 0.18) {
      b.done = true;
      if (b.hits > longest) longest = b.hits;
      if (b.hits >= 6) {
        floaters.add(Floater(b.hops.last.b, 'CHAIN ${b.hits}!', const Color(0xFFFFF1A8)));
      }
      _retargetHint();
    }
  }

  void _resolve(BoltHop hop) {
    _burst(hop.b, const Color(0xFF9BE8FF));
    if (hop.tag.startsWith('fruit:') || hop.tag.startsWith('arc:')) {
      final id = int.parse(hop.tag.split(':')[1]);
      Fruit? f;
      for (final x in fruits) {
        if (x.id == id) f = x;
      }
      if (f != null && !f.dead) _killFruit(f, hop.b);
    } else if (hop.tag == 'boss' && boss != null) {
      final hit = save.dmg + (bolt?.hits ?? 0) ~/ 2 + (buff == 'zeus' ? 2 : 0);
      boss!.hp = max(0, boss!.hp - hit);
      _burst(boss!.p, const Color(0xFFFFE27A));
      floaters.add(Floater(boss!.p, '-$hit', const Color(0xFFFFF3C0)));
      shake = 10;
    } else if (hop.tag.startsWith('prop:')) {
      final i = int.parse(hop.tag.split(':')[1]);
      if (i >= 0 && i < props.length) {
        final p = props[i];
        if (p.kind == PropKind.barrier || p.kind == PropKind.wreck) {
          p.hp -= 1;
          if (hadesOn) p.hp = 0;
          if (p.hp <= 0) {
            p.gone = true;
            cue = 'barrier';
            _burst(p.p, const Color(0xFFC9A2FF));
          }
        } else if (p.kind == PropKind.altar) {
          p.mark = false;
          gathered += 12;
          cue = 'altar';
          floaters.add(Floater(p.p, 'ALTAR +12', const Color(0xFFB6F3FF)));
        } else if (p.kind == PropKind.reflector) {
          cue = 'reflect';
        }
      }
    }
  }

  void _killFruit(Fruit f, Offset at) {
    if (f.dead) return;
    f.dead = true;
    f.pop = 0.02;
    final hops = bolt?.hits ?? 1;
    var worth = f.special ? 5 : 2;
    worth += hops ~/ 2;
    if (hops >= 10) worth += 8;
    if (hops >= 15) worth += 12;
    gems.add(Gem(f.p, f.id % 4, worth, f.special && _rng.nextDouble() < 0.45));
    if (doublePulse && _rng.nextDouble() < 0.32) {
      gems.add(Gem(f.p + const Offset(10, -8), (f.id + 1) % 4, 2, false));
    }
    _burst(at, f.special ? const Color(0xFFFFC46B) : const Color(0xFF7FE7FF));
    if (f.kind == FruitKind.boom) {
      for (final o in fruits) {
        if (o.dead || o.id == f.id) continue;
        if ((o.p - f.p).distance < 110) _killFruit(o, o.p);
      }
      for (final p in props) {
        if (p.gone) continue;
        if ((p.p - f.p).distance < 100 && (p.kind == PropKind.wreck || p.kind == PropKind.barrier)) {
          p.hp = 0;
          p.gone = true;
        }
      }
    } else if (f.kind == FruitKind.ice) {
      for (final o in fruits) {
        if (o.dead) continue;
        if ((o.p - f.p).distance < 150) o.v *= 0.45;
      }
    } else if (f.kind == FruitKind.magnet) {
      for (final g in gems) {
        g.flying = true;
        g.wait = 0;
      }
    }
  }

  void _burst(Offset p, Color c) {
    for (var i = 0; i < 10; i++) {
      final a = _rng.nextDouble() * pi * 2;
      sparks.add(Spark(p, Offset(cos(a), sin(a)) * (80 + _rng.nextDouble() * 160), 0.28 + _rng.nextDouble() * 0.25, c));
    }
  }

  void _retargetHint() {
    hintId = null;
    if (!athenaOn && buff != 'athena') return;
    var best = -1;
    var bestN = -1;
    for (final f in fruits) {
      if (f.dead) continue;
      final n = _plan(f).where((h) => h.tag.startsWith('fruit')).length;
      if (n > bestN) {
        bestN = n;
        best = f.id;
      }
    }
    hintId = best;
  }

  void _checkEnd() {
    if (won || lost) return;
    if (bolt != null && !bolt!.done) return;
    final live = fruits.where((f) => !f.dead).isEmpty;
    if (boss != null) {
      if (boss!.hp <= 0) {
        won = true;
        gathered += 40 + run.zone * 15;
        rareGot += 2;
        cue = 'win';
        return;
      }
      if (charges <= 0) {
        lost = true;
        cue = 'lose';
      }
      return;
    }
    if (live) {
      for (final g in gems) {
        gathered += g.worth;
        if (g.rare) rareGot += 1;
      }
      gems.clear();
      won = true;
      cue = 'win';
      return;
    }
    if (charges <= 0) {
      for (final g in gems) {
        gathered += g.worth;
        if (g.rare) rareGot += 1;
      }
      gems.clear();
      lost = true;
      cue = 'lose';
    }
  }

  bool useGod(String id) {
    if (buffT > 0 || busy || won || lost) return false;
    if (!save.gods.contains(id)) return false;
    buff = id;
    buffT = 8;
    switch (id) {
      case 'zeus':
        extraArc = true;
        extraChain += 1;
        cue = 'zeus';
        break;
      case 'poseidon':
        radiusMul = 1.45;
        slowMul *= 0.7;
        for (final f in fruits) {
          f.v *= 0.7;
        }
        cue = 'poseidon';
        break;
      case 'athena':
        athenaOn = true;
        _retargetHint();
        cue = 'athena';
        break;
      case 'hades':
        hadesOn = true;
        for (final p in props) {
          if (p.kind == PropKind.barrier) {
            p.gone = true;
            _burst(p.p, const Color(0xFFB07CFF));
          }
        }
        cue = 'hades';
        break;
    }
    poke();
    return true;
  }

  void poke() => notifyListeners();

  int previewChain(Fruit f) => _plan(f).where((h) => h.tag.startsWith('fruit')).length;
}

class Catalog {
  static const blessInfo = {
    Blessing.chain: ('Chain +1', 'Maximum lightning hops increase by one.', Spr.pendant),
    Blessing.radius: ('Wide Arc', 'The bolt reaches farther between targets.', Spr.crown),
    Blessing.arc: ('Side Arc', 'Every fourth hop throws a spare bolt.', Spr.wings),
    Blessing.magnet: ('Gem Magnet', 'Crystals rush to you the moment they fall.', Spr.orb),
    Blessing.slow: ('Still Aether', 'Fruits drift slower across the court.', Spr.gemTeal),
    Blessing.pulse: ('Double Pulse', 'Destroyed fruit may spark a second burst.', Spr.relicZeus),
  };

  static const godCost = {'poseidon': 6, 'athena': 9, 'hades': 12};

  static List<Blessing> roll(Random rng, List<Blessing> have) {
    final pool = Blessing.values.toList()..shuffle(rng);
    final fresh = pool.where((b) => !have.contains(b)).toList();
    final used = pool.where((b) => have.contains(b)).toList();
    final out = <Blessing>[];
    for (final b in [...fresh, ...used]) {
      if (out.contains(b)) continue;
      out.add(b);
      if (out.length == 3) break;
    }
    return out;
  }
}
