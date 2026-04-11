import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/pet.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/pet_avatar.dart';
import '../../widgets/user_avatar.dart';
import '../pet/pet_detail_screen.dart';

class _PadProfileColors {
  static const background = Color(0xFFFFFBF2);
  static const shell = Color(0xFFF7F0DE);
  static const card = Color(0xFFFFFFFF);
  static const cardSoft = Color(0xFFF7F3E9);
  static const text = Color(0xFF43391E);
  static const muted = Color(0xFF7B6E4B);
  static const green = Color(0xFF15752E);
  static const greenSoft = Color(0xFFD6ECC8);
  static const blue = Color(0xFFDDECF9);
  static const blueText = Color(0xFF2F5985);
  static const gold = Color(0xFFF4E2A8);
  static const goldText = Color(0xFF8A6508);
  static const coral = Color(0xFFF7DED5);
  static const coralText = Color(0xFFAE4B2F);
}

class MemberProfileIpadScreen extends ConsumerStatefulWidget {
  const MemberProfileIpadScreen({
    super.key,
    required this.memberId,
    required this.nickname,
    required this.role,
  });

  final int memberId;
  final String nickname;
  final String role;

  @override
  ConsumerState<MemberProfileIpadScreen> createState() =>
      _MemberProfileIpadScreenState();
}

