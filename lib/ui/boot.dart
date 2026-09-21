import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app.dart';
import '../atlas.dart';
import '../audio.dart';
import '../save.dart';
import '../theme.dart';

class BootPage extends StatefulWidget {
  const BootPage({super.key});

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
      final save = await SaveFile.read();
      setState(() => _p = 0.08);
      final audio = AudioHub()
        ..sound = save.sound
        ..music = save.music;
      await audio.warm();
      setState(() => _p = 0.16);
      final atlas = await Atlas.load((v) {
        if (mounted) setState(() => _p = 0.16 + v * 0.8);
      });
      await audio.startWind();
      if (!mounted) return;
      await SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await Future<void>.delayed(const Duration(milliseconds: 280));
      if (!mounted) return;
      final bag = Bag(atlas, save, audio);
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, _, _) => Store(
            bag: bag,
            child: const Shell(),
          ),
          transitionDuration: const Duration(milliseconds: 420),
          transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _err = '$e');
    }
  }

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
                    Text(_err!, style: Pal.body.copyWith(color: const Color(0xFFFFB4B4), decoration: TextDecoration.none))
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
