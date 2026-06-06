import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'home_guide_controller.dart';

const String _guideFingerAsset = 'assets/images/ui/login/finger1.png';
const String _guideBubbleAsset = 'assets/images/ui/login/bubble.png';
const double _guideFingerSize = 76.0;
const Color _guideScrimColor = Color(0x2E000000);
const double _guideBubbleMinWidth = 184.0;
const double _guideBubbleMaxWidth = 224.0;
const double _guideBubbleWidthFactor = 0.54;
const double _guideBubbleAspectRatio = 1024 / 1536;
const double _guideBubbleTailYFraction = 0.70;
const double _guideBubbleFingerGap = 12.0;
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
    required this.hotspotRect,
    required this.bubbleRect,
    required this.bubbleTailOnRight,
    required this.fingerRect,
  });

  final _HomeGuideSpec spec;
  final Rect targetRect;
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
    this.targetAssetPath,
    this.targetAssetCropRect,
    required this.onHotspotTap,
    required this.onSkip,
  });

  final HomeGuideStep step;
  final Rect anchorRect;
  final Size screenSize;
  final String? targetAssetPath;
  final Rect? targetAssetCropRect;
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
            Positioned.fill(
              child: IgnorePointer(
                child: KeyedSubtree(
                  key: const ValueKey('home_guide_background_scrim'),
                  child: const _GuideObjectGlow(
                    key: ValueKey('home_guide_target_glow'),
                  ),
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
            final maxMessageFontSize = (constraints.maxWidth * 0.104)
                .clamp(17.0, 22.0)
                .toDouble();
            final leftPadding =
                constraints.maxWidth * (tailOnRight ? 0.22 : 0.24);
            final topPadding = constraints.maxHeight * 0.22;
            final rightPadding =
                constraints.maxWidth * (tailOnRight ? 0.28 : 0.22);
            final bottomPadding = constraints.maxHeight * 0.26;
            final baseStyle = TextStyle(
              color: const Color(0xFF6B4C36),
              fontSize: maxMessageFontSize,
              fontWeight: FontWeight.w900,
              height: 1.12,
            );
            final messageFontSize = _fitGuideBubbleFontSize(
              copy: copy,
              baseStyle: baseStyle,
              textDirection:
                  Directionality.maybeOf(context) ?? TextDirection.ltr,
              maxWidth: math.max(
                1.0,
                constraints.maxWidth - leftPadding - rightPadding,
              ),
              maxHeight: math.max(
                1.0,
                constraints.maxHeight - topPadding - bottomPadding,
              ),
              minFontSize: 13.0,
            );
            return Padding(
              padding: EdgeInsets.fromLTRB(
                leftPadding,
                topPadding,
                rightPadding,
                bottomPadding,
              ),
              child: Center(
                child: RichText(
                  key: const ValueKey('home_guide_bubble_message'),
                  maxLines: 2,
                  overflow: TextOverflow.visible,
                  softWrap: false,
                  textAlign: TextAlign.center,
                  textWidthBasis: TextWidthBasis.longestLine,
                  textScaler: TextScaler.noScaling,
                  text: copy.toTextSpan(
                    baseStyle.copyWith(fontSize: messageFontSize),
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

double _fitGuideBubbleFontSize({
  required _GuideBubbleCopy copy,
  required TextStyle baseStyle,
  required TextDirection textDirection,
  required double maxWidth,
  required double maxHeight,
  required double minFontSize,
}) {
  final maxFontSize = baseStyle.fontSize ?? 18.0;
  var fontSize = maxFontSize;
  while (fontSize > minFontSize) {
    final painter = TextPainter(
      text: copy.toTextSpan(baseStyle.copyWith(fontSize: fontSize)),
      textDirection: textDirection,
      textAlign: TextAlign.center,
      maxLines: 2,
      textScaler: TextScaler.noScaling,
    )..layout(maxWidth: double.infinity);
    final fits = painter.width <= maxWidth && painter.height <= maxHeight;
    painter.dispose();
    if (fits) {
      return fontSize;
    }
    fontSize -= 0.5;
  }
  return minFontSize;
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

class _GuideObjectGlow extends StatelessWidget {
  const _GuideObjectGlow({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(painter: _GuideObjectGlowPainter());
  }
}

class _GuideObjectGlowPainter extends CustomPainter {
  const _GuideObjectGlowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }

    canvas.drawRect(Offset.zero & size, Paint()..color = _guideScrimColor);
  }

  @override
  bool shouldRepaint(covariant _GuideObjectGlowPainter oldDelegate) => false;
}
