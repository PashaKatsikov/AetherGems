import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../app.dart';
import '../atlas.dart';
import '../audio.dart';
import '../game/draw.dart';
import '../game/sim.dart';
import '../theme.dart';
import 'chrome.dart';

class PlayPage extends StatefulWidget {
  const PlayPage();

  @override
  State<PlayPage> createState() => _PlayPageState();
}

class _PlayPageState extends State<PlayPage> with SingleTickerProviderStateMixin {
  Ticker? _tick;
  Duration _last = Duration.zero;
  bool _closed = false;
  FieldLayout? _layout;
  Bag? _bag;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bag = Store.of(context);
    if (!_started) {
      _started = true;
      _tick = createTicker(_onTick)..start();
    }
  }

  @override
  void dispose() {
    _tick?.dispose();
    super.dispose();
  }

  void _onTick(Duration t) {
    final bag = _bag;
    if (bag == null || !mounted) return;
    final sim = bag.sim;
    if (sim == null) return;
    final dt = _last == Duration.zero ? 0.016 : (t - _last).inMicroseconds / 1e6;
    _last = t;
    sim.step(dt.clamp(0.0, 0.033));
    _sfx(bag, sim);
    if (!_closed && sim.won) {
      _closed = true;
      Future<void>.delayed(const Duration(milliseconds: 520), () {
        if (mounted) bag.nextAfterWin();
      });
    }
    if (!_closed && sim.lost) {
      _closed = true;
      Future<void>.delayed(const Duration(milliseconds: 420), () {
        if (mounted) bag.fail();
      });
    }
  }

  void _sfx(Bag bag, Sim sim) {
    final cue = sim.cue;
    if (cue.isEmpty) return;
    sim.cue = '';
    if (bag.save.rumble && (cue == 'launch' || cue == 'chain' || cue == 'win')) {
      HapticFeedback.mediumImpact();
    }
    switch (cue) {
      case 'launch':
        bag.audio.play(Sfx.launch);
        break;
      case 'arc':
        bag.audio.play(Sfx.arc, vol: 0.7);
        break;
      case 'chain':
        bag.audio.play(Sfx.chain);
        break;
      case 'reflect':
        bag.audio.play(Sfx.reflect, vol: 0.8);
        break;
      case 'barrier':
        bag.audio.play(Sfx.barrier);
        break;
      case 'altar':
        bag.audio.play(Sfx.altar);
        break;
      case 'zeus':
        bag.audio.play(Sfx.zeus);
        break;
      case 'poseidon':
        bag.audio.play(Sfx.poseidon);
        break;
      case 'athena':
        bag.audio.play(Sfx.athena);
        break;
      case 'hades':
        bag.audio.play(Sfx.hades);
        break;
      case 'win':
        bag.audio.play(Sfx.win);
        break;
      case 'lose':
        bag.audio.play(Sfx.lose);
        break;
      case 'thunder':
        bag.audio.play(Sfx.thunder, vol: 0.55);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bag = Store.of(context);
    final sim = bag.sim!;
    final z = zones[sim.run.zone];
    return AnimatedBuilder(
      animation: sim,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, box) {
            _layout = FieldLayout(box.biggest);
            sim.origin = _layout!.toWorld(Offset(box.maxWidth * 0.10, box.maxHeight * 0.42));
            return Stack(
              children: [
                Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (e) {
                    if (sim.paused) return;
                    final w = _layout!.toWorld(e.localPosition);
                    sim.fireAt(w);
                  },
                  child: CustomPaint(
                    painter: ArenaPainter(bag.atlas, sim, _layout!),
                    size: box.biggest,
                  ),
                ),
                Positioned(
                  top: MediaQuery.paddingOf(context).top + 6,
                  left: 10,
                  right: 10,
                  child: Plate(
                    pad: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            bag.audio.open();
                            sim.paused = !sim.paused;
                            sim.poke();
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xAA0B1A38),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: C.gold),
                            ),
                            child: Icon(sim.paused ? Icons.play_arrow : Icons.pause, color: C.gold),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            sim.run.isBoss ? bossNames[sim.run.zone] : '${z.name}  ·  Court ${sim.run.stage + 1}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Pal.heading.copyWith(fontSize: 16),
                          ),
                        ),
                        const SizedBox(width: 8),
                        CrystalChip(atlas: bag.atlas, value: sim.gathered + sim.run.gems),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: MediaQuery.paddingOf(context).bottom + 8,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Plate(
                        pad: const EdgeInsets.fromLTRB(10, 6, 12, 6),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Charges', style: Pal.dim.copyWith(fontSize: 11)),
                            Row(
                              children: [
                                SpriteView(bag.atlas, Spr.pendant, height: 22),
                                const SizedBox(width: 4),
                                Text(
                                  '${sim.charges}',
                                  style: Pal.heading.copyWith(
                                    fontSize: 18,
                                    color: sim.charges == 0 ? const Color(0xFFFF8A8A) : C.gold,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '${sim.fruits.where((f) => !f.dead).length} left',
                                  style: Pal.dim,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      for (final id in ['zeus', 'poseidon', 'athena', 'hades'])
                        if (bag.save.gods.contains(id))
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: _GodOrb(id: id),
                          ),
                    ],
                  ),
                ),
                if (!sim.paused && sim.time < 5 && sim.run.stage == 0 && sim.run.bless.isEmpty)
                  Positioned(
                    top: MediaQuery.paddingOf(context).top + 56,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Plate(
                        pad: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text('Tap a fruit to start the chain', style: Pal.body.copyWith(color: C.gold)),
                      ),
                    ),
                  ),
                if (sim.paused) const _PauseMask(),
              ],
            );
          },
        );
      },
    );
  }
}

