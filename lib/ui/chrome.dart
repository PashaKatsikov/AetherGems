import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../atlas.dart';
import '../audio.dart';
import '../game/draw.dart';
import '../theme.dart';

class GoldBtn extends StatefulWidget {
  const GoldBtn({
    super.key,
    required this.label,
    required this.onTap,
    this.wide = false,
    this.audio,
  });

  final String label;
  final VoidCallback onTap;
  final bool wide;
  final AudioHub? audio;

  @override
  State<GoldBtn> createState() => _GoldBtnState();
}

class _GoldBtnState extends State<GoldBtn> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: () {
        widget.audio?.click();
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: AnimatedScale(
        duration: const Duration(milliseconds: 80),
        scale: _down ? 0.96 : 1,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: widget.wide ? 36 : 22, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF3DC8A), Color(0xFFC7922E)],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFFFF4C4), width: 1.2),
            boxShadow: const [
              BoxShadow(color: Color(0x89000000), blurRadius: 10, offset: Offset(0, 5)),
              BoxShadow(color: Color(0x55E8C56A), blurRadius: 12),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(widget.label, textAlign: TextAlign.center, style: Pal.goldBtn),
          ),
        ),
      ),
    );
  }
}

class GhostBtn extends StatelessWidget {
  const GhostBtn({super.key, required this.label, required this.onTap, this.audio});
  final String label;
  final VoidCallback onTap;
  final AudioHub? audio;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        audio?.click();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xE10C1C40),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: C.gold.withValues(alpha: 0.85)),
        ),
        child: Text(label, style: Pal.body.copyWith(color: C.gold)),
      ),
    );
  }
}

class Plate extends StatelessWidget {
  const Plate({super.key, required this.child, this.pad = const EdgeInsets.all(16), this.width, this.height});
  final Widget child;
  final EdgeInsets pad;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: pad,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xF2183268), Color(0xE30C1C42)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: C.panelEdge, width: 1.7),
        boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 16, offset: Offset(0, 8))],
      ),
      child: child,
    );
  }
}

class CrystalChip extends StatelessWidget {
  const CrystalChip({super.key, required this.atlas, required this.value, this.rare = false});
  final Atlas atlas;
  final int value;
  final bool rare;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SpriteView(atlas, rare ? Spr.gemPurple : Spr.gemBlue, height: 28),
        const SizedBox(width: 6),
        Text('$value', style: Pal.heading.copyWith(fontSize: 16, color: rare ? C.violet : C.cyan)),
      ],
    );
  }
}

class BackOrb extends StatelessWidget {
  const BackOrb({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xCC0B1A38),
          border: Border.all(color: C.gold, width: 1.4),
        ),
        child: const Icon(Icons.arrow_back_ios_new_rounded, color: C.gold, size: 18),
      ),
    );
  }
}

class Scenic extends StatelessWidget {
  const Scenic({super.key, required this.atlas, required this.bg, required this.child, this.dim = 0.28});
  final Atlas atlas;
  final String bg;
  final Widget child;
  final double dim;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(
          child: FittedBox(
            fit: BoxFit.cover,
            child: RawImage(image: atlas[bg], filterQuality: FilterQuality.high),
          ),
        ),
        IgnorePointer(child: Container(color: Color.fromRGBO(5, 10, 24, dim))),
        child,
      ],
    );
  }
}
