import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/ui/sprite_atlas.dart';
import '../../../models/pet.dart';
import '../../../widgets/user_avatar.dart';
import '../../family/models/family_member_view_data.dart';
import '../../family/widgets/family_member_grid.dart';
import '../../family/widgets/family_sprite_slice.dart';
import '../../pet/pet_detail_sprite_catalog.dart';
import '../task_panel_sprite_catalog.dart';
import 'home_guide_controller.dart';

const String _guideFingerAsset = 'assets/images/ui/login/finger1.png';
const String _guideBubbleAsset = 'assets/images/ui/login/bubble.png';
const String _guideTaskPetAsset =
    'assets/images/pets/grow/dog/baby/sitting.png';
const double _guideCompanionPetLeftFactor = 0.009;
const double _guideCompanionPetBottomFactor = 0.046;
const double _guideCompanionPetSizeBaseline = 0.32;
const double _guideFingerSize = 76.0;
// finger1.png is 176x169; the visible fingertip is near pixel (41, 33).
const Offset _guideFingerTipFraction = Offset(0.235, 0.207);

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
    final pointer = _pointerRectFor(safeAnchor, preview, screenSize);

    return SizedBox.expand(
      child: IgnorePointer(
        ignoring: false,
        child: Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              Positioned.fromRect(
                rect: _hotspotRectFor(safeAnchor),
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: onHotspotTap,
                  child: _GuideObjectGlow(step: step),
                ),
              ),
              if (step != HomeGuideStep.done)
                Positioned.fromRect(
                  rect: _taskPetRectFor(screenSize),
                  child: const IgnorePointer(
                    child: SizedBox.expand(
                      key: ValueKey('home_guide_task_pet'),
                      child: _GuideTaskPet(),
                    ),
                  ),
                ),
              Positioned.fromRect(
                rect: pointer,
                child: IgnorePointer(
                  child: SizedBox.expand(
                    key: const ValueKey('home_guide_finger'),
                    child: const _GuideFinger(),
                  ),
                ),
              ),
              Positioned.fromRect(
                rect: preview,
                child: IgnorePointer(
                  child: SizedBox.expand(
                    key: const ValueKey('home_guide_preview'),
                    child: _GuidePreviewCard(step: step),
                  ),
                ),
              ),
              Positioned.fromRect(
                rect: bubble,
                child: SizedBox.expand(
                  key: const ValueKey('home_guide_bubble'),
                  child: _GuideBubble(step: step),
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

  Rect _previewRectFor(Rect _, Size size) {
    const margin = 18.0;
    final compact = size.width < 520;

    if (step == HomeGuideStep.done) {
      return Rect.zero;
    }

    final maxWidth = math.max(0.0, size.width - margin * 2);
    final targetWidth = compact
        ? math.max(size.width * 0.66, 258.0)
        : math.min(size.width * 0.62, 620.0);
    final width = math.min(maxWidth, targetWidth);
    final height = width * TaskBoardReferenceAsset.panelHeightRatio;
    final desiredCenterX = switch (step) {
      HomeGuideStep.familyFrame => size.width * (compact ? 0.42 : 0.45),
      _ => size.width * (compact ? 0.60 : 0.58),
    };
    var left = desiredCenterX - width * 0.5;
    var top = size.height * (compact ? 0.3 : 0.3);

    left = left
        .clamp(margin, math.max(margin, size.width - width - margin))
        .toDouble();
    top = top
        .clamp(margin + 8, math.max(margin + 8, size.height - height - 238))
        .toDouble();

    return Rect.fromLTWH(left, top, width, height);
  }

  Rect _bubbleRectFor(Rect _, Size size) {
    const margin = 18.0;
    if (step == HomeGuideStep.done) {
      return Rect.zero;
    }
    final width = math.min(
      size.width - margin * 2,
      math.max(size.width * 0.62, 242.0),
    );
    final height = width * (1024 / 1536);
    final targetCenterX = size.width * 0.50;
    var left = targetCenterX - width * 0.5;
    var top = size.height * 0.72;

    left = left.clamp(margin, size.width - width - margin).toDouble();
    top = top
        .clamp(margin + 8, math.max(margin + 8, size.height - height - margin))
        .toDouble();
    return Rect.fromLTWH(left, top, width, height);
  }

  Rect _taskPetRectFor(Size size) {
    final petSize =
        size.width.clamp(360.0, 560.0) * _guideCompanionPetSizeBaseline;
    final left = size.width * _guideCompanionPetLeftFactor;
    final bottom = size.height * _guideCompanionPetBottomFactor;
    return Rect.fromLTWH(
      left,
      size.height - bottom - petSize,
      petSize,
      petSize,
    );
  }

  Rect _hotspotRectFor(Rect anchor) {
    if (step != HomeGuideStep.petArea) {
      return anchor.inflate(20);
    }
    return anchor.inflate(10);
  }

  Rect _pointerRectFor(Rect anchor, Rect preview, Size screenSize) {
    final target = switch (step) {
      HomeGuideStep.taskSticker => anchor.bottomRight + const Offset(2, -2),
      HomeGuideStep.familyFrame => anchor.bottomRight + const Offset(2, -2),
      HomeGuideStep.petArea =>
        anchor.center + Offset(anchor.width * 0.12, anchor.height * 0.16),
      HomeGuideStep.done => anchor.center,
    };
    final maxLeft = math.max(
      8.0,
      screenSize.width - _guideFingerSize * (1 - _guideFingerTipFraction.dx),
    );
    final left = (target.dx - _guideFingerSize * _guideFingerTipFraction.dx)
        .clamp(8.0, maxLeft)
        .toDouble();
    final top = (target.dy - _guideFingerSize * _guideFingerTipFraction.dy)
        .clamp(8.0, math.max(8.0, screenSize.height - _guideFingerSize - 8))
        .toDouble();
    return Rect.fromLTWH(left, top, _guideFingerSize, _guideFingerSize);
  }
}

class _GuideBubble extends StatelessWidget {
  const _GuideBubble({required this.step});

  final HomeGuideStep step;

  @override
  Widget build(BuildContext context) {
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
            final messageFontSize = (constraints.maxWidth * 0.093)
                .clamp(20.0, 24.0)
                .toDouble();
            return Padding(
              padding: EdgeInsets.fromLTRB(
                constraints.maxWidth * 0.18,
                constraints.maxHeight * 0.18,
                constraints.maxWidth * 0.23,
                constraints.maxHeight * 0.26,
              ),
              child: Center(
                child: RichText(
                  key: const ValueKey('home_guide_bubble_message'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  text: _messageSpanFor(
                    step,
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

  TextSpan _messageSpanFor(HomeGuideStep step, TextStyle baseStyle) {
    const highlightStyle = TextStyle(color: Color(0xFFD8665B));
    TextSpan span(String text, {bool highlight = false}) {
      return TextSpan(
        text: text,
        style: highlight ? baseStyle.merge(highlightStyle) : baseStyle,
      );
    }

    return switch (step) {
      HomeGuideStep.familyFrame => TextSpan(
        children: [span('点击这里管理\n'), span('家庭成员', highlight: true)],
      ),
      HomeGuideStep.taskSticker => TextSpan(
        children: [span('点击这里打开\n'), span('任务', highlight: true), span('面板')],
      ),
      HomeGuideStep.petArea => TextSpan(
        children: [span('点这里查看\n'), span('宠物详情', highlight: true)],
      ),
      HomeGuideStep.done => span(''),
    };
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
        return Opacity(opacity: 0.94 + press * 0.06, child: child);
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
              for (var index = 0; index < 4; index++)
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
    return const _CurrentFamilyPagePreview();
  }
}

class _CurrentFamilyPagePreview extends StatelessWidget {
  const _CurrentFamilyPagePreview();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: Image.asset(
            FamilyPopupAssets.mainPanel,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.medium,
            isAntiAlias: true,
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: Image.asset(
              FamilyPopupAssets.mainPanelOutline,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.medium,
              isAntiAlias: true,
            ),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            final titleWidth = (width * 0.42).clamp(96.0, 288.0).toDouble();
            final titleHeight = titleWidth / 3.03;
            final addSize = (width * 0.16).clamp(30.0, 66.0).toDouble();
            final notebookSize = (width * 0.078).clamp(22.0, 46.0).toDouble();

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: width * 0.070,
                  top: height * 0.058,
                  width: addSize,
                  height: addSize,
                  child: Image.asset(
                    FamilyPopupAssets.addButton,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                    isAntiAlias: true,
                  ),
                ),
                Positioned(
                  top: height * 0.055,
                  left: (width - titleWidth) / 2,
                  width: titleWidth,
                  height: titleHeight,
                  child: Image.asset(
                    FamilyPopupAssets.title,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                    isAntiAlias: true,
                  ),
                ),
                Positioned(
                  top: height * 0.052,
                  left: width * 0.705,
                  width: notebookSize,
                  height: notebookSize,
                  child: Transform.rotate(
                    angle: 0.20,
                    child: const _FamilyNotebookPreviewIcon(),
                  ),
                ),
                Positioned(
                  left: width * 0.055,
                  right: width * 0.055,
                  top: height * 0.195,
                  bottom: height * 0.062,
                  child: FamilyMemberGrid(
                    members: _previewFamilyMembers,
                    petAvatarAssetPathsById: _previewFamilyPetAvatarAssetPaths,
                    entryAnimation: const AlwaysStoppedAnimation<double>(1),
                    canAddMembers: true,
                    onAddMemberTap: () {},
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 2,
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Image.asset(
                      FamilyPopupAssets.closeButton,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.medium,
                      isAntiAlias: true,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

final List<FamilyMemberViewData> _previewFamilyMembers = [
  FamilyMemberViewData(
    id: 1,
    nickname: '爸爸',
    role: 'admin',
    points: 74,
    petId: 101,
    petType: 'cat',
    avatarUrl: userDadAvatarAssetPath,
    pet: Pet(
      id: 101,
      name: '团团',
      petType: 'cat',
      petForm: 'pet',
      level: 3,
      experience: 44,
      ownerId: 1,
      familyId: 1,
      levelThreshold: 60,
    ),
  ),
  FamilyMemberViewData(
    id: 2,
    nickname: '妈妈',
    role: 'member',
    points: 46,
    petId: 102,
    petType: 'dog',
    avatarUrl: userMomAvatarAssetPath,
    pet: Pet(
      id: 102,
      name: '豆豆',
      petType: 'dog',
      petForm: 'pet',
      level: 2,
      experience: 28,
      ownerId: 2,
      familyId: 1,
      levelThreshold: 60,
    ),
  ),
  FamilyMemberViewData(
    id: 3,
    nickname: '哥哥',
    role: 'member',
    points: 32,
    petId: 103,
    petType: 'rabbit',
    avatarUrl: userBoyAvatarAssetPath,
    pet: Pet(
      id: 103,
      name: '雪球',
      petType: 'rabbit',
      petForm: 'pet',
      level: 2,
      experience: 18,
      ownerId: 3,
      familyId: 1,
      levelThreshold: 60,
    ),
  ),
  FamilyMemberViewData(
    id: 4,
    nickname: '妹妹',
    role: 'member',
    points: 58,
    petId: 104,
    petType: 'hamster',
    avatarUrl: userGirlAvatarAssetPath,
    pet: Pet(
      id: 104,
      name: '米粒',
      petType: 'hamster',
      petForm: 'pet',
      level: 3,
      experience: 52,
      ownerId: 4,
      familyId: 1,
      levelThreshold: 60,
    ),
  ),
];

const Map<int, String> _previewFamilyPetAvatarAssetPaths = {
  101: 'assets/images/pets/grow/cat/growing/sitting.png',
  102: 'assets/images/pets/grow/dog/growing/sitting.png',
  103: 'assets/images/pets/grow/rabbit/growing/sitting.png',
  104: 'assets/images/pets/grow/hamster/growing/sitting.png',
};

class _FamilyNotebookPreviewIcon extends StatelessWidget {
  const _FamilyNotebookPreviewIcon();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFB642),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3E230F), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24361D0D),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.favorite_rounded, color: Colors.white, size: 21),
      ),
    );
  }
}

class _PetGrowthPreview extends StatelessWidget {
  const _PetGrowthPreview();

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.fill,
      child: SizedBox(
        width: 412,
        height: 655,
        child: DefaultTextStyle.merge(
          style: const TextStyle(
            color: Color(0xFF6B4C36),
            decoration: TextDecoration.none,
            fontWeight: FontWeight.w800,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x2D402413),
                        blurRadius: 22,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: _PetDetailSpritePreview(
                    frame: PetDetailSheetSpriteCatalog.panelBlank,
                    fit: BoxFit.fill,
                    sampleInset: 1,
                  ),
                ),
              ),
              const Positioned(
                top: -18,
                left: 76,
                width: 260,
                height: 86,
                child: _GuidePetNameBanner(text: '团团'),
              ),
              const Positioned(
                left: 34,
                top: 94,
                width: 186,
                height: 268,
                child: _GuidePetPortraitFrame(
                  assetPath: 'assets/images/pets/grow/cat/growing/sitting.png',
                ),
              ),
              const Positioned(
                left: 226,
                top: 98,
                width: 166,
                child: Column(
                  children: [
                    _GuidePetMetricCard(
                      frame: PetDetailSheetSpriteCatalog.stageCard,
                      title: '成长阶段',
                      value: '成长期 LV3',
                      progress: 0.72,
                      height: 100,
                    ),
                    SizedBox(height: 11),
                    _GuidePetMetricCard(
                      frame: PetDetailSheetSpriteCatalog.growthCard,
                      title: '成长值',
                      value: '44 / 60',
                      height: 82,
                    ),
                    SizedBox(height: 12),
                    _GuidePetMetricCard(
                      frame: PetDetailSheetSpriteCatalog.feedCard,
                      title: '所属成员',
                      value: '妈妈',
                      height: 82,
                    ),
                  ],
                ),
              ),
              const Positioned(
                left: 30,
                top: 401,
                width: 248,
                height: 207,
                child: _GuidePetRecentPanel(),
              ),
              const Positioned(
                left: 258,
                top: 386,
                width: 118,
                height: 205,
                child: _GuidePetAchievementTag(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuidePetNameBanner extends StatelessWidget {
  const _GuidePetNameBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const _PetDetailSpritePreview(
          frame: PetDetailSheetSpriteCatalog.nameBanner,
          fit: BoxFit.fill,
        ),
        Align(
          alignment: const Alignment(0, -0.12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                text,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF6B4C36),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GuidePetPortraitFrame extends StatelessWidget {
  const _GuidePetPortraitFrame({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const _PetDetailSpritePreview(
          frame: PetDetailSheetSpriteCatalog.portraitFrameBlank,
          fit: BoxFit.fill,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
          child: Center(
            child: Image.asset(
              assetPath,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      ],
    );
  }
}

class _GuidePetMetricCard extends StatelessWidget {
  const _GuidePetMetricCard({
    required this.frame,
    required this.title,
    required this.value,
    required this.height,
    this.progress,
  });

  final SpriteAtlasFrame frame;
  final String title;
  final String value;
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
            left: 51,
            top: progress == null ? 17 : 15,
            right: 10,
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Color(0xFF6B4C36),
              ),
            ),
          ),
          Positioned(
            left: 51,
            top: 40,
            right: 8,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF6B4C36),
                ),
              ),
            ),
          ),
          if (progress != null)
            Positioned(
              left: 18,
              right: 12,
              bottom: 14,
              height: 12,
              child: _GuidePetProgressBar(value: progress!),
            ),
        ],
      ),
    );
  }
}

class _GuidePetProgressBar extends StatelessWidget {
  const _GuidePetProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final clampedValue = value.clamp(0.0, 1.0).toDouble();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4C6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE3B66F), width: 1.6),
      ),
      child: Padding(
        padding: const EdgeInsets.all(1.5),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: clampedValue,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFFC957), Color(0xFFF09944)],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GuidePetRecentPanel extends StatelessWidget {
  const _GuidePetRecentPanel();

  static const _rows = ['整理书包 +10', '喂宠物 +8', '睡前阅读 +12'];

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const _PetDetailSpritePreview(
          frame: PetDetailSheetSpriteCatalog.recentPanel,
          fit: BoxFit.fill,
        ),
        for (var index = 0; index < _rows.length; index++)
          Positioned(
            left: 42,
            top: <double>[44, 94, 144][index],
            right: 24,
            height: 34,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _rows[index],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF6B4C36),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _GuidePetAchievementTag extends StatelessWidget {
  const _GuidePetAchievementTag();

  static const _assetPath = 'assets/images/ui/sprites/label_blank.png';
  static const _aspectRatio = 266 / 368;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: _aspectRatio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              _assetPath,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
            Align(
              alignment: const Alignment(0.1, 0.42),
              child: Transform.rotate(
                angle: 0.12,
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 70,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'LV3',
                          style: TextStyle(
                            fontSize: 22,
                            height: 1,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFD46F35),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '成长',
                      style: TextStyle(
                        fontSize: 19,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF6E9245),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '伙伴',
                      style: TextStyle(
                        fontSize: 19,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF6B4C36),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RealTaskRowPreview extends StatelessWidget {
  const _RealTaskRowPreview({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    const titles = ['整理书包', '喂宠物', '收拾玩具', '睡前阅读'];
    const points = [10, 8, 6, 12];
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
          right: 56,
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
          right: 8,
          top: 0,
          bottom: 0,
          width: 48,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  TaskBoardReferenceAsset.rewardStar,
                  width: 16,
                  height: 16,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                ),
                const SizedBox(width: 2),
                Text(
                  '+${points[index]}',
                  maxLines: 1,
                  style: const TextStyle(
                    color: Color(0xFF7A4C24),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
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
