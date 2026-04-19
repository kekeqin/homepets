import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/pet.dart';
import '../../../models/pet_artwork.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/pet_detail_service.dart';
import '../../../widgets/pet_avatar.dart';
import '../models/pet_history_entry.dart';

class PetDetailView extends ConsumerStatefulWidget {
  const PetDetailView({
    super.key,
    required this.pet,
    this.embedded = false,
    this.onClose,
  });

  final Pet pet;
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
    final stageLabel = _stageLabel(pet);
    final moodLabel = _moodLabel(pet);
    final scrollPadding = EdgeInsets.fromLTRB(
      widget.embedded ? 18 : 20,
      widget.embedded ? 18 : 22,
      widget.embedded ? 18 : 20,
      widget.embedded ? 20 : 28,
    );

    final content = Stack(
      children: [
        const Positioned(
          top: -42,
          right: -24,
          child: _WashBlob(
            width: 176,
            height: 176,
            color: _PetDetailPalette.washHoney,
          ),
        ),
        const Positioned(
          top: 168,
          left: -34,
          child: _WashBlob(
            width: 124,
            height: 124,
            color: _PetDetailPalette.washGreen,
          ),
        ),
        const Positioned(
          bottom: 88,
          right: -18,
          child: _WashBlob(
            width: 126,
            height: 126,
            color: _PetDetailPalette.washCoral,
          ),
        ),
        const Positioned(
          left: 26,
          top: 120,
          child: _BrickMarks(color: _PetDetailPalette.paperShadow),
        ),
        const Positioned(
          right: 24,
          bottom: 156,
          child: _BrickMarks(color: _PetDetailPalette.paperShadow),
        ),
        SingleChildScrollView(
          padding: scrollPadding,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 600;
              final notes = _buildStickyNotes(
                pet: pet,
                moodLabel: moodLabel,
                stageLabel: stageLabel,
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PetHeroCard(
                    pet: pet,
                    stageLabel: stageLabel,
                    moodLabel: moodLabel,
                    ownerLabel: _ownerLabel(pet),
                    typeLabel: _petTypeName(pet),
                    progressNote: _progressNote(pet),
                    onClose: widget.onClose,
                  ),
                  const SizedBox(height: 16),
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 7,
                          child: _GrowthNotebook(
                            pet: pet,
                            stageLabel: stageLabel,
                            moodLabel: moodLabel,
                            typeLabel: _petTypeName(pet),
                            progressNote: _progressNote(pet),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          flex: 5,
                          child: _StickyNoteBoard(notes: notes),
                        ),
                      ],
                    )
                  else ...[
                    _GrowthNotebook(
                      pet: pet,
                      stageLabel: stageLabel,
                      moodLabel: moodLabel,
                      typeLabel: _petTypeName(pet),
                      progressNote: _progressNote(pet),
                    ),
                    const SizedBox(height: 16),
                    _StickyNoteBoard(notes: notes),
                  ],
                  const SizedBox(height: 16),
                  _HistoryNotebook(
                    loading: _loading,
                    entries: _history.take(widget.embedded ? 5 : 8).toList(),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );

    final decorated = DecoratedBox(
      decoration: BoxDecoration(
        color: widget.embedded
            ? _PetDetailPalette.embeddedBackground
            : _PetDetailPalette.background,
        borderRadius: widget.embedded ? BorderRadius.circular(30) : null,
        border: widget.embedded
            ? Border.all(color: _PetDetailPalette.ink.withValues(alpha: 0.18))
            : null,
      ),
      child: content,
    );

    if (widget.embedded) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: decorated,
      );
    }

