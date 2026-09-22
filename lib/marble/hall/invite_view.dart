import 'package:flutter/material.dart';

import '../../ui/gem_pills.dart';
import '../line/push_desk.dart';
import '../line/slate_box.dart';
import '../tablet/court_spec.dart';
import '../tablet/plates.dart';
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
    final String bg = landscape ? Plates.heraldWide : Plates.heraldTall;

    final Widget body = Scaffold(
      backgroundColor: const Color(0xFF071226),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Image.asset(bg, fit: BoxFit.cover, width: size.width, height: size.height),
          Positioned(
            left: size.width * 0.08,
            right: size.width * 0.08,
            bottom: size.height * (landscape ? 0.06 : 0.08),
            child: landscape ? _wide(size) : _tall(size),
          ),
        ],
      ),
    );

    if (!landscape) return body;
    return MediaQuery.removePadding(
      context: context,
      removeLeft: true,
      removeRight: true,
      child: body,
    );
  }

  Widget _tall(Size size) {
    final double width = size.width * 0.64;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        GemPill(label: 'Accept', width: width, onTap: _accept),
        const SizedBox(height: 14),
        GemPill(label: 'Skip', quiet: true, width: width, onTap: _skip),
      ],
    );
  }

  Widget _wide(Size size) {
    final double width = size.width * 0.2;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        GemPill(label: 'Accept', compact: true, width: width, onTap: _accept),
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
