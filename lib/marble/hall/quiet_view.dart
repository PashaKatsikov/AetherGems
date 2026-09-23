import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../ui/gem_pills.dart';
import 'court_plate.dart';

/// Offline plate. No art asset — a gilded gradient with a readable headline
/// and a single retry action.
class QuietView extends StatefulWidget {
  const QuietView({super.key, required this.onRetryBuild});

  final WidgetBuilder onRetryBuild;

  @override
  State<QuietView> createState() => _QuietViewState();
}

class _QuietViewState extends State<QuietView> {
  bool _spinning = false;

  Future<void> _retry() async {
    if (_spinning) return;
    setState(() => _spinning = true);
    await Future<void>.delayed(const Duration(milliseconds: 620));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: widget.onRetryBuild),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool landscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final Size size = MediaQuery.of(context).size;
    final double width =
        landscape ? size.width * 0.34 : (size.width * 0.66).clamp(220.0, 360.0);

    return Scaffold(
      backgroundColor: C.navy,
      body: DecoratedBox(
        decoration: courtGradient,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: landscape ? 40 : 28,
            vertical: 24,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const CourtGlyph(
                  icon: Icons.wifi_off_rounded,
                  tint: C.cyan,
                ),
                SizedBox(height: landscape ? 18 : 26),
                const CourtHeadline('NO INTERNET CONNECTION'),
                const SizedBox(height: 12),
                const CourtCaption('Check your connection and try again'),
                SizedBox(height: landscape ? 26 : 38),
                GemPill(
                  label: 'Retry',
                  icon: Icons.refresh_rounded,
                  width: width,
                  compact: landscape,
                  busy: _spinning,
                  onTap: _retry,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