    return ColoredBox(
      color: _PetDetailPalette.background,
      child: SafeArea(bottom: false, child: decorated),
    );
  }

  List<_StickyNoteData> _buildStickyNotes({
    required Pet pet,
    required String moodLabel,
    required String stageLabel,
  }) {
    return <_StickyNoteData>[
      _StickyNoteData(
        title: '当前成长值',
        value: '${pet.experience}',
        note: '今天每次互动都会继续累积。',
        icon: Icons.auto_awesome_rounded,
        color: _PetDetailPalette.noteHoney,
        accent: _PetDetailPalette.honeyDeep,
        angle: -0.028,
      ),
      _StickyNoteData(
        title: '距离升级',
        value: _remainingValue(pet),
        note: _remainingNote(pet),
        icon: Icons.star_rounded,
        color: _PetDetailPalette.noteGreen,
        accent: _PetDetailPalette.greenDeep,
        angle: 0.024,
      ),
      _StickyNoteData(
        title: '今日状态',
        value: moodLabel,
        note: '这会影响这张档案页现在的气质。',
        icon: Icons.favorite_rounded,
        color: _PetDetailPalette.noteCoral,
        accent: _PetDetailPalette.coralDeep,
        angle: 0.018,
      ),
      _StickyNoteData(
        title: '成长阶段',
        value: stageLabel,
        note: '${_petTypeName(pet)}小伙伴正在慢慢长大。',
        icon: Icons.eco_rounded,
        color: _PetDetailPalette.paperMuted,
        accent: _PetDetailPalette.ink,
        angle: -0.018,
      ),
    ];
  }

  String _petTypeName(Pet pet) => petTypeLabel(pet.petType);

  String _stageLabel(Pet pet) {
    return switch (pet.level) {
      1 => '幼崽期',
      2 => '成长期',
      3 => '活力期',
      4 => '闪耀期',
      _ => '传奇期',
    };
  }

  String _moodLabel(Pet pet) {
    final progress = pet.progress;
    if (progress >= 0.85) {
      return '活力满满';
    }
    if (progress >= 0.55) {
      return '开心玩耍';
    }
    if (progress >= 0.25) {
      return '认真成长';
    }
    return '需要鼓励';
  }

  String _progressNote(Pet pet) {
    final threshold = pet.levelThreshold;
    if (threshold == null || threshold == 0) {
      return '已经来到满级阶段，是家里最闪亮的小伙伴。';
    }
    final remaining = math.max(threshold - pet.experience, 0);
    return '再收集 $remaining 点成长值，就能升到 Lv.${pet.level + 1}。';
  }

  String _remainingValue(Pet pet) {
    final threshold = pet.levelThreshold;
    if (threshold == null || threshold == 0) {
      return '满级';
    }
    return '${math.max(threshold - pet.experience, 0)}';
  }

  String _remainingNote(Pet pet) {
    final threshold = pet.levelThreshold;
    if (threshold == null || threshold == 0) {
      return '这一阶段已经全部完成。';
    }
    return '离下一级只差一点点。';
  }

  String _ownerLabel(Pet pet) {
    final owner = pet.ownerNickname?.trim();
    if (owner == null || owner.isEmpty) {
      return '家庭小伙伴';
    }
    return '$owner 的伙伴';
  }
}

class _PetDetailPalette {
  static const background = Color(0xFFF8EEDF);
  static const embeddedBackground = Color(0xFFF7EAD8);
  static const paper = Color(0xFFFFFBF2);
  static const paperMuted = Color(0xFFF5E9D5);
  static const paperWarm = Color(0xFFF7E7BF);
  static const noteHoney = Color(0xFFF6E4AA);
  static const noteGreen = Color(0xFFDCE9C7);
  static const noteCoral = Color(0xFFF4D7CD);
  static const washHoney = Color(0xFFF3D79F);
  static const washGreen = Color(0xFFDCEAC2);
  static const washCoral = Color(0xFFF2D3C7);
  static const honey = Color(0xFFE5BD6F);
  static const honeyDeep = Color(0xFF9A6A1A);
  static const green = Color(0xFF98B96C);
  static const greenDeep = Color(0xFF427139);
  static const coral = Color(0xFFDEA48F);
  static const coralDeep = Color(0xFFAF5C45);
  static const ink = Color(0xFF664625);
  static const inkSoft = Color(0xFF866C49);
  static const paperShadow = Color(0x18000000);
}

