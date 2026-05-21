import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/ui/sprite_atlas.dart';
import '../../../widgets/user_avatar.dart';
import '../../family/widgets/family_sprite_slice.dart';
import '../../pet/pet_detail_sprite_catalog.dart';
import '../task_panel_sprite_catalog.dart';
import 'home_guide_controller.dart';

const String _guideFingerAsset = 'assets/images/ui/login/finger1.png';
const String _guideBubbleAsset = 'assets/images/ui/login/bubble.png';
const String _guideTaskPetAsset =
    'assets/images/pets/grow/dog/baby/sitting.png';

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
    final arrowStart = _arrowStartFor(safeAnchor, pointer);
    final arrowEnd = _arrowEndFor(preview);

    return SizedBox.expand(
      child: IgnorePointer(
        ignoring: false,
        child: Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              Positioned.fromRect(
                rect: safeAnchor.inflate(20),
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: onHotspotTap,
                  child: _GuideObjectGlow(step: step),
                ),
              ),
              if (step == HomeGuideStep.taskSticker)
                Positioned.fromRect(
                  rect: _taskPetRectFor(screenSize),
                  child: const IgnorePointer(
                    child: SizedBox.expand(
                      key: ValueKey('home_guide_task_pet'),
                      child: _GuideTaskPet(),
                    ),
                  ),
                ),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    key: const ValueKey('home_guide_arrow'),
                    painter: _GuideArrowPainter(
                      start: arrowStart,
                      end: arrowEnd,
                    ),
                  ),
                ),
              ),
              Positioned.fromRect(
                rect: pointer,
                child: IgnorePointer(
                  child: SizedBox.expand(
                    key: const ValueKey('home_guide_finger'),
                    child: _GuideFinger(
                      flipX: pointer.center.dx < safeAnchor.center.dx,
                    ),
                  ),
                ),
              ),
              Positioned.fromRect(
                rect: preview,
                child: IgnorePointer(
                  child: SizedBox.expand(
                    key: ValueKey('home_guide_preview'),
                    child: _GuidePreviewCard(step: step),
                  ),
                ),
              ),
              Positioned.fromRect(
                rect: bubble,
                child: SizedBox.expand(
                  key: ValueKey('home_guide_bubble'),
                  child: _GuideBubble(
                    step: step,
                    message: _messageFor(step),
                    stepLabel: _stepLabelFor(step),
                    onSkip: onSkip,
                  ),
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

    if (step == HomeGuideStep.taskSticker) {
      final maxWidth = math.max(0.0, size.width - margin * 2);
      final targetWidth = compact
          ? math.max(size.width * 0.66, 258.0)
          : math.min(size.width * 0.62, 620.0);
      final width = math.min(maxWidth, targetWidth);
      final height = width * TaskBoardReferenceAsset.panelHeightRatio;
      final desiredCenterX = size.width * (compact ? 0.60 : 0.58);
      var left = desiredCenterX - width * 0.5;
      var top = size.height * (compact ? 0.18 : 0.16);

      left = left
          .clamp(margin, math.max(margin, size.width - width - margin))
          .toDouble();
      top = top
          .clamp(margin + 8, math.max(margin + 8, size.height - height - 238))
          .toDouble();

      return Rect.fromLTWH(left, top, width, height);
    }

    final width = switch (step) {
      _ =>
        compact
            ? math.min(size.width * 0.46, 178.0)
            : math.min(size.width * 0.30, 238.0),
    };
    final height = switch (step) {
      HomeGuideStep.taskSticker =>
        width * TaskBoardReferenceAsset.panelHeightRatio,
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

    var top = step == HomeGuideStep.taskSticker
        ? math.max(size.height * 0.14, anchor.center.dy - height * 0.28)
        : anchor.center.dy - height * 0.46;

    left = left
        .clamp(margin, math.max(margin, size.width - width - margin))
        .toDouble();
    final bottomReserve = step == HomeGuideStep.taskSticker ? 248.0 : 112.0;
    top = top
        .clamp(
          margin + 8,
          math.max(margin + 8, size.height - height - bottomReserve),
        )
        .toDouble();

    return Rect.fromLTWH(left, top, width, height);
  }

  Rect _bubbleRectFor(Rect preview, Size size) {
    const margin = 18.0;
    final isTaskGuide = step == HomeGuideStep.taskSticker;

    if (isTaskGuide) {
      final width = math.min(
        size.width - margin * 2,
        math.max(size.width * 0.62, 242.0),
      );
      final height = width * (1024 / 1536);
      final targetCenterX = size.width * 0.50;
      var left = targetCenterX - width * 0.5;
      var top = size.height * 0.64;

      left = left.clamp(margin, size.width - width - margin).toDouble();
      top = top
          .clamp(
            margin + 8,
            math.max(margin + 8, size.height - height - margin),
          )
          .toDouble();
      return Rect.fromLTWH(left, top, width, height);
    }

    final width = isTaskGuide
        ? math.min(size.width * 0.58, 330.0)
        : math.min(size.width - (margin * 2), 320.0);
    final height = isTaskGuide ? width * 0.38 : 104.0;
    var left = isTaskGuide
        ? size.width * 0.38
        : preview.center.dx - width * 0.5;
    var top = isTaskGuide ? preview.bottom + 20 : preview.bottom + 14;
    if (top + height > size.height - margin) {
      top = preview.top - height - 14;
    }

    left = left.clamp(margin, size.width - width - margin).toDouble();
    top = top
        .clamp(margin + 8, math.max(margin + 8, size.height - height - margin))
        .toDouble();
    return Rect.fromLTWH(left, top, width, height);
  }

  Rect _taskPetRectFor(Size size) {
    final petSize = size.width.clamp(360.0, 560.0) * 0.18;
    final left = size.width * 0.004;
    final bottom = size.height * 0.018;
    return Rect.fromLTWH(
      left,
      size.height - bottom - petSize,
      petSize,
      petSize,
    );
  }

  Rect _pointerRectFor(Rect anchor, Rect preview) {
    const size = 76.0;
    if (step == HomeGuideStep.taskSticker) {
      return Rect.fromLTWH(
        anchor.center.dx - size * 0.08,
        anchor.center.dy - size * 0.34,
        size,
        size,
      );
    }

    final fromLeft = preview.center.dx > anchor.center.dx;
    final left = fromLeft ? anchor.right - 8 : anchor.left - size + 8;
    final top = anchor.center.dy - size * 0.34;
    return Rect.fromLTWH(left, top, size, size);
  }

  Offset _arrowStartFor(Rect anchor, Rect pointer) {
    if (step == HomeGuideStep.taskSticker) {
      return Offset(pointer.right - 12, pointer.top + pointer.height * 0.46);
    }
    return anchor.center;
  }

  Offset _arrowEndFor(Rect preview) {
    if (step == HomeGuideStep.taskSticker) {
      return Offset(
        preview.left + preview.width * 0.24,
        preview.top + preview.height * 0.20,
      );
    }
    return preview.center;
  }

  String _messageFor(HomeGuideStep step) {
    return switch (step) {
      HomeGuideStep.taskSticker => '点击这里打开\n任务面板',
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
    required this.step,
    required this.message,
    required this.stepLabel,
    required this.onSkip,
  });

  final HomeGuideStep step;
  final String message;
  final String stepLabel;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    if (step == HomeGuideStep.taskSticker) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            _guideBubbleAsset,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.medium,
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final messageFontSize = (constraints.maxWidth * 0.048)
                  .clamp(13.0, 14.0)
                  .toDouble();
              final stepFontSize = (messageFontSize - 4).clamp(9.0, 10.5);
              final skipFontSize = (messageFontSize - 3).clamp(10.0, 11.5);
              return Padding(
                padding: EdgeInsets.fromLTRB(
                  constraints.maxWidth * 0.30,
                  constraints.maxHeight * 0.33,
                  constraints.maxWidth * 0.26,
                  constraints.maxHeight * 0.22,
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: Text(
                          message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF6B4C36),
                            fontSize: messageFontSize,
                            fontWeight: FontWeight.w700,
                            height: 1.05,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            stepLabel,
                            style: TextStyle(
                              color: const Color(0xFF9D7653),
                              fontSize: stepFontSize,
                              fontWeight: FontWeight.w800,
                              height: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: onSkip,
                            style: TextButton.styleFrom(
                              minimumSize: const Size(52, 24),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              foregroundColor: const Color(0xFF8E6748),
                              textStyle: TextStyle(
                                fontSize: skipFontSize,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            child: const Text('稍后再看'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      );
    }

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

class _GuideTaskPet extends StatelessWidget {
  const _GuideTaskPet();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _guideTaskPetAsset,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );
  }
}

class _GuideObjectGlow extends StatefulWidget {
  const _GuideObjectGlow({required this.step});

  final HomeGuideStep step;

  @override
  State<_GuideObjectGlow> createState() => _GuideObjectGlowState();
}

class _GuideObjectGlowState extends State<_GuideObjectGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
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

class _TaskPanelPreview extends StatelessWidget {
  const _TaskPanelPreview();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: TaskBoardReferenceAsset.panelAspectRatio,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          final rowWidth = size.width * 0.858;
          final rowHeight = size.height * 0.094;
          final rowLeft = (size.width - rowWidth) * 0.5;
          final rowsTop = size.height * 0.260;
          final rowGap = size.height * 0.025;
          final titleTop = size.height * 0.119;
          final titleHeight = size.height * 0.080;
          final addButtonWidth = size.width * 0.460;
          final addButtonHeight =
              addButtonWidth / TaskBoardReferenceAsset.addTaskButtonAspectRatio;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              const Positioned.fill(child: _TaskBoardPreviewBase()),
              Positioned(
                left: size.width * 0.18,
                right: size.width * 0.18,
                top: titleTop,
                height: titleHeight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      TaskBoardReferenceAsset.pawLeft,
                      height: size.height * 0.045,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.medium,
                    ),
                    SizedBox(width: size.width * 0.018),
                    const Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '任务清单',
                          maxLines: 1,
                          style: TextStyle(
                            color: Color(0xFF4A2014),
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: size.width * 0.018),
                    Transform.flip(
                      flipX: true,
                      child: Image.asset(
                        TaskBoardReferenceAsset.pawLeft,
                        height: size.height * 0.045,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
                  ],
                ),
              ),
              for (var index = 0; index < 3; index++)
                Positioned(
                  left: rowLeft,
                  top: rowsTop + index * (rowHeight + rowGap),
                  width: rowWidth,
                  height: rowHeight,
                  child: _RealTaskRowPreview(index: index),
                ),
              Positioned(
                left: (size.width - addButtonWidth) * 0.5,
                bottom: size.height * 0.060,
                width: addButtonWidth,
                height: addButtonHeight,
                child: Image.asset(
                  TaskBoardReferenceAsset.addTaskButton,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TaskBoardPreviewBase extends StatelessWidget {
  const _TaskBoardPreviewBase();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final boardTop =
            size.height *
            (TaskBoardReferenceAsset.boardTopOffset /
                TaskBoardReferenceAsset.panelHeight);
        final boardHeight =
            size.height *
            (TaskBoardReferenceAsset.boardSize.height /
                TaskBoardReferenceAsset.panelHeight);
        final boardWidth =
            boardHeight *
            (TaskBoardReferenceAsset.boardSize.width /
                TaskBoardReferenceAsset.boardSize.height);
        final clipWidth =
            size.width *
            (TaskBoardReferenceAsset.clipSize.width /
                TaskBoardReferenceAsset.panelWidth) *
            0.76;
        final clipHeight =
            clipWidth *
            (TaskBoardReferenceAsset.clipSize.height /
                TaskBoardReferenceAsset.clipSize.width);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: (size.width - boardWidth) * 0.5,
              top: boardTop,
              width: boardWidth,
              height: boardHeight,
              child: Image.asset(
                TaskBoardReferenceAsset.board,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.medium,
              ),
            ),
            Positioned(
              left: (size.width - clipWidth) * 0.5,
              top: 0,
              width: clipWidth,
              height: clipHeight,
              child: Image.asset(
                TaskBoardReferenceAsset.clip,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FamilyAlbumPreview extends StatelessWidget {
  const _FamilyAlbumPreview();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF0DC), Color(0xFFF1DDBF)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF604429).withValues(alpha: 0.16),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(9, 10, 9, 8),
        child: Column(
          children: [
            const _FamilyPreviewHeader(),
            const SizedBox(height: 8),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                children: const [
                  _RealFamilyMemberPreviewCard(
                    skin: FamilySpriteSkins.memberCardWarm,
                    avatarAsset: userMomAvatarAssetPath,
                    petAsset: 'assets/images/pets/grow/cat/growing/sitting.png',
                    name: '妈妈',
                    progress: 0.74,
                  ),
                  _RealFamilyMemberPreviewCard(
                    skin: FamilySpriteSkins.memberCardGreen,
                    avatarAsset: userBoyAvatarAssetPath,
                    petAsset: 'assets/images/pets/grow/dog/growing/sitting.png',
                    name: '孩子',
                    progress: 0.46,
                  ),
                  _RealFamilyMemberPreviewCard(
                    skin: FamilySpriteSkins.memberCardBlue,
                    name: '等待',
                    progress: 0.0,
                    empty: true,
                  ),
                  _RealFamilyMemberPreviewCard(
                    skin: FamilySpriteSkins.memberCardPink,
                    name: '添加',
                    progress: 0.0,
                    add: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            const _FamilyPreviewPageDots(),
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
    return AspectRatio(
      aspectRatio: 499 / 793,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned.fill(
            child: _PetDetailSpritePreview(
              frame: PetDetailSheetSpriteCatalog.panelBlank,
              fit: BoxFit.fill,
              sampleInset: 1,
            ),
          ),
          const Positioned(
            left: 38,
            right: 38,
            top: -6,
            height: 42,
            child: _PetNameBannerPreview(),
          ),
          Positioned(
            left: 17,
            top: 52,
            width: 86,
            bottom: 112,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const _PetDetailSpritePreview(
                  frame: PetDetailSheetSpriteCatalog.portraitFrameBlank,
                  fit: BoxFit.fill,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 15, 10, 16),
                  child: Image.asset(
                    'assets/images/pets/grow/cat/growing/sitting.png',
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            right: 13,
            top: 58,
            width: 86,
            child: Column(
              children: [
                _PetMetricCardPreview(
                  frame: PetDetailSheetSpriteCatalog.stageCard,
                  valueWidth: 0.70,
                  progress: 0.72,
                  height: 50,
                ),
                SizedBox(height: 6),
                _PetMetricCardPreview(
                  frame: PetDetailSheetSpriteCatalog.growthCard,
                  valueWidth: 0.82,
                  height: 43,
                ),
                SizedBox(height: 6),
                _PetMetricCardPreview(
                  frame: PetDetailSheetSpriteCatalog.feedCard,
                  valueWidth: 0.58,
                  height: 43,
                ),
              ],
            ),
          ),
          const Positioned(
            left: 15,
            right: 92,
            bottom: 35,
            height: 76,
            child: _PetRecentPanelPreview(),
          ),
          const Positioned(
            right: 13,
            bottom: 34,
            width: 62,
            height: 82,
            child: _PetAchievementPreview(),
          ),
        ],
      ),
    );
  }
}

class _RealTaskRowPreview extends StatelessWidget {
  const _RealTaskRowPreview({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    const titles = ['整理书包', '喂宠物', '收拾玩具'];
    final rowAsset = switch (index % 4) {
      0 => TaskBoardReferenceAsset.rowWarm,
      1 => TaskBoardReferenceAsset.rowGreen,
      2 => TaskBoardReferenceAsset.rowPink,
      _ => TaskBoardReferenceAsset.rowYellow,
    };

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          rowAsset,
          fit: BoxFit.fill,
          filterQuality: FilterQuality.medium,
        ),
        Positioned(
          left: 10,
          top: 0,
          bottom: 0,
          width: 18,
          child: Center(
            child: Image.asset(
              TaskBoardReferenceAsset.checkboxEmpty,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
        Positioned(
          left: 34,
          right: 36,
          top: 0,
          bottom: 0,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              titles[index],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF4A2014),
                fontSize: 12,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
        ),
        Positioned(
          right: 12,
          top: 0,
          bottom: 0,
          width: 22,
          child: Image.asset(
            TaskBoardReferenceAsset.rewardStar,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          ),
        ),
      ],
    );
  }
}

class _FamilyPreviewHeader extends StatelessWidget {
  const _FamilyPreviewHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      child: Row(
        children: [
          Image.asset(
            FamilyHomePartAssets.familyIllustration,
            width: 30,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          ),
          const SizedBox(width: 6),
          const Expanded(
            child: Text(
              '家庭相册',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Color(0xFF684328),
                fontSize: 13,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
          SizedBox.square(
            dimension: 22,
            child: Image.asset(
              FamilyPopupAssets.addButton,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ],
      ),
    );
  }
}

class _RealFamilyMemberPreviewCard extends StatelessWidget {
  const _RealFamilyMemberPreviewCard({
    required this.skin,
    required this.name,
    required this.progress,
    this.avatarAsset,
    this.petAsset,
    this.empty = false,
    this.add = false,
  });

  final FamilySpritePanelSkin skin;
  final String name;
  final double progress;
  final String? avatarAsset;
  final String? petAsset;
  final bool empty;
  final bool add;

  @override
  Widget build(BuildContext context) {
    return FamilySpritePanel(
      skin: skin,
      padding: const EdgeInsets.all(5),
      child: Column(
        children: [
          SizedBox(
            height: 18,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFFFFEF6).withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF2A12A), width: 0.8),
              ),
              child: Center(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF3E230F),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: empty || add
                  ? Icon(
                      add ? Icons.add_rounded : Icons.pets_rounded,
                      color: const Color(0xFF8F663F),
                      size: 28,
                    )
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        if (petAsset != null)
                          Image.asset(
                            petAsset!,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.medium,
                          ),
                        if (avatarAsset != null)
                          Positioned(
                            left: 0,
                            top: 2,
                            width: 22,
                            height: 22,
                            child: Image.asset(
                              avatarAsset!,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.medium,
                            ),
                          ),
                      ],
                    ),
            ),
          ),
          SizedBox(
            height: 20,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFFFFCF3).withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF3A52F), width: 0.8),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: FamilySpriteProgressBar(value: progress, height: 7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FamilyPreviewPageDots extends StatelessWidget {
  const _FamilyPreviewPageDots();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          TaskBoardReferenceAsset.paginationDotActive,
          width: 8,
          height: 8,
          filterQuality: FilterQuality.medium,
        ),
        const SizedBox(width: 5),
        Image.asset(
          TaskBoardReferenceAsset.paginationDotInactive,
          width: 8,
          height: 8,
          filterQuality: FilterQuality.medium,
        ),
      ],
    );
  }
}

class _PetDetailSpritePreview extends StatelessWidget {
  const _PetDetailSpritePreview({
    required this.frame,
    this.fit = BoxFit.contain,
    this.sampleInset = 0,
  });

  final SpriteAtlasFrame frame;
  final BoxFit fit;
  final double sampleInset;

  @override
  Widget build(BuildContext context) {
    return SpriteFrameImage(
      imageAsset: PetDetailSheetSpriteCatalog.imageAsset,
      sheetSize: PetDetailSheetSpriteCatalog.sheetSize,
      frame: frame,
      fit: fit,
      filterQuality: FilterQuality.medium,
      sampleInset: sampleInset,
    );
  }
}

class _PetNameBannerPreview extends StatelessWidget {
  const _PetNameBannerPreview();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const _PetDetailSpritePreview(
          frame: PetDetailSheetSpriteCatalog.nameBanner,
          fit: BoxFit.fill,
        ),
        Center(
          child: Container(
            width: 46,
            height: 7,
            decoration: BoxDecoration(
              color: const Color(0xFF684328).withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
      ],
    );
  }
}

class _PetMetricCardPreview extends StatelessWidget {
  const _PetMetricCardPreview({
    required this.frame,
    required this.valueWidth,
    required this.height,
    this.progress,
  });

  final SpriteAtlasFrame frame;
  final double valueWidth;
  final double height;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _PetDetailSpritePreview(frame: frame, fit: BoxFit.fill),
          Positioned(
            left: 14,
            right: 16,
            top: 11,
            child: Container(
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFF684328).withValues(alpha: 0.26),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          Positioned(
            left: 14,
            top: 23,
            width: 52 * valueWidth,
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFF88613E).withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          if (progress != null)
            Positioned(
              left: 14,
              right: 16,
              bottom: 8,
              height: 8,
              child: _PetProgressPreview(value: progress!),
            ),
        ],
      ),
    );
  }
}

