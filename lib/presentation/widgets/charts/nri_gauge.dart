import 'dart:math' as math;

import 'package:flutter/material.dart';

class NriGauge extends StatelessWidget {
  const NriGauge({
    super.key,
    required this.value,
    required this.delta,
    required this.updatedAt,
    this.size = 180,
  });

  final double value;
  final double delta;
  final DateTime updatedAt;
  final double size;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0, 100);
    final now = DateTime.now();
    final mins = now.difference(updatedAt).inMinutes;
    final deltaPositive = delta >= 0;

    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: clamped.toDouble()),
          duration: const Duration(milliseconds: 900),
          builder: (context, animatedValue, child) {
            return SizedBox(
              width: size,
              height: size / 2 + 24,
              child: CustomPaint(
                painter: _GaugePainter(value: animatedValue),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 22),
                    child: Text(
                      animatedValue.toStringAsFixed(0),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Chip(
          avatar: Icon(
            deltaPositive ? Icons.arrow_upward : Icons.arrow_downward,
            size: 16,
          ),
          label: Text('${deltaPositive ? '+' : ''}${delta.toStringAsFixed(1)}%'),
        ),
        const SizedBox(height: 6),
        Text('Updated $mins mins ago'),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.value});

  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 12);
    final radius = math.min(size.width / 2 - 10, size.height - 10);
    const start = math.pi;
    const totalSweep = math.pi;

    void drawZone(double from, double to, Color color) {
      final paint = Paint()
        ..color = color
        ..strokeWidth = 14
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start + totalSweep * (from / 100),
        totalSweep * ((to - from) / 100),
        false,
        paint,
      );
    }

    drawZone(0, 30, Colors.green);
    drawZone(30, 60, Colors.yellow.shade700);
    drawZone(60, 80, Colors.orange);
    drawZone(80, 100, Colors.red);

    final pointerSweep = totalSweep * (value / 100);
    final pointerAngle = start + pointerSweep;
    final pointerEnd = Offset(
      center.dx + radius * math.cos(pointerAngle),
      center.dy + radius * math.sin(pointerAngle),
    );

    final pointerPaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, pointerEnd, pointerPaint);
    canvas.drawCircle(center, 5, Paint()..color = Colors.black87);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.value != value;
}
