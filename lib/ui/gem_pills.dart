import 'package:flutter/material.dart';

import '../theme.dart';

/// Bottom-of-screen action used by the court plates (offline / invite).
///
/// Styled after the neon shell slabs but in the Aether palette: a gilded
/// primary with a warm glow and ink text, or a translucent "quiet" ghost
/// with milk text. Labels carry a shadow so they stay legible over whatever
/// art sits behind them.
class GemPill extends StatefulWidget {
  const GemPill({
    super.key,
    required this.label,
    required this.onTap,
    this.compact = false,
    this.quiet = false,
    this.busy = false,
    this.icon,
    this.width,
  });

  final String label;
  final VoidCallback onTap;
  final bool compact;
  final bool quiet;
  final bool busy;
  final IconData? icon;
  final double? width;

  @override
  State<GemPill> createState() => _GemPillState();
}

class _GemPillState extends State<GemPill> {
  double _scale = 1;

  void _reset() => setState(() => _scale = 1);

  @override
  Widget build(BuildContext context) {
    final bool quiet = widget.quiet;
    final Color textColor = quiet ? C.milk : C.ink;
    final Color glow = quiet ? C.cyan : C.gold;

    final List<Color> colors = quiet
        ? const <Color>[Color(0xF21C3358), Color(0xF20E1C38)]
        : const <Color>[Color(0xFFF6E6AC), C.gold, C.goldDeep];

    final bool locked = widget.busy;

    return GestureDetector(
      onTapDown: locked ? null : (_) => setState(() => _scale = 0.96),
      onTapCancel: locked ? null : _reset,
      onTapUp: locked
          ? null
          : (_) {
              _reset();
              widget.onTap();
            },
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 90),
        child: Container(
          width: widget.width,
          height: widget.compact ? 48 : 56,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xE6F4EEDC), width: 1.5),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: glow.withValues(alpha: quiet ? 0.30 : 0.45),
                blurRadius: 16,
                spreadRadius: 1,
                offset: const Offset(0, 3),
              ),
              const BoxShadow(
                color: Color(0x66000000),
                offset: Offset(0, 3),
                blurRadius: 8,
              ),
            ],
          ),
          child: widget.busy
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    valueColor: AlwaysStoppedAnimation<Color>(textColor),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    if (widget.icon != null) ...<Widget>[
                      Icon(
                        widget.icon,
                        color: textColor,
                        size: widget.compact ? 18 : 20,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        widget.label,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontSize: widget.compact ? 15 : 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          height: 1,
                          shadows: quiet
                              ? const <Shadow>[
                                  Shadow(color: Color(0xCC000000), blurRadius: 6),
                                ]
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
