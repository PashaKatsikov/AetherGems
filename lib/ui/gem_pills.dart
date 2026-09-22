import 'package:flutter/material.dart';

import '../theme.dart';

class GemPill extends StatefulWidget {
  const GemPill({
    super.key,
    required this.label,
    required this.onTap,
    this.compact = false,
    this.quiet = false,
    this.width,
  });

  final String label;
  final VoidCallback onTap;
  final bool compact;
  final bool quiet;
  final double? width;

  @override
  State<GemPill> createState() => _GemPillState();
}

class _GemPillState extends State<GemPill> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    final List<Color> colors = widget.quiet
        ? const <Color>[Color(0xFF1C3358), Color(0xFF0E1C38)]
        : const <Color>[Color(0xFFF3E2A8), C.gold, C.goldDeep];
    final Color textColor = widget.quiet ? C.milk : C.ink;

    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.96),
      onTapCancel: () => setState(() => _scale = 1),
      onTapUp: (_) {
        setState(() => _scale = 1);
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 90),
        child: Container(
          width: widget.width,
          padding: EdgeInsets.symmetric(
            horizontal: 22,
            vertical: widget.compact ? 10 : 14,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xCCF4EEDC), width: 1.5),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x66000000),
                offset: Offset(0, 3),
                blurRadius: 8,
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: widget.compact ? 15 : 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
