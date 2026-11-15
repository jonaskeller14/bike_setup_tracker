import 'dart:math';

import 'package:flutter/material.dart';

class FireworkParticle {
  final double angle;
  final double speed;

  const FireworkParticle({required this.angle, required this.speed});
}

class FireworkBurst {
  /// Seconds after the start of the show at which the rocket leaves the ground.
  final double launch;

  /// Where the rocket explodes, as a fraction of the painted area.
  final Offset origin;

  /// 1 is a full-size burst; smaller values are smaller and sparser.
  final double scale;
  final int colorIndex;
  final List<FireworkParticle> particles;

  const FireworkBurst({
    required this.launch,
    required this.origin,
    required this.scale,
    required this.colorIndex,
    required this.particles,
  });

  /// A salvo that opens with a big burst and then fades out: later bursts come
  /// further apart and get smaller and sparser.
  static List<FireworkBurst> decliningSalvo(Random random) {
    const launches = [0.0, 0.3, 0.65, 1.1, 1.7, 2.4, 3.2];
    const scales = [1.0, 0.9, 0.8, 0.68, 0.55, 0.45, 0.35];
    final colorOffset = random.nextInt(3);
    return [
      for (var i = 0; i < launches.length; i++)
        FireworkBurst(
          launch: launches[i],
          origin: Offset(
            (i.isEven ? 0.2 : 0.55) + random.nextDouble() * 0.25,
            0.12 + random.nextDouble() * 0.43,
          ),
          scale: scales[i],
          colorIndex: colorOffset + i,
          particles: [
            for (var k = 0, n = (14 + 22 * scales[i]).round(); k < n; k++)
              FireworkParticle(
                angle: (k + random.nextDouble() * 0.6) / n * 2 * pi,
                speed: 0.75 + random.nextDouble() * 0.25,
              ),
          ],
        ),
    ];
  }
}

class FireworksPainter extends CustomPainter {
  static const speed = 0.85;
  static const _showSeconds = 5.2;
  static final duration = Duration(milliseconds: (_showSeconds * 1000 / speed).round());
  static const _riseSeconds = 0.45;
  static const _explosionSeconds = 1.5;

  final Animation<double> animation;
  final List<FireworkBurst> bursts;
  final List<Color> colors;

  FireworksPainter({
    required this.animation,
    required this.bursts,
    required this.colors,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final seconds = animation.value * _showSeconds;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (final burst in bursts) {
      final elapsed = seconds - burst.launch;
      if (elapsed < 0) continue;
      final color = colors[burst.colorIndex % colors.length];
      final center = Offset(burst.origin.dx * size.width, burst.origin.dy * size.height);
      if (elapsed < _riseSeconds) {
        _paintRocket(canvas, paint, color, Offset(center.dx, size.height), center, elapsed / _riseSeconds);
      } else {
        final life = (elapsed - _riseSeconds) / _explosionSeconds;
        if (life < 1) {
          _paintExplosion(canvas, paint, color, burst, center, size.shortestSide * 0.42 * burst.scale, life);
        }
      }
    }
  }

  void _paintRocket(Canvas canvas, Paint paint, Color color, Offset from, Offset to, double progress) {
    final head = Offset.lerp(from, to, Curves.easeOut.transform(progress))!;
    final tail = Offset.lerp(from, to, Curves.easeOut.transform(max(0, progress - 0.2)))!;
    paint
      ..color = color.withValues(alpha: 0.8)
      ..strokeWidth = 2;
    canvas.drawLine(tail, head, paint);
  }

  void _paintExplosion(
    Canvas canvas,
    Paint paint,
    Color color,
    FireworkBurst burst,
    Offset center,
    double radius,
    double life,
  ) {
    if (life < 0.15) {
      final flash = life / 0.15;
      canvas.drawCircle(
        center,
        radius * 0.25 * flash,
        Paint()..color = color.withValues(alpha: (1 - flash) * 0.35),
      );
    }

    Offset position(FireworkParticle particle, double t) {
      final distance = particle.speed * radius * Curves.easeOutCubic.transform(t);
      final drop = radius * 0.45 * t * t;
      return center + Offset(cos(particle.angle) * distance, sin(particle.angle) * distance + drop);
    }

    final fade = pow(1 - life, 1.4).toDouble();
    paint.strokeWidth = 2.2 * (1 - life * 0.6);
    for (var k = 0; k < burst.particles.length; k++) {
      final particle = burst.particles[k];
      final flicker = life > 0.6 ? 0.6 + 0.4 * sin(life * 60 + k) : 1.0;
      paint.color = color.withValues(alpha: fade * flicker);
      canvas.drawLine(position(particle, max(0, life - 0.07)), position(particle, life), paint);
    }
  }

  @override
  bool shouldRepaint(FireworksPainter oldDelegate) =>
      oldDelegate.animation != animation || oldDelegate.bursts != bursts || oldDelegate.colors != colors;
}
