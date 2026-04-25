import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/pet.dart';
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
    final content = SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        widget.embedded ? 12 : 20,
        widget.embedded ? 24 : 24,
        widget.embedded ? 12 : 20,
        widget.embedded ? 18 : 28,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: widget.embedded ? 412 : 448),
          child: DefaultTextStyle.merge(
            style: const TextStyle(
              decoration: TextDecoration.none,
              decorationColor: Colors.transparent,
            ),
            child: _ProfileCard(
              pet: pet,
              stageLabel: _stageLabel(pet),
              growthValue: _growthValueLabel(pet),
              feedCountLabel: _feedCountLabel(),
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

  String _feedCountLabel() {
    final count = _todayFeedCount();
    return '$count次/天';
  }

  int _todayFeedCount() {
    final now = DateTime.now();
    var todayCount = 0;
    var totalCount = 0;

    for (final entry in _history) {
      if (entry.eventType != 'feed') {
        continue;
      }
      totalCount += 1;
      final createdAt = entry.createdAt;
      if (createdAt == null) {
        continue;
      }
      if (createdAt.year == now.year &&
          createdAt.month == now.month &&
          createdAt.day == now.day) {
        todayCount += 1;
      }
    }

    return todayCount > 0 ? todayCount : totalCount;
  }

  List<_InteractionData> _buildRecentTasks() {
    final tasks = <_InteractionData>[];
    final icons = <IconData>[
      Icons.pan_tool_alt_rounded,
      Icons.content_cut_rounded,
      Icons.sports_baseball_rounded,
    ];

    for (final entry in _history) {
      if (entry.eventType != 'task') {
        continue;
      }
      tasks.add(
        _InteractionData(
          label: entry.title.trim().isEmpty ? '完成任务' : entry.title.trim(),
          icon: icons[tasks.length % icons.length],
          highlight: tasks.isEmpty,
        ),
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
  static const background = Color(0xFFDCE5EA);
  static const paper = Color(0xFFF3EBDD);
  static const paperSoft = Color(0xFFE9DFCF);
  static const accent = Color(0xFFC9B7A1);
  static const accentStrong = Color(0xFFAA9577);
  static const highlight = Color(0xFFDDD2BF);
  static const ink = Color(0xFF5B4632);
  static const line = Color(0xFF6A5237);
  static const green = Color(0xFF869A77);
  static const greenTrack = Color(0xFFD2C9BA);
  static const shadow = Color(0x16212A30);
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.pet,
    required this.stageLabel,
    required this.growthValue,
    required this.feedCountLabel,
    required this.recentTasks,
    required this.statusLabel,
    required this.loading,
    required this.onClose,
  });

  final Pet pet;
  final String stageLabel;
  final String growthValue;
  final String feedCountLabel;
  final List<_InteractionData> recentTasks;
  final String statusLabel;
  final bool loading;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 38, 16, 16),
          decoration: BoxDecoration(
            color: _PetDetailColors.paper,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: _PetDetailColors.line, width: 3),
            boxShadow: const [
              BoxShadow(
                color: _PetDetailColors.shadow,
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 310;

                  if (isCompact) {
                    return Column(
                      children: [
                        _PortraitFrame(pet: pet),
                        const SizedBox(height: 12),
                        _MetricColumn(
                          stageLabel: stageLabel,
                          level: pet.level,
                          growthValue: growthValue,
                          feedCountLabel: feedCountLabel,
                          progress: pet.progress,
                        ),
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _PortraitFrame(pet: pet)),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 124,
                        child: _MetricColumn(
                          stageLabel: stageLabel,
                          level: pet.level,
                          growthValue: growthValue,
                          feedCountLabel: feedCountLabel,
                          progress: pet.progress,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: _RecentTasksPanel(
                      tasks: recentTasks,
                      loading: loading,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _AchievementTag(level: pet.level, statusLabel: statusLabel),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          top: -18,
          left: 0,
          right: 0,
          child: Center(child: _NameBanner(text: pet.name)),
        ),
        if (onClose != null)
          Positioned(
            top: -14,
            right: 14,
            child: _PetDetailCloseButton(onPressed: onClose!),
          ),
      ],
    );
  }
}

class _PetDetailCloseButton extends StatelessWidget {
  const _PetDetailCloseButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFF9EF),
      shape: const CircleBorder(
        side: BorderSide(color: _PetDetailColors.line, width: 2.5),
      ),
      elevation: 4,
      shadowColor: _PetDetailColors.shadow,
      child: IconButton(
        onPressed: onPressed,
        tooltip: '关闭',
        icon: const Icon(Icons.close_rounded),
        color: _PetDetailColors.ink,
        iconSize: 19,
        constraints: const BoxConstraints.tightFor(width: 36, height: 36),
        padding: EdgeInsets.zero,
        splashRadius: 20,
      ),
    );
  }
}