class _PetHeroCard extends StatelessWidget {
  const _PetHeroCard({
    required this.pet,
    required this.stageLabel,
    required this.moodLabel,
    required this.ownerLabel,
    required this.typeLabel,
    required this.progressNote,
    this.onClose,
  });

  final Pet pet;
  final String stageLabel;
  final String moodLabel;
  final String ownerLabel;
  final String typeLabel;
  final String progressNote;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return _PaperPanel(
      color: _PetDetailPalette.paper,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _PaperTapeLabel(
                text: '宠物档案',
                background: _PetDetailPalette.paperWarm,
                foreground: _PetDetailPalette.ink,
              ),
              const Spacer(),
              _PaperBadge(
                icon: Icons.workspace_premium_rounded,
                label: 'Lv.${pet.level}',
                background: _PetDetailPalette.noteHoney,
                foreground: _PetDetailPalette.honeyDeep,
              ),
              if (onClose != null) ...[
                const SizedBox(width: 8),
                _CircleInkButton(
                  tooltip: '关闭',
                  icon: Icons.close_rounded,
                  onTap: onClose,
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 520;

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PetStageCard(pet: pet, moodLabel: moodLabel),
                    const SizedBox(width: 18),
                    Expanded(
                      child: _HeroInfoColumn(
                        pet: pet,
                        stageLabel: stageLabel,
                        ownerLabel: ownerLabel,
                        typeLabel: typeLabel,
                        moodLabel: moodLabel,
                        progressNote: progressNote,
                      ),
                    ),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: _PetStageCard(pet: pet, moodLabel: moodLabel),
                  ),
                  const SizedBox(height: 16),
                  _HeroInfoColumn(
                    pet: pet,
                    stageLabel: stageLabel,
                    ownerLabel: ownerLabel,
                    typeLabel: typeLabel,
                    moodLabel: moodLabel,
                    progressNote: progressNote,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HeroInfoColumn extends StatelessWidget {
  const _HeroInfoColumn({
    required this.pet,
    required this.stageLabel,
    required this.ownerLabel,
    required this.typeLabel,
    required this.moodLabel,
    required this.progressNote,
  });

  final Pet pet;
  final String stageLabel;
  final String ownerLabel;
  final String typeLabel;
  final String moodLabel;
  final String progressNote;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          pet.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 32,
            height: 1.05,
            fontWeight: FontWeight.w900,
            color: _PetDetailPalette.ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$typeLabel · $stageLabel',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _PetDetailPalette.inkSoft,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _PaperBadge(
              icon: Icons.favorite_rounded,
              label: moodLabel,
              background: _PetDetailPalette.noteCoral,
              foreground: _PetDetailPalette.coralDeep,
            ),
            _PaperBadge(
              icon: Icons.person_rounded,
              label: ownerLabel,
              background: _PetDetailPalette.noteGreen,
              foreground: _PetDetailPalette.greenDeep,
            ),
            _PaperBadge(
              icon: Icons.auto_awesome_rounded,
              label: pet.displayEmoji,
              background: _PetDetailPalette.paperMuted,
              foreground: _PetDetailPalette.ink,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: _PetDetailPalette.paperWarm.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _PetDetailPalette.ink.withValues(alpha: 0.14),
            ),
          ),
          child: Text(
            progressNote,
            style: const TextStyle(
              fontSize: 13,
              height: 1.6,
              fontWeight: FontWeight.w600,
              color: _PetDetailPalette.ink,
            ),
          ),
        ),
      ],
    );
  }
}

class _PetStageCard extends StatelessWidget {
  const _PetStageCard({required this.pet, required this.moodLabel});

