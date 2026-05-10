import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/sprite_atlas.dart';
import '../../../models/pet.dart';
import '../../../models/pet_artwork.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/pet_detail_service.dart';
import '../models/pet_history_entry.dart';
import '../pet_detail_sprite_catalog.dart';

class PetDetailView extends ConsumerStatefulWidget {
  const PetDetailView({
    super.key,
    required this.pet,
    this.avatarAssetPath,
    this.embedded = false,
    this.onClose,
  });

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
    final horizontalPadding = widget.embedded ? 8.0 : 20.0;
    final content = SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        widget.embedded ? 28 : 32,
        horizontalPadding,
        widget.embedded ? 16 : 28,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: widget.embedded ? 412 : 448),
          child: DefaultTextStyle.merge(
            style: const TextStyle(
              color: _PetDetailColors.ink,
              decoration: TextDecoration.none,
              decorationColor: Colors.transparent,
              fontWeight: FontWeight.w800,
            ),
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
    );

    if (widget.embedded) {
      return content;
    }

    return ColoredBox(
      color: _PetDetailColors.background,
      child: SafeArea(child: content),
    );
  }

  String _stageLabel(Pet pet) {
    return switch (pet.level) {
      1 => '幼崽期',
      2 => '成长期',
      3 => '活力期',
      4 => '闪耀期',
      _ => '传奇期',
    };
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
  static const background = Color(0xFFF3E0C4);
  static const ink = Color(0xFF684328);
  static const softInk = Color(0xFF88613E);
  static const progressTrack = Color(0xFFFFF6D9);
  static const progressBorder = Color(0xFF536F2B);
  static const progressFill = Color(0xFF9ABC4D);
  static const progressFillDark = Color(0xFF86A941);
  static const shadow = Color(0x28604429);
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
    return AspectRatio(
      aspectRatio: 499 / 793,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          double x(double value) => width * value / 412;
          double y(double value) => height * value / 655;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: _PetDetailColors.shadow,
                        blurRadius: 22,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const _PetDetailSprite(
                    frame: PetDetailSheetSpriteCatalog.panelBlank,
                    fit: BoxFit.fill,
                    sampleInset: 1,
                  ),
                ),
              ),
              Positioned(
                top: y(-18),
                left: x(76),
                width: x(260),
                height: y(86),
                child: _NameBanner(text: pet.name),
              ),
              Positioned(
                left: x(34),
                top: y(94),
                width: x(186),
                height: y(268),
                child: _PortraitFrame(
                  pet: pet,
                  avatarAssetPath: avatarAssetPath,
                ),
              ),
              Positioned(
                left: x(226),
                top: y(98),
                width: x(166),
                child: _MetricColumn(
                  stageLabel: stageLabel,
                  level: pet.level,
                  growthValue: growthValue,
                  ownerNameLabel: ownerNameLabel,
                  progress: pet.progress,
                ),
              ),
              Positioned(
                left: x(30),
                top: y(401),
                width: x(248),
                height: y(207),
                child: _RecentTasksPanel(tasks: recentTasks, loading: loading),
              ),
              Positioned(
                left: x(274),
                top: y(388),
                width: x(128),
                height: y(205),
                child: _AchievementTag(
                  level: pet.level,
                  statusLabel: statusLabel,
                ),
              ),
              if (onClose != null)
                Positioned(
                  top: y(18),
                  right: x(16),
                  width: x(52),
                  height: x(52),
                  child: _PetDetailCloseButton(onPressed: onClose!),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _PetDetailCloseButton extends StatelessWidget {
  const _PetDetailCloseButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '关闭',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _NameBanner extends StatelessWidget {
  const _NameBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const _PetDetailSprite(
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
  const _PortraitFrame({required this.pet, required this.avatarAssetPath});

  final Pet pet;
  final String? avatarAssetPath;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const _PetDetailSprite(
          frame: PetDetailSheetSpriteCatalog.portraitFrameBlank,
          fit: BoxFit.fill,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
          child: Center(
            child: _PetPoseImage(pet: pet, assetPath: avatarAssetPath),
          ),
        ),
      ],
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
        petAvatarAssetPath(
          pet.petType,
          deterministicPetPoseIndex(pet.petType, pet.id),
        );

    return Image.asset(
      resolvedAssetPath,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, _, _) =>
          const Icon(Icons.pets_rounded, size: 82, color: Color(0xFF628222)),
    );
  }
}

class _MetricColumn extends StatelessWidget {
  const _MetricColumn({
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
          frame: PetDetailSheetSpriteCatalog.stageCard,
          title: '成长阶段',
          value: '$stageLabel (LV$level)',
          progress: progress,
          height: 100,
        ),
        const SizedBox(height: 11),
        _MetricCard(
          frame: PetDetailSheetSpriteCatalog.growthCard,
          title: '成长值',
          value: growthValue,
          height: 82,
        ),
        const SizedBox(height: 12),
        _MetricCard(
          frame: PetDetailSheetSpriteCatalog.feedCard,
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
          _PetDetailSprite(frame: frame, fit: BoxFit.fill),
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
            top: progress == null ? 40 : 40,
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
  const _RecentTasksPanel({required this.tasks, required this.loading});

  final List<_InteractionData> tasks;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const _PetDetailSprite(
          frame: PetDetailSheetSpriteCatalog.recentPanel,
          fit: BoxFit.fill,
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
  const _AchievementTag({required this.level, required this.statusLabel});

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
      filterQuality: FilterQuality.high,
      sampleInset: sampleInset,
    );
  }
}

class _InteractionData {
  const _InteractionData({required this.label});

  final String label;
}
