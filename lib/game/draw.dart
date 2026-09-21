import 'dart:math';

import 'package:flutter/material.dart';

import '../atlas.dart';
import 'sim.dart';

class FieldLayout {
  FieldLayout(this.size)
      : play = Rect.fromCenter(
          center: Offset(size.width * 0.58, size.height * 0.56),
          width: size.width * 0.54,
          height: size.height * 0.58,
        );

  final Size size;
  final Rect play;

  Offset toScreen(Offset w) {
    return Offset(
      play.left + (w.dx / Sim.W) * play.width,
      play.top + (w.dy / Sim.H) * play.height,
    );
  }

  Offset toWorld(Offset s) {
    return Offset(
      (s.dx - play.left) / play.width * Sim.W,
      (s.dy - play.top) / play.height * Sim.H,
    );
  }

  double scaleY(Offset w) => 0.86 + 0.2 * (w.dy / Sim.H);
}

void blit(Canvas c, Atlas atlas, Slice slice, Offset center, double h, {double alpha = 1, double rot = 0, double scaleX = 1}) {
  final img = atlas.of(slice);
  final src = slice.src;
  final sc = h / src.height;
  final w = src.width * sc * scaleX;
  final dst = Rect.fromCenter(center: center, width: w, height: h);
  final paint = Paint()..filterQuality = FilterQuality.high;
  if (alpha < 1) paint.color = Color.fromRGBO(255, 255, 255, alpha.clamp(0, 1));
  if (rot == 0) {
    c.drawImageRect(img, src, dst, paint);
  } else {
    c.save();
    c.translate(center.dx, center.dy);
    c.rotate(rot);
    c.drawImageRect(img, src, Rect.fromCenter(center: Offset.zero, width: w, height: h), paint);
    c.restore();
  }
}

void shadow(Canvas c, Offset p, double w) {
  c.drawOval(
    Rect.fromCenter(center: p, width: w, height: w * 0.28),
    Paint()..color = const Color(0x66000000),
  );
}

class ArenaPainter extends CustomPainter {
  ArenaPainter(this.atlas, this.sim, this.layout) : super(repaint: sim);

  final Atlas atlas;
  final Sim sim;
  final FieldLayout layout;

