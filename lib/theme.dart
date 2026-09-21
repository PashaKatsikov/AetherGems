import 'package:flutter/material.dart';

class C {
  static const navy = Color(0xFF071226);
  static const panel = Color(0xE6122A58);
  static const panelEdge = Color(0xFFD7B45A);
  static const gold = Color(0xFFE8C56A);
  static const goldDeep = Color(0xFFB8892C);
  static const ink = Color(0xFF0B1A38);
  static const milk = Color(0xFFF4EEDC);
  static const cyan = Color(0xFF6AE7FF);
  static const violet = Color(0xFFB07CFF);
}

class Pal {
  static const title = TextStyle(
    fontFamily: 'serif',
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: C.gold,
    letterSpacing: 0.6,
    height: 1.05,
  );

  static const heading = TextStyle(
    fontFamily: 'serif',
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: C.milk,
    letterSpacing: 0.4,
  );

  static const body = TextStyle(
    fontSize: 14,
    color: C.milk,
    height: 1.25,
  );

  static const dim = TextStyle(
    fontSize: 12,
    color: Color(0xFFB9C6E0),
    height: 1.2,
  );

  static const goldBtn = TextStyle(
    fontFamily: 'serif',
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: C.ink,
    letterSpacing: 0.8,
  );
}

ThemeData buildTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: C.navy,
    colorScheme: const ColorScheme.dark(
      primary: C.gold,
      secondary: C.cyan,
      surface: C.ink,
    ),
    fontFamily: 'sans-serif',
    splashFactory: InkRipple.splashFactory,
    useMaterial3: false,
  );
}
