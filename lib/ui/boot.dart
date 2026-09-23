import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app.dart';
import '../atlas.dart';
import '../audio.dart';
import '../marble/hall/gate_view.dart';
import '../marble/hall/invite_view.dart';
import '../marble/hall/quiet_view.dart';
import '../marble/line/push_desk.dart';
import '../marble/line/reach_tap.dart';
import '../marble/line/slate_box.dart';
import '../marble/marble_gate.dart';
import '../marble/omen/arrival.dart';
import '../save.dart';
import '../theme.dart';

class BootPage extends StatefulWidget {
  const BootPage({
    super.key,
    required this.gate,
    required this.slate,
    required this.desk,
  });

  final MarbleGate gate;
  final SlateBox slate;
  final PushDesk desk;

  @override
  State<BootPage> createState() => _BootPageState();
}

class _BootPageState extends State<BootPage> {
  /// Fastest a full 0..100 sweep may run when the work is already ahead of
  /// the bar, so a warm cache still reads as a fill rather than a snap.
  static const int _sweepMillis = 1800;
  static const Duration _beat = Duration(milliseconds: 16);

  /// While work is pending the bar eases toward the phase ceiling by this
  /// share of the remaining gap per beat: it keeps moving, slows down, and
  /// never reaches the ceiling on its own.
  static const double _creepPerBeat = 0.005;

  /// 100% is shown only this long before the hand-off.
  static const Duration _fullHold = Duration(milliseconds: 150);

  static const double _decisionTo = 0.60;
  static const double _decisionCap = 0.57;
  static const double _prepTo = 0.68;
  static const double _assetsTo = 0.95;

  /// Confirmed by finished work; the bar catches up to it at sweep speed.
  double _floor = 0;

  /// Soft ceiling of the current phase; the bar creeps toward it while the
  /// work inside the phase is still pending. Only the hand-off lifts it to 1.
  double _cap = 0;
  double _shown = 0;
  Timer? _ticker;
  bool _loading = false;
  String? _err;

  double _atlasShare = 0;
  bool _assetPhase = false;

  void _reach(double floor, {required double cap}) {
    if (floor > _floor) _floor = floor;
    if (cap > _cap) _cap = cap;
  }

  void _onAtlas(double share) {
    _atlasShare = share;
    if (_assetPhase) _aimAtlas();
  }

  void _aimAtlas() => _reach(
        _prepTo + _atlasShare * (_assetsTo - _prepTo),
        cap: _assetsTo,
      );

  void _startBar() {
    final double step = _beat.inMilliseconds / _sweepMillis;
    _ticker = Timer.periodic(_beat, (_) {
      if (!mounted) return;
      double next;
      if (_shown < _floor) {
        next = _shown + step;
        if (next > _floor) next = _floor;
      } else if (_shown < _cap) {
        double creep = (_cap - _shown) * _creepPerBeat;
        if (creep > step) creep = step;
        next = _shown + creep;
      } else {
        return;
      }
      setState(() => _shown = next);
    });
  }

  /// Drives the bar to a full 100 right before the hand-off, so every
  /// launch — court or native game — ends on a completed bar and nothing
  /// else sits between 100% and the next screen.
  Future<void> _finishBar() async {
    _reach(1, cap: 1);
    int guard = _sweepMillis ~/ _beat.inMilliseconds + 60;
    while (mounted && _shown < 1 - 0.001 && guard > 0) {
      guard--;
      await Future<void>.delayed(_beat);
    }
    if (!mounted) return;
    _ticker?.cancel();
    setState(() => _shown = 1);
    await Future<void>.delayed(_fullHold);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _load();
  }

  Future<void> _load() async {
    try {
      // A genuinely offline launch (no active adapter) on any route other
      // than the native arena drops straight onto the quiet plate, so the
      // loading bar never flashes for it.
      if (widget.slate.route != RouteMark.arena) {
        if (!await ReachTap().hasAdapter()) {
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => QuietView(onRetryBuild: _retryBoot),
            ),
          );
          return;
        }
      }

      // From here the loading screen is genuinely up, so the bar and its
      // percent stay on screen the whole time, climbing through the config
      // decision (0..60) and then the asset load (60..95).
      if (!mounted) return;
      setState(() => _loading = true);
      _reach(0.04, cap: _decisionCap);
      _startBar();

