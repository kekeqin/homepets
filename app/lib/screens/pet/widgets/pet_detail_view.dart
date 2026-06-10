import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/adaptive_design_layout.dart';
import '../../../core/ui/sprite_atlas.dart';
import '../../../models/pet.dart';
import '../../../models/pet_artwork.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/pet_detail_service.dart';
import '../models/pet_history_entry.dart';
import '../pet_detail_sprite_catalog.dart';

class PetDetailDesignLayout {
  const PetDetailDesignLayout._();

  static const designSize = Size(412, 655);
  static const embeddedMinimumInsets = EdgeInsets.fromLTRB(0, 28, 0, 16);
  static const screenMinimumInsets = EdgeInsets.fromLTRB(20, 32, 20, 28);

  static const profileCardRect = Rect.fromLTWH(0, 0, 412, 655);
  static const nameBannerRect = Rect.fromLTWH(76, -18, 260, 86);
  static const portraitFrameRect = Rect.fromLTWH(34, 94, 186, 268);
  static const metricColumnRect = Rect.fromLTWH(226, 98, 166, 287);
  static const recentTasksPanelRect = Rect.fromLTWH(30, 401, 248, 207);
  static const achievementTagRect = Rect.fromLTWH(274, 388, 128, 205);
  static const closeButtonRect = Rect.fromLTWH(354, 0, 56, 56);
}

class PetDetailView extends ConsumerStatefulWidget {
  const PetDetailView({
    super.key,
    required this.pet,
    this.avatarAssetPath,
    this.embedded = false,
    this.onClose,
  });

  static const profileCardKey = Key('pet_detail_profile_card');
  static const nameBannerKey = Key('pet_detail_name_banner');
  static const portraitFrameKey = Key('pet_detail_portrait_frame');
  static const metricColumnKey = Key('pet_detail_metric_column');
  static const recentTasksPanelKey = Key('pet_detail_recent_tasks_panel');
  static const achievementTagKey = Key('pet_detail_achievement_tag');

  final Pet pet;
  final String? avatarAssetPath;
  final bool embedded;
  final VoidCallback? onClose;

  @override
  ConsumerState<PetDetailView> createState() => _PetDetailViewState();
}

class _PetDetailViewState extends ConsumerState<PetDetailView> {
  List<PetHistoryEntry> _history = const <PetHistoryEntry>[];
  bool _loading = false;

