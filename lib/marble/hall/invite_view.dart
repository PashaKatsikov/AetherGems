import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../ui/gem_pills.dart';
import '../line/push_desk.dart';
import '../line/slate_box.dart';
import '../tablet/court_spec.dart';
import 'court_plate.dart';
import 'gate_view.dart';

class InviteView extends StatefulWidget {
  const InviteView({
    super.key,
    required this.slate,
    required this.desk,
    required this.destinationUrl,
  });

  final SlateBox slate;
  final PushDesk desk;
  final String destinationUrl;

  @override
  State<InviteView> createState() => _InviteViewState();
}

class _InviteViewState extends State<InviteView> {
  Future<void> _accept() async {
    await widget.desk.askPermission();
    await widget.slate.markPermissionInviteConsumed();
    if (mounted) _forward();
  }

  Future<void> _skip() async {
    await widget.slate.writePermissionSnoozeUntil(_snoozeTarget());
    if (mounted) _forward();
  }

  int _snoozeTarget() =>
      DateTime.now().millisecondsSinceEpoch ~/ 1000 +
      CourtSpec.permissionSnoozeSeconds;

  void _forward() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => GateView(
          url: widget.destinationUrl,
          slate: widget.slate,
          desk: widget.desk,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final bool landscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

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
                  icon: Icons.notifications_active_rounded,
                  tint: C.gold,
                ),
                SizedBox(height: landscape ? 16 : 24),
                const CourtHeadline(
                  'ALLOW NOTIFICATIONS ABOUT BONUSES AND PROMOS',
                ),
                const SizedBox(height: 12),
                const CourtCaption('Stay tuned for special offers and rewards'),
                SizedBox(height: landscape ? 24 : 36),
                landscape ? _wide(size) : _tall(size),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tall(Size size) {
    final double width = (size.width * 0.66).clamp(220.0, 380.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        GemPill(
          label: 'Accept',
          icon: Icons.notifications_active_rounded,
          width: width,
          onTap: _accept,
        ),
        const SizedBox(height: 14),
        GemPill(label: 'Skip', quiet: true, width: width, onTap: _skip),
      ],
    );
  }

  Widget _wide(Size size) {
    final double width = (size.width * 0.28).clamp(180.0, 320.0);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        GemPill(
          label: 'Accept',
          icon: Icons.notifications_active_rounded,
          compact: true,
          width: width,
          onTap: _accept,
        ),
        const SizedBox(width: 18),
        GemPill(
          label: 'Skip',
          compact: true,
          quiet: true,
          width: width,
          onTap: _skip,
        ),
      ],
    );
  }
}
