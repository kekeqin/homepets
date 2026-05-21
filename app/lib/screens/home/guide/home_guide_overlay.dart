import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'home_guide_controller.dart';

class HomeGuideOverlay extends StatelessWidget {
  const HomeGuideOverlay({
    super.key,
    required this.step,
    required this.anchorRect,
    required this.screenSize,
    required this.onHotspotTap,
    required this.onSkip,
  });

  final HomeGuideStep step;
  final Rect anchorRect;
  final Size screenSize;
  final VoidCallback onHotspotTap;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final safeAnchor = _clampAnchor(anchorRect, screenSize);
    final bubble = _bubbleRectFor(safeAnchor, screenSize);
    final pointer = _pointerOffsetFor(safeAnchor, bubble);

    return SizedBox.expand(
      child: IgnorePointer(
        ignoring: false,
        child: Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _GuideScrimPainter(anchorRect: safeAnchor),
                ),
              ),
              Positioned.fromRect(
                rect: safeAnchor.inflate(16),
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: onHotspotTap,
                  child: CustomPaint(
                    painter: _GuideGlowPainter(),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
              Positioned(
                left: pointer.dx,
                top: pointer.dy,
                child: IgnorePointer(
                  child: _GuidePointer(
                    angle: _pointerAngleFor(safeAnchor, bubble),
                  ),
                ),
              ),
              Positioned.fromRect(
                rect: bubble,
                child: _GuideBubble(
                  title: _titleFor(step),
                  message: _messageFor(step),
                  stepLabel: _stepLabelFor(step),
                  onSkip: onSkip,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Rect _clampAnchor(Rect rect, Size size) {
    if (size.isEmpty) {
      return rect;
    }
    final width = rect.width.clamp(48.0, size.width).toDouble();
    final height = rect.height.clamp(48.0, size.height).toDouble();
    final left = rect.left
        .clamp(0.0, math.max(0.0, size.width - width))
        .toDouble();
    final top = rect.top
        .clamp(0.0, math.max(0.0, size.height - height))
        .toDouble();
    return Rect.fromLTWH(left, top, width, height);
  }

  Rect _bubbleRectFor(Rect anchor, Size size) {
    const horizontalPadding = 18.0;
    const verticalPadding = 20.0;
    final width = math.min(size.width - (horizontalPadding * 2), 330.0);
    const height = 150.0;
    final preferBelow = anchor.center.dy < size.height * 0.55;
    var left = anchor.center.dx - (width * 0.5);
    var top = preferBelow ? anchor.bottom + 26 : anchor.top - height - 26;

    left = left
        .clamp(horizontalPadding, size.width - width - horizontalPadding)
        .toDouble();
    top = top
        .clamp(
          verticalPadding + 8,
          math.max(verticalPadding + 8, size.height - height - verticalPadding),
        )
        .toDouble();

    return Rect.fromLTWH(left, top, width, height);
  }

  Offset _pointerOffsetFor(Rect anchor, Rect bubble) {
    final midpoint = Offset.lerp(anchor.center, bubble.center, 0.44)!;
    return midpoint - const Offset(22, 22);
  }

  double _pointerAngleFor(Rect anchor, Rect bubble) {
    final delta = anchor.center - bubble.center;
    return math.atan2(delta.dy, delta.dx) + (math.pi / 4);
  }

  String _titleFor(HomeGuideStep step) {
    return switch (step) {
      HomeGuideStep.taskSticker => '任务入口',
      HomeGuideStep.familyFrame => '家庭相册',
      HomeGuideStep.petArea => '宠物伙伴',
      HomeGuideStep.done => '',
    };
  }

  String _messageFor(HomeGuideStep step) {
    return switch (step) {
      HomeGuideStep.taskSticker => '点贴纸查看任务',
      HomeGuideStep.familyFrame => '点相框管理家庭',
      HomeGuideStep.petArea => '完成任务后宠物会回应你',
      HomeGuideStep.done => '',
    };
  }

  String _stepLabelFor(HomeGuideStep step) {
    return switch (step) {
      HomeGuideStep.familyFrame => '1/3',
      HomeGuideStep.taskSticker => '2/3',
      HomeGuideStep.petArea => '3/3',
      HomeGuideStep.done => '',
    };
  }
}

class _GuideBubble extends StatelessWidget {
  const _GuideBubble({
    required this.title,
    required this.message,
    required this.stepLabel,
    required this.onSkip,
  });

  final String title;
  final String message;
  final String stepLabel;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5C48D), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6D4A2E).withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF6B4C36),
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                ),
                Text(
                  stepLabel,
                  style: const TextStyle(
                    color: Color(0xFF9D7653),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF7A5C42),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.28,
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: TextButton(
                onPressed: onSkip,
                style: TextButton.styleFrom(
                  minimumSize: const Size(64, 34),
                  foregroundColor: const Color(0xFF8E6748),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                child: const Text('稍后再看'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuidePointer extends StatelessWidget {
  const _GuidePointer({required this.angle});

  final double angle;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7E4),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE9C57D), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6D4A2E).withValues(alpha: 0.18),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Text('☝', style: TextStyle(fontSize: 24, height: 1)),
          ),
        ),
      ),
    );
  }
}

class _GuideScrimPainter extends CustomPainter {
  const _GuideScrimPainter({required this.anchorRect});

  final Rect anchorRect;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF3A2517).withValues(alpha: 0.10),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        anchorRect.inflate(18),
        const Radius.circular(28),
      ),
      Paint()
        ..blendMode = BlendMode.clear
        ..color = Colors.transparent,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GuideScrimPainter oldDelegate) {
    return oldDelegate.anchorRect != anchorRect;
  }
}

class _GuideGlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(4),
      const Radius.circular(28),
    );
    final glowPaint = Paint()
      ..color = const Color(0xFFFFD976).withValues(alpha: 0.34)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    final borderPaint = Paint()
      ..color = const Color(0xFFFFD976).withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2;
    canvas.drawRRect(rrect, glowPaint);
    canvas.drawRRect(rrect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
