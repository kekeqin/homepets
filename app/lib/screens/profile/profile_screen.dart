import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/pet.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../member/member_detail_screen.dart';
import '../member/member_home_screen.dart';

class _AppColors {
  static const primary = Color(0xFF006B1B);
  static const primaryContainer = Color(0xFF91F78E);
  static const onPrimary = Color(0xFFD1FFC8);
  static const secondary = Color(0xFF755700);
  static const secondaryContainer = Color(0xFFFFCA4D);
  static const tertiary = Color(0xFF005E9F);
  static const tertiaryContainer = Color(0xFF70B5FF);
  static const background = Color(0xFFFDF6E3);
  static const surface = Color(0xFFFDF6E3);
  static const surfaceContainer = Color(0xFFEFE8D2);
  static const onSurface = Color(0xFF322F22);
  static const onSurfaceVariant = Color(0xFF5F5B4D);
}

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String _avatarEmoji = '';
  final int _completedTasks = 0;
  int _totalExperience = 0;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    final user = ref.read(authProvider).user;
    if (user?.familyId == null) return;
    try {
      final dio = ref.read(apiClientProvider).dio;
      final resp = await dio.get('/api/families/${user!.familyId}/pets');
      final pets = (resp.data as List).map((e) => Pet.fromJson(e)).toList();
      final myPet = pets.where((p) => p.ownerId == user.id).firstOrNull;
      if (myPet != null) {
        setState(() {
          _avatarEmoji = myPet.displayEmoji;
          _totalExperience = myPet.experience;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isLoggedIn = authState.isAuthenticated;
    final isViewOnly = authState.viewOnly;

    return Scaffold(
      backgroundColor: _AppColors.background,
      body: Column(
        children: [
          // 个人资料头部
          _ProfileHeader(
            isLoggedIn: isLoggedIn,
            nickname: user?.nickname ?? '',
            avatarEmoji: _avatarEmoji,
            isAdmin: user?.isAdmin == true,
            isViewOnly: isViewOnly,
            points: user?.points ?? 0,
          ),
          // 内容区域
          if (!isLoggedIn || user == null)
            Expanded(child: _buildGuestContent())
          else
            Expanded(child: _buildProfileContent(user)),
        ],
      ),
    );
  }

  Widget _buildGuestContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _ClayIcon(icon: Icons.person, size: 80),
          const SizedBox(height: 16),
          const Text(
            '未登录',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '登录后可管理家庭和宠物',
            style: TextStyle(color: _AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          _ClayButton(
            icon: Icons.login,
            label: '登录 / 注册',
            onPressed: () => context.go('/login'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(User user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 统计卡片
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: '✅',
                  label: '完成任务',
                  value: '$_completedTasks',
                  color: _AppColors.primaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: '⭐',
                  label: '总经验',
                  value: '$_totalExperience',
                  color: _AppColors.secondaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // 菜单列表
          _MenuItem(
            icon: Icons.edit,
            iconColor: _AppColors.primary,
            title: '编辑资料',
            onTap: () => _editProfile(context, ref),
          ),
          _MenuItem(
            icon: Icons.cottage_rounded,
            iconColor: _AppColors.secondary,
            title: '成员主页',
            onTap: () => _openMemberHome(context),
          ),
          if (_showMyMemberProfileEntry)
            _MenuItem(
              icon: Icons.badge_outlined,
              iconColor: _AppColors.tertiary,
              title: '我的成员详情',
              onTap: () => _openMyMemberProfile(context),
            ),
          _MenuItem(
            icon: Icons.info_outline,
            iconColor: _AppColors.tertiary,
            title: '关于',
            onTap: () => _showAbout(context),
          ),
          const SizedBox(height: 24),
          // 退出登录按钮
          _MenuItem(
            icon: Icons.logout,
            iconColor: Colors.red,
            title: '退出登录',
            titleColor: Colors.red,
            onTap: () async {
              await ref.read(authProvider.notifier).logout();
              if (!mounted) {
                return;
              }
              context.go('/home');
            },
          ),
        ],
      ),
    );
  }

  void _openMemberHome(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MemberHomeScreen()),
    );
  }

  bool get _showMyMemberProfileEntry => false;

  void _openMyMemberProfile(BuildContext context) {
    final user = ref.read(authProvider).user;
    if (user == null) {
      return;
    }

    showMemberDetailDialog(
      context,
      memberId: user.id,
      nickname: user.nickname,
      role: user.isAdmin ? 'admin' : 'member',
    );
  }

  void _editProfile(BuildContext context, WidgetRef ref) {
    final user = ref.read(authProvider).user;
    final nicknameCtrl = TextEditingController(text: user?.nickname);
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('编辑资料'),
          content: TextField(
            controller: nicknameCtrl,
            decoration: const InputDecoration(labelText: '昵称'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                if (nicknameCtrl.text.isEmpty) return;
                try {
                  final dio = ref.read(apiClientProvider).dio;
                  await dio.put(
                    '/api/users/${user!.id}',
                    data: {'nickname': nicknameCtrl.text},
                  );
                  if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                  await ref.read(authProvider.notifier).refreshUser();
                  messenger.showSnackBar(const SnackBar(content: Text('修改成功')));
                } catch (e) {
                  if (dialogCtx.mounted) {
                    ScaffoldMessenger.of(
                      dialogCtx,
                    ).showSnackBar(SnackBar(content: Text('修改失败: $e')));
                  }
                }
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('关于家庭宠物'),
        content: const Text('家庭宠物养成系统\n版本: 1.0.0\n\n通过任务互动喂养宠物，增进亲子关系。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

// ============ 个人资料主题组件 ============

class _ProfileHeader extends StatelessWidget {
  final bool isLoggedIn;
  final String nickname;
  final String avatarEmoji;
  final bool isAdmin;
  final bool isViewOnly;
  final int points;

  const _ProfileHeader({
    required this.isLoggedIn,
    required this.nickname,
    required this.avatarEmoji,
    required this.isAdmin,
    required this.isViewOnly,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_AppColors.primaryContainer, _AppColors.onPrimary],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '👤 个人中心',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: _AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (isLoggedIn)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: _AppColors.primary.withAlpha(40),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // 头像
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: _AppColors.secondaryContainer,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: _AppColors.secondary.withAlpha(40),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            avatarEmoji.isNotEmpty
                                ? avatarEmoji
                                : (nickname.isNotEmpty
                                      ? nickname.substring(0, 1)
                                      : ''),
                            style: TextStyle(
                              fontSize: avatarEmoji.isNotEmpty ? 36 : 28,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // 用户信息
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nickname,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: _AppColors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isViewOnly
                                        ? _AppColors.tertiaryContainer
                                        : _AppColors.secondaryContainer,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    isViewOnly
                                        ? '观看模式'
                                        : (isAdmin ? '管理员' : '成员'),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _AppColors.onSurface,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _AppColors.primaryContainer,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '💰 $points',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: _AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _AppColors.primary.withAlpha(40),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Text('🏝️', style: TextStyle(fontSize: 28)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '欢迎来到个人中心！',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _AppColors.onSurface,
                              ),
                            ),
                            Text(
                              '登录后管理你的资料和宠物',
                              style: TextStyle(
                                fontSize: 12,
                                color: _AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
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
}

class _StatCard extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(60),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(icon, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: _AppColors.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _AppColors.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Color? titleColor;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.titleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _AppColors.onSurface.withAlpha(15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: titleColor ?? _AppColors.onSurface,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: _AppColors.onSurfaceVariant.withAlpha(150),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClayButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ClayButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: _AppColors.primary,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: _AppColors.primary.withAlpha(60),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClayIcon extends StatelessWidget {
  final IconData icon;
  final double size;

  const _ClayIcon({required this.icon, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _AppColors.surfaceContainer,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _AppColors.primary.withAlpha(30),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, size: size * 0.5, color: _AppColors.onSurfaceVariant),
    );
  }
}