class _PetRecentPanelPreview extends StatelessWidget {
  const _PetRecentPanelPreview();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const _PetDetailSpritePreview(
          frame: PetDetailSheetSpriteCatalog.recentPanel,
          fit: BoxFit.fill,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(13, 18, 13, 13),
          child: Column(
            children: const [
              _PetDetailTextLine(widthFactor: 0.72),
              SizedBox(height: 8),
              _PetDetailTextLine(widthFactor: 0.88),
              SizedBox(height: 8),
              _PetDetailTextLine(widthFactor: 0.64),
            ],
          ),
        ),
      ],
    );
  }
}

class _PetAchievementPreview extends StatelessWidget {
  const _PetAchievementPreview();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const _PetDetailSpritePreview(
          frame: PetDetailSheetSpriteCatalog.achievementTag,
          fit: BoxFit.fill,
        ),
        Center(
          child: Image.asset(
            TaskBoardReferenceAsset.rewardStar,
            width: 22,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          ),
        ),
      ],
    );
  }
}

class _PetDetailTextLine extends StatelessWidget {
  const _PetDetailTextLine({required this.widthFactor});

  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: Container(
        height: 5,
        decoration: BoxDecoration(
          color: const Color(0xFF88613E).withValues(alpha: 0.26),
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}

class _PetProgressPreview extends StatelessWidget {
  const _PetProgressPreview({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6D9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF536F2B), width: 0.8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(1),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value.clamp(0.0, 1.0).toDouble(),
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF9ABC4D), Color(0xFF86A941)],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
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

    final pulse = 0.72 + progress * 0.28;
    final glowRect = Offset.zero & size;
    final center = glowRect.center;
    final radius = math.max(size.width, size.height) * (0.47 + progress * 0.08);
    final gradient = RadialGradient(
      colors: [
        const Color(0xFFFFE58A).withValues(alpha: 0.40 * pulse),
        const Color(0xFFFFD34D).withValues(alpha: 0.28 * pulse),
        const Color(0xFFFFC845).withValues(alpha: 0.00),
      ],
      stops: const [0.0, 0.52, 1.0],
    );
    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    if (shape == _GuideObjectGlowShape.oval) {
      canvas.drawOval(glowRect.deflate(size.shortestSide * 0.04), paint);
      return;
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        glowRect.deflate(size.shortestSide * 0.04),
        Radius.circular(size.shortestSide * 0.30),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _GuideObjectGlowPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.shape != shape;
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