class _GodOrb extends StatelessWidget {
  const _GodOrb({required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final bag = Store.of(context);
    final sim = bag.sim!;
    final slice = switch (id) {
      'poseidon' => Spr.statuePoseidon,
      'athena' => Spr.statueAthena,
      'hades' => Spr.statueHades,
      _ => Spr.statueZeus,
    };
    final hot = sim.buff == id;
    return GestureDetector(
      onTap: () {
        if (sim.useGod(id)) {
          bag.god = id;
        }
      },
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: hot ? C.cyan : C.gold, width: 2),
          color: const Color(0xAA081428),
        ),
        clipBehavior: Clip.antiAlias,
        child: SpriteView(bag.atlas, slice, height: 52),
      ),
    );
  }
}

class _PauseMask extends StatelessWidget {
  const _PauseMask();

  @override
  Widget build(BuildContext context) {
    final bag = Store.of(context);
    final sim = bag.sim!;
    return Container(
      color: const Color(0x99050A16),
      child: Center(
        child: Plate(
          width: 340,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Paused', style: Pal.title),
              const SizedBox(height: 16),
              GoldBtn(
                label: 'Resume',
                wide: true,
                audio: bag.audio,
                onTap: () {
                  sim.paused = false;
                  sim.poke();
                },
              ),
              const SizedBox(height: 10),
              GhostBtn(
                label: 'Settings',
                audio: bag.audio,
                onTap: bag.openSettings,
              ),
              const SizedBox(height: 8),
              GhostBtn(
                label: 'Abandon run',
                audio: bag.audio,
                onTap: () {
                  sim.paused = false;
                  bag.fail();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BlessingPage extends StatelessWidget {
  const BlessingPage();

  @override
  Widget build(BuildContext context) {
    final bag = Store.of(context);
    return Scenic(
      atlas: bag.atlas,
      bg: zones[bag.run!.zone].bg,
      dim: 0.4,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
          child: Column(
            children: [
              const Text('CHOOSE A BLESSING', style: Pal.title),
              const SizedBox(height: 6),
              Text('One gift for the rest of this run.', style: Pal.dim),
              const Spacer(),
              Row(
                children: [
                  for (final b in bag.offer)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: _BlessCard(b: b),
                      ),
                    ),
                ],
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlessCard extends StatelessWidget {
  const _BlessCard({required this.b});
  final Blessing b;

  @override
  Widget build(BuildContext context) {
    final bag = Store.of(context);
    final info = Catalog.blessInfo[b]!;
    return GestureDetector(
      onTap: () {
        bag.audio.play(Sfx.reward);
        bag.pickBless(b);
      },
      child: Plate(
        child: Column(
          children: [
            SpriteView(bag.atlas, info.$3, height: 86),
            const SizedBox(height: 8),
            Text(info.$1, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: Pal.heading.copyWith(fontSize: 16, color: C.gold)),
            const SizedBox(height: 6),
            Text(info.$2, textAlign: TextAlign.center, maxLines: 4, overflow: TextOverflow.ellipsis, style: Pal.body.copyWith(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class VictoryPage extends StatelessWidget {
  const VictoryPage();

  @override
  Widget build(BuildContext context) {
    final bag = Store.of(context);
    final r = bag.run!;
    return Scenic(
      atlas: bag.atlas,
      bg: zones[r.zone].bg,
      dim: 0.3,
      child: SafeArea(
        child: Row(
          children: [
            Expanded(child: Center(child: SpriteView(bag.atlas, Spr.zeus, height: 280))),
            Expanded(
              child: Plate(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SpriteView(bag.atlas, Spr.portal, height: 92),
                    const SizedBox(height: 8),
                    const Text('VICTORY!', style: Pal.title),
                    const SizedBox(height: 6),
                    Text('${zones[r.zone].name} is restored.', style: Pal.body),
                    const SizedBox(height: 12),
                    CrystalChip(atlas: bag.atlas, value: r.gems),
                    const SizedBox(height: 6),
                    CrystalChip(atlas: bag.atlas, value: r.rare, rare: true),
                    const SizedBox(height: 6),
                    Text('Longest chain  ${r.longest}', style: Pal.dim),
                    const SizedBox(height: 16),
                    GoldBtn(
                      label: 'Continue',
                      wide: true,
                      audio: bag.audio,
                      onTap: () {
                        bag.audio.play(Sfx.portal);
                        bag.finishZone();
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 24),
          ],
        ),
      ),
    );
  }
}

class DefeatPage extends StatelessWidget {
  const DefeatPage();

  @override
  Widget build(BuildContext context) {
    final bag = Store.of(context);
    return Scenic(
      atlas: bag.atlas,
      bg: Pic.bgStorm,
      dim: 0.45,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Plate(
            width: min(420, MediaQuery.sizeOf(context).width * 0.7),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SpriteView(bag.atlas, Spr.statueHades, height: 130),
                const SizedBox(height: 8),
                const Text('DEFEAT', style: Pal.title),
                const SizedBox(height: 6),
                const Text('The Aether is still waiting…', textAlign: TextAlign.center, style: Pal.body),
                const SizedBox(height: 14),
                GoldBtn(
                  label: 'Try Again',
                  wide: true,
                  audio: bag.audio,
                  onTap: bag.retry,
                ),
                const SizedBox(height: 10),
                GhostBtn(
                  label: 'Main menu',
                  audio: bag.audio,
                  onTap: () {
                    bag.run = null;
                    bag.sim = null;
                    bag.go(Screen.menu);
                  },
                ),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }
}
