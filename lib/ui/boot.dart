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
  /// Shortest time a full 0..100 sweep may take. The atlas is quick once
  /// warm, so the fill is paced on its own clock instead of snapping.
  static const int _fillMillis = 2600;
  static const Duration _beat = Duration(milliseconds: 16);

  /// A long config wait would park the bar on one checkpoint for seconds,
  /// so it drifts on its own — but never into the hand-off zone.
  static const double _driftPerBeat = 0.0004;
  static const double _driftCap = 0.9;

  double _target = 0;
  double _shown = 0;
  Timer? _ticker;
  bool _loading = false;
  String? _err;

  /// Raises the work target; the ticker walks the bar up to it.
  void _aim(double v) {
    if (v > _target) _target = v;
  }

  void _startBar() {
    final double step = _beat.inMilliseconds / _fillMillis;
    _ticker = Timer.periodic(_beat, (_) {
      if (!mounted) return;
      if (_shown >= _target) {
        if (_target >= _driftCap) return;
        _target = _target + _driftPerBeat;
        if (_target > _driftCap) _target = _driftCap;
      }
      final double next = _shown + step;
      setState(() => _shown = next > _target ? _target : next);
    });
  }

  /// Waits for the bar to actually reach what the work has claimed, with a
  /// ceiling so a stalled ticker can never wedge the boot.
  Future<void> _barCatchUp() async {
    int guard = _fillMillis ~/ _beat.inMilliseconds + 60;
    while (mounted && _shown < _target - 0.001 && guard > 0) {
      guard--;
      await Future<void>.delayed(_beat);
    }
  }

  /// Drives the bar to a full 100 and lets it sit there, so every hand-off
  /// — court or native game — ends on a completed bar.
  Future<void> _finishBar() async {
    _aim(1);
    await _barCatchUp();
    if (!mounted) return;
    setState(() => _shown = 1);
    await Future<void>.delayed(const Duration(milliseconds: 850));
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
      // decision and then the asset load. The decision phase owns 0..0.50.
      if (!mounted) return;
      setState(() {
        _loading = true;
        _target = 0.04;
      });
      _startBar();

      final Arrival arrival = await widget.gate.decide(
        onProgress: (double v) => _aim(0.04 + v * 0.46),
      );
      if (!mounted) return;

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

      // The court is the app for this user, so the bar completes and holds
      // exactly like the native hand-off does.
      if (arrival is PortalArrival) {
        final String url = arrival.url;
        await _finishBar();
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => _court(url)),
        );
        return;
      }

      // Native game. Each group raises the target; the ticker below is what
      // the user actually sees, so a cached atlas cannot skip the fill.
      final save = await SaveFile.read();
      if (!mounted) return;
      _aim(0.58);

      final audio = AudioHub()
        ..sound = save.sound
        ..music = save.music;
      await audio.warm();
      if (!mounted) return;
      _aim(0.70);

      final atlas = await Atlas.load((v) => _aim(0.70 + v * 0.22));
      if (!mounted) return;
      _aim(0.94);

      await audio.startWind();
      if (!mounted) return;

      // The bar fills to a full 100 and holds there before anything else
      // moves. The orientation flip used to fire at 94%, and that flip is
      // what read as the game starting ahead of the bar.
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