  final Pet pet;
  final String moodLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 204,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _PetDetailPalette.paperMuted,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: _PetDetailPalette.ink.withValues(alpha: 0.15),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 18,
            top: -6,
            child: _TapePiece(
              width: 46,
              color: _PetDetailPalette.noteHoney.withValues(alpha: 0.8),
            ),
          ),
          Positioned(
            right: 18,
            top: -4,
            child: _TapePiece(
              width: 38,
              color: _PetDetailPalette.noteGreen.withValues(alpha: 0.76),
            ),
          ),
          Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: _PaperBadge(
                  icon: Icons.eco_rounded,
                  label: moodLabel,
                  background: _PetDetailPalette.paper,
                  foreground: _PetDetailPalette.inkSoft,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                height: 156,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _PetDetailPalette.paper,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: _PetDetailPalette.ink.withValues(alpha: 0.12),
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      bottom: 22,
                      child: Container(
                        width: 110,
                        height: 28,
                        decoration: BoxDecoration(
                          color: _PetDetailPalette.noteGreen,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const Positioned(
                      top: 18,
                      left: 20,
                      child: Icon(
                        Icons.star_rounded,
                        color: _PetDetailPalette.honey,
                        size: 18,
                      ),
                    ),
                    const Positioned(
                      top: 22,
                      right: 24,
                      child: Icon(
                        Icons.eco_rounded,
                        color: _PetDetailPalette.green,
                        size: 18,
                      ),
                    ),
                    PetAvatar(pet: pet, size: 118, showBackground: false),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GrowthNotebook extends StatelessWidget {
  const _GrowthNotebook({
    required this.pet,
    required this.stageLabel,
    required this.moodLabel,
    required this.typeLabel,
    required this.progressNote,
  });

  final Pet pet;
  final String stageLabel;
  final String moodLabel;
  final String typeLabel;
  final String progressNote;

  @override
  Widget build(BuildContext context) {
    final threshold = pet.levelThreshold;
    final maxed = threshold == null || threshold == 0;

    return _PaperPanel(
      color: _PetDetailPalette.paper,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeading(
            title: '成长纸条',
            subtitle: '把每一次喂养和任务都贴进这本成长手帐里。',
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _PetDetailPalette.paperWarm.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: Text(
                        '成长进度',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: _PetDetailPalette.ink,
                        ),
                      ),
                    ),
                    _PaperBadge(
                      icon: maxed
                          ? Icons.workspace_premium_rounded
                          : Icons.arrow_upward_rounded,
                      label: maxed ? '已经满级' : '${pet.experience}/$threshold',
                      background: _PetDetailPalette.paper,
                      foreground: _PetDetailPalette.ink,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  progressNote,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.55,
                    color: _PetDetailPalette.inkSoft,
                  ),
                ),
                const SizedBox(height: 14),
                _PaperProgressBar(progress: pet.progress, maxed: maxed),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _InfoPill(
                      icon: Icons.pets_rounded,
                      label: typeLabel,
                      background: _PetDetailPalette.paper,
                    ),
                    _InfoPill(
                      icon: Icons.auto_awesome_rounded,
                      label: stageLabel,
                      background: _PetDetailPalette.paper,
                    ),
                    _InfoPill(
                      icon: Icons.favorite_rounded,
                      label: moodLabel,
                      background: _PetDetailPalette.paper,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StickyNoteBoard extends StatelessWidget {
  const _StickyNoteBoard({required this.notes});

  final List<_StickyNoteData> notes;

  @override
  Widget build(BuildContext context) {
    return _PaperPanel(
      color: _PetDetailPalette.paper,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeading(title: '成长便签', subtitle: '把最重要的几件小事先贴在最上面。'),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final singleColumn = constraints.maxWidth < 260;
              final columns = singleColumn ? 1 : 2;
              const spacing = 12.0;
              final width =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: notes
                    .map(
                      (note) => SizedBox(
                        width: width,
                        child: Transform.rotate(
                          angle: note.angle,
                          child: _StickyNoteCard(data: note),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HistoryNotebook extends StatelessWidget {
  const _HistoryNotebook({required this.loading, required this.entries});

  final bool loading;
  final List<PetHistoryEntry> entries;

  @override
  Widget build(BuildContext context) {
    return _PaperPanel(
      color: _PetDetailPalette.paper,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeading(
            title: '最近记录',
            subtitle: '每一张便签都记着一次喂养、一次任务，或者一次小升级。',
          ),
          const SizedBox(height: 14),
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(
                  color: _PetDetailPalette.greenDeep,
                ),
              ),
            )
          else if (entries.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _PetDetailPalette.paperMuted,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Text(
                '暂时还没有新的成长记录，先去完成一项任务吧。',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.6,
                  color: _PetDetailPalette.inkSoft,
                ),
              ),
            )
          else
            Column(
              children: [
                for (var index = 0; index < entries.length; index++)
                  _TimelineRow(
                    entry: entries[index],
                    isLast: index == entries.length - 1,
                    angle: index.isEven ? -0.012 : 0.014,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.entry,
    required this.isLast,
    required this.angle,
  });

  final PetHistoryEntry entry;
  final bool isLast;
  final double angle;

  @override
  Widget build(BuildContext context) {
    final palette = _HistoryPalette.fromEntry(entry);

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: palette.dotColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _PetDetailPalette.ink.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Icon(
                    _timelineIcon(entry.eventType),
                    size: 11,
                    color: palette.iconColor,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 62,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: _PetDetailPalette.ink.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Transform.rotate(
              angle: angle,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: palette.cardColor,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: _PetDetailPalette.ink.withValues(alpha: 0.14),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            entry.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: _PetDetailPalette.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _PaperBadge(
                          icon: entry.isPositive
                              ? Icons.add_rounded
                              : Icons.remove_rounded,
                          label:
                              '${entry.isPositive ? '+' : ''}${entry.points}',
                          background: _PetDetailPalette.paper,
                          foreground: entry.isPositive
                              ? _PetDetailPalette.greenDeep
                              : _PetDetailPalette.coralDeep,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      entry.subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: _PetDetailPalette.inkSoft,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _PaperTapeLabel(
                        text: _formatTime(entry.createdAt),
                        background: _PetDetailPalette.paper.withValues(
                          alpha: 0.82,
                        ),
                        foreground: _PetDetailPalette.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static IconData _timelineIcon(String eventType) {
    return switch (eventType) {
      'feed' => Icons.restaurant_rounded,
      'task' => Icons.task_alt_rounded,
      _ => Icons.auto_awesome_rounded,
    };
  }

  static String _formatTime(DateTime? time) {
    if (time == null) {
      return '刚刚';
    }
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) {
      return '刚刚';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} 分钟前';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} 小时前';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays} 天前';
    }
    return '${time.month}月${time.day}日';
  }
}

class _HistoryPalette {
  const _HistoryPalette({
    required this.cardColor,
    required this.dotColor,
    required this.iconColor,
  });

  final Color cardColor;
  final Color dotColor;
  final Color iconColor;

  factory _HistoryPalette.fromEntry(PetHistoryEntry entry) {
    if (entry.eventType == 'feed') {
      return const _HistoryPalette(
        cardColor: _PetDetailPalette.noteGreen,
        dotColor: _PetDetailPalette.green,
        iconColor: _PetDetailPalette.greenDeep,
      );
    }
    if (entry.eventType == 'task') {
      return const _HistoryPalette(
        cardColor: _PetDetailPalette.noteHoney,
        dotColor: _PetDetailPalette.honey,
        iconColor: _PetDetailPalette.honeyDeep,
      );
    }
    return const _HistoryPalette(
      cardColor: _PetDetailPalette.noteCoral,
      dotColor: _PetDetailPalette.coral,
      iconColor: _PetDetailPalette.coralDeep,
    );
  }
}

class _PaperPanel extends StatelessWidget {
  const _PaperPanel({
    required this.child,
    this.color = _PetDetailPalette.paper,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: _PetDetailPalette.ink.withValues(alpha: 0.14),
        ),
        boxShadow: const [
          BoxShadow(
            color: _PetDetailPalette.paperShadow,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: _PetDetailPalette.ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            height: 1.55,
            color: _PetDetailPalette.inkSoft,
          ),
        ),
      ],
    );
  }
}

class _PaperProgressBar extends StatelessWidget {
  const _PaperProgressBar({required this.progress, required this.maxed});

  final double progress;
  final bool maxed;

  @override
  Widget build(BuildContext context) {
    final safeProgress = progress.clamp(0.0, 1.0).toDouble();

    return LayoutBuilder(
      builder: (context, constraints) {
        const knobSize = 24.0;
        final knobLeft = math.max(
          0.0,
          safeProgress * (constraints.maxWidth - knobSize),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Text(
                  '开始成长',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _PetDetailPalette.inkSoft,
                  ),
                ),
                Spacer(),
                Text(
                  '成长终点',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _PetDetailPalette.inkSoft,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 34,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: _PetDetailPalette.paper,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: _PetDetailPalette.ink.withValues(alpha: 0.14),
                        ),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: maxed
                              ? 1
                              : math.max(safeProgress, 0.08).toDouble(),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  _PetDetailPalette.green,
                                  _PetDetailPalette.honey,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: knobLeft,
                    top: 5,
                    child: Container(
                      width: knobSize,
                      height: knobSize,
                      decoration: BoxDecoration(
                        color: _PetDetailPalette.paperWarm,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _PetDetailPalette.ink.withValues(alpha: 0.14),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: _PetDetailPalette.paperShadow,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        maxed
                            ? Icons.workspace_premium_rounded
                            : Icons.star_rounded,
                        size: 15,
                        color: _PetDetailPalette.honeyDeep,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    required this.background,
  });

  final IconData icon;
  final String label;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: _PetDetailPalette.ink.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: _PetDetailPalette.inkSoft),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _PetDetailPalette.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaperBadge extends StatelessWidget {
  const _PaperBadge({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: foreground.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaperTapeLabel extends StatelessWidget {
  const _PaperTapeLabel({
    required this.text,
    required this.background,
    required this.foreground,
  });

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: foreground,
        ),
      ),
    );
  }
}

class _CircleInkButton extends StatelessWidget {
  const _CircleInkButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _PetDetailPalette.paperMuted,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _PetDetailPalette.ink.withValues(alpha: 0.14),
              ),
            ),
            child: Icon(icon, size: 18, color: _PetDetailPalette.ink),
          ),
        ),
      ),
    );
  }
}

class _StickyNoteData {
  const _StickyNoteData({
    required this.title,
    required this.value,
    required this.note,
    required this.icon,
    required this.color,
    required this.accent,
    required this.angle,
  });

  final String title;
  final String value;
  final String note;
  final IconData icon;
  final Color color;
  final Color accent;
  final double angle;
}

class _StickyNoteCard extends StatelessWidget {
  const _StickyNoteCard({required this.data});

  final _StickyNoteData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: data.color,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _PetDetailPalette.ink.withValues(alpha: 0.12),
        ),
        boxShadow: const [
          BoxShadow(
            color: _PetDetailPalette.paperShadow,
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(data.icon, size: 18, color: data.accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  data.title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: data.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            data.value,
            style: TextStyle(
              fontSize: 22,
              height: 1.1,
              fontWeight: FontWeight.w900,
              color: data.accent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data.note,
            style: const TextStyle(
              fontSize: 11,
              height: 1.5,
              color: _PetDetailPalette.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _TapePiece extends StatelessWidget {
  const _TapePiece({required this.width, required this.color});

  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.1,
      child: Container(
        width: width,
        height: 16,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}

class _WashBlob extends StatelessWidget {
  const _WashBlob({
    required this.width,
    required this.height,
    required this.color,
  });

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(
            math.max(width, height).toDouble(),
          ),
        ),
      ),
    );
  }
}

class _BrickMarks extends StatelessWidget {
  const _BrickMarks({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BrickMark(width: 18, color: color),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.only(left: 14),
            child: _BrickMark(width: 12, color: _PetDetailPalette.paperShadow),
          ),
          const SizedBox(height: 26),
          const Padding(
            padding: EdgeInsets.only(left: 30),
            child: _BrickMark(width: 20, color: _PetDetailPalette.paperShadow),
          ),
        ],
      ),
    );
  }
}

class _BrickMark extends StatelessWidget {
  const _BrickMark({required this.width, required this.color});

  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 6,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