class _MemberProfileIpadScreenState
    extends ConsumerState<MemberProfileIpadScreen> {
  List<Pet> _pets = [];
  List<Map<String, dynamic>> _completions = [];
  int _memberPoints = 0;
  String? _avatarUrl;
  bool _loading = true;
  DateTime? _joinDate;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = ref.read(authProvider).user;
    if (user?.familyId == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _pets = [];
        _completions = [];
        _memberPoints = 0;
        _avatarUrl = null;
        _joinDate = null;
        _loading = false;
      });
      return;
    }

    try {
      final dio = ref.read(apiClientProvider).dio;
      final familyId = user!.familyId!;
      final results = await Future.wait([
        dio.get('/api/families/$familyId/members'),
        dio.get('/api/families/$familyId/pets'),
        dio.get('/api/families/$familyId/completions'),
      ]);

      final members = (results[0].data as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      final currentMember = members.firstWhere(
        (member) => member['id'] == widget.memberId,
        orElse: () => <String, dynamic>{'points': 0},
      );

      final pets = (results[1].data as List)
          .map((item) => Pet.fromJson(Map<String, dynamic>.from(item as Map)))
          .where((pet) => pet.ownerId == widget.memberId)
          .toList();

      final completions =
          (results[2].data as List)
              .map((item) => Map<String, dynamic>.from(item as Map))
              .where((completion) => completion['member_id'] == widget.memberId)
              .toList()
            ..sort((a, b) {
              final timeA = (a['created_at'] ?? '').toString();
              final timeB = (b['created_at'] ?? '').toString();
              return timeB.compareTo(timeA);
            });

      DateTime? joinDate;
      if (completions.isNotEmpty) {
        joinDate = DateTime.tryParse(
          (completions.last['created_at'] ?? '').toString(),
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _memberPoints = currentMember['points'] as int? ?? 0;
        _avatarUrl = currentMember['avatar_url']?.toString();
        _pets = pets;
        _completions = completions;
        _joinDate = joinDate;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _deleteMember() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除成员'),
        content: Text('确认删除“${widget.nickname}”？该成员名下宠物也会一起删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) {
      return;
    }

    try {
      final user = ref.read(authProvider).user;
      final dio = ref.read(apiClientProvider).dio;
      await dio.delete(
        '/api/families/${user!.familyId}/members/${widget.memberId}',
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('成员已删除')));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('删除失败：$e')));
    }
  }

  bool get _canEditAvatar {
    final authUser = ref.read(authProvider).user;
    if (authUser == null) {
      return false;
    }
    return authUser.id == widget.memberId ||
        (authUser.isAdmin && authUser.familyId != null);
  }

  Future<void> _changeAvatar() async {
    if (!_canEditAvatar) {
      return;
    }

    String? selectedAvatarValue = _avatarUrl;
    final pickedAvatar = await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: _PadProfileColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '更换头像',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: _PadProfileColors.text,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: UserAvatar(
                        nickname: widget.nickname,
                        avatarValue: selectedAvatarValue,
                        size: 78,
                        backgroundColor: const Color(0xFFFFE8C2),
                        foregroundColor: const Color(0xFF755700),
                        border: Border.all(
                          color: const Color(0x33A87500),
                          width: 2,
                        ),
                        fontSize: 32,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _AvatarOptionChip(
                          label: '默认',
                          selected: selectedAvatarValue == null,
                          onTap: () {
                            setModalState(() => selectedAvatarValue = null);
                          },
                          child: UserAvatar(
                            nickname: widget.nickname,
                            avatarValue: null,
                            size: 42,
                            border: Border.all(
                              color: const Color(0x33A87500),
                              width: 1.4,
                            ),
                          ),
                        ),
                        for (final emoji in presetAvatarEmojis)
                          _AvatarOptionChip(
                            label: emoji,
                            selected:
                                selectedAvatarValue ==
                                userAvatarValueFromEmoji(emoji),
                            onTap: () {
                              setModalState(
                                () => selectedAvatarValue =
                                    userAvatarValueFromEmoji(emoji),
                              );
                            },
                            child: Center(
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 28),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            child: const Text('取消'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => Navigator.of(
                              sheetContext,
                            ).pop(selectedAvatarValue),
                            child: const Text('保存'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (pickedAvatar == _avatarUrl) {
      return;
    }

    try {
      final dio = ref.read(apiClientProvider).dio;
      await dio.put(
        '/api/users/${widget.memberId}',
        data: {'avatar_url': pickedAvatar},
      );
      await _loadData();
      if (ref.read(authProvider).user?.id == widget.memberId) {
        await ref.read(authProvider.notifier).refreshUser();
      }
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('头像已更新')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('头像更新失败：$error')));
    }
  }

  String _joinDateText() {
    if (_joinDate == null) {
      return '暂无';
    }
    return '${_joinDate!.year}/${_joinDate!.month}/${_joinDate!.day}';
  }

  String _formatActivityTime(String raw) {
    final time = DateTime.tryParse(raw);
    if (time == null) {
      return '';
    }
    return '${time.month}/${time.day} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _taskTypeLabel(String rawType) {
    return switch (rawType) {
      'limited' => '限时任务',
      'challenge' => '挑战任务',
      _ => '日常任务',
    };
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isAdmin = authState.user?.isAdmin == true && !authState.viewOnly;
    final isNotSelf = authState.user?.id != widget.memberId;
    final canDelete = isAdmin && isNotSelf;
    final avatarEmoji = _pets.isNotEmpty
        ? _pets.first.displayEmoji
        : (widget.role == 'admin' ? '🧑' : '👤');

    return Scaffold(
      backgroundColor: _PadProfileColors.background,
      appBar: AppBar(
        leading: Navigator.of(context).canPop()
            ? IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
              )
            : null,
        title: const Text('成员详情'),
        backgroundColor: _PadProfileColors.background,
        foregroundColor: _PadProfileColors.text,
        surfaceTintColor: _PadProfileColors.background,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 28),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: _PadProfileColors.shell,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: _OverviewPanel(
                          avatarEmoji: avatarEmoji,
                          avatarValue: _avatarUrl,
                          nickname: widget.nickname,
                          role: widget.role,
                          points: _memberPoints,
                          canDelete: canDelete,
                          canEditAvatar: _canEditAvatar,
                          onEditAvatar: _changeAvatar,
                          onDelete: _deleteMember,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 5,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _MetricCard(
                                    label: '完成任务',
                                    value: '${_completions.length}',
                                    background: _PadProfileColors.blue,
                                    foreground: _PadProfileColors.blueText,
                                    icon: Icons.task_alt_rounded,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _MetricCard(
                                    label: '当前积分',
                                    value: '$_memberPoints',
                                    background: _PadProfileColors.gold,
                                    foreground: _PadProfileColors.goldText,
                                    icon: Icons.bolt_rounded,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _MetricCard(
                                    label: '加入时间',
                                    value: _joinDateText(),
                                    background: _PadProfileColors.greenSoft,
                                    foreground: _PadProfileColors.green,
                                    icon: Icons.calendar_month_rounded,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _PanelCard(
                              title: '宠物伙伴',
                              child: _pets.isEmpty
                                  ? const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 26,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '还没有宠物伙伴',
                                          style: TextStyle(
                                            color: _PadProfileColors.muted,
                                          ),
                                        ),
                                      ),
                                    )
                                  : GridView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 3,
                                            crossAxisSpacing: 12,
                                            mainAxisSpacing: 12,
                                            childAspectRatio: 0.98,
                                          ),
                                      itemCount: _pets.length,
                                      itemBuilder: (context, index) {
                                        final pet = _pets[index];
                                        return _PetCard(
                                          pet: pet,
                                          onTap: () =>
                                              Navigator.of(
                                                    context,
                                                    rootNavigator: true,
                                                  )
                                                  .push(
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          PetDetailScreen(
                                                            pet: pet,
                                                          ),
                                                    ),
                                                  )
                                                  .then((_) => _loadData()),
                                        );
                                      },
                                    ),
                            ),
                            const SizedBox(height: 16),
                            _PanelCard(
                              title: '最近记录',
                              child: _completions.isEmpty
                                  ? const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 26,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '还没有完成记录',
                                          style: TextStyle(
                                            color: _PadProfileColors.muted,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Column(
                                      children: _completions
                                          .map(
                                            (completion) => Padding(
                                              padding: const EdgeInsets.only(
                                                top: 10,
                                              ),
                                              child: _ActivityRow(
                                                title:
                                                    (completion['task_title'] ??
                                                            '任务 #${completion['task_id']}')
                                                        .toString(),
                                                taskTypeLabel: _taskTypeLabel(
                                                  (completion['task_type'] ??
                                                          'daily')
                                                      .toString(),
                                                ),
                                                points:
                                                    completion['task_points']
                                                        as int? ??
                                                    0,
                                                timeLabel: _formatActivityTime(
                                                  (completion['created_at'] ??
                                                          '')
                                                      .toString(),
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _OverviewPanel extends StatelessWidget {
  const _OverviewPanel({
    required this.avatarEmoji,
    required this.avatarValue,
    required this.nickname,
    required this.role,
    required this.points,
    required this.canDelete,
    required this.canEditAvatar,
    required this.onEditAvatar,
    required this.onDelete,
  });

  final String avatarEmoji;
  final String? avatarValue;
  final String nickname;
  final String role;
  final int points;
  final bool canDelete;
  final bool canEditAvatar;
  final VoidCallback onEditAvatar;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == 'admin';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _PadProfileColors.card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              color: _PadProfileColors.cardSoft,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Container(
                  width: 150,
                  height: 150,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF8E9),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: UserAvatar(
                      nickname: nickname,
                      avatarValue:
                          avatarValue ?? userAvatarValueFromEmoji(avatarEmoji),
                      size: 120,
                      backgroundColor: const Color(0xFFFFF8E9),
                      foregroundColor: const Color(0xFF755700),
                      fontSize: 52,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  nickname,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: _PadProfileColors.text,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Pill(
                      label: isAdmin ? '家长成员' : '家庭成员',
                      background: isAdmin
                          ? _PadProfileColors.gold
                          : _PadProfileColors.blue,
                      foreground: isAdmin
                          ? _PadProfileColors.goldText
                          : _PadProfileColors.blueText,
                    ),
                    _Pill(
                      label: '$points 分',
                      background: _PadProfileColors.greenSoft,
                      foreground: _PadProfileColors.green,
                    ),
                  ],
                ),
                if (canEditAvatar) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: onEditAvatar,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('更换头像'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _PadProfileColors.green,
                      side: const BorderSide(color: _PadProfileColors.green),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '成员档案',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _PadProfileColors.text,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '保留成员积分、宠物清单、删除成员和任务记录等原有功能，同时将布局调整为更接近设计稿的信息卡片风格。',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: _PadProfileColors.muted,
            ),
          ),
          if (canDelete) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('删除该成员'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _PadProfileColors.coralText,
                  side: const BorderSide(color: _PadProfileColors.coralText),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.background,
    required this.foreground,
    required this.icon,
  });

  final String label;
  final String value;
  final Color background;
  final Color foreground;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: foreground),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: foreground,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelCard extends StatelessWidget {
  const _PanelCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _PadProfileColors.card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _PadProfileColors.text,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _PetCard extends StatelessWidget {
  const _PetCard({required this.pet, required this.onTap});

  final Pet pet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final levelThreshold = pet.levelThreshold ?? 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _PadProfileColors.cardSoft,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PetAvatar(pet: pet, size: 66),
              const SizedBox(height: 12),
              Text(
                pet.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _PadProfileColors.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                pet.levelName,
                style: const TextStyle(
                  fontSize: 12,
                  color: _PadProfileColors.muted,
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: pet.progress,
                  minHeight: 8,
                  backgroundColor: Colors.white,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    _PadProfileColors.green,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "${pet.experience}/${levelThreshold == 0 ? '满级' : levelThreshold}",
                style: const TextStyle(
                  fontSize: 11,
                  color: _PadProfileColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.title,
    required this.taskTypeLabel,
    required this.points,
    required this.timeLabel,
  });

  final String title;
  final String taskTypeLabel;
  final int points;
  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    final isPositive = points >= 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _PadProfileColors.cardSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isPositive
                  ? _PadProfileColors.greenSoft
                  : _PadProfileColors.coral,
              borderRadius: BorderRadius.circular(999),
            ),
            alignment: Alignment.center,
            child: Icon(
              isPositive ? Icons.arrow_upward_rounded : Icons.remove_rounded,
              color: isPositive
                  ? _PadProfileColors.green
                  : _PadProfileColors.coralText,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _PadProfileColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (isPositive
                                ? _PadProfileColors.green
                                : _PadProfileColors.coralText)
                            .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '已完成任务 · $taskTypeLabel',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isPositive
                          ? _PadProfileColors.green
                          : _PadProfileColors.coralText,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  timeLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _PadProfileColors.muted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isPositive ? '+' : ''}$points',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: isPositive
                  ? _PadProfileColors.green
                  : _PadProfileColors.coralText,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: foreground,
        ),
      ),
    );
  }
}

class _AvatarOptionChip extends StatelessWidget {
  const _AvatarOptionChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 72,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE1F7D8) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? const Color(0xFF006B1B) : const Color(0xFFE3D7B8),
            width: selected ? 2 : 1.2,
          ),
        ),
        child: Column(
          children: [
            SizedBox(width: 42, height: 42, child: child),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected
                    ? const Color(0xFF006B1B)
                    : const Color(0xFF755700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
