import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../app.dart';
import '../atlas.dart';
import '../game/draw.dart';
import '../game/sim.dart';
import '../theme.dart';
import 'chrome.dart';

class MenuPage extends StatelessWidget {
  const MenuPage();

  @override
  Widget build(BuildContext context) {
    final bag = Store.of(context);
    return Scenic(
      atlas: bag.atlas,
      bg: Pic.bgOlympus,
      dim: 0.22,
      child: Stack(
        children: [
          Align(
            alignment: const Alignment(-1.05, 0.35),
            child: SpriteView(bag.atlas, Spr.zeus, height: MediaQuery.sizeOf(context).height * 0.78),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
              child: Row(
                children: [
                  Plate(
                    pad: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CrystalChip(atlas: bag.atlas, value: bag.save.crystals),
                        const SizedBox(width: 12),
                        CrystalChip(atlas: bag.atlas, value: bag.save.rare, rare: true),
                      ],
                    ),
                  ),
                  const Spacer(),
                  GhostBtn(
                    label: 'How to play',
                    audio: bag.audio,
                    onTap: () {
                      bag.audio.open();
                      bag.go(Screen.tutorial);
                    },
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0.42, -0.04),
            child: Plate(
              pad: const EdgeInsets.fromLTRB(22, 10, 22, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SpriteView(bag.atlas, const Slice(Pic.logo, ui.Rect.fromLTWH(0, 0, 512, 512)), height: 150),
                  const SizedBox(height: 4),
                  Text('Restore the aether of Olympus', style: Pal.dim.copyWith(fontSize: 13, color: const Color(0xFFE8F0FF))),
                  const SizedBox(height: 14),
                  GoldBtn(
                    label: 'PLAY',
                    wide: true,
                    audio: bag.audio,
                    onTap: () {
                      bag.audio.open();
                      bag.go(Screen.world);
                    },
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      GhostBtn(
                        label: 'Upgrades',
                        audio: bag.audio,
                        onTap: () {
                          bag.audio.open();
                          bag.go(Screen.upgrades);
                        },
                      ),
                      GhostBtn(
                        label: 'Abilities',
                        audio: bag.audio,
                        onTap: () {
                          bag.audio.open();
                          bag.go(Screen.abilities);
                        },
                      ),
                      GhostBtn(
                        label: 'Settings',
                        audio: bag.audio,
                        onTap: bag.openSettings,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WorldPage extends StatelessWidget {
  const WorldPage();

  @override
  Widget build(BuildContext context) {
    final bag = Store.of(context);
    return Scenic(
      atlas: bag.atlas,
      bg: Pic.bgRealm,
      dim: 0.22,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            children: [
              Row(
                children: [
                  BackOrb(onTap: () {
                    bag.audio.close();
                    bag.go(Screen.menu);
                  }),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('WORLD MAP', maxLines: 1, overflow: TextOverflow.ellipsis, style: Pal.title)),
                  CrystalChip(atlas: bag.atlas, value: bag.save.crystals),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Row(
                  children: [
                    for (var i = 0; i < 4; i++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: _ZoneCard(index: i),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ZoneCard extends StatelessWidget {
  const _ZoneCard({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    final bag = Store.of(context);
    final z = zones[index];
    final open = bag.save.zoneUnlocked > index;
    return GestureDetector(
      onTap: () {
        if (!open) return;
        bag.audio.click();
        bag.pickZone = index;
        bag.go(Screen.run);
      },
      child: Plate(
        pad: const EdgeInsets.fromLTRB(10, 12, 10, 12),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SpriteView(bag.atlas, z.cloud, height: 90),
                  SpriteView(bag.atlas, z.island, height: 118),
                  if (!open)
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0x99081428),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(child: Icon(Icons.lock, color: C.gold, size: 32)),
                    ),
                ],
              ),
            ),
            Text(z.name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: Pal.heading.copyWith(fontSize: 14, color: C.gold)),
            const SizedBox(height: 4),
            Text(z.range, maxLines: 1, overflow: TextOverflow.ellipsis, style: Pal.dim),
          ],
        ),
      ),
    );
  }
}

class RunPage extends StatelessWidget {
  const RunPage();

  @override
  Widget build(BuildContext context) {
    final bag = Store.of(context);
    final z = zones[bag.pickZone];
    return Scenic(
      atlas: bag.atlas,
      bg: z.bg,
      dim: 0.35,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
          child: Column(
            children: [
              Row(
                children: [
                  BackOrb(onTap: () {
                    bag.audio.close();
                    bag.go(Screen.world);
                  }),
                  const SizedBox(width: 12),
                  const Text('CHOOSE A RUN', style: Pal.title),
                ],
              ),
              const Spacer(),
              Plate(
                width: min(520, MediaQuery.sizeOf(context).width * 0.72),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(child: SpriteView(bag.atlas, z.island, height: 110)),
                    const SizedBox(height: 8),
                    Text(z.name, style: Pal.heading.copyWith(color: C.gold, fontSize: 24)),
                    const SizedBox(height: 6),
                    Text(z.blurb, textAlign: TextAlign.center, style: Pal.body),
                    const SizedBox(height: 8),
                    Text('Five courts, then ${bossNames[bag.pickZone]}.', style: Pal.dim),
                    const SizedBox(height: 4),
                    Text('Best chain  ${bag.save.bestChain}', style: Pal.dim),
                    const SizedBox(height: 16),
                    GoldBtn(
                      label: 'Begin run',
                      wide: true,
                      audio: bag.audio,
                      onTap: () {
                        if (!bag.save.tutorial) {
                          bag.startRun(bag.pickZone);
                          bag.go(Screen.tutorial);
                        } else {
                          bag.startRun(bag.pickZone);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class UpgradesPage extends StatelessWidget {
  const UpgradesPage();

  @override
  Widget build(BuildContext context) {
    final bag = Store.of(context);
    return Scenic(
      atlas: bag.atlas,
      bg: Pic.bgTemples,
      dim: 0.4,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            children: [
              Row(
                children: [
                  BackOrb(onTap: () {
                    bag.audio.close();
                    bag.go(Screen.menu);
                  }),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('UPGRADES', maxLines: 1, overflow: TextOverflow.ellipsis, style: Pal.title)),
                  CrystalChip(atlas: bag.atlas, value: bag.save.crystals),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Row(
                  children: [
                    _UpCard(
                      slice: Spr.pendant,
                      title: 'Lightning Power',
                      blurb: 'Bolts bite harder into bosses and barriers.',
                      level: bag.save.power,
                      onBuy: () => _buy(bag, () => bag.save.power++, bag.save.power),
                    ),
                    _UpCard(
                      slice: Spr.crown,
                      title: 'Chain Length',
                      blurb: 'One extra hop before the spark dies out.',
                      level: bag.save.chain,
                      onBuy: () => _buy(bag, () => bag.save.chain++, bag.save.chain),
                    ),
                    _UpCard(
                      slice: Spr.orb,
                      title: 'Gem Magnet',
                      blurb: 'Crystals find you faster after every burst.',
                      level: bag.save.magnet,
                      onBuy: () => _buy(bag, () => bag.save.magnet++, bag.save.magnet),
                    ),
                    _UpCard(
                      slice: Spr.wings,
                      title: 'Starting Energy',
                      blurb: 'Carry more lightning charges into each court.',
                      level: bag.save.energy,
                      onBuy: () => _buy(bag, () => bag.save.energy++, bag.save.energy),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _buy(Bag bag, VoidCallback apply, int level) {
    if (level >= 8) return;
    final c = bag.save.cost(level);
    if (bag.save.crystals < c) return;
    bag.save.crystals -= c;
    apply();
    bag.audio.play('Aether_Gems_sounds_assets/Reward_Received_asset.mp3');
    bag.save.write();
    bag.refresh();
  }
}

class _UpCard extends StatelessWidget {
  const _UpCard({
    required this.slice,
    required this.title,
    required this.blurb,
    required this.level,
    required this.onBuy,
  });

  final Slice slice;
  final String title;
  final String blurb;
  final int level;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final bag = Store.of(context);
    final cost = bag.save.cost(level);
    final maxed = level >= 8;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Plate(
          child: Column(
            children: [
              FittedBox(child: SpriteView(bag.atlas, slice, height: 64)),
              const SizedBox(height: 6),
              Text(title, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: Pal.heading.copyWith(fontSize: 14, color: C.gold)),
              const SizedBox(height: 4),
              Text('Lv ${level + 1}', style: Pal.dim),
              const SizedBox(height: 6),
              Expanded(child: Text(blurb, textAlign: TextAlign.center, maxLines: 4, overflow: TextOverflow.ellipsis, style: Pal.body.copyWith(fontSize: 12))),
              GoldBtn(
                label: maxed ? 'Max' : '$cost',
                audio: bag.audio,
                onTap: maxed ? () {} : onBuy,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AbilitiesPage extends StatelessWidget {
  const AbilitiesPage();

  @override
  Widget build(BuildContext context) {
    final bag = Store.of(context);
    return Scenic(
      atlas: bag.atlas,
      bg: Pic.bgStorm,
      dim: 0.38,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            children: [
              Row(
                children: [
                  BackOrb(onTap: () {
                    bag.audio.close();
                    bag.go(Screen.menu);
                  }),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('DIVINE ABILITIES', maxLines: 1, overflow: TextOverflow.ellipsis, style: Pal.title)),
                  CrystalChip(atlas: bag.atlas, value: bag.save.rare, rare: true),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Row(
                  children: const [
                    _GodCard(
                      id: 'zeus',
                      name: 'Zeus',
                      slice: Spr.statueZeus,
                      text: 'Empowers the next storm: longer chains and a crueler bite.',
                    ),
                    _GodCard(
                      id: 'poseidon',
                      name: 'Poseidon',
                      slice: Spr.statuePoseidon,
                      text: 'Widens the search and stills the fruit for a few breaths.',
                    ),
                    _GodCard(
                      id: 'athena',
                      name: 'Athena',
                      slice: Spr.statueAthena,
                      text: 'Marks the first target that will carry the longest chain.',
                    ),
                    _GodCard(
                      id: 'hades',
                      name: 'Hades',
                      slice: Spr.statueHades,
                      text: 'Tears down aether barriers so the bolt can pass the seals.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GodCard extends StatelessWidget {
  const _GodCard({required this.id, required this.name, required this.slice, required this.text});
  final String id;
  final String name;
  final Slice slice;
  final String text;

  @override
  Widget build(BuildContext context) {
    final bag = Store.of(context);
    final owned = bag.save.gods.contains(id);
    final cost = Catalog.godCost[id] ?? 0;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Plate(
          child: Column(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SpriteView(bag.atlas, slice, height: 130),
                ),
              ),
              Text(name, style: Pal.heading.copyWith(color: C.gold)),
              const SizedBox(height: 4),
              Text(text, textAlign: TextAlign.center, maxLines: 4, overflow: TextOverflow.ellipsis, style: Pal.body.copyWith(fontSize: 12)),
              const SizedBox(height: 10),
              if (owned)
                Text(id == 'zeus' ? 'Active' : 'Unlocked', style: Pal.dim.copyWith(color: C.cyan))
              else
                GoldBtn(
                  label: 'Unlock  $cost',
                  audio: bag.audio,
                  onTap: () {
                    if (bag.save.rare < cost) return;
                    bag.save.rare -= cost;
                    bag.save.gods.add(id);
                    bag.audio.play('Aether_Gems_sounds_assets/Reward_Received_asset.mp3');
                    bag.save.write();
                    bag.refresh();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage();

  @override
  Widget build(BuildContext context) {
    final bag = Store.of(context);
    return Scenic(
      atlas: bag.atlas,
      bg: Pic.bgOlympus,
      dim: 0.45,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            children: [
              Row(
                children: [
                  BackOrb(onTap: () {
                    bag.audio.close();
                    bag.go(bag.settingsReturn);
                  }),
                  const SizedBox(width: 12),
                  const Text('SETTINGS', style: Pal.title),
                ],
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Plate(
                width: min(460.0, MediaQuery.sizeOf(context).width - 36),
                child: Column(
                  children: [
                    _tog(bag, 'Sound', bag.save.sound, (v) {
                      bag.save.sound = v;
                      bag.audio.sound = v;
                    }),
                    _tog(bag, 'Music', bag.save.music, (v) {
                      bag.save.music = v;
                      bag.audio.music = v;
                      bag.audio.syncMusic();
                    }),
                    _tog(bag, 'Vibration', bag.save.rumble, (v) {
                      bag.save.rumble = v;
                    }),
                    ListTile(
                      dense: true,
                      title: const Text('Language', style: Pal.body),
                      trailing: Text('English', style: Pal.dim.copyWith(color: C.gold)),
                    ),
                    const Divider(color: Color(0x44D7B45A)),
                    ListTile(
                      dense: true,
                      title: const Text('Privacy Policy', style: Pal.body),
                      trailing: const Icon(Icons.chevron_right, color: C.gold),
                      onTap: () => bag.openLegal(
                        'Privacy Policy',
                        'https://aethergems.site/privacy-policy.html',
                        privacy: true,
                      ),
                    ),
                    ListTile(
                      dense: true,
                      title: const Text('Support', style: Pal.body),
                      trailing: const Icon(Icons.chevron_right, color: C.gold),
                      onTap: () => bag.openLegal(
                        'Support',
                        'https://aethergems.site/support.html',
                      ),
                    ),
                  ],
                ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tog(Bag bag, String label, bool value, ValueChanged<bool> set) {
    return SwitchListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: Pal.body),
      value: value,
      activeThumbColor: C.ink,
      activeTrackColor: C.gold,
      onChanged: (v) {
        bag.audio.click();
        set(v);
        bag.save.write();
        bag.refresh();
      },
    );
  }
}

class TutorialPage extends StatelessWidget {
  const TutorialPage();

  @override
  Widget build(BuildContext context) {
    final bag = Store.of(context);
    return Scenic(
      atlas: bag.atlas,
      bg: Pic.bgOlympus,
      dim: 0.42,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            children: [
              Row(
                children: [
                  BackOrb(onTap: () {
                    bag.audio.close();
                    if (bag.run != null && bag.sim != null && !bag.save.tutorial) {
                      bag.save.tutorial = true;
                      bag.save.write();
                      bag.go(Screen.play);
                    } else {
                      bag.go(Screen.menu);
                    }
                  }),
                  const SizedBox(width: 12),
                  const Text('HOW TO PLAY', style: Pal.title),
                ],
              ),
              Expanded(
                flex: 8,
                child: Row(
                  children: [
                    _step(bag, Spr.fig, '1. Tap a fruit', 'The first strike is yours. Choose the spark that starts the storm.'),
                    _step(bag, Spr.gemBlue, '2. Lightning chains', 'The bolt jumps on its own to nearby fruit, relics and bosses.'),
                    _step(bag, Spr.boom, '3. Gather aether', 'Broken fruit spill crystals. Longer chains pay far better.'),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              GoldBtn(
                label: 'Got it',
                wide: true,
                audio: bag.audio,
                onTap: () {
                  bag.save.tutorial = true;
                  bag.save.write();
                  if (bag.run != null && bag.sim != null) {
                    bag.go(Screen.play);
                  } else {
                    bag.go(Screen.menu);
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _step(Bag bag, Slice slice, String title, String body) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Plate(
          child: Column(
            children: [
              FittedBox(child: SpriteView(bag.atlas, slice, height: 80)),
              const SizedBox(height: 8),
              Text(title, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: Pal.heading.copyWith(fontSize: 15, color: C.gold)),
              const SizedBox(height: 6),
              Expanded(child: Text(body, textAlign: TextAlign.center, style: Pal.body.copyWith(fontSize: 12))),
            ],
          ),
        ),
      ),
    );
  }
}