      // A returning arena player almost always lands in the native game, so
      // the sheets decode while the config call is still out.
      Future<Atlas>? preload;
      if (widget.slate.route == RouteMark.arena) {
        preload = Atlas.load(_onAtlas)..ignore();
      }

      final Arrival arrival = await widget.gate.decide(
        onProgress: (double v) => _reach(v * _decisionTo, cap: _decisionCap),
      );
      if (!mounted) return;
      _reach(_decisionTo, cap: _decisionTo);

      if (arrival is! PlayArrival && preload != null) {
        unawaited(preload.then((Atlas a) => a.dispose(), onError: (_) {}));
      }

      // Offline is a dead end rather than a finished load, so it shows at
      // once instead of pretending to complete.
      if (arrival is QuietArrival) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => QuietView(onRetryBuild: _retryBoot),
          ),
        );
        return;
      }

      // The court is the app for this user, so the bar completes right
      // before the hand-off exactly like the native one does.
      if (arrival is PortalArrival) {
        final String url = arrival.url;
        await _finishBar();
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => _court(url)),
        );
        return;
      }

      // Native game.
      _reach(_decisionTo, cap: _prepTo);
      final save = await SaveFile.read();
      if (!mounted) return;

      final audio = AudioHub()
        ..sound = save.sound
        ..music = save.music;
      await audio.warm();
      if (!mounted) return;
      _reach(_prepTo, cap: _assetsTo);

      _assetPhase = true;
      _aimAtlas();
      final atlas = await (preload ?? Atlas.load(_onAtlas));
      if (!mounted) return;
      _reach(_assetsTo, cap: _assetsTo);

      await audio.startWind();
      if (!mounted) return;

      // The bar fills to a full 100 before anything else moves. The
      // orientation flip used to fire early, and that flip is what read as
      // the game starting ahead of the bar.
      await _finishBar();
      if (!mounted) return;

      await SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      if (!mounted) return;

      final bag = Bag(atlas, save, audio);
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, _, _) => Store(
            bag: bag,
            child: const Shell(),
          ),
          transitionDuration: const Duration(milliseconds: 360),
          transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _err = '$e');
    }
  }

  Widget _court(String url) {
    if (widget.slate.shouldInvitePermission) {
      return InviteView(
        slate: widget.slate,
        desk: widget.desk,
        destinationUrl: url,
      );
    }
    return GateView(url: url, slate: widget.slate, desk: widget.desk);
  }

  Widget _retryBoot(BuildContext _) => BootPage(
        gate: widget.gate,
        slate: widget.slate,
        desk: widget.desk,
      );

  @override
  Widget build(BuildContext context) {
    final tall = MediaQuery.orientationOf(context) == Orientation.portrait;
    final asset = tall ? Pic.loadV : Pic.loadH;
    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(asset, fit: BoxFit.cover),
          if (_err != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(48, 0, 48, 28),
                child: Text(
                  _err!,
                  textAlign: TextAlign.center,
                  style: Pal.body.copyWith(
                    color: const Color(0xFFFFB4B4),
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            )
          else if (_loading)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(44, 0, 44, 30),
                child: _ProgressReadout(value: _shown.clamp(0, 1)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Big, bold percentage over a doubly-thick staged bar. The readout is the
/// only load text now, and it always matches the fill beneath it.
class _ProgressReadout extends StatelessWidget {
  const _ProgressReadout({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final int pct = (value * 100).round().clamp(0, 100);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$pct%',
          style: const TextStyle(
            fontFamily: 'serif',
            fontSize: 40,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 1.2,
            height: 1,
            decoration: TextDecoration.none,
            shadows: <Shadow>[
              Shadow(color: Color(0xF2000000), blurRadius: 10, offset: Offset(0, 2)),
              Shadow(color: Color(0x99B8892C), blurRadius: 20),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 18,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: const Color(0xAA040A18),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: const Color(0xCCD7B45A), width: 1.3),
          ),
          child: LayoutBuilder(
            builder: (context, box) {
              return Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: box.maxWidth * value.clamp(0.03, 1),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF6E6AC), C.gold, C.goldDeep],
                    ),
                    boxShadow: const [
                      BoxShadow(color: Color(0x66E8C56A), blurRadius: 10, spreadRadius: 1),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
