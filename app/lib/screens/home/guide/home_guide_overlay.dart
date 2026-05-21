import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'home_guide_controller.dart';

const String _guideFingerAsset = 'assets/images/ui/login/finger1.png';

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
    final preview = _previewRectFor(safeAnchor, screenSize);
    final bubble = _bubbleRectFor(preview, screenSize);
    final pointer = _pointerRectFor(safeAnchor, preview);

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
                  child: _GuideHotspotGlow(step: step),
                ),
              ),
              Positioned.fromRect(
                rect: pointer,
                child: IgnorePointer(
                  child: _GuideFinger(
                    flipX: pointer.center.dx < safeAnchor.center.dx,
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _GuideArrowPainter(
                      start: safeAnchor.center,
                      end: preview.center,
                    ),
                  ),
                ),
              ),
              Positioned.fromRect(
                rect: preview,
                child: IgnorePointer(child: _GuidePreviewCard(step: step)),
              ),
              Positioned.fromRect(
                rect: bubble,
                child: _GuideBubble(
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

  Rect _previewRectFor(Rect anchor, Size size) {
    const margin = 18.0;
    final compact = size.width < 520;
    final width = compact
        ? math.min(size.width * 0.46, 178.0)
        : math.min(size.width * 0.30, 238.0);
    final height = switch (step) {
      HomeGuideStep.taskSticker => width * 1.04,
      HomeGuideStep.familyFrame => width * 0.86,
      HomeGuideStep.petArea => width * 0.78,
      HomeGuideStep.done => width * 0.72,
    };

    var left = anchor.center.dx < size.width * 0.56
        ? anchor.right + 28
        : anchor.left - width - 28;
    if (left < margin || left + width > size.width - margin) {
      left = anchor.center.dx - width * 0.5;
    }

    var top = anchor.center.dy - height * 0.46;

    left = left
        .clamp(margin, math.max(margin, size.width - width - margin))
        .toDouble();
    top = top
        .clamp(margin + 8, math.max(margin + 8, size.height - height - 112))
        .toDouble();

    return Rect.fromLTWH(left, top, width, height);
  }

  Rect _bubbleRectFor(Rect preview, Size size) {
    const margin = 18.0;
    final width = math.min(size.width - (margin * 2), 320.0);
    const height = 104.0;
    var left = preview.center.dx - width * 0.5;
    var top = preview.bottom + 14;
    if (top + height > size.height - margin) {
      top = preview.top - height - 14;
    }

    left = left.clamp(margin, size.width - width - margin).toDouble();
    top = top
        .clamp(margin + 8, math.max(margin + 8, size.height - height - margin))
        .toDouble();
    return Rect.fromLTWH(left, top, width, height);
  }

  Rect _pointerRectFor(Rect anchor, Rect preview) {
    const size = 66.0;
    final fromLeft = preview.center.dx > anchor.center.dx;
    final left = fromLeft ? anchor.right - 8 : anchor.left - size + 8;
    final top = anchor.center.dy - size * 0.34;
    return Rect.fromLTWH(left, top, size, size);
  }

  String _messageFor(HomeGuideStep step) {
    return switch (step) {
      HomeGuideStep.taskSticker => '点击这里打开任务面板',
      HomeGuideStep.familyFrame => '点击这里管理家庭成员',
      HomeGuideStep.petArea => '点击宠物查看成长',
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
    required this.message,
    required this.stepLabel,
    required this.onSkip,
  });

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
                    message,
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
            const Spacer(),
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

class _GuideFinger extends StatefulWidget {
  const _GuideFinger({required this.flipX});

  final bool flipX;

  @override
  State<_GuideFinger> createState() => _GuideFingerState();
}

class _GuideFingerState extends State<_GuideFinger>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1150),
  )..repeat(reverse: true);

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
        final press = Curves.easeInOut.transform(_controller.value);
        final matrix = Matrix4.identity()
          ..translateByDouble(
            widget.flipX ? 8.0 - press * 6 : press * 6,
            press * 5,
            0,
            1,
          )
          ..scaleByDouble(widget.flipX ? -1.0 : 1.0, 1.0, 1.0, 1.0);
        return Transform(
          alignment: Alignment.center,
          transform: matrix,
          child: child,
        );
      },
      child: Image.asset(
        _guideFingerAsset,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}

class _GuideHotspotGlow extends StatelessWidget {
  const _GuideHotspotGlow({required this.step});

  final HomeGuideStep step;

  @override
  Widget build(BuildContext context) {
    final asset = switch (step) {
      HomeGuideStep.taskSticker =>
        'assets/images/ui/guide/hotspot_task_sticker_highlight.png',
      HomeGuideStep.familyFrame =>
        'assets/images/ui/guide/hotspot_family_frame_highlight.png',
      HomeGuideStep.petArea =>
        'assets/images/ui/guide/hotspot_pet_highlight.png',
      HomeGuideStep.done => 'assets/images/ui/guide/guide_glow_soft.png',
    };

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.92, end: 1.06),
      duration: const Duration(milliseconds: 1350),
      curve: Curves.easeInOut,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      onEnd: () {},
      child: DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD976).withValues(alpha: 0.55),
              blurRadius: 28,
              spreadRadius: 8,
            ),
          ],
        ),
        child: Image.asset(
          asset,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}

class _GuidePreviewCard extends StatelessWidget {
  const _GuidePreviewCard({required this.step});

