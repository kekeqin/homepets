import 'package:flutter/material.dart';

class SourceScaledRRectBorder extends StatelessWidget {
  const SourceScaledRRectBorder({
    super.key,
    required this.sourceSize,
    required this.sourceRect,
    required this.sourceRadius,
    this.color = const Color(0xFF2F2218),
    this.strokeWidth = 2,
  });

  final Size sourceSize;
  final Rect sourceRect;
  final Radius sourceRadius;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SourceScaledRRectBorderPainter(
        sourceSize: sourceSize,
        sourceRect: sourceRect,
        sourceRadius: sourceRadius,
        color: color,
        strokeWidth: strokeWidth,
      ),
    );
  }
}

class _SourceScaledRRectBorderPainter extends CustomPainter {
  const _SourceScaledRRectBorderPainter({
    required this.sourceSize,
    required this.sourceRect,
    required this.sourceRadius,
    required this.color,
    required this.strokeWidth,
  });

  final Size sourceSize;
  final Rect sourceRect;
  final Radius sourceRadius;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 ||
        size.height <= 0 ||
        sourceSize.width <= 0 ||
        sourceSize.height <= 0) {
      return;
    }

    final scaleX = size.width / sourceSize.width;
    final scaleY = size.height / sourceSize.height;
    final rect = Rect.fromLTRB(
      sourceRect.left * scaleX,
      sourceRect.top * scaleY,
      sourceRect.right * scaleX,
      sourceRect.bottom * scaleY,
    ).deflate(strokeWidth / 2);
    if (rect.width <= 0 || rect.height <= 0) {
      return;
    }

    final radius = Radius.elliptical(
      sourceRadius.x * scaleX,
      sourceRadius.y * scaleY,
    );
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), paint);
  }

  @override
  bool shouldRepaint(covariant _SourceScaledRRectBorderPainter oldDelegate) {
    return oldDelegate.sourceSize != sourceSize ||
        oldDelegate.sourceRect != sourceRect ||
        oldDelegate.sourceRadius != sourceRadius ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