  PetDetailService get _service =>
      PetDetailService(ref.read(apiClientProvider));

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void didUpdateWidget(covariant PetDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pet.id != widget.pet.id) {
      _loadHistory();
    }
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);
    final history = await _service.loadHistory(widget.pet.id);
    if (!mounted) {
      return;
    }
    setState(() {
      _history = history;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pet = widget.pet;
    final content = DefaultTextStyle.merge(
      style: const TextStyle(
        color: _PetDetailColors.ink,
        decoration: TextDecoration.none,
        decorationColor: Colors.transparent,
        fontWeight: FontWeight.w800,
      ),
      child: AdaptiveDesignLayout(
        designSize: PetDetailDesignLayout.designSize,
        minimumInsets: widget.embedded
            ? PetDetailDesignLayout.embeddedMinimumInsets
            : PetDetailDesignLayout.screenMinimumInsets,
        useViewPadding: !widget.embedded,
        builder: (context, geometry) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fromRect(
                rect: geometry.designRect,
                child: FittedBox(
                  fit: BoxFit.fill,
                  child: SizedBox(
                    width: PetDetailDesignLayout.designSize.width,
                    height: PetDetailDesignLayout.designSize.height,
                    child: _ProfileCard(
                      pet: pet,
                      avatarAssetPath: widget.avatarAssetPath,
                      stageLabel: _stageLabel(pet),
                      growthValue: _growthValueLabel(pet),
                      ownerNameLabel: pet.ownerDisplayName,
                      recentTasks: _buildRecentTasks(),
                      statusLabel: _statusStampLabel(pet),
                      loading: _loading,
                      onClose: widget.onClose,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    if (widget.embedded) {
      return content;
    }

    return ColoredBox(color: _PetDetailColors.background, child: content);
  }

  String _stageLabel(Pet pet) {
    return petGrowthStageLabel(petGrowthStageForLevel(pet.level));
  }

  String _growthValueLabel(Pet pet) {
    final threshold = pet.levelThreshold;
    if (threshold == null || threshold == 0) {
      return '满级';
    }
    return '${pet.experience} / $threshold';
  }

  List<_InteractionData> _buildRecentTasks() {
    final tasks = <_InteractionData>[];

    for (final entry in _history) {
      if (entry.eventType != 'task') {
        continue;
      }
      final trimmedTitle = entry.title.trim();
      tasks.add(
        _InteractionData(label: trimmedTitle.isEmpty ? '未命名任务' : trimmedTitle),
      );
      if (tasks.length == 3) {
        break;
      }
    }

    return tasks;
  }

  String _statusStampLabel(Pet pet) {
    final progress = pet.progress;
    if (progress >= 0.85) {
      return '闪亮';
    }
    if (progress >= 0.45) {
      return '成长';
    }
    return '关注';
  }
}

class _PetDetailColors {
  static const paywallPanelTop = Color(0xFFFCE8C1);
  static const paywallPanelBottom = Color(0xFFFEEDC9);
  static const background = Color(0xFFFDEBC6);
  static const ink = Color(0xFF684328);
  static const softInk = Color(0xFF88613E);
  static const progressTrack = Color(0xFFFFF6D9);
  static const progressBorder = Color(0xFF536F2B);
  static const progressFill = Color(0xFF9ABC4D);
  static const progressFillDark = Color(0xFF86A941);
  static const shadow = Color(0x28604429);
}

class _PetDetailFrameDecorations {
  const _PetDetailFrameDecorations._();

  static const outerPanel = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        _PetDetailColors.paywallPanelTop,
        _PetDetailColors.paywallPanelBottom,
      ],
    ),
    borderRadius: BorderRadius.all(Radius.circular(28)),
    border: Border.fromBorderSide(
      BorderSide(color: Color(0xFF6D4A2D), width: 4.2),
    ),
    boxShadow: [
      BoxShadow(
        color: _PetDetailColors.shadow,
        blurRadius: 22,
        offset: Offset(0, 10),
      ),
    ],
  );

  static const portraitFrame = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFEAC3), Color(0xFFF8D8A8)],
    ),
    borderRadius: BorderRadius.all(Radius.circular(20)),
    border: Border.fromBorderSide(
      BorderSide(color: Color(0xFF6D4A2D), width: 4),
    ),
  );

  static const recentPanel = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFF2D8), Color(0xFFF8E0BB)],
    ),
    borderRadius: BorderRadius.all(Radius.circular(22)),
    border: Border.fromBorderSide(
      BorderSide(color: Color(0xFF6D4A2D), width: 3.8),
    ),
  );

  static const stageCard = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFDEDD0), Color(0xFFFFF6E1)],
    ),
    borderRadius: BorderRadius.all(Radius.circular(16)),
    border: Border.fromBorderSide(
      BorderSide(color: Color(0xFF63843A), width: 3.6),
    ),
  );

  static const growthCard = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFEEECF), Color(0xFFFFF7E3)],
    ),
    borderRadius: BorderRadius.all(Radius.circular(16)),
    border: Border.fromBorderSide(
      BorderSide(color: Color(0xFFD8A21C), width: 3.6),
    ),
  );

  static const feedCard = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFDEACC), Color(0xFFFFF4DD)],
    ),
    borderRadius: BorderRadius.all(Radius.circular(16)),
    border: Border.fromBorderSide(
      BorderSide(color: Color(0xFFD07B2E), width: 3.6),
    ),
  );
}

class _PetDetailMetricIconFrames {
  const _PetDetailMetricIconFrames._();

  static const stagePlant = SpriteAtlasFrame(
    name: 'stage_plant_icon.png',
    textureRect: Rect.fromLTWH(823, 231, 68, 72),
    sourceRect: Rect.fromLTWH(0, 0, 68, 72),
    sourceSize: Size(68, 72),
    rotated: false,
    trimmed: false,
  );

  static const growthStar = SpriteAtlasFrame(
    name: 'growth_star_icon.png',
    textureRect: Rect.fromLTWH(814, 530, 74, 78),
    sourceRect: Rect.fromLTWH(0, 0, 74, 78),
    sourceSize: Size(74, 78),
    rotated: false,
    trimmed: false,
  );

  static const feedBowl = SpriteAtlasFrame(
    name: 'feed_bowl_icon.png',
    textureRect: Rect.fromLTWH(806, 740, 74, 76),
    sourceRect: Rect.fromLTWH(0, 0, 74, 76),
    sourceSize: Size(74, 76),
    rotated: false,
    trimmed: false,
  );
}

class _PetDetailFrameSurface extends StatelessWidget {
  const _PetDetailFrameSurface({
    required this.decoration,
    required this.child,
    this.foregroundPainter,
  });

  final BoxDecoration decoration;
  final Widget child;
  final CustomPainter? foregroundPainter;