  final HomeGuideStep step;

  @override
  Widget build(BuildContext context) {
    return switch (step) {
      HomeGuideStep.taskSticker => const _TaskPanelPreview(),
      HomeGuideStep.familyFrame => const _FamilyAlbumPreview(),
      HomeGuideStep.petArea => const _PetGrowthPreview(),
      HomeGuideStep.done => const SizedBox.shrink(),
    };
  }
}

class _MiniPaperPanel extends StatelessWidget {
  const _MiniPaperPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6E5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4BF83), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6D4A2E).withValues(alpha: 0.16),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _TaskPanelPreview extends StatelessWidget {
  const _TaskPanelPreview();

  @override
  Widget build(BuildContext context) {
    return _MiniPaperPanel(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _PreviewHeader(widthFactor: 0.66),
            const SizedBox(height: 10),
            const _PreviewTaskRow(color: Color(0xFFFFD882), widthFactor: 0.82),
            const SizedBox(height: 7),
            const _PreviewTaskRow(color: Color(0xFFFFB7C6), widthFactor: 0.68),
            const SizedBox(height: 7),
            const _PreviewTaskRow(color: Color(0xFFAEE3CF), widthFactor: 0.74),
            const Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                width: 34,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD976),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FamilyAlbumPreview extends StatelessWidget {
  const _FamilyAlbumPreview();

  @override
  Widget build(BuildContext context) {
    return _MiniPaperPanel(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: const [
            _PreviewMemberCard(color: Color(0xFFFFD8E0)),
            _PreviewMemberCard(color: Color(0xFFDFF1CB)),
            _PreviewMemberCard(color: Color(0xFFDDEBFF), empty: true),
            _PreviewMemberCard(color: Color(0xFFFFE4A8), add: true),
          ],
        ),
      ),
    );
  }
}

class _PetGrowthPreview extends StatelessWidget {
  const _PetGrowthPreview();

  @override
  Widget build(BuildContext context) {
    return _MiniPaperPanel(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFFE4C2),
              ),
              child: const Icon(
                Icons.pets_rounded,
                color: Color(0xFF9D7653),
                size: 30,
              ),
            ),
            const SizedBox(height: 12),
            const _PreviewHeader(widthFactor: 0.72),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LinearProgressIndicator(
                minHeight: 10,
                value: 0.62,
                backgroundColor: const Color(0xFFFFE8C7),
                valueColor: const AlwaysStoppedAnimation(Color(0xFFFFC95D)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewHeader extends StatelessWidget {
  const _PreviewHeader({required this.widthFactor});

  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: 10,
        decoration: BoxDecoration(
          color: const Color(0xFFE7C795),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class _PreviewTaskRow extends StatelessWidget {
  const _PreviewTaskRow({required this.color, required this.widthFactor});

  final Color color;
  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(color: const Color(0xFFD2A76E), width: 1),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: widthFactor,
            child: Container(
              height: 9,
              decoration: BoxDecoration(
                color: const Color(0xFFD8B88E),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PreviewMemberCard extends StatelessWidget {
  const _PreviewMemberCard({
    required this.color,
    this.empty = false,
    this.add = false,
  });

  final Color color;
  final bool empty;
  final bool add;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: empty ? 0.42 : 0.72),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0BC84), width: 1),
      ),
      child: Center(
        child: Icon(
          add ? Icons.add_rounded : (empty ? Icons.help_outline : Icons.pets),
          size: 22,
          color: const Color(0xFF9D7653),
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
      Paint()..color = const Color(0xFF3A2517).withValues(alpha: 0.08),
    );
    canvas.drawOval(
      anchorRect.inflate(30),
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

class _GuideArrowPainter extends CustomPainter {
  const _GuideArrowPainter({required this.start, required this.end});

  final Offset start;
  final Offset end;

  @override
  void paint(Canvas canvas, Size size) {
    final delta = end - start;
    if (delta.distance < 12) {
      return;
    }

    final direction = delta / delta.distance;
    final from = start + direction * 34;
    final to = end - direction * 34;
    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..quadraticBezierTo(
        (from.dx + to.dx) * 0.5,
        (from.dy + to.dy) * 0.5 - 22,
        to.dx,
        to.dy,
      );

    final shadowPaint = Paint()
      ..color = const Color(0xFF6D4A2E).withValues(alpha: 0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final paint = Paint()
      ..color = const Color(0xFFFFF3C2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    _drawDashedPath(canvas, path, shadowPaint, 10, 8);
    _drawDashedPath(canvas, path, paint, 10, 8);

    final arrowAngle = math.atan2(delta.dy, delta.dx);
    final arrowPath = Path()
      ..moveTo(to.dx, to.dy)
      ..lineTo(
        to.dx - math.cos(arrowAngle - 0.55) * 13,
        to.dy - math.sin(arrowAngle - 0.55) * 13,
      )
      ..moveTo(to.dx, to.dy)
      ..lineTo(
        to.dx - math.cos(arrowAngle + 0.55) * 13,
        to.dy - math.sin(arrowAngle + 0.55) * 13,
      );
    canvas.drawPath(arrowPath, shadowPaint);
    canvas.drawPath(arrowPath, paint);
  }

  void _drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint,
    double dash,
    double gap,
  ) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = math.min(distance + dash, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GuideArrowPainter oldDelegate) {
    return oldDelegate.start != start || oldDelegate.end != end;
  }
}
