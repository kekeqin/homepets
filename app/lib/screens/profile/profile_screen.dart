import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_error_helper.dart';
import '../../models/pet.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/homepets_button.dart';
import '../../widgets/homepets_dialog.dart';
import '../../widgets/homepets_text_field.dart';
import '../member/member_home_screen.dart';

class _ProfilePalette {
  static const backgroundTop = Color(0xFFFFF5D9);
  static const backgroundBottom = Color(0xFFFFD4AE);
  static const paperTop = Color(0xFFFFFAEA);
  static const paperBottom = Color(0xFFFFEED2);
  static const paperAlt = Color(0xFFFFF6E4);
  static const ink = Color(0xFF5C3E29);
  static const mutedInk = Color(0xFF7C634C);
  static const outline = Color(0xFF8A5734);
  static const outlineSoft = Color(0xFFE9B47B);
  static const sage = Color(0xFF79A95C);
  static const sageSoft = Color(0xFFEAF3D2);
  static const honey = Color(0xFFE7A846);
  static const honeySoft = Color(0xFFFFE5A8);
  static const sky = Color(0xFF74AFC5);
  static const skySoft = Color(0xFFE2F3F5);
  static const berry = Color(0xFFD66F5E);
  static const berrySoft = Color(0xFFFFDDD4);
  static const toast = Color(0xFF3E2B21);
}

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String _avatarEmoji = '';
  int _petExperience = 0;
  bool _loadingPetSummary = false;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    final user = ref.read(authProvider).user;
    if (user?.familyId == null) {
      return;
    }

    setState(() => _loadingPetSummary = true);

    try {
      final dio = ref.read(apiClientProvider).dio;
      final response = await dio.get('/api/families/${user!.familyId}/pets');
      final pets = (response.data as List<dynamic>)
          .map((item) => Pet.fromJson(item as Map<String, dynamic>))
          .toList(growable: false);

      Pet? myPet;
      for (final pet in pets) {
        if (pet.ownerId == user.id) {
          myPet = pet;
          break;
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _avatarEmoji = myPet?.displayEmoji ?? '';
        _petExperience = myPet?.experience ?? 0;
        _loadingPetSummary = false;
      });
    } catch (error) {
      debugPrint('加载个人宠物摘要失败: $error');
      if (!mounted) {
        return;
      }
      setState(() => _loadingPetSummary = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: _ProfilePalette.backgroundBottom,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _ProfilePalette.backgroundTop,
              _ProfilePalette.backgroundBottom,
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: authState.isAuthenticated && user != null
              ? _buildProfileContent(context, user, authState)
              : _buildGuestContent(context),
        ),
      ),
    );
  }

  Widget _buildGuestContent(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(18, 14, 18, bottomPadding + 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProfileTopBar(onHomeTap: () => context.go('/home')),
          const SizedBox(height: 22),
          _GuestProfilePanel(onLoginTap: () => context.go('/login')),
        ],
      ),
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    User user,
    AuthState authState,
  ) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final readOnly = ref.watch(coreMutationBlockedProvider);
    final roleLabel = readOnly
        ? '观看模式'
        : user.isAdmin
        ? '家庭家长'
        : '家庭成员';

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(18, 14, 18, bottomPadding + 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProfileTopBar(onHomeTap: () => context.go('/home')),
          const SizedBox(height: 18),
          _ProfileHeroCard(
            nickname: user.nickname,
            avatarEmoji: _avatarEmoji,
            roleLabel: roleLabel,
            points: user.points,
            hasFamily: user.familyId != null,
          ),
          const SizedBox(height: 14),
          _ProfileMetricRow(
            points: user.points,
            petExperience: _petExperience,
            loadingPetSummary: _loadingPetSummary,
          ),
          const SizedBox(height: 26),
          const _ProfileSectionTitle('家庭与资料'),
          const SizedBox(height: 10),
          _ProfileActionTile(
            icon: Icons.edit_note_rounded,
            tone: _ProfilePalette.sage,
            toneSoft: _ProfilePalette.sageSoft,
            title: '编辑资料',
            subtitle: '修改昵称和个人展示信息',
            onTap: () => _editProfile(ref),
          ),
          const SizedBox(height: 10),
          _ProfileActionTile(
            icon: Icons.cottage_rounded,
            tone: _ProfilePalette.honey,
            toneSoft: _ProfilePalette.honeySoft,
            title: '成员主页',
            subtitle: '查看家庭成员和成长记录',
            onTap: () => _openMemberHome(context),
          ),
          const SizedBox(height: 24),
          const _ProfileSectionTitle('帮助与协议'),
          const SizedBox(height: 10),
          _ProfileActionTile(
            icon: Icons.info_outline_rounded,
            tone: _ProfilePalette.sky,
            toneSoft: _ProfilePalette.skySoft,
            title: '关于 HomePets',
            subtitle: '版本和产品说明',
            onTap: () => _showAbout(context),
          ),
          const SizedBox(height: 10),
          _ProfileActionTile(
            icon: Icons.privacy_tip_outlined,
            tone: _ProfilePalette.sage,
            toneSoft: _ProfilePalette.sageSoft,
            title: '隐私政策',
            subtitle: '了解数据收集和使用方式',
            onTap: () => context.go('/profile/legal/privacy'),
          ),
          const SizedBox(height: 10),
          _ProfileActionTile(
            icon: Icons.description_outlined,
            tone: _ProfilePalette.honey,
            toneSoft: _ProfilePalette.honeySoft,
            title: '用户协议',
            subtitle: '查看服务使用条款',
            onTap: () => context.go('/profile/legal/terms'),
          ),
          const SizedBox(height: 10),
          _ProfileActionTile(
            icon: Icons.support_agent_rounded,
            tone: _ProfilePalette.sky,
            toneSoft: _ProfilePalette.skySoft,
            title: '联系客服',
            subtitle: '反馈问题或获取帮助',
            onTap: () => context.go('/support'),
          ),
          const SizedBox(height: 24),
          const _ProfileSectionTitle('账号'),
          const SizedBox(height: 10),
          _ProfileActionTile(
            icon: Icons.delete_forever_outlined,
            tone: _ProfilePalette.berry,
            toneSoft: _ProfilePalette.berrySoft,
            title: '删除账号/数据',
            subtitle: '申请删除账号和家庭数据',
            onTap: () => context.go('/account/delete'),
          ),
          const SizedBox(height: 10),
          _ProfileActionTile(
            icon: Icons.logout_rounded,
            tone: _ProfilePalette.berry,
            toneSoft: _ProfilePalette.berrySoft,
            title: '退出登录',
            subtitle: '退出当前账号',
            isDestructive: true,
            onTap: _handleLogout,
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

  Future<void> _handleLogout() async {
    final confirmed = await _showLogoutConfirmDialog(context);
    if (!mounted || !confirmed) {
      return;
    }

    await ref.read(authProvider.notifier).logout();
    if (!mounted) {
      return;
    }
    context.go('/home');
  }

  Future<void> _editProfile(WidgetRef ref) async {
    final authState = ref.read(authProvider);
    if (ref.read(coreMutationBlockedProvider)) {
      _showProfileSnackBar('试用期已结束，开通会员后可继续养成和编辑');
      return;
    }

    final user = authState.user;
    if (user == null) {
      return;
    }

    final nicknameController = TextEditingController(text: user.nickname);
    final nickname = await showHomePetsDialog<String>(
      context: context,
      barrierLabel: 'profile_edit_dialog',
      title: '编辑资料',
      contentBuilder: (dialogContext) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '这个名字会显示在家庭成员和任务记录里。',
              style: TextStyle(
                color: _ProfilePalette.mutedInk,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1.4,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 14),
            HomePetsTextField(
              controller: nicknameController,
              hintText: '请输入昵称',
              icon: Icons.person_outline_rounded,
              maxLength: 20,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) =>
                  _submitNicknameDialog(dialogContext, nicknameController),
            ),
          ],
        );
      },
      actionsBuilder: (dialogContext) {
        return <Widget>[
          HomePetsButton(
            label: '取消',
            variant: HomePetsButtonVariant.secondary,
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          HomePetsButton(
            label: '保存',
            onPressed: () =>
                _submitNicknameDialog(dialogContext, nicknameController),
          ),
        ];
      },
    );
    nicknameController.dispose();

    if (!mounted || nickname == null || nickname == user.nickname.trim()) {
      return;
    }

    try {
      final dio = ref.read(apiClientProvider).dio;
      await dio.put('/api/users/${user.id}', data: {'nickname': nickname});
      await ref.read(authProvider.notifier).refreshUser();
      if (!mounted) {
        return;
      }
      _showProfileSnackBar('资料已更新');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showProfileErrorSnackBar(error, fallbackMessage: '资料更新失败，请稍后重试');
    }
  }

  void _submitNicknameDialog(
    BuildContext dialogContext,
    TextEditingController nicknameController,
  ) {
    final nickname = nicknameController.text.trim();
    if (nickname.isEmpty) {
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        const SnackBar(
          content: Text('昵称不能为空'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _ProfilePalette.toast,
        ),
      );
      return;
    }

    Navigator.of(dialogContext).pop(nickname);
  }

  Future<void> _showAbout(BuildContext context) {
    return showHomePetsDialog<void>(
      context: context,
      barrierLabel: 'profile_about_dialog',
      title: '关于 HomePets',
      contentBuilder: (dialogContext) {
        return const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AboutLine(label: '版本', value: '1.0.0'),
            SizedBox(height: 10),
            Text(
              'HomePets 是面向中国家庭的亲子宠物养成系统。'
              '家长和孩子可以通过任务、奖励和宠物成长记录每天的陪伴。',
              style: TextStyle(
                color: _ProfilePalette.mutedInk,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1.45,
                letterSpacing: 0,
              ),
            ),
          ],
        );
      },
      actionsBuilder: (dialogContext) {
        return <Widget>[
          HomePetsButton(
            label: '知道了',
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
        ];
      },
    );
  }

  Future<bool> _showLogoutConfirmDialog(BuildContext context) async {
    final result = await showHomePetsDialog<bool>(
      context: context,
      barrierLabel: 'profile_logout_confirm_dialog',
      title: '退出登录',
      contentBuilder: (dialogContext) {
        return const Text(
          '确定要退出当前账号吗？退出后需要重新登录才能继续管理家庭和宠物。',
          style: TextStyle(
            color: _ProfilePalette.mutedInk,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            height: 1.45,
            letterSpacing: 0,
          ),
        );
      },
      actionsBuilder: (dialogContext) {
        return <Widget>[
          HomePetsButton(
            label: '取消',
            variant: HomePetsButtonVariant.secondary,
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          HomePetsButton(
            label: '确认退出',
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ];
      },
    );

    return result == true;
  }

  void _showProfileSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _ProfilePalette.toast,
      ),
    );
  }

  void _showProfileErrorSnackBar(
    Object error, {
    required String fallbackMessage,
  }) {
    if (isUnauthorizedError(error)) {
      return;
    }

    _showProfileSnackBar(
      friendlyApiErrorMessage(error, fallbackMessage: fallbackMessage),
    );
  }
}

