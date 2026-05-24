import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'home_guide_controller.dart';

const String _guideFingerAsset = 'assets/images/ui/login/finger1.png';
const String _guideBubbleAsset = 'assets/images/ui/login/bubble.png';
const double _guideFingerSize = 76.0;
const double _guideTargetGlowOutset = 14.0;
const double _guideBubbleMinWidth = 244.0;
const double _guideBubbleMaxWidth = 268.0;
const double _guideBubbleWidthFactor = 0.62;
const double _guideBubbleAspectRatio = 1024 / 1536;
const double _guideBubbleTailYFraction = 0.70;
const double _guideBubbleFingerGap = 20.0;
// finger1.png is 176x169; the visible fingertip is near pixel (41, 33).
const Offset _guideFingerTipFraction = Offset(0.235, 0.207);

typedef _GuideFingerTargetResolver = Offset Function(Rect targetRect);

class _GuideTextSegment {
  const _GuideTextSegment(this.text, {this.highlight = false});

  final String text;
  final bool highlight;
}

class _GuideBubbleCopy {
  const _GuideBubbleCopy(this.segments);

  final List<_GuideTextSegment> segments;

  TextSpan toTextSpan(TextStyle baseStyle) {
    const highlightStyle = TextStyle(color: Color(0xFFD8665B));
    return TextSpan(
      children: [
        for (final segment in segments)
          TextSpan(
            text: segment.text,
            style: segment.highlight
                ? baseStyle.merge(highlightStyle)
                : baseStyle,
          ),
      ],
    );
  }
}

class _HomeGuideSpec {
  const _HomeGuideSpec({
    required this.step,
    required this.fingerTargetResolver,
    required this.hotspotInflate,
    required this.bubbleCopy,
  });

  final HomeGuideStep step;
  final _GuideFingerTargetResolver fingerTargetResolver;
  final double hotspotInflate;
  final _GuideBubbleCopy bubbleCopy;

  static _HomeGuideSpec forStep(HomeGuideStep step) {
    return switch (step) {
      HomeGuideStep.taskSticker => _taskSticker,
      HomeGuideStep.familyFrame => _familyFrame,
      HomeGuideStep.petArea => _petArea,
      HomeGuideStep.done => _done,
    };
  }

  static final _taskSticker = _HomeGuideSpec(
    step: HomeGuideStep.taskSticker,
    fingerTargetResolver: (target) => target.bottomRight - const Offset(2, 2),
    hotspotInflate: 20,
    bubbleCopy: const _GuideBubbleCopy([
      _GuideTextSegment('点击这里打开\n'),
      _GuideTextSegment('任务', highlight: true),
      _GuideTextSegment('面板'),
    ]),
  );

  static final _familyFrame = _HomeGuideSpec(
    step: HomeGuideStep.familyFrame,
    fingerTargetResolver: (target) => target.bottomRight - const Offset(2, 2),
    hotspotInflate: 20,
    bubbleCopy: const _GuideBubbleCopy([
      _GuideTextSegment('点击这里管理\n'),
      _GuideTextSegment('家庭成员', highlight: true),
    ]),
  );

  static final _petArea = _HomeGuideSpec(
    step: HomeGuideStep.petArea,
    fingerTargetResolver: (target) =>
        target.center + Offset(target.width * 0.12, target.height * 0.16),
    hotspotInflate: 10,
    bubbleCopy: const _GuideBubbleCopy([
      _GuideTextSegment('点这里查看\n'),
      _GuideTextSegment('宠物详情', highlight: true),
    ]),
  );

  static final _done = _HomeGuideSpec(
    step: HomeGuideStep.done,
    fingerTargetResolver: (target) => target.center,
    hotspotInflate: 0,
    bubbleCopy: const _GuideBubbleCopy([]),
  );
}

class _HomeGuideLayout {
  const _HomeGuideLayout({
    required this.spec,
    required this.targetRect,
    required this.glowRect,
    required this.hotspotRect,
    required this.bubbleRect,
    required this.bubbleTailOnRight,
    required this.fingerRect,
  });

  final _HomeGuideSpec spec;
  final Rect targetRect;
  final Rect glowRect;
  final Rect hotspotRect;
  final Rect bubbleRect;
  final bool bubbleTailOnRight;
  final Rect fingerRect;
}