  @override
  Widget build(BuildContext context) {
    final foregroundPainter = this.foregroundPainter;

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(decoration: decoration),
        child,
        if (foregroundPainter != null)
          IgnorePointer(child: CustomPaint(painter: foregroundPainter)),
      ],
    );
  }
}

class _RoundedDashedBorderPainter extends CustomPainter {
  const _RoundedDashedBorderPainter({
    required this.color,
    required this.inset,
    required this.radius,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashGap,
  });

  final Color color;
  final double inset;
  final double radius;
  final double strokeWidth;
  final double dashWidth;
  final double dashGap;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - (inset * 2),
      size.height - (inset * 2),
    );
    if (rect.width <= 0 || rect.height <= 0) {
      return;
    }

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    final paint = Paint()
      ..color = color
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + dashWidth, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dashWidth + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RoundedDashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.inset != inset ||
        oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashGap != dashGap;
  }
}

class _RecentPanelGuidesPainter extends CustomPainter {
  const _RecentPanelGuidesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const lineYs = <double>[84, 131];
    const left = 30.0;
    const rightInset = 28.0;
    const dashWidth = 9.0;
    const dashGap = 7.0;

    final paint = Paint()
      ..color = const Color(0xFFD0A670)
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2;

    for (final y in lineYs) {
      final right = size.width - rightInset;
      var x = left;
      while (x < right) {
        canvas.drawLine(
          Offset(x, y),
          Offset(math.min(x + dashWidth, right), y),
          paint,
        );
        x += dashWidth + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RecentPanelGuidesPainter oldDelegate) => false;
}

class _RecentPanelRibbon extends StatelessWidget {
  const _RecentPanelRibbon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _RecentPanelRibbonPainter(),
      child: const Center(
        child: Padding(
          padding: EdgeInsets.fromLTRB(25, 8, 25, 9),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '最近互动TOP3',
              maxLines: 1,
              style: TextStyle(
                fontSize: 24,
                height: 1,
                fontWeight: FontWeight.w900,
                color: Color(0xFFFFF7E7),
                shadows: [
                  Shadow(
                    color: Color(0x805E2F17),
                    offset: Offset(0, 1.2),
                    blurRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentPanelRibbonPainter extends CustomPainter {
  const _RecentPanelRibbonPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) {
      return;
    }

    final rect = Offset.zero & size;
    final path = _buildRibbonPath(size);
    final shadowPaint = Paint()
      ..color = const Color(0x22604429)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2)
      ..style = PaintingStyle.fill;
    final fillPaint = Paint()
      ..isAntiAlias = true
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFE98B45), Color(0xFFD97032)],
      ).createShader(rect);
    final borderPaint = Paint()
      ..color = const Color(0xFF96511F)
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path.shift(const Offset(0, 2)), shadowPaint);
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);
  }

  Path _buildRibbonPath(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.10, h * 0.10)
      ..lineTo(w * 0.88, h * 0.10)
      ..quadraticBezierTo(w * 0.94, h * 0.10, w * 0.95, h * 0.22)
      ..lineTo(w * 0.99, h * 0.50)
      ..lineTo(w * 0.95, h * 0.78)
      ..quadraticBezierTo(w * 0.94, h * 0.90, w * 0.88, h * 0.90)
      ..lineTo(w * 0.10, h * 0.90)
      ..quadraticBezierTo(w * 0.06, h * 0.90, w * 0.05, h * 0.78)
      ..lineTo(w * 0.01, h * 0.50)
      ..lineTo(w * 0.05, h * 0.22)
      ..quadraticBezierTo(w * 0.06, h * 0.10, w * 0.10, h * 0.10)
      ..close();
  }

  @override
  bool shouldRepaint(covariant _RecentPanelRibbonPainter oldDelegate) => false;
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.pet,
    required this.avatarAssetPath,
    required this.stageLabel,
    required this.growthValue,
    required this.ownerNameLabel,
    required this.recentTasks,
    required this.statusLabel,
    required this.loading,
    required this.onClose,
  });

  final Pet pet;
  final String? avatarAssetPath;
  final String stageLabel;
  final String growthValue;
  final String ownerNameLabel;
  final List<_InteractionData> recentTasks;
  final String statusLabel;
  final bool loading;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: PetDetailView.profileCardKey,
      width: PetDetailDesignLayout.designSize.width,
      height: PetDetailDesignLayout.designSize.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned.fill(
            child: _PetDetailFrameSurface(
              decoration: _PetDetailFrameDecorations.outerPanel,
              child: SizedBox.expand(),
            ),
          ),
          Positioned.fromRect(
            rect: PetDetailDesignLayout.nameBannerRect,
            child: _NameBanner(
              key: PetDetailView.nameBannerKey,
              text: pet.name,
            ),
          ),
          Positioned.fromRect(
            rect: PetDetailDesignLayout.portraitFrameRect,
            child: _PortraitFrame(
              key: PetDetailView.portraitFrameKey,
              pet: pet,
              avatarAssetPath: avatarAssetPath,
            ),
          ),
          Positioned.fromRect(
            rect: PetDetailDesignLayout.metricColumnRect,
            child: _MetricColumn(
              key: PetDetailView.metricColumnKey,
              stageLabel: stageLabel,
              level: pet.level,
              growthValue: growthValue,
              ownerNameLabel: ownerNameLabel,
              progress: pet.progress,
            ),
          ),
          Positioned.fromRect(
            rect: PetDetailDesignLayout.recentTasksPanelRect,
            child: _RecentTasksPanel(
              key: PetDetailView.recentTasksPanelKey,
              tasks: recentTasks,
              loading: loading,
            ),
          ),
          Positioned.fromRect(
            rect: PetDetailDesignLayout.achievementTagRect,
            child: _AchievementTag(
              key: PetDetailView.achievementTagKey,
              level: pet.level,
              statusLabel: statusLabel,
            ),
          ),
          if (onClose != null)
            Positioned.fromRect(
              rect: PetDetailDesignLayout.closeButtonRect,
              child: _PetDetailCloseButton(onPressed: onClose!),
            ),
        ],
      ),
    );
  }
}

