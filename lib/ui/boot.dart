import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app.dart';
import '../atlas.dart';
import '../audio.dart';
import '../marble/hall/gate_view.dart';
import '../marble/hall/invite_view.dart';
import '../marble/hall/quiet_view.dart';
import '../marble/line/push_desk.dart';
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
  double _p = 0;
  String? _err;

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
      final Arrival arrival = await widget.gate.decide(
        onProgress: (double v) {
          if (mounted) setState(() => _p = 0.04 + v * 0.1);
        },
      );
      if (!mounted) return;

      if (arrival is! PlayArrival) {
        final Widget next = switch (arrival) {
          PortalArrival(:final String url) => _court(url),
          QuietArrival() => QuietView(onRetryBuild: _retryBoot),
          PlayArrival() => const SizedBox.shrink(),
        };
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => next),
        );
        return;
      }

      final save = await SaveFile.read();
      setState(() => _p = 0.18);
      final audio = AudioHub()
        ..sound = save.sound
        ..music = save.music;
      await audio.warm();
      setState(() => _p = 0.28);
      final atlas = await Atlas.load((v) {
        if (mounted) setState(() => _p = 0.28 + v * 0.68);
      });
      await audio.startWind();
      if (!mounted) return;
      await SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await Future<void>.delayed(const Duration(milliseconds: 240));
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
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(48, 0, 48, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_err != null)
                    Text(
                      _err!,
                      style: Pal.body.copyWith(
                        color: const Color(0xFFFFB4B4),
                        decoration: TextDecoration.none,
                      ),
                    )
                  else ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _p.clamp(0.05, 1),
                        minHeight: 8,
                        backgroundColor: const Color(0x66000000),
                        color: C.gold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Gathering the gems',
                      style: Pal.dim.copyWith(
                        color: Colors.white,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
