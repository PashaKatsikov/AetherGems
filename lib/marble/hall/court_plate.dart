import 'package:flutter/material.dart';

/// Shared look for the asset-free court plates (offline / invite): a gilded
/// Olympus gradient plus a legible headline and caption treatment.
const BoxDecoration courtGradient = BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[
      Color(0xFF0E244E),
      Color(0xFF091A38),
      Color(0xFF03060F),
    ],
    stops: <double>[0.0, 0.52, 1.0],
  ),
);

/// A glowing circular badge around a single icon.
class CourtGlyph extends StatelessWidget {
  const CourtGlyph({super.key, required this.icon, required this.tint});

  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 108,
      height: 108,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: <Color>[
            tint.withValues(alpha: 0.28),
            tint.withValues(alpha: 0.05),
            const Color(0x00000000),
          ],
          stops: const <double>[0.0, 0.6, 1.0],
        ),
        border: Border.all(color: tint.withValues(alpha: 0.55), width: 1.4),
      ),
      child: Icon(
        icon,
        size: 52,
        color: Colors.white,
        shadows: <Shadow>[
          Shadow(color: tint, blurRadius: 16),
          Shadow(color: tint.withValues(alpha: 0.6), blurRadius: 28),
        ],
      ),
    );
  }
}

/// Uppercase, bold headline that stays legible over the gradient.
class CourtHeadline extends StatelessWidget {
  const CourtHeadline(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontFamily: 'serif',
        fontSize: 23,
        fontWeight: FontWeight.w800,
        color: Color(0xFFF6ECCF),
        letterSpacing: 1.4,
        height: 1.15,
        decoration: TextDecoration.none,
        shadows: <Shadow>[
          Shadow(color: Color(0xF2000000), blurRadius: 10, offset: Offset(0, 2)),
          Shadow(color: Color(0x88B8892C), blurRadius: 20),
        ],
      ),
    );
  }
}

/// Softer supporting line beneath the headline.
class CourtCaption extends StatelessWidget {
  const CourtCaption(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: Color(0xFFD5DEEF),
        height: 1.3,
        letterSpacing: 0.3,
        decoration: TextDecoration.none,
        shadows: <Shadow>[
          Shadow(color: Color(0xCC000000), blurRadius: 8),
        ],
      ),
    );
  }
}
