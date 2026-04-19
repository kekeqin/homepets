import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/pet.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/pet_avatar.dart';
import '../pet/pet_detail_screen.dart';

class _MemberHomeColors {
  static const background = Color(0xFFF7F1DD);
  static const card = Color(0xFFF0E8D3);
  static const cardSoft = Color(0xFFF8F4EA);
  static const text = Color(0xFF4C3D1F);
  static const muted = Color(0xFF7A6B48);
  static const green = Color(0xFF0B7A2A);
  static const greenDark = Color(0xFF065E1F);
  static const blue = Color(0xFFD8EAF9);
  static const blueText = Color(0xFF2F5B88);
  static const gold = Color(0xFFF4E1A5);
  static const goldText = Color(0xFF8A6508);
  static const pink = Color(0xFFF4D8E7);
  static const pinkText = Color(0xFF8E4B6C);
}

class MemberHomeScreen extends ConsumerStatefulWidget {
  const MemberHomeScreen({super.key});

  @override
  ConsumerState<MemberHomeScreen> createState() => _MemberHomeScreenState();
}

class _MemberHomeScreenState extends ConsumerState<MemberHomeScreen> {
  List<Pet> _myPets = [];
  List<Map<String, dynamic>> _todayTasks = [];
  List<Map<String, dynamic>> _recentActivities = [];
  bool _loading = true;

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
        _myPets = [];
        _todayTasks = [];
        _recentActivities = [];
        _loading = false;
      });
      return;
    }

    try {
      final dio = ref.read(apiClientProvider).dio;
      final familyId = user!.familyId!;
      final userId = user.id;

      final results = await Future.wait([
        dio.get('/api/families/$familyId/pets'),
        dio.get('/api/families/$familyId/tasks'),
        dio.get('/api/families/$familyId/completions'),
      ]);

      final pets = (results[0].data as List)
          .map((item) => Pet.fromJson(Map<String, dynamic>.from(item as Map)))
          .where((pet) => pet.ownerId == userId)
          .toList();

      final tasks = (results[1].data as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final todayTasks = tasks.where((task) {
        final dueDate = DateTime.tryParse((task['due_date'] ?? '').toString());
        if (dueDate == null) {
          return false;
        }
        final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
        return dueDay == today;
      }).toList();

      final activities =
          (results[2].data as List)
              .map((item) => Map<String, dynamic>.from(item as Map))
              .where((completion) => completion['member_id'] == userId)
              .toList()
            ..sort((a, b) {
              final timeA = (a['created_at'] ?? '').toString();
              final timeB = (b['created_at'] ?? '').toString();
              return timeB.compareTo(timeA);
            });

      if (!mounted) {
        return;
      }

      setState(() {
        _myPets = pets;
        _todayTasks = todayTasks;
        _recentActivities = activities.take(10).toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _greeting(int hour) {
    if (hour < 6) {
      return '夜深了';
    }
    if (hour < 12) {
      return '早上好';
    }
    if (hour < 18) {
      return '下午好';
    }
    return '晚上好';
  }

  String _formatTimeAgo(String raw) {
    final date = DateTime.tryParse(raw);
    if (date == null) {
      return '';
    }
    final diff = DateTime.now().difference(date);
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
    return '${date.month}/${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isTablet = MediaQuery.sizeOf(context).width >= 900;
    final maxWidth = isTablet ? 980.0 : 460.0;
    final nickname = (user?.nickname ?? '成员').toString();
    final greeting = _greeting(DateTime.now().hour);

    return Scaffold(
      backgroundColor: _MemberHomeColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 32),
                    children: [
                      _MemberHero(
                        greeting: greeting,
                        nickname: nickname,
                        points: user?.points ?? 0,
                        petCount: _myPets.length,
                        taskCount: _todayTasks.length,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricCard(
                              label: '今日任务',
                              value: '${_todayTasks.length}',
                              background: _MemberHomeColors.blue,
                              foreground: _MemberHomeColors.blueText,
                              icon: Icons.task_alt_rounded,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _MetricCard(
                              label: '我的宠物',
                              value: '${_myPets.length}',
                              background: _MemberHomeColors.gold,
                              foreground: _MemberHomeColors.goldText,
                              icon: Icons.pets_rounded,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _MetricCard(
                              label: '最近记录',
                              value: '${_recentActivities.length}',
                              background: _MemberHomeColors.pink,
                              foreground: _MemberHomeColors.pinkText,
                              icon: Icons.history_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _SectionCard(
                        title: '今日任务',
                        child: _todayTasks.isEmpty
                            ? const _EmptySection(
                                icon: '🛋️',
                                title: '今天没有安排任务',
                                message: '可以好好休息，也可以看看宠物现在过得怎么样。',
                              )
                            : SizedBox(
                                height: 142,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _todayTasks.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(width: 10),
                                  itemBuilder: (context, index) =>
                                      _TaskCard(task: _todayTasks[index]),
                                ),
                              ),
                      ),
                      const SizedBox(height: 12),
                      _SectionCard(
                        title: '我的宠物',
                        child: _myPets.isEmpty
                            ? const _EmptySection(
                                icon: '🥚',
                                title: '还没有宠物伙伴',
                                message: '完成任务后会更容易孵化和养成属于你的宠物。',
                              )
                            : SizedBox(
                                height: 168,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _myPets.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(width: 10),
                                  itemBuilder: (context, index) {
                                    final pet = _myPets[index];
                                    return _PetCard(
                                      pet: pet,
                                      onTap: () => showPetDetailDialog(
                                        context,
                                        pet: pet,
                                      ).then((_) => _loadData()),
                                    );
                                  },
                                ),
                              ),
                      ),
                      const SizedBox(height: 12),
                      _SectionCard(
                        title: '最近活动',
                        child: _recentActivities.isEmpty
                            ? const _EmptySection(
                                icon: '📝',
                                title: '还没有活动记录',
                                message: '完成任务之后，这里会自动出现你的成长轨迹。',
                              )
                            : Column(
                                children: _recentActivities
                                    .map(
                                      (activity) => Padding(
                                        padding: const EdgeInsets.only(top: 10),
                                        child: _ActivityTile(
                                          title:
                                              (activity['task_title'] ??
                                                      '任务 #${activity['task_id']}')
                                                  .toString(),
                                          points:
                                              activity['task_points'] as int? ??
                                              0,
                                          timeLabel: _formatTimeAgo(
                                            (activity['created_at'] ?? '')
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
              ),
            ),
    );
  }
}

class _MemberHero extends StatelessWidget {
  const _MemberHero({
    required this.greeting,
    required this.nickname,
    required this.points,
    required this.petCount,
    required this.taskCount,
  });

  final String greeting;
  final String nickname;
  final int points;
  final int petCount;
  final int taskCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _MemberHomeColors.card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '成员主页',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _MemberHomeColors.muted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$greeting，$nickname',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: _MemberHomeColors.text,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '今天也来看看你的宠物和任务进度吧。',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: _MemberHomeColors.muted,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Pill(
                      label: '⚡ $points',
                      background: _MemberHomeColors.gold,
                      foreground: _MemberHomeColors.goldText,
                    ),
                    _Pill(
                      label: '🐾 $petCount 只宠物',
                      background: const Color(0xFFD7ECCB),
                      foreground: _MemberHomeColors.greenDark,
                    ),
                    _Pill(
                      label: '📋 $taskCount 个今日任务',
                      background: _MemberHomeColors.blue,
                      foreground: _MemberHomeColors.blueText,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: _MemberHomeColors.cardSoft,
              borderRadius: BorderRadius.circular(26),
            ),
            alignment: Alignment.center,
            child: const Text('🧁', style: TextStyle(fontSize: 38)),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _MemberHomeColors.card,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _MemberHomeColors.text,
            ),
          ),
          const SizedBox(height: 10),
          child,
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: foreground),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: foreground,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task});

  final Map<String, dynamic> task;

  @override
  Widget build(BuildContext context) {
    final title = (task['title'] ?? '未命名任务').toString();
    final points = task['points'] as int? ?? 0;
    final completed = task['is_completed'] == true;
    final type = (task['task_type'] ?? 'daily').toString();
    final badgeColor = switch (type) {
      'limited' => _MemberHomeColors.gold,
      'challenge' => _MemberHomeColors.pink,
      _ => _MemberHomeColors.blue,
    };
    final badgeTextColor = switch (type) {
      'limited' => _MemberHomeColors.goldText,
      'challenge' => _MemberHomeColors.pinkText,
      _ => _MemberHomeColors.blueText,
    };

    return Container(
      width: 180,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: completed ? const Color(0xFFD7ECCB) : _MemberHomeColors.cardSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  switch (type) {
                    'limited' => '限时',
                    'challenge' => '挑战',
                    _ => '日常',
                  },
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: badgeTextColor,
                  ),
                ),
              ),
              const Spacer(),
              if (completed)
                const Icon(
                  Icons.check_circle_rounded,
                  color: _MemberHomeColors.green,
                ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: completed
                  ? _MemberHomeColors.greenDark
                  : _MemberHomeColors.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${points >= 0 ? '+' : ''}$points 积分',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: points >= 0
                  ? _MemberHomeColors.greenDark
                  : _MemberHomeColors.pinkText,
            ),
          ),
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
    final threshold = pet.levelThreshold ?? 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 150,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _MemberHomeColors.cardSoft,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PetAvatar(pet: pet, size: 58),
              const SizedBox(height: 10),
              Text(
                pet.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _MemberHomeColors.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                pet.levelName,
                style: const TextStyle(
                  fontSize: 12,
                  color: _MemberHomeColors.muted,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: pet.progress,
                  minHeight: 8,
                  backgroundColor: Colors.white,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    _MemberHomeColors.green,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "${pet.experience}/${threshold == 0 ? '满级' : threshold}",
                style: const TextStyle(
                  fontSize: 11,
                  color: _MemberHomeColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.title,
    required this.points,
    required this.timeLabel,
  });

  final String title;
  final int points;
  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    final positive = points >= 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _MemberHomeColors.cardSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: positive
                  ? const Color(0xFFD7ECCB)
                  : _MemberHomeColors.pink,
              borderRadius: BorderRadius.circular(999),
            ),
            alignment: Alignment.center,
            child: Icon(
              positive ? Icons.add_rounded : Icons.remove_rounded,
              color: positive
                  ? _MemberHomeColors.greenDark
                  : _MemberHomeColors.pinkText,
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
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _MemberHomeColors.text,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  timeLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    color: _MemberHomeColors.muted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${positive ? '+' : ''}$points',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: positive
                  ? _MemberHomeColors.greenDark
                  : _MemberHomeColors.pinkText,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({
    required this.icon,
    required this.title,
    required this.message,
  });

  final String icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 34)),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _MemberHomeColors.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              height: 1.45,
              color: _MemberHomeColors.muted,
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
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: foreground,
        ),
      ),
    );
  }
}