class _PortraitFrame extends StatelessWidget {
  const _PortraitFrame({required this.pet});

  final Pet pet;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 228,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _PetDetailColors.paper,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _PetDetailColors.line, width: 3),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: _PetDetailColors.paperSoft,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: _PetDetailColors.line, width: 3),
          boxShadow: const [
            BoxShadow(
              color: Color(0x143D5A66),
              blurRadius: 20,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: PetAvatar(pet: pet, size: 132, showBackground: false),
        ),
      ),
    );
  }
}

class _MetricColumn extends StatelessWidget {
  const _MetricColumn({
    required this.stageLabel,
    required this.level,
    required this.growthValue,
    required this.feedCountLabel,
    required this.progress,
  });

  final String stageLabel;
  final int level;
  final String growthValue;
  final String feedCountLabel;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MetricCard(
          title: '成长阶段',
          icon: Icons.spa_outlined,
          value: '$stageLabel (LV$level)',
          progress: progress,
        ),
        const SizedBox(height: 10),
        _MetricCard(
          title: '成长值',
          icon: Icons.star_border_rounded,
          value: growthValue,
        ),
        const SizedBox(height: 10),
        _MetricCard(
          title: '喂养次数',
          icon: Icons.lunch_dining_outlined,
          value: feedCountLabel,
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.icon,
    required this.value,
    this.progress,
  });

  final String title;
  final IconData icon;
  final String value;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: _PetDetailColors.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _PetDetailColors.line, width: 3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: _PetDetailColors.ink),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: _PetDetailColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: _PetDetailColors.ink,
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: _PetDetailColors.greenTrack,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  _PetDetailColors.green,
                ),
              ),
            ),
          ],
        ],
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
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(10, 30, 10, 10),
          decoration: BoxDecoration(
            color: _PetDetailColors.paper,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _PetDetailColors.line, width: 3),
          ),
          child: Column(
            children: [
              if (loading && tasks.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: CircularProgressIndicator(
                    color: _PetDetailColors.green,
                  ),
                )
              else if (tasks.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    '还没有完成任务',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _PetDetailColors.ink,
                    ),
                  ),
                )
              else
                for (var index = 0; index < tasks.length; index++) ...[
                  _InteractionRow(data: tasks[index]),
                  if (index != tasks.length - 1) const SizedBox(height: 8),
                ],
            ],
          ),
        ),
        const Positioned(
          top: -12,
          left: 0,
          child: _RibbonLabel(text: '最近互动TOP3'),
        ),
      ],
    );
  }
}

class _InteractionRow extends StatelessWidget {
  const _InteractionRow({required this.data});

  final _InteractionData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: data.highlight
            ? _PetDetailColors.highlight
            : _PetDetailColors.paperSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _PetDetailColors.line, width: 2.5),
      ),
      child: Row(
        children: [
          Icon(data.icon, size: 18, color: _PetDetailColors.ink),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              data.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: _PetDetailColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementTag extends StatelessWidget {
  const _AchievementTag({required this.level, required this.statusLabel});

  final int level;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 0.14,
      child: Container(
        width: 78,
        padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
        decoration: BoxDecoration(
          color: _PetDetailColors.paper,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _PetDetailColors.line, width: 3),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned(
              top: -10,
              right: -4,
              child: Icon(
                Icons.star_rounded,
                size: 24,
                color: _PetDetailColors.accentStrong,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'LV$level',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: _PetDetailColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  statusLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: _PetDetailColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  '成就',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: _PetDetailColors.ink,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NameBanner extends StatelessWidget {
  const _NameBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return _BannerShell(
      backgroundColor: _PetDetailColors.accent,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: _PetDetailColors.ink,
        ),
      ),
    );
  }
}

class _RibbonLabel extends StatelessWidget {
  const _RibbonLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return _BannerShell(
      backgroundColor: _PetDetailColors.accent,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: _PetDetailColors.ink,
        ),
      ),
    );
  }
}

class _BannerShell extends StatelessWidget {
  const _BannerShell({
    required this.backgroundColor,
    required this.padding,
    required this.child,
  });

  final Color backgroundColor;
  final EdgeInsetsGeometry padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _PetDetailColors.line, width: 3),
      ),
      child: child,
    );
  }
}

class _InteractionData {
  const _InteractionData({
    required this.label,
    required this.icon,
    this.highlight = false,
  });

  final String label;
  final IconData icon;
  final bool highlight;
}
