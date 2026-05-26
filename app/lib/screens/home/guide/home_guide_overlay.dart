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
const String _guideAlphaGlowShaderAsset = 'shaders/guide_alpha_glow.frag';
// finger1.png is 176x169; the visible fingertip is near pixel (41, 33).
const Offset _guideFingerTipFraction = Offset(0.235, 0.207);

typedef _GuideFingerTargetResolver = Offset Function(Rect targetRect);

String? _guideFlutterAssetPath(String? assetPath) {
  if (assetPath == null || assetPath.trim().isEmpty) {
    return null;
  }
  final trimmed = assetPath.trim();
  return trimmed.startsWith('assets/') ? trimmed : 'assets/$trimmed';
}

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
            Positioned.fromRect(
              rect: layout.glowRect,
              child: IgnorePointer(
                child: _GuideObjectGlow(
                  key: const ValueKey('home_guide_target_glow'),
                  step: step,
                  targetAssetPath: targetAssetPath,
                  targetAssetCropRect: targetAssetCropRect,
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
  const _GuideObjectGlow({
    super.key,
    required this.step,
    required this.targetAssetPath,
    required this.targetAssetCropRect,
  });

  final HomeGuideStep step;
  final String? targetAssetPath;
  final Rect? targetAssetCropRect;

  @override
  State<_GuideObjectGlow> createState() => _GuideObjectGlowState();
}

class _GuideObjectGlowState extends State<_GuideObjectGlow>
    with SingleTickerProviderStateMixin {
  static bool _shaderLoadStarted = false;
  static ui.FragmentProgram? _shaderProgram;

  ImageStream? _targetImageStream;
  ImageStreamListener? _targetImageListener;
  ui.Image? _targetImage;
  Object? _targetImageKey;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1550),
  )..repeat(reverse: true);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureShaderProgram();
    _resolveTargetImage();
  }

  @override
  void didUpdateWidget(covariant _GuideObjectGlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetAssetPath != widget.targetAssetPath) {
      _resolveTargetImage();
    }
  }

  @override
  void dispose() {
    final listener = _targetImageListener;
    if (listener != null) {
      _targetImageStream?.removeListener(listener);
    }
    _targetImage?.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _resolveTargetImage() {
    final assetPath = _guideFlutterAssetPath(widget.targetAssetPath);
    final nextKey = assetPath;
    if (_targetImageKey == nextKey) {
      return;
    }

    if (_targetImageStream != null && _targetImageListener != null) {
      _targetImageStream!.removeListener(_targetImageListener!);
    }
    _targetImageStream = null;
    _targetImageListener = null;
    _targetImage?.dispose();
    _targetImage = null;
    _targetImageKey = nextKey;

    if (assetPath == null) {
      if (mounted) {
        setState(() {});
      }
      return;
    }

    final provider = AssetImage(assetPath);
    final stream = provider.resolve(createLocalImageConfiguration(context));
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (imageInfo, synchronousCall) {
        final image = imageInfo.image.clone();
        imageInfo.dispose();
        if (!mounted) {
          image.dispose();
          return;
        }
        setState(() {
          _targetImage?.dispose();
          _targetImage = image;
        });
      },
      onError: (Object error, StackTrace? stackTrace) {
        debugPrint('Home guide target image failed to load: $assetPath');
        debugPrint('$error');
      },
    );
    _targetImageStream = stream;
    _targetImageListener = listener;
    stream.addListener(listener);
  }

  void _ensureShaderProgram() {
    if (_shaderLoadStarted || _shaderProgram != null) {
      return;
    }
    _shaderLoadStarted = true;
    ui.FragmentProgram.fromAsset(_guideAlphaGlowShaderAsset)
        .then((program) {
          _shaderProgram = program;
          if (mounted) {
            setState(() {});
          }
        })
        .catchError((Object error, StackTrace stackTrace) {
          debugPrint('Home guide alpha glow shader failed to load.');
          debugPrint('$error');
        });
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
            targetImage: _targetImage,
            targetAssetCropRect: widget.targetAssetCropRect,
            shaderProgram: _shaderProgram,
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
  const _GuideObjectGlowPainter({
    required this.progress,
    required this.shape,
    required this.targetImage,
    required this.targetAssetCropRect,
    required this.shaderProgram,
  });

  final double progress;
  final _GuideObjectGlowShape shape;
  final ui.Image? targetImage;
  final Rect? targetAssetCropRect;
  final ui.FragmentProgram? shaderProgram;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }

    final image = targetImage;
    if (image != null) {
      _paintAssetMaskedGlow(canvas, size, image);
      return;
    }

    _paintFallbackGeometryGlow(canvas, size);
  }

  void _paintAssetMaskedGlow(Canvas canvas, Size size, ui.Image image) {
    final targetRect = _targetRectFor(size);
    if (targetRect.isEmpty) {
      return;
    }

    if (_paintFragmentShaderGlow(
      canvas: canvas,
      size: size,
      image: image,
      targetRect: targetRect,
    )) {
      return;
    }

    _paintImageFilterGlow(canvas, size, image, targetRect);
  }

  bool _paintFragmentShaderGlow({
    required Canvas canvas,
    required Size size,
    required ui.Image image,
    required Rect targetRect,
  }) {
    final program = shaderProgram;
    if (program == null) {
      return false;
    }

    final shader = program.fragmentShader();
    try {
      final sourceRect = _imageSourceRectFor(image);
      shader
        ..getUniformFloat('u_size', 0).set(size.width)
        ..getUniformFloat('u_size', 1).set(size.height)
        ..getUniformFloat('u_target_origin', 0).set(targetRect.left)
        ..getUniformFloat('u_target_origin', 1).set(targetRect.top)
        ..getUniformFloat('u_target_size', 0).set(targetRect.width)
        ..getUniformFloat('u_target_size', 1).set(targetRect.height)
        ..getUniformFloat('u_image_size', 0).set(image.width.toDouble())
        ..getUniformFloat('u_image_size', 1).set(image.height.toDouble())
        ..getUniformFloat('u_source_rect', 0).set(sourceRect.left)
        ..getUniformFloat('u_source_rect', 1).set(sourceRect.top)
        ..getUniformFloat('u_source_rect', 2).set(sourceRect.width)
        ..getUniformFloat('u_source_rect', 3).set(sourceRect.height)
        ..getUniformFloat(
          'u_outline_width',
          0,
        ).set(math.max(3.0, size.shortestSide * 0.092))
        ..getUniformFloat(
          'u_softness',
          0,
        ).set(math.max(1.5, size.shortestSide * 0.036))
        ..getUniformFloat('u_progress', 0).set(progress)
        ..setImageSampler(0, image, filterQuality: FilterQuality.medium);

      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = shader
          ..blendMode = BlendMode.plus,
      );
      return true;
    } catch (error) {
      debugPrint('Home guide alpha glow shader paint failed.');
      debugPrint('$error');
      return false;
    } finally {
      shader.dispose();
    }
  }

  void _paintImageFilterGlow(
    Canvas canvas,
    Size size,
    ui.Image image,
    Rect targetRect,
  ) {
    final pulse = 0.84 + progress * 0.16;
    final imageSourceRect = _imageSourceRectFor(image);
    final layerRect = Offset.zero & size;
    final glowSpread = math.max(4.5, size.shortestSide * 0.092);
    final edgeSpread = math.max(2.0, size.shortestSide * 0.030);
    final edgeWidth = math.max(2.0, size.shortestSide * 0.026);
    final sweepRotation = progress * math.pi * 2;

    canvas.saveLayer(layerRect, Paint()..blendMode = BlendMode.plus);
    _paintMaskPass(
      canvas: canvas,
      paintBounds: layerRect,
      targetRect: targetRect,
      image: image,
      sourceRect: imageSourceRect,
      shader: ui.Gradient.radial(
        targetRect.center,
        math.max(targetRect.width, targetRect.height) * 0.72,
        <Color>[
          const Color(0xFFFFF8CF).withValues(alpha: 0.30 * pulse),
          const Color(0xFFFFDE70).withValues(alpha: 0.46 * pulse),
          const Color(0xFFFFC85A).withValues(alpha: 0.16 * pulse),
          const Color(0xFFFFF8CF).withValues(alpha: 0.00),
        ],
        const <double>[0.0, 0.50, 0.78, 1.0],
      ),
      imageFilter: ui.ImageFilter.compose(
        outer: ui.ImageFilter.blur(
          sigmaX: glowSpread,
          sigmaY: glowSpread,
          tileMode: TileMode.decal,
        ),
        inner: ui.ImageFilter.dilate(radiusX: edgeSpread, radiusY: edgeSpread),
      ),
      opacity: 0.92,
    );
    _paintMaskPass(
      canvas: canvas,
      paintBounds: layerRect,
      targetRect: targetRect,
      image: image,
      sourceRect: imageSourceRect,
      shader: ui.Gradient.sweep(
        targetRect.center,
        <Color>[
          const Color(0xFFFFEF95).withValues(alpha: 0.58 * pulse),
          const Color(0xFFFFFFFF).withValues(alpha: 0.88 * pulse),
          const Color(0xFFFFD05E).withValues(alpha: 0.34 * pulse),
          const Color(0xFFFFFEED).withValues(alpha: 0.78 * pulse),
          const Color(0xFFFFEF95).withValues(alpha: 0.58 * pulse),
        ],
        const <double>[0.0, 0.18, 0.42, 0.62, 1.0],
        TileMode.clamp,
        sweepRotation,
        sweepRotation + math.pi * 2,
      ),
      imageFilter: ui.ImageFilter.dilate(
        radiusX: edgeWidth,
        radiusY: edgeWidth,
      ),
      opacity: 0.82,
    );
    _paintMaskPass(
      canvas: canvas,
      paintBounds: layerRect,
      targetRect: targetRect,
      image: image,
      sourceRect: imageSourceRect,
      shader: ui.Gradient.sweep(
        targetRect.center,
        <Color>[
          const Color(0xFFFFFFFF).withValues(alpha: 0.00),
          const Color(0xFFFFFFFF).withValues(alpha: 0.00),
          const Color(0xFFFFFFFF).withValues(alpha: 0.72 * pulse),
          const Color(0xFFFFFFFF).withValues(alpha: 0.00),
          const Color(0xFFFFFFFF).withValues(alpha: 0.00),
        ],
        const <double>[0.0, 0.40, 0.48, 0.56, 1.0],
        TileMode.clamp,
        sweepRotation - math.pi * 0.22,
        sweepRotation + math.pi * 1.78,
      ),
      imageFilter: ui.ImageFilter.dilate(
        radiusX: math.max(1.0, edgeWidth * 0.46),
        radiusY: math.max(1.0, edgeWidth * 0.46),
      ),
      opacity: 0.82,
    );
    canvas.restore();
  }

  void _paintMaskPass({
    required Canvas canvas,
    required Rect paintBounds,
    required Rect targetRect,
    required ui.Image image,
    required Rect sourceRect,
    required ui.Shader shader,
    required ui.ImageFilter imageFilter,
    required double opacity,
  }) {
    canvas.saveLayer(paintBounds, Paint()..blendMode = BlendMode.srcOver);
    canvas.saveLayer(paintBounds, Paint()..imageFilter = imageFilter);
    canvas.drawRect(paintBounds, Paint()..shader = shader);
    canvas.drawImageRect(
      image,
      sourceRect,
      targetRect,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..filterQuality = FilterQuality.medium
        ..color = const Color(0xFFFFFFFF).withValues(alpha: opacity),
    );
    canvas.restore();
    canvas.drawImageRect(
      image,
      sourceRect,
      targetRect,
      Paint()
        ..blendMode = BlendMode.dstOut
        ..filterQuality = FilterQuality.medium,
    );
    canvas.restore();
  }

  Rect _targetRectFor(Size size) {
    final inset = math.min(_guideTargetGlowOutset, size.shortestSide * 0.22);
    final rect = (Offset.zero & size).deflate(inset);
    if (rect.isEmpty) {
      return Offset.zero & size;
    }
    return rect;
  }

  Rect _imageSourceRectFor(ui.Image image) {
    final imageRect = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final crop = targetAssetCropRect;
    if (crop == null || crop.isEmpty) {
      return imageRect;
    }
    return Rect.fromLTWH(
      imageRect.width * crop.left,
      imageRect.height * crop.top,
      imageRect.width * crop.width,
      imageRect.height * crop.height,
    ).intersect(imageRect);
  }

  void _paintFallbackGeometryGlow(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }

    final glowRect = Offset.zero & size;
    final glowInset = math.min(
      _guideTargetGlowOutset,
      size.shortestSide * 0.22,
    );
    final shapeRect = glowRect.deflate(glowInset);
    if (shapeRect.isEmpty) {
      return;
    }

    final pulse = 0.84 + progress * 0.16;
    final outerStrokeWidth = math.max(8.0, shapeRect.shortestSide * 0.14);
    final innerStrokeWidth = math.max(3.8, shapeRect.shortestSide * 0.058);
    final coreStrokeWidth = math.max(1.5, shapeRect.shortestSide * 0.022);
    final center = shapeRect.center;
    final shaderRadius = math.max(shapeRect.width, shapeRect.height) * 0.72;
    final sweepRotation = progress * math.pi * 2;
    final outerPaint = _strokePaint(
      shader: ui.Gradient.radial(
        center,
        shaderRadius,
        <Color>[
          const Color(0xFFFFF7C8).withValues(alpha: 0.00),
          const Color(0xFFFFF1A8).withValues(alpha: 0.44 * pulse),
          const Color(0xFFFFC95F).withValues(alpha: 0.18 * pulse),
          const Color(0xFFFFF7C8).withValues(alpha: 0.00),
        ],
        const <double>[0.42, 0.66, 0.86, 1.0],
      ),
      strokeWidth: outerStrokeWidth,
    );
    final innerPaint = _strokePaint(
      shader: ui.Gradient.sweep(
        center,
        <Color>[
          const Color(0xFFFFF7C8).withValues(alpha: 0.72 * pulse),
          const Color(0xFFFFD974).withValues(alpha: 0.34 * pulse),
          const Color(0xFFFFFEED).withValues(alpha: 0.86 * pulse),
          const Color(0xFFFFD974).withValues(alpha: 0.34 * pulse),
          const Color(0xFFFFF7C8).withValues(alpha: 0.72 * pulse),
        ],
        const <double>[0.0, 0.28, 0.48, 0.68, 1.0],
        TileMode.clamp,
        sweepRotation,
        sweepRotation + math.pi * 2,
      ),
      strokeWidth: innerStrokeWidth,
    );
    final corePaint = _strokePaint(
      shader: ui.Gradient.linear(
        shapeRect.topLeft,
        shapeRect.bottomRight,
        <Color>[
          const Color(0xFFFFFFFF).withValues(alpha: 0.30 * pulse),
          const Color(0xFFFFF4B8).withValues(alpha: 0.56 * pulse),
          const Color(0xFFFFFFFF).withValues(alpha: 0.26 * pulse),
        ],
        const <double>[0.0, 0.48, 1.0],
      ),
      strokeWidth: coreStrokeWidth,
    );
    final glintPaint = _strokePaint(
      shader: ui.Gradient.sweep(
        center,
        <Color>[
          const Color(0xFFFFFFFF).withValues(alpha: 0.00),
          const Color(0xFFFFFFFF).withValues(alpha: 0.00),
          const Color(0xFFFFFFFF).withValues(alpha: 0.62 * pulse),
          const Color(0xFFFFFFFF).withValues(alpha: 0.00),
          const Color(0xFFFFFFFF).withValues(alpha: 0.00),
        ],
        const <double>[0.0, 0.40, 0.48, 0.56, 1.0],
        TileMode.clamp,
        sweepRotation - math.pi * 0.20,
        sweepRotation + math.pi * 1.80,
      ),
      strokeWidth: math.max(2.0, innerStrokeWidth * 0.42),
    );

    if (shape == _GuideObjectGlowShape.oval) {
      final ovalRect = shapeRect.inflate(1.5);
      canvas.drawOval(ovalRect, outerPaint);
      canvas.drawOval(ovalRect, innerPaint);
      canvas.drawOval(ovalRect, corePaint);
      canvas.drawOval(ovalRect, glintPaint);
      return;
    }

    final glowTargetRect = shapeRect.inflate(1.2);
    final radiusCorner = Radius.circular(shapeRect.shortestSide * 0.18);
    final targetShape = RRect.fromRectAndRadius(glowTargetRect, radiusCorner);
    canvas.drawRRect(targetShape, outerPaint);
    canvas.drawRRect(targetShape, innerPaint);
    canvas.drawRRect(targetShape, corePaint);
    canvas.drawRRect(targetShape, glintPaint);
  }

  Paint _strokePaint({required ui.Shader shader, required double strokeWidth}) {
    return Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..blendMode = BlendMode.plus;
  }

  @override
  bool shouldRepaint(covariant _GuideObjectGlowPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.shape != shape ||
        oldDelegate.targetImage != targetImage ||
        oldDelegate.targetAssetCropRect != targetAssetCropRect ||
        oldDelegate.shaderProgram != shaderProgram;
  }
}