class _ProfileTopBar extends StatelessWidget {
  const _ProfileTopBar({required this.onHomeTap});

  final VoidCallback onHomeTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundIconButton(
          icon: Icons.arrow_back_rounded,
          tooltip: '返回首页',
          onTap: onHomeTap,
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '我的',
                style: TextStyle(
                  color: _ProfilePalette.ink,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1,
                  letterSpacing: 0,
                ),
              ),
              SizedBox(height: 6),
              Text(
                '资料、设置和家庭入口',
                style: TextStyle(
                  color: _ProfilePalette.mutedInk,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({
    required this.nickname,
    required this.avatarEmoji,
    required this.roleLabel,
    required this.points,
    required this.hasFamily,
  });

  final String nickname;
  final String avatarEmoji;
  final String roleLabel;
  final int points;
  final bool hasFamily;

  @override
  Widget build(BuildContext context) {
    return _HandDrawnPanel(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _AvatarBadge(avatarEmoji: avatarEmoji, fallbackName: nickname),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nickname.trim().isEmpty ? '家庭成员' : nickname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ProfilePalette.ink,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ProfileChip(
                      icon: Icons.verified_user_outlined,
                      label: roleLabel,
                      color: _ProfilePalette.sage,
                      background: _ProfilePalette.sageSoft,
                    ),
                    _ProfileChip(
                      icon: Icons.stars_rounded,
                      label: '$points 积分',
                      color: _ProfilePalette.honey,
                      background: _ProfilePalette.honeySoft,
                    ),
                    _ProfileChip(
                      icon: Icons.home_rounded,
                      label: hasFamily ? '已加入家庭' : '未加入家庭',
                      color: _ProfilePalette.sky,
                      background: _ProfilePalette.skySoft,
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

class _ProfileMetricRow extends StatelessWidget {
  const _ProfileMetricRow({
    required this.points,
    required this.petExperience,
    required this.loadingPetSummary,
  });

  final int points;
  final int petExperience;
  final bool loadingPetSummary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ProfileMetricCard(
            icon: Icons.star_rounded,
            label: '当前积分',
            value: '$points',
            tone: _ProfilePalette.honey,
            toneSoft: _ProfilePalette.honeySoft,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ProfileMetricCard(
            icon: Icons.pets_rounded,
            label: '宠物经验',
            value: loadingPetSummary ? '...' : '$petExperience',
            tone: _ProfilePalette.sage,
            toneSoft: _ProfilePalette.sageSoft,
          ),
        ),
      ],
    );
  }
}

class _ProfileMetricCard extends StatelessWidget {
  const _ProfileMetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.tone,
    required this.toneSoft,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color tone;
  final Color toneSoft;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 92),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: _ProfilePalette.paperAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _ProfilePalette.outlineSoft, width: 1.8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x205A371F),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: toneSoft,
              shape: BoxShape.circle,
              border: Border.all(color: tone.withValues(alpha: 0.42)),
            ),
            child: Icon(icon, color: tone, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ProfilePalette.mutedInk,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 5),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: const TextStyle(
                      color: _ProfilePalette.ink,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      height: 1,
                      letterSpacing: 0,
                    ),
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

class _ProfileSectionTitle extends StatelessWidget {
  const _ProfileSectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: _ProfilePalette.honey,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: _ProfilePalette.ink,
            fontSize: 17,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  const _ProfileActionTile({
    required this.icon,
    required this.tone,
    required this.toneSoft,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final Color tone;
  final Color toneSoft;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final titleColor = isDestructive
        ? _ProfilePalette.berry
        : _ProfilePalette.ink;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: _ProfilePalette.paperTop,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _ProfilePalette.outlineSoft, width: 1.8),
            boxShadow: const [
              BoxShadow(
                color: Color(0x185A371F),
                blurRadius: 9,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: toneSoft,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: tone.withValues(alpha: 0.38)),
                ),
                child: Icon(icon, color: tone, size: 25),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ProfilePalette.mutedInk,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.chevron_right_rounded,
                color: tone.withValues(alpha: 0.86),
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuestProfilePanel extends StatelessWidget {
  const _GuestProfilePanel({required this.onLoginTap});

  final VoidCallback onLoginTap;

  @override
  Widget build(BuildContext context) {
    return _HandDrawnPanel(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: _ProfilePalette.sageSoft,
              shape: BoxShape.circle,
              border: Border.all(color: _ProfilePalette.outline, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x225A371F),
                  blurRadius: 12,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.person_rounded,
              color: _ProfilePalette.sage,
              size: 46,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            '还没有登录',
            style: TextStyle(
              color: _ProfilePalette.ink,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '登录后可以管理家庭、任务和宠物成长。',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _ProfilePalette.mutedInk,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1.4,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 24),
          HomePetsButton(label: '登录 / 注册', onPressed: onLoginTap, width: 180),
        ],
      ),
    );
  }
}

class _HandDrawnPanel extends StatelessWidget {
  const _HandDrawnPanel({required this.child, required this.padding});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_ProfilePalette.paperTop, _ProfilePalette.paperBottom],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _ProfilePalette.outline, width: 2.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x285A371F),
            blurRadius: 14,
            offset: Offset(0, 7),
          ),
          BoxShadow(
            color: Color(0x80FFFFFF),
            blurRadius: 7,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({required this.avatarEmoji, required this.fallbackName});

  final String avatarEmoji;
  final String fallbackName;

  @override
  Widget build(BuildContext context) {
    final fallback = fallbackName.trim().isEmpty ? '我' : fallbackName.trim()[0];
    final label = avatarEmoji.trim().isEmpty ? fallback : avatarEmoji;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 76,
          height: 76,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _ProfilePalette.honeySoft,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _ProfilePalette.outline, width: 2.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x205A371F),
                blurRadius: 9,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _ProfilePalette.ink,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              height: 1,
              letterSpacing: 0,
            ),
          ),
        ),
        Positioned(
          right: -5,
          bottom: -5,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _ProfilePalette.sageSoft,
              shape: BoxShape.circle,
              border: Border.all(color: _ProfilePalette.outline, width: 1.7),
            ),
            child: const Icon(
              Icons.pets_rounded,
              color: _ProfilePalette.sage,
              size: 16,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileChip extends StatelessWidget {
  const _ProfileChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.42)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: _ProfilePalette.ink,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Ink(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _ProfilePalette.paperTop,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _ProfilePalette.outline, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x205A371F),
                  blurRadius: 9,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: _ProfilePalette.ink, size: 28),
          ),
        ),
      ),
    );
  }
}

class _AboutLine extends StatelessWidget {
  const _AboutLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label：',
          style: const TextStyle(
            color: _ProfilePalette.ink,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: _ProfilePalette.mutedInk,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}