  @override
  void paint(Canvas c, Size size) {
    final z = zones[sim.run.zone];
    final bg = atlas[z.bg];
    c.drawImageRect(
      bg,
      Rect.fromLTWH(0, 0, bg.width.toDouble(), bg.height.toDouble()),
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.high,
    );

    final drift = sim.time * 8;
    blit(c, atlas, z.cloud, Offset(size.width * 0.18, size.height * 0.16 + sin(sim.time * 0.4) * 6), size.height * 0.22, alpha: 0.55);
    blit(c, atlas, Spr.clouds[(sim.run.zone + 1) % 4], Offset(size.width * 0.84, size.height * 0.14 + sin(drift * 0.02) * 5), size.height * 0.18, alpha: 0.4);

    c.save();
    if (sim.shake > 0) {
      final s = sim.shake;
      c.translate(sin(sim.time * 54) * s, cos(sim.time * 48) * s * 0.6);
    }

    final plat = sim.run.isBoss ? Spr.bossRing : z.platform;
    final platC = layout.toScreen(const Offset(Sim.W * 0.5, Sim.H * 0.58));
    blit(c, atlas, plat, platC, layout.play.height * (sim.run.isBoss ? 0.92 : 0.78));

    if (sim.run.stage == 3) {
      blit(c, atlas, Spr.well, layout.toScreen(const Offset(Sim.W * 0.5, 70)), 90, alpha: 0.9);
    }

    final drawProps = [...sim.props]..sort((a, b) => a.p.dy.compareTo(b.p.dy));
    for (final p in drawProps) {
      if (p.gone) continue;
      final sp = layout.toScreen(p.p);
      final sc = layout.scaleY(p.p);
      shadow(c, sp.translate(0, 18 * sc), p.r * 1.6);
      var h = 86.0 * sc;
      if (p.kind == PropKind.column) h = 120 * sc;
      if (p.kind == PropKind.altar) h = 110 * sc;
      if (p.kind == PropKind.reflector) h = 78 * sc;
      blit(c, atlas, propSlice(p.kind, p.variant), sp, h);
    }

    if (sim.boss != null && sim.boss!.hp > 0) {
      final b = sim.boss!;
      final sp = layout.toScreen(b.p);
      shadow(c, sp.translate(0, 28), 90);
      blit(c, atlas, z.boss, sp, 168);
      final ratio = (b.hp / b.cap).clamp(0.0, 1.0);
      final bar = Rect.fromCenter(center: sp.translate(0, -86), width: 120, height: 10);
      c.drawRRect(RRect.fromRectAndRadius(bar.inflate(2), const Radius.circular(6)), Paint()..color = const Color(0xAA000000));
      c.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(bar.left, bar.top, bar.width * ratio, bar.height), const Radius.circular(4)),
        Paint()..color = const Color(0xFFE24B4B),
      );
    }

    final ordered = [...sim.fruits]..sort((a, b) => a.p.dy.compareTo(b.p.dy));
    for (final f in ordered) {
      if (f.dead && f.pop >= 1) continue;
      final bob = sin(f.phase) * 5;
      final sp = layout.toScreen(f.p).translate(0, bob);
      final pop = f.dead ? (1 - f.pop) : 1.0;
      final h = (86 + (f.special ? 6 : 0)) * layout.scaleY(f.p) * pop;
      if (h < 4) continue;
      shadow(c, layout.toScreen(f.p).translate(0, 22), f.r * 1.5 * pop);
      blit(c, atlas, fruitSlice(f.kind), sp, h, alpha: pop);
      if (sim.hintId == f.id) {
        c.drawCircle(
          sp,
          h * 0.62 + sin(sim.time * 6) * 3,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = const Color(0xCCFFE27A),
        );
      }
    }

    for (final g in sim.gems) {
      blit(c, atlas, Spr.gemFaces[g.face], layout.toScreen(g.p), 28 + sin(g.life * 8) * 2);
    }

    _bolts(c);

    for (final s in sim.sparks) {
      c.drawCircle(layout.toScreen(s.p), 2.2 + s.life * 4, Paint()..color = s.color.withValues(alpha: (s.life * 3).clamp(0, 1)));
    }

    for (final f in sim.floaters) {
      final tp = TextPainter(
        text: TextSpan(
          text: f.text,
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: f.color.withValues(alpha: (1 - f.t).clamp(0, 1)),
            shadows: const [Shadow(blurRadius: 8, color: Color(0xEE000000))],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final p = layout.toScreen(f.p);
      tp.paint(c, Offset(p.dx - tp.width / 2, p.dy));
    }

    c.restore();

    final zeusH = size.height * 0.56;
    blit(c, atlas, Spr.zeus, Offset(size.width * 0.09, size.height * 0.62), zeusH);

    if (sim.flash > 0) {
      c.drawRect(Offset.zero & size, Paint()..color = Color.fromRGBO(180, 230, 255, 0.16 * sim.flash));
    }
  }

  void _bolts(Canvas c) {
    final b = sim.bolt;
    if (b == null) return;
    final n = min(b.shown, b.hops.length);
    for (var i = 0; i < n; i++) {
      final h = b.hops[i];
      final a = layout.toScreen(h.a);
      final bb = layout.toScreen(h.b);
      _stroke(c, a, bb, 18 + i * 0.4, const Color(0x8846D7FF), i);
      _stroke(c, a, bb, 7, const Color(0xDDB8F4FF), i + 11);
      _stroke(c, a, bb, 2.2, const Color(0xFFFFFFFF), i + 29);
    }
  }

  void _stroke(Canvas c, Offset a, Offset b, double w, Color col, int seed) {
    final path = _jagged(a, b, seed);
    c.drawPath(
      path,
      Paint()
        ..color = col
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round
        ..maskFilter = w > 10 ? const MaskFilter.blur(BlurStyle.normal, 8) : null,
    );
  }

  Path _jagged(Offset a, Offset b, int seed) {
    final rng = Random(seed + 4);
    final d = b - a;
    final len = max(1.0, d.distance);
    final perp = Offset(-d.dy, d.dx) / len;
    final path = Path()..moveTo(a.dx, a.dy);
    const steps = 9;
    for (var i = 1; i < steps; i++) {
      final t = i / steps;
      final fall = sin(t * pi);
      final off = (rng.nextDouble() - 0.5) * 26 * fall;
      final p = Offset.lerp(a, b, t)! + perp * off;
      path.lineTo(p.dx, p.dy);
    }
    path.lineTo(b.dx, b.dy);
    return path;
  }

  @override
  bool shouldRepaint(covariant ArenaPainter old) => true;
}

class SpriteView extends StatelessWidget {
  const SpriteView(this.atlas, this.slice, {super.key, this.height, this.width});

  final Atlas atlas;
  final Slice slice;
  final double? height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width ?? (height ?? 80) * (slice.src.width / slice.src.height), height ?? 80),
      painter: _SlicePainter(atlas, slice),
    );
  }
}

class _SlicePainter extends CustomPainter {
  _SlicePainter(this.atlas, this.slice);
  final Atlas atlas;
  final Slice slice;

  @override
  void paint(Canvas c, Size size) {
    final img = atlas.of(slice);
    c.drawImageRect(
      img,
      slice.src,
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  @override
  bool shouldRepaint(covariant _SlicePainter old) => old.slice != slice;
}
