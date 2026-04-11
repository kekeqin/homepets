import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/pet.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/pet_avatar.dart';
import '../../widgets/user_avatar.dart';
import '../pet/pet_detail_screen.dart';

class _ProfileColors {
  static const background = Color(0xFFF9F1DE);
  static const shell = Color(0xFFF8EFD7);
  static const card = Color(0xFFFFFAEE);
  static const cardSoft = Color(0xFFF4EAD7);
  static const line = Color(0xFFE2D0A4);
  static const text = Color(0xFF6A501F);
  static const muted = Color(0xFF978056);
  static const green = Color(0xFF2C8C3B);
  static const greenSoft = Color(0xFFDFF0DA);
  static const gold = Color(0xFFF2C75B);
  static const goldDeep = Color(0xFF9A6710);
  static const blue = Color(0xFFCEE2F4);
  static const blueText = Color(0xFF48709C);
  static const coral = Color(0xFFCA765E);
  static const shadow = Color(0x14000000);
}

class MemberProfileScreen extends ConsumerStatefulWidget {
  const MemberProfileScreen({
    super.key,
    required this.memberId,
    required this.nickname,
    required this.role,
  });

  final int memberId;
  final String nickname;
  final String role;

  @override
  ConsumerState<MemberProfileScreen> createState() =>
      _MemberProfileScreenState();
}