class _PetDetailCloseButton extends StatelessWidget {
  const _PetDetailCloseButton({required this.onPressed});

  static const _assetPath = 'assets/images/ui/sprites/close.png';

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '关闭',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Image.asset(
          _assetPath,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}

class _NameBanner extends StatelessWidget {
  const _NameBanner({super.key, required this.text});

  static const _assetPath = 'assets/images/ui/sprites/pet-title.png';

  final String text;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          _assetPath,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
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
                  color: _PetDetailColors.ink,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PortraitFrame extends StatelessWidget {
  const _PortraitFrame({
    super.key,
    required this.pet,
    required this.avatarAssetPath,
  });

  final Pet pet;
  final String? avatarAssetPath;

  @override
  Widget build(BuildContext context) {
    return _PetDetailFrameSurface(
      decoration: _PetDetailFrameDecorations.portraitFrame,
      foregroundPainter: const _RoundedDashedBorderPainter(
        color: Color(0xFFE8B56E),
        inset: 15,
        radius: 14,
        strokeWidth: 2,
        dashWidth: 8,
        dashGap: 8,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 30),
        child: Center(
          child: _PetPoseImage(pet: pet, assetPath: avatarAssetPath),
        ),
      ),
    );
  }
}

class _PetPoseImage extends StatelessWidget {
  const _PetPoseImage({required this.pet, required this.assetPath});

  final Pet pet;
  final String? assetPath;

  @override
  Widget build(BuildContext context) {
    final resolvedAssetPath =
        assetPath ??
        petGrowthAvatarAssetPath(
          pet.petType,
          pet.level,
          deterministicPetGrowthPoseIndex(pet.petType, pet.level, pet.id),
        );

    final normalizedType = normalizePetType(pet.petType);
    final widthFactor = normalizedType == 'turtle' ? 0.90 : 0.96;
    final heightFactor = normalizedType == 'turtle' ? 0.86 : 0.94;

    return FractionallySizedBox(
      widthFactor: widthFactor,
      heightFactor: heightFactor,
      child: Image.asset(
        resolvedAssetPath,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, _, _) =>
            const Icon(Icons.pets_rounded, size: 82, color: Color(0xFF628222)),
      ),
    );
  }
}

class _MetricColumn extends StatelessWidget {
  const _MetricColumn({
    super.key,
    required this.stageLabel,
    required this.level,
    required this.growthValue,
    required this.ownerNameLabel,
    required this.progress,
  });

