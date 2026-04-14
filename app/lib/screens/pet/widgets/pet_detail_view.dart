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
    final body = LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = widget.embedded ? 18.0 : 20.0;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            widget.embedded ? 18 : 20,
            horizontalPadding,
            widget.embedded ? 18 : 28,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(pet),
              const SizedBox(height: 16),
              _buildSummaryCards(pet, constraints.maxWidth),
              const SizedBox(height: 16),
              _buildProgressCard(pet),
              const SizedBox(height: 16),
              _buildHistorySection(),
            ],
          ),
        );
      },
    );

    if (widget.embedded) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF8EED8),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: const Color(0xFF7A5733).withValues(alpha: 0.28),
          ),
        ),
        child: body,
      );
    }

    return ColoredBox(
      color: const Color(0xFFF5F1E8),
      child: SafeArea(bottom: false, child: body),
    );
  }

  Widget _buildHeader(Pet pet) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE9D5AC), Color(0xFFDAB986)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '宠物档案',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF5A3A21),
                  ),
                ),
              ),
              if (widget.onClose != null)
                IconButton(
                  onPressed: widget.onClose,
                  tooltip: '关闭',
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF5A3A21),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: PetAvatar(pet: pet, size: 72, showBackground: false),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pet.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF5A3A21),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_petTypeName(pet)} · ${_stageLabel(pet)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6A4A31),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _HeaderChip(
                          icon: Icons.workspace_premium_rounded,
                          label: '等级 ${pet.level}',
                        ),
                        _HeaderChip(
                          icon: Icons.favorite_rounded,
                          label: _moodLabel(pet),
                        ),
                        if ((pet.ownerNickname ?? '').trim().isNotEmpty)
                          _HeaderChip(
                            icon: Icons.person_rounded,
                            label: '${pet.ownerNickname} 的伙伴',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(Pet pet, double width) {
    const spacing = 10.0;
    final cardWidth = math.max(120.0, (width - 20 - spacing * 2) / 3);

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: [
        SizedBox(
          width: cardWidth,
          child: _InfoCard(
            title: '当前成长',
            value: '${pet.experience}',
            caption: '已获得成长值',
            icon: Icons.bolt_rounded,
            accent: const Color(0xFF3A8E36),
            background: const Color(0xFFE2F0D7),
          ),
        ),
        SizedBox(
          width: cardWidth,
          child: _InfoCard(
            title: '下一目标',
            value: _nextGoalValue(pet),
            caption: _nextGoalCaption(pet),
            icon: Icons.flag_rounded,
            accent: const Color(0xFF8B5E16),
            background: const Color(0xFFF7E5BC),
          ),
        ),
        SizedBox(
          width: cardWidth,
          child: _InfoCard(
            title: '关键状态',
            value: pet.isEgg ? '等待孵化' : '成长中',
            caption: pet.levelThreshold == null ? '当前已满级' : '继续完成任务可提升',
            icon: Icons.insights_rounded,
            accent: const Color(0xFF4A6E9C),
            background: const Color(0xFFDCEAF8),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCard(Pet pet) {
    final threshold = pet.levelThreshold;
    final nextLabel = threshold == null || threshold == 0
        ? '已经达到当前形态的最高等级'
        : '距离下一等级还差 ${math.max(threshold - pet.experience, 0)} 点成长值';

    return _SectionCard(
      title: '成长进度',
      subtitle: nextLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: pet.progress,
                    minHeight: 12,
                    backgroundColor: const Color(0xFFF1E4C7),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF7A5733),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                threshold == null || threshold == 0
                    ? '满级'
                    : '${pet.experience}/$threshold',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF5A3A21),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _StatePill(label: '类型：${_petTypeName(pet)}'),
              _StatePill(label: '阶段：${_stageLabel(pet)}'),
              _StatePill(label: '心情：${_moodLabel(pet)}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    return _SectionCard(
      title: '最近成长记录',
      subtitle: '这里会展示喂养、任务和成长变化',
      child: _loading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            )
          : _history.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                '暂时还没有新的成长记录，先去完成一项任务吧。',
                style: TextStyle(color: Color(0xFF816447), height: 1.5),
              ),
            )
          : Column(
              children: _history.take(widget.embedded ? 5 : 8).map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _HistoryTile(entry: entry),
                );
              }).toList(),
            ),
    );
  }

  String _petTypeName(Pet pet) {
    if (pet.isEgg) {
      return '宠物蛋';
    }
    return petTypeLabel(pet.petType);
  }

  String _stageLabel(Pet pet) {
    if (pet.isEgg) {
      return '孵化前';
    }
    return switch (pet.level) {
      1 => '幼崽期',
      2 => '成长期',
      3 => '活力期',
      4 => '闪耀期',
      _ => '传奇期',
    };
  }

  String _moodLabel(Pet pet) {
    if (pet.isEgg) {
      return '静待孵化';
    }
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

  String _nextGoalValue(Pet pet) {
    final threshold = pet.levelThreshold;
    if (threshold == null || threshold == 0) {
      return '已满级';
    }
    return '${math.max(threshold - pet.experience, 0)}';
  }

  String _nextGoalCaption(Pet pet) {
    final threshold = pet.levelThreshold;
    if (threshold == null || threshold == 0) {
      return '当前阶段已毕业';
    }
    return '距离下一等级';
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF6A4A31)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6A4A31),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF3),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF5A3A21),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              height: 1.4,
              color: Color(0xFF816447),
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.value,
    required this.caption,
    required this.icon,
    required this.accent,
    required this.background,
  });

  final String title;
  final String value;
  final String caption;
  final IconData icon;
  final Color accent;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: accent),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: accent,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            caption,
            style: const TextStyle(fontSize: 11, color: Color(0xFF6A4A31)),
          ),
        ],
      ),
    );
  }
}

class _StatePill extends StatelessWidget {
  const _StatePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E4C7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF6A4A31),
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.entry});

  final PetHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final accent = entry.isPositive
        ? const Color(0xFF3A8E36)
        : const Color(0xFFB85C4A);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F1E0),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(_iconFor(entry.eventType), color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF5A3A21),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${entry.subtitle} · ${_formatTime(entry.createdAt)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF816447),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${entry.isPositive ? '+' : ''}${entry.points}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String eventType) {
    return switch (eventType) {
      'feed' => Icons.restaurant_rounded,
      'hatch' => Icons.egg_alt_rounded,
      'task' => Icons.task_alt_rounded,
      _ => Icons.auto_awesome_rounded,
    };
  }

  String _formatTime(DateTime? time) {
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