class _GuideBubblePlacement {
  const _GuideBubblePlacement({required this.rect, required this.tailOnRight});

  final Rect rect;
  final bool tailOnRight;
}

class _HomeGuideLayoutResolver {
  const _HomeGuideLayoutResolver._();

  static _HomeGuideLayout resolve({
    required HomeGuideStep step,
    required Rect anchorRect,
    required Size screenSize,
  }) {
    final spec = _HomeGuideSpec.forStep(step);
    final targetRect = _clampTarget(anchorRect, screenSize);
    final fingerRect = _fingerRectFor(
      targetPoint: spec.fingerTargetResolver(targetRect),
      screenSize: screenSize,
    );
    final bubble = _bubblePlacementFor(
      spec: spec,
      targetRect: targetRect,
      fingerRect: fingerRect,
      screenSize: screenSize,
    );
    return _HomeGuideLayout(
      spec: spec,
      targetRect: targetRect,
      glowRect: _clampLooseRect(
        targetRect.inflate(_guideTargetGlowOutset),
        screenSize,
      ),
      hotspotRect: targetRect.inflate(spec.hotspotInflate),
      bubbleRect: bubble.rect,
      bubbleTailOnRight: bubble.tailOnRight,
      fingerRect: fingerRect,
    );
  }

  static Rect _clampTarget(Rect rect, Size size) {
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

  static Rect _clampLooseRect(Rect rect, Size size) {
    if (size.isEmpty) {
      return rect;
    }
    final left = math.max(0.0, rect.left);
    final top = math.max(0.0, rect.top);
    final right = math.min(size.width, rect.right);
    final bottom = math.min(size.height, rect.bottom);
    if (right <= left || bottom <= top) {
      return rect;
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }

  static _GuideBubblePlacement _bubblePlacementFor({
    required _HomeGuideSpec spec,
    required Rect targetRect,
    required Rect fingerRect,
    required Size screenSize,
  }) {
    const margin = 14.0;
    final width = (screenSize.width * _guideBubbleWidthFactor)
        .clamp(_guideBubbleMinWidth, _guideBubbleMaxWidth)
        .toDouble();
    final height = width * _guideBubbleAspectRatio;
    final maxLeft = math.max(margin, screenSize.width - width - margin);
    final maxTop = math.max(margin, screenSize.height - height - margin);
    final targetPoint = spec.fingerTargetResolver(targetRect);
    final targetSafeRect = targetRect.inflate(spec.hotspotInflate + 12);
    _GuideBubblePlacement? best;
    double? bestScore;

    for (final tailOnRight in const <bool>[false, true]) {
      final idealLeft = tailOnRight
          ? fingerRect.left - width - _guideBubbleFingerGap
          : fingerRect.right + _guideBubbleFingerGap;
      for (final yOffset in <double>[
        0,
        -height * 0.40,
        height * 0.40,
        -height * 0.78,
        height * 0.78,
      ]) {
        final left = idealLeft.clamp(margin, maxLeft).toDouble();
        final top =
            (targetPoint.dy - (height * _guideBubbleTailYFraction) + yOffset)
                .clamp(margin, maxTop)
                .toDouble();
        final rect = Rect.fromLTWH(left, top, width, height);
        final tailPoint = Offset(
          tailOnRight ? rect.right : rect.left,
          rect.top + rect.height * _guideBubbleTailYFraction,
        );
        final overlap = _intersectionArea(rect, targetSafeRect);
        final centerPenalty = rect.contains(targetSafeRect.center)
            ? 3000.0
            : 0.0;
        final tailDistance = (tailPoint - targetPoint).distance;
        final sideClampDistance = (left - idealLeft).abs();
        final sidePenalty = tailOnRight ? 8.0 : 0.0;
        final score =
            centerPenalty +
            (overlap * 0.05) +
            (tailDistance * 6) +
            sideClampDistance +
            sidePenalty;
        if (bestScore == null || score < bestScore) {
          bestScore = score;
          best = _GuideBubblePlacement(rect: rect, tailOnRight: tailOnRight);
        }
      }
    }

    return best!;
  }

  static double _intersectionArea(Rect a, Rect b) {
    final intersection = a.intersect(b);
    if (intersection.isEmpty) {
      return 0;
    }
    return intersection.width * intersection.height;
  }

  static Rect _fingerRectFor({
    required Offset targetPoint,
    required Size screenSize,
  }) {
    final safeTargetPoint = Offset(
      targetPoint.dx.clamp(8.0, math.max(8.0, screenSize.width - 8)),
      targetPoint.dy.clamp(8.0, math.max(8.0, screenSize.height - 8)),
    );
    final left =
        safeTargetPoint.dx - _guideFingerSize * _guideFingerTipFraction.dx;
    final top =
        safeTargetPoint.dy - _guideFingerSize * _guideFingerTipFraction.dy;
    return Rect.fromLTWH(left, top, _guideFingerSize, _guideFingerSize);
  }
}

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
    final layout = _HomeGuideLayoutResolver.resolve(
      step: step,
      anchorRect: anchorRect,
      screenSize: screenSize,
    );

    return SizedBox.expand(
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            Positioned.fromRect(
              rect: layout.glowRect,
              child: IgnorePointer(
                child: _GuideObjectGlow(
                  key: const ValueKey('home_guide_target_glow'),
                  step: step,
                ),
              ),
            ),
            Positioned.fromRect(
              rect: layout.hotspotRect,
              child: GestureDetector(
                key: const ValueKey('home_guide_hotspot'),
                behavior: HitTestBehavior.translucent,
                onTap: onHotspotTap,
                child: const SizedBox.expand(),
              ),
            ),
            Positioned.fromRect(
              rect: layout.bubbleRect,
              child: IgnorePointer(
                child: SizedBox.expand(
                  key: const ValueKey('home_guide_bubble'),
                  child: _GuideBubble(
                    copy: layout.spec.bubbleCopy,
                    tailOnRight: layout.bubbleTailOnRight,
                  ),
                ),
              ),
            ),
            Positioned.fromRect(
              rect: layout.fingerRect,
              child: IgnorePointer(
                child: SizedBox.expand(
                  key: const ValueKey('home_guide_finger'),
                  child: const _GuideFinger(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideBubble extends StatelessWidget {
  const _GuideBubble({required this.copy, required this.tailOnRight});

  final _GuideBubbleCopy copy;
  final bool tailOnRight;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Transform.scale(
          scaleX: tailOnRight ? -1 : 1,
          child: Image.asset(
            _guideBubbleAsset,
            key: const ValueKey('home_guide_bubble_image'),
            fit: BoxFit.fill,
            filterQuality: FilterQuality.medium,
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final messageFontSize = (constraints.maxWidth * 0.083)
                .clamp(21.0, 23.0)
                .toDouble();
            return Padding(
              padding: EdgeInsets.fromLTRB(
                constraints.maxWidth * (tailOnRight ? 0.16 : 0.20),
                constraints.maxHeight * 0.20,
                constraints.maxWidth * (tailOnRight ? 0.20 : 0.16),
                constraints.maxHeight * 0.24,
              ),
              child: Center(
                child: RichText(
                  key: const ValueKey('home_guide_bubble_message'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  text: copy.toTextSpan(
                    TextStyle(
                      color: const Color(0xFF6B4C36),
                      fontSize: messageFontSize,
                      fontWeight: FontWeight.w900,
                      height: 1.12,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _GuideFinger extends StatefulWidget {
  const _GuideFinger();

  @override
  State<_GuideFinger> createState() => _GuideFingerState();
}

class _GuideFingerState extends State<_GuideFinger>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 920),
  )..repeat();

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
        final cycle = _controller.value;
        final press = cycle < 0.46
            ? Curves.easeOutCubic.transform(cycle / 0.46)
            : Curves.easeInCubic.transform((1 - cycle) / 0.54);
        final scale = 1 - (press * 0.055);
        return Transform.rotate(
          angle: press * 0.018,
          alignment: FractionalOffset(
            _guideFingerTipFraction.dx,
            _guideFingerTipFraction.dy,
          ),
          child: Transform.scale(
            scale: scale,
            alignment: FractionalOffset(
              _guideFingerTipFraction.dx,
              _guideFingerTipFraction.dy,
            ),
            child: CustomPaint(
              foregroundPainter: _GuideFingerTapPainter(progress: cycle),
              child: Opacity(opacity: 0.94 + press * 0.06, child: child),
            ),
          ),
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

class _GuideFingerTapPainter extends CustomPainter {
  const _GuideFingerTapPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }

    final pulse = progress < 0.56 ? progress / 0.56 : 0.0;
    if (pulse <= 0 || pulse >= 1) {
      return;
    }

    final center = Offset(
      size.width * _guideFingerTipFraction.dx,
      size.height * _guideFingerTipFraction.dy,
    );
    final eased = Curves.easeOutCubic.transform(pulse);
    final radius =
        ui.lerpDouble(
          size.shortestSide * 0.05,
          size.shortestSide * 0.16,
          eased,
        ) ??
        size.shortestSide * 0.12;
    final alpha = (1 - eased) * 0.36;
    final paint = Paint()
      ..color = const Color(0xFFFFF3B0).withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.4, size.shortestSide * 0.028)
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _GuideFingerTapPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _GuideObjectGlow extends StatefulWidget {
  const _GuideObjectGlow({super.key, required this.step});

  final HomeGuideStep step;

  @override
  State<_GuideObjectGlow> createState() => _GuideObjectGlowState();
}

class _GuideObjectGlowState extends State<_GuideObjectGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1550),
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
        final value = Curves.easeInOut.transform(_controller.value);
        return CustomPaint(
          painter: _GuideObjectGlowPainter(
            progress: value,
            shape: _GuideObjectGlowShape.forStep(widget.step),
          ),
        );
      },
    );
  }
}

enum _GuideObjectGlowShape {
  roundedRect,
  oval;

  static _GuideObjectGlowShape forStep(HomeGuideStep step) {
    return switch (step) {
      HomeGuideStep.taskSticker => _GuideObjectGlowShape.roundedRect,
      HomeGuideStep.familyFrame => _GuideObjectGlowShape.roundedRect,
      HomeGuideStep.petArea => _GuideObjectGlowShape.oval,
      HomeGuideStep.done => _GuideObjectGlowShape.oval,
    };
  }
}

class _GuideObjectGlowPainter extends CustomPainter {
  const _GuideObjectGlowPainter({required this.progress, required this.shape});

  final double progress;
  final _GuideObjectGlowShape shape;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }

    final pulse = 0.86 + progress * 0.14;
    final glowRect = Offset.zero & size;
    final glowInset = math.min(
      _guideTargetGlowOutset,
      size.shortestSide * 0.22,
    );
    final shapeRect = glowRect.deflate(glowInset);
    final outerStrokeWidth = math.max(7.0, shapeRect.shortestSide * 0.115);
    final innerStrokeWidth = math.max(3.6, shapeRect.shortestSide * 0.055);
    final coreStrokeWidth = math.max(1.4, shapeRect.shortestSide * 0.020);
    final outerPaint = Paint()
      ..color = const Color(0xFFFFE08A).withValues(alpha: 0.42 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = outerStrokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..blendMode = BlendMode.plus
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7.5);
    final innerPaint = Paint()
      ..color = const Color(0xFFFFF2B8).withValues(alpha: 0.70 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = innerStrokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..blendMode = BlendMode.plus
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.8);
    final corePaint = Paint()
      ..color = const Color(0xFFFFFADE).withValues(alpha: 0.42 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = coreStrokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..blendMode = BlendMode.plus;

    if (shape == _GuideObjectGlowShape.oval) {
      final ovalRect = shapeRect.inflate(1.5);
      canvas.drawOval(ovalRect, outerPaint);
      canvas.drawOval(ovalRect, innerPaint);
      canvas.drawOval(ovalRect, corePaint);
      return;
    }

    final glowTargetRect = shapeRect.inflate(1.2);
    final radiusCorner = Radius.circular(shapeRect.shortestSide * 0.18);
    final targetShape = RRect.fromRectAndRadius(glowTargetRect, radiusCorner);
    canvas.drawRRect(targetShape, outerPaint);
    canvas.drawRRect(targetShape, innerPaint);
    canvas.drawRRect(targetShape, corePaint);
  }

  @override
  bool shouldRepaint(covariant _GuideObjectGlowPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.shape != shape;
  }
}