  final String stageLabel;
  final int level;
  final String growthValue;
  final String ownerNameLabel;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MetricCard(
          decoration: _PetDetailFrameDecorations.stageCard,
          iconFrame: _PetDetailMetricIconFrames.stagePlant,
          iconLeft: 12,
          iconTop: 15,
          iconSize: 39,
          title: '成长阶段',
          value: '$stageLabel (LV$level)',
          progress: progress,
          height: 100,
        ),
        const SizedBox(height: 11),
        _MetricCard(
          decoration: _PetDetailFrameDecorations.growthCard,
          iconFrame: _PetDetailMetricIconFrames.growthStar,
          iconLeft: 12,
          iconTop: 16,
          iconSize: 39,
          title: '成长值',
          value: growthValue,
          height: 82,
        ),
        const SizedBox(height: 12),
        _MetricCard(
          decoration: _PetDetailFrameDecorations.feedCard,
          iconFrame: _PetDetailMetricIconFrames.feedBowl,
          iconLeft: 12,
          iconTop: 16,
          iconSize: 40,
          title: '所属人员',
          value: ownerNameLabel,
          height: 82,
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.decoration,
    required this.iconFrame,
    required this.iconLeft,
    required this.iconTop,
    required this.iconSize,
    required this.title,
    required this.value,
    required this.height,
    this.progress,
  });

  final BoxDecoration decoration;
  final SpriteAtlasFrame iconFrame;
  final double iconLeft;
  final double iconTop;
  final double iconSize;
  final String title;
  final String value;
  final double height;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: _PetDetailFrameSurface(
        decoration: decoration,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              left: iconLeft,
              top: iconTop,
              width: iconSize,
              height: iconSize,
              child: _PetDetailSprite(
                frame: iconFrame,
                fit: BoxFit.contain,
                sampleInset: 0,
              ),
            ),
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
                  color: _PetDetailColors.ink,
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
                    color: _PetDetailColors.ink,
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
                child: _SpriteProgressBar(value: progress!),
              ),
          ],
        ),
      ),
    );
  }
}

class _SpriteProgressBar extends StatelessWidget {
  const _SpriteProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final clampedValue = value.clamp(0.0, 1.0).toDouble();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _PetDetailColors.progressTrack,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _PetDetailColors.progressBorder, width: 1.6),
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
                  colors: [
                    _PetDetailColors.progressFill,
                    _PetDetailColors.progressFillDark,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentTasksPanel extends StatelessWidget {
  const _RecentTasksPanel({
    super.key,
    required this.tasks,
    required this.loading,
  });

  final List<_InteractionData> tasks;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Positioned(
          left: 0,
          top: 24,
          right: 0,
          bottom: 0,
          child: _PetDetailFrameSurface(
            decoration: _PetDetailFrameDecorations.recentPanel,
            child: SizedBox.expand(),
          ),
        ),
        const Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _RecentPanelGuidesPainter()),
          ),
        ),
        const Positioned(
          left: 13,
          top: -8,
          width: 184,
          height: 48,
          child: _RecentPanelRibbon(),
        ),
        if (loading && tasks.isEmpty)
          const Positioned(
            left: 40,
            top: 98,
            right: 24,
            child: Text(
              '加载中...',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: _PetDetailColors.softInk,
              ),
            ),
          )
        else if (tasks.isEmpty)
          const Positioned(
            left: 42,
            top: 98,
            right: 24,
            child: Text(
              '还没有完成任务',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: _PetDetailColors.softInk,
              ),
            ),
          )
        else
          for (var index = 0; index < tasks.length; index++)
            _InteractionRow(
              data: tasks[index],
              top: <double>[52, 94, 136][index],
            ),
      ],
    );
  }
}

class _InteractionRow extends StatelessWidget {
  const _InteractionRow({required this.data, required this.top});

  final _InteractionData data;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 42,
      top: top,
      right: 24,
      height: 34,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          data.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 18,
            height: 1,
            fontWeight: FontWeight.w900,
            color: _PetDetailColors.ink,
          ),
        ),
      ),
    );
  }
}

class _AchievementTag extends StatelessWidget {
  const _AchievementTag({
    super.key,
    required this.level,
    required this.statusLabel,
  });

  static const _assetPath = 'assets/images/ui/sprites/label_blank.png';
  static const _aspectRatio = 266 / 368;

  final int level;
  final String statusLabel;

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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 70,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'LV$level',
                          style: const TextStyle(
                            fontSize: 22,
                            height: 1,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFD46F35),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statusLabel,
                      style: const TextStyle(
                        fontSize: 19,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF6E9245),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '成就',
                      style: TextStyle(
                        fontSize: 19,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        color: _PetDetailColors.ink,
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

class _PetDetailSprite extends StatelessWidget {
  const _PetDetailSprite({
    required this.frame,
    this.fit = BoxFit.contain,
    this.sampleInset = 1,
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
      filterQuality: FilterQuality.high,
      sampleInset: sampleInset,
    );
  }
}

class _InteractionData {
  const _InteractionData({required this.label});

  final String label;
}