class _MemberProfileScreenState extends ConsumerState<MemberProfileScreen> {
  List<Pet> _pets = [];
  List<Map<String, dynamic>> _completions = [];
  int _memberPoints = 0;
  String? _avatarUrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = ref.read(authProvider).user;
    if (user?.familyId == null) {
      if (!mounted) return;
      setState(() {
        _pets = [];
        _completions = [];
        _memberPoints = 0;
        _avatarUrl = null;
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

      final pets =
          (results[1].data as List)
              .map(
                (item) => Pet.fromJson(Map<String, dynamic>.from(item as Map)),
              )
              .where((pet) => pet.ownerId == widget.memberId)
              .toList()
            ..sort((a, b) => b.experience.compareTo(a.experience));

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

      if (!mounted) return;
      setState(() {
        _memberPoints = currentMember['points'] as int? ?? 0;
        _avatarUrl = currentMember['avatar_url']?.toString();
        _pets = pets;
        _completions = completions;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('加载成员档案失败，请稍后重试')));
    }
  }

  Future<void> _deleteMember() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除成员'),
        content: Text('确认删除“${widget.nickname}”吗？该成员名下的宠物也会一起删除。'),
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
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('删除失败：$error')));
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
      backgroundColor: _ProfileColors.card,
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
                        color: _ProfileColors.text,
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

  int get _memberLevel => math.max(1, (_memberPoints / 60).floor() + 1);

  String get _memberTitle {
    if (widget.role == 'admin') {
      return '家庭守护者';
    }
    if (_memberLevel >= 12) {
      return '超凡探险家';
    }
    if (_memberLevel >= 8) {
      return '成长领航员';
    }
    if (_memberLevel >= 4) {
      return '活力探索家';
    }
    return '闪亮新成员';
  }

  Pet? get _mainPet => _pets.isEmpty ? null : _pets.first;

  String _formatTime(String raw) {
    final time = DateTime.tryParse(raw);
    if (time == null) {
      return '刚刚完成';
    }
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) {
      return '刚刚完成';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} 分钟前完成';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} 小时前完成';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays} 天前完成';
    }
    return '${time.month}月${time.day}日完成';
  }

  double _bondScore(Pet pet) {
    final completionsBoost = (_completions.length / 10).clamp(0.0, 0.35);
    final levelBoost = (pet.level / 8).clamp(0.0, 0.4);
    return (0.28 + completionsBoost + levelBoost).clamp(0.0, 1.0).toDouble();
  }

  double _growthScore(Pet pet) {
    if (pet.levelThreshold == null || pet.levelThreshold == 0) {
      return 1;
    }
    return (pet.experience / pet.levelThreshold!).clamp(0.0, 1.0).toDouble();
  }

  String _petStage(Pet pet) {
    if (pet.isEgg) {
      return '宠物蛋';
    }
    return switch (pet.level) {
      1 => '幼崽期',
      2 => '少年期',
      3 => '进阶期',
      4 => '闪耀期',
      _ => '传奇期',
    };
  }

  List<Map<String, dynamic>> get _badges {
    final hasEarlyBird = _completions.any((completion) {
      final time = DateTime.tryParse(
        (completion['created_at'] ?? '').toString(),
      );
      return time != null && time.hour < 9;
    });

    return [
      {
        'label': '任务达人',
        'icon': Icons.task_alt_rounded,
        'on': _completions.isNotEmpty,
        'color': _ProfileColors.gold,
        'iconColor': _ProfileColors.goldDeep,
      },
      {
        'label': '早起小能手',
        'icon': Icons.wb_sunny_rounded,
        'on': hasEarlyBird,
        'color': const Color(0xFFC9EF9F),
        'iconColor': const Color(0xFF4F7E0E),
      },
      {
        'label': '宠物知音',
        'icon': Icons.pets_rounded,
        'on': _pets.isNotEmpty,
        'color': const Color(0xFFBEDAF6),
        'iconColor': _ProfileColors.blueText,
      },
      {
        'label': '成长新星',
        'icon': Icons.auto_awesome_rounded,
        'on': _memberPoints >= 300,
        'color': const Color(0xFFF3D7C6),
        'iconColor': _ProfileColors.coral,
      },
      {
        'label': '稳定输出',
        'icon': Icons.bolt_rounded,
        'on': _completions.length >= 5,
        'color': const Color(0xFFF5E1AB),
        'iconColor': _ProfileColors.goldDeep,
      },
      {
        'label': '闪耀传说',
        'icon': Icons.workspace_premium_rounded,
        'on': _memberLevel >= 10,
        'color': const Color(0xFFD8EDCB),
        'iconColor': _ProfileColors.green,
      },
    ];
  }

  IconData _activityIcon(String title, int points) {
    final lower = title.toLowerCase();
    if (lower.contains('meal') ||
        title.contains('餐') ||
        title.contains('喂') ||
        title.contains('饭')) {
      return Icons.restaurant_rounded;
    }
    if (lower.contains('groom') ||
        title.contains('洗') ||
        title.contains('整理') ||
        title.contains('清洁')) {
      return Icons.brush_rounded;
    }
    if (lower.contains('explore') ||
        title.contains('探') ||
        title.contains('远足')) {
      return Icons.explore_rounded;
    }
    return points >= 100 ? Icons.star_rounded : Icons.check_rounded;
  }

  Color _activityColor(String title, int points) {
    final lower = title.toLowerCase();
    if (lower.contains('meal') || title.contains('餐') || title.contains('喂')) {
      return _ProfileColors.green;
    }
    if (lower.contains('groom') ||
        title.contains('洗') ||
        title.contains('整理')) {
      return _ProfileColors.goldDeep;
    }
    if (lower.contains('explore') || title.contains('探')) {
      return _ProfileColors.blueText;
    }
    return points >= 100 ? _ProfileColors.coral : _ProfileColors.text;
  }

  String _taskTypeLabel(String rawType) {
    return switch (rawType) {
      'limited' => '限时任务',
      'challenge' => '挑战任务',
      _ => '日常任务',
    };
  }

  Widget _glow(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  Widget _chip(String label, Color background, Color foreground) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

  Widget _topButton({required IconData icon, VoidCallback? onTap}) {
    return Opacity(
      opacity: onTap == null ? 0 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _ProfileColors.card.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: _ProfileColors.shadow,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: _ProfileColors.green, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _avatarFallback() {
    final initial = widget.nickname.trim().isEmpty
        ? '家'
        : widget.nickname.characters.first;

    return Stack(
      children: [
        Positioned(
          top: 18,
          left: 24,
          right: 24,
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
        ),
        Center(
          child: Text(
            initial,
            style: const TextStyle(
              fontSize: 70,
              fontWeight: FontWeight.w900,
              color: Color(0xFFF8E3B2),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 18,
          child: Icon(
            Icons.face_retouching_natural_rounded,
            size: 30,
            color: Colors.white.withValues(alpha: 0.68),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: _ProfileColors.goldDeep,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            height: 1.45,
            color: _ProfileColors.muted,
          ),
        ),
      ],
    );
  }

  Widget _emptyCard({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _ProfileColors.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: _ProfileColors.shadow,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: _ProfileColors.cardSoft,
            ),
            child: Icon(icon, color: _ProfileColors.muted, size: 28),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: _ProfileColors.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.55,
              color: _ProfileColors.muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricBar(String label, double value, Color color) {
    final percent = (value * 100).round().clamp(0, 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: Color(0xFF8C6A2D),
                ),
              ),
            ),
            Text(
              '$percent%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: 7,
            backgroundColor: Colors.white.withValues(alpha: 0.55),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildHero() {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 146,
              height: 146,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _ProfileColors.card,
                boxShadow: [
                  BoxShadow(
                    color: _ProfileColors.gold.withValues(alpha: 0.18),
                    blurRadius: 22,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _ProfileColors.line, width: 2),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF536A60), Color(0xFF2E3F39)],
                  ),
                ),
                child: ClipOval(
                  child: Builder(
                    builder: (context) {
                      final emoji = userAvatarEmojiFromValue(_avatarUrl);
                      if (emoji != null) {
                        return Center(
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 62),
                          ),
                        );
                      }
                      if (isNetworkAvatarValue(_avatarUrl)) {
                        return Image.network(
                          _avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _avatarFallback(),
                        );
                      }
                      return _avatarFallback();
                    },
                  ),
                ),
              ),
            ),
            Positioned(
              right: -2,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _ProfileColors.gold,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(
                  'Lv. $_memberLevel',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: _ProfileColors.goldDeep,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          widget.nickname,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 36,
            height: 1,
            fontWeight: FontWeight.w900,
            color: _ProfileColors.goldDeep,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _memberTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: _ProfileColors.green,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            _chip(
              widget.role == 'admin' ? '家长成员' : '家庭成员',
              _ProfileColors.cardSoft,
              _ProfileColors.text,
            ),
            _chip(
              '$_memberPoints 积分',
              _ProfileColors.gold.withValues(alpha: 0.22),
              _ProfileColors.goldDeep,
            ),
            _chip(
              '${_completions.length} 次任务',
              _ProfileColors.greenSoft,
              _ProfileColors.green,
            ),
          ],
        ),
        if (_canEditAvatar) ...[
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _changeAvatar,
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text('更换头像'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _ProfileColors.green,
              side: const BorderSide(color: _ProfileColors.green),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPetCard(Pet pet) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context, rootNavigator: true)
              .push(
                MaterialPageRoute(builder: (_) => PetDetailScreen(pet: pet)),
              )
              .then((_) => _loadData());
        },
        borderRadius: BorderRadius.circular(30),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE7C47E), Color(0xFFD2A85D)],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [
              BoxShadow(
                color: _ProfileColors.shadow,
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4EB85A),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.9),
                        width: 2,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2F4138),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Center(child: PetAvatar(pet: pet, size: 52)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6DDB79),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _petStage(pet),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF245629),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
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
                        color: _ProfileColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '专属伙伴',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: Color(0xFFFDF8EA),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _metricBar('亲密度', _bondScore(pet), _ProfileColors.green),
                    const SizedBox(height: 10),
                    _metricBar(
                      '成长值',
                      _growthScore(pet),
                      _ProfileColors.blueText,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 24) / 3;
        return Wrap(
          spacing: 12,
          runSpacing: 18,
          children: _badges.map((badge) {
            final unlocked = badge['on'] as bool;
            final color = badge['color'] as Color;
            final iconColor = badge['iconColor'] as Color;
            return SizedBox(
              width: itemWidth,
              child: Column(
                children: [
                  Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: unlocked
                          ? _ProfileColors.card
                          : Colors.transparent,
                      border: Border.all(
                        color: unlocked
                            ? Colors.transparent
                            : _ProfileColors.line,
                        width: 1.4,
                      ),
                      boxShadow: unlocked
                          ? const [
                              BoxShadow(
                                color: _ProfileColors.shadow,
                                blurRadius: 14,
                                offset: Offset(0, 8),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: unlocked
                              ? color
                              : _ProfileColors.cardSoft.withValues(alpha: 0.6),
                        ),
                        child: Icon(
                          unlocked
                              ? badge['icon'] as IconData
                              : Icons.lock_outline_rounded,
                          color: unlocked ? iconColor : _ProfileColors.muted,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    unlocked ? badge['label'] as String : '???',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: unlocked
                          ? _ProfileColors.text
                          : _ProfileColors.muted,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildProgressTile(Map<String, dynamic> completion) {
    final points = completion['task_points'] as int? ?? 0;
    final title = (completion['task_title'] ?? '任务 #${completion['task_id']}')
        .toString();
    final taskTypeLabel = _taskTypeLabel(
      (completion['task_type'] ?? 'daily').toString(),
    );
    final accent = _activityColor(title, points);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _ProfileColors.card,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: _ProfileColors.shadow,
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.16),
                shape: BoxShape.circle,
                border: Border.all(color: accent.withValues(alpha: 0.25)),
              ),
              child: Icon(
                _activityIcon(title, points),
                color: accent,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _ProfileColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '已完成任务 · $taskTypeLabel',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: accent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatTime((completion['created_at'] ?? '').toString()),
                    style: const TextStyle(
                      fontSize: 12,
                      color: _ProfileColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${points >= 0 ? '+' : ''}$points',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: points >= 0 ? accent : _ProfileColors.coral,
                  ),
                ),
                const Text(
                  '积分',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _ProfileColors.muted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isAdmin = authState.user?.isAdmin == true && !authState.viewOnly;
    final isNotSelf = authState.user?.id != widget.memberId;
    final canDelete = isAdmin && isNotSelf;
    final canPop = Navigator.of(context).canPop();
    final topPadding = MediaQuery.paddingOf(context).top;
    final mainPet = _mainPet;

    return Scaffold(
      backgroundColor: _ProfileColors.background,
      body: Stack(
        children: [
          Positioned(
            top: 110,
            left: -40,
            child: _glow(150, _ProfileColors.gold.withValues(alpha: 0.14)),
          ),
          Positioned(
            top: 240,
            right: -30,
            child: _glow(130, _ProfileColors.blue.withValues(alpha: 0.22)),
          ),
          Positioned(
            bottom: 160,
            left: -20,
            child: _glow(100, _ProfileColors.greenSoft.withValues(alpha: 0.7)),
          ),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(color: _ProfileColors.green),
            )
          else
            RefreshIndicator(
              color: _ProfileColors.green,
              onRefresh: _loadData,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                children: [
                  Container(
                    padding: EdgeInsets.fromLTRB(18, topPadding + 12, 18, 20),
                    decoration: const BoxDecoration(
                      color: _ProfileColors.shell,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(34),
                        bottomRight: Radius.circular(34),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _ProfileColors.shadow,
                          blurRadius: 18,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        _topButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          onTap: canPop
                              ? () => Navigator.of(context).maybePop()
                              : null,
                        ),
                        const Expanded(
                          child: Text(
                            '成员档案',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: _ProfileColors.green,
                            ),
                          ),
                        ),
                        _topButton(icon: Icons.more_horiz_rounded, onTap: null),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 26, 20, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(child: _buildHero()),
                        if (canDelete) ...[
                          const SizedBox(height: 18),
                          Center(
                            child: OutlinedButton.icon(
                              onPressed: _deleteMember,
                              icon: const Icon(Icons.delete_outline_rounded),
                              label: const Text('删除该成员'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _ProfileColors.coral,
                                side: const BorderSide(
                                  color: _ProfileColors.coral,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 30),
                        _sectionTitle('宠物伙伴', '和 TA 一起升级、一起成长'),
                        const SizedBox(height: 14),
                        if (mainPet == null)
                          _emptyCard(
                            icon: Icons.pets_outlined,
                            title: '还没有绑定宠物',
                            message: '完成任务、领养伙伴后，这里会出现专属宠物档案。',
                          )
                        else
                          _buildPetCard(mainPet),
                        const SizedBox(height: 28),
                        _sectionTitle('荣誉墙', '每一个徽章都记录着成长瞬间'),
                        const SizedBox(height: 14),
                        _buildBadgeGrid(),
                        const SizedBox(height: 28),
                        _sectionTitle('最近进展', '最近完成的任务会在这里点亮'),
                        const SizedBox(height: 14),
                        if (_completions.isEmpty)
                          _emptyCard(
                            icon: Icons.schedule_rounded,
                            title: '还没有完成记录',
                            message: '完成一项家庭任务后，这里会展示最近的成长动态。',
                          )
                        else
                          ..._completions.take(5).map(_buildProgressTile),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
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
