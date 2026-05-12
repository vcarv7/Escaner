import 'dart:math';
import 'package:flutter/material.dart';

class MathCurveLoader extends StatefulWidget {
  final double size;
  final Color color;
  final Duration duration;
  final double outerRadius;
  final double innerRadius;
  final int particleCount;
  final double trailSpan;
  final double strokeWidth;
  final bool animate;
  final bool reverse;

  const MathCurveLoader.epicycloid({
    super.key,
    this.size = 220,
    this.color = const Color(0xFF141210),
    this.duration = const Duration(milliseconds: 1800),
    this.outerRadius = 18.0,
    this.innerRadius = 7.0,
    this.particleCount = 80,
    this.trailSpan = 0.46,
    this.strokeWidth = 5.5,
    this.animate = true,
    this.reverse = false,
  });

  @override
  State<MathCurveLoader> createState() => _MathCurveLoaderState();
}

class _MathCurveLoaderState extends State<MathCurveLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _EpicycloidPainter(
            progress: widget.reverse ? 1 - _controller.value : _controller.value,
            color: widget.color,
            outerRadius: widget.outerRadius,
            innerRadius: widget.innerRadius,
            particleCount: widget.particleCount,
            trailSpan: widget.trailSpan,
            strokeWidth: widget.strokeWidth,
          ),
        );
      },
    );
  }
}

class _EpicycloidPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double outerRadius;
  final double innerRadius;
  final int particleCount;
  final double trailSpan;
  final double strokeWidth;

  _EpicycloidPainter({
    required this.progress,
    required this.color,
    required this.outerRadius,
    required this.innerRadius,
    required this.particleCount,
    required this.trailSpan,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final scale = (size.width / 2 - strokeWidth) / (outerRadius + innerRadius);

    for (int i = 0; i < particleCount; i++) {
      final offset = i / (particleCount - 1);
      final pointProgress = (progress - offset * trailSpan + 1) % 1;

      final t = pointProgress * 2 * pi;
      final k = innerRadius / outerRadius;

      final x = (outerRadius + innerRadius) * cos(t) - innerRadius * cos((1 + k) * t);
      final y = (outerRadius + innerRadius) * sin(t) - innerRadius * sin((1 + k) * t);

      final fade = pow(1 - offset, 2).toDouble();
      final particlePaint = Paint()
        ..color = color.withAlpha((fade * 255).toInt())
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(center.dx + x * scale, center.dy + y * scale),
        strokeWidth / 2 * fade + 1,
        particlePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_EpicycloidPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.outerRadius != outerRadius ||
        oldDelegate.innerRadius != innerRadius ||
        oldDelegate.particleCount != particleCount ||
        oldDelegate.trailSpan != trailSpan ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}