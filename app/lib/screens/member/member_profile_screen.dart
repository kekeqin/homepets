import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_error_helper.dart';
import '../../models/pet.dart';
import '../../providers/auth_provider.dart';
import '../../services/member_profile_service.dart';
import '../../widgets/pet_avatar.dart';
import '../../widgets/user_avatar.dart';
import '../pet/pet_detail_screen.dart';
import 'models/member_profile_view_data.dart';
import 'widgets/member_avatar_picker_sheet.dart';
import 'widgets/member_profile_common.dart';

class MemberProfileScreen extends ConsumerStatefulWidget {
  const MemberProfileScreen({
    super.key,
    required this.memberId,
    required this.nickname,
    required this.role,
    this.embedded = false,
  });

  final int memberId;
  final String nickname;
  final String role;
  final bool embedded;

  @override
  ConsumerState<MemberProfileScreen> createState() =>
      _MemberProfileScreenState();
}

class _MemberProfileScreenState extends ConsumerState<MemberProfileScreen> {
  MemberProfileViewData _profile = MemberProfileViewData.empty;
  bool _loading = true;

  MemberProfileService get _profileService =>
      MemberProfileService(ref.read(apiClientProvider));

  List<MemberTaskCompletion> get _completions => _profile.completions;
  List<Pet> get _pets => _profile.pets;
  int get _memberPoints => _profile.memberPoints;
  String? get _avatarUrl => _profile.avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final familyId = ref.read(authProvider).user?.familyId;
    if (familyId == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _profile = MemberProfileViewData.empty;
        _loading = false;
      });
      return;
    }

    try {
      final profile = await _profileService.loadProfile(
        familyId: familyId,
        memberId: widget.memberId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _profile = profile;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      showFriendlyApiErrorSnackBar(
        context,
        error,
        fallbackMessage: '加载成员详情失败，请稍后重试',
      );
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

    final familyId = ref.read(authProvider).user?.familyId;
    if (familyId == null) {
      return;
    }

    try {
      await _profileService.deleteMember(
        familyId: familyId,
        memberId: widget.memberId,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('成员已删除')));
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      showFriendlyApiErrorSnackBar(
        context,
        error,
        fallbackMessage: '删除失败，请稍后重试',
      );
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

    final pickedAvatar = await showMemberAvatarPickerSheet(
      context,
      nickname: widget.nickname,
      initialAvatarValue: _avatarUrl,
    );
    if (pickedAvatar == _avatarUrl) {
      return;
    }

    try {
      await _profileService.updateAvatar(
        memberId: widget.memberId,
        avatarUrl: pickedAvatar,
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
      showFriendlyApiErrorSnackBar(
        context,
        error,
        fallbackMessage: '头像更新失败，请稍后重试',
      );
    }
  }

  int get _memberLevel => math.max(1, (_memberPoints / 60).floor() + 1);

  String get _roleLabel => widget.role == 'admin' ? '家长成员' : '家庭成员';

  Pet? get _mainPet => _pets.isEmpty ? null : _pets.first;

  Future<void> _openPetDetail(Pet pet) async {
    await showPetDetailDialog(context, pet: pet);
    if (!mounted) {
      return;
    }
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isAdmin = authState.user?.isAdmin == true && !authState.viewOnly;
    final isNotSelf = authState.user?.id != widget.memberId;
    final canDelete = isAdmin && isNotSelf;
    final canPop = Navigator.of(context).canPop();
    final mainPet = _mainPet;

    return Scaffold(
      backgroundColor: widget.embedded
          ? Colors.transparent
          : MemberProfileColors.background,
      body: Stack(
        children: [
          if (!widget.embedded) ...[
            Positioned(
              top: 88,
              left: -32,
              child: MemberProfileGlow(
                size: 164,
                color: MemberProfileColors.orangeSoft.withValues(alpha: 0.42),
              ),
            ),
            Positioned(
              top: 260,
              right: -28,
              child: MemberProfileGlow(
                size: 136,
                color: MemberProfileColors.blueSoft.withValues(alpha: 0.6),
              ),
            ),
            Positioned(
              bottom: 90,
              left: 10,
              child: MemberProfileGlow(
                size: 110,
                color: MemberProfileColors.greenTint.withValues(alpha: 0.56),
              ),
            ),
          ],
          if (_loading)
            const Center(
              child: CircularProgressIndicator(
                color: MemberProfileColors.orange,
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final horizontalPadding = widget.embedded
                    ? (constraints.maxWidth >= 520 ? 22.0 : 14.0)
                    : (constraints.maxWidth >= 760 ? 28.0 : 20.0);
                final topPadding = widget.embedded
                    ? 14.0
                    : MediaQuery.paddingOf(context).top + 12;

                return RefreshIndicator(
                  color: MemberProfileColors.orange,
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      topPadding,
                      horizontalPadding,
                      28,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 860),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _MemberProfileHeader(
                              embedded: widget.embedded,
                              canPop: canPop,
                              onBack: canPop
                                  ? () => Navigator.of(context).maybePop()
                                  : null,
                              onClose: () => Navigator.of(context).maybePop(),
                            ),
                            SizedBox(height: widget.embedded ? 14 : 18),
                            _MemberIdentityCard(
                              compact: widget.embedded,
                              nickname: widget.nickname,
                              roleLabel: _roleLabel,
                              avatarUrl: _avatarUrl,
                              canEditAvatar: _canEditAvatar,
                              onChangeAvatar: _changeAvatar,
                              hasPetPartner: mainPet != null,
                            ),
                            SizedBox(height: widget.embedded ? 12 : 16),
                            _MemberStatsStrip(
                              compact: widget.embedded,
                              memberLevel: _memberLevel,
                              memberPoints: _memberPoints,
                              completionCount: _completions.length,
                            ),
                            SizedBox(height: widget.embedded ? 14 : 18),
                            _MemberPanel(
                              compact: widget.embedded,
                              title: '宠物伙伴',
                              child: mainPet == null
                                  ? const _MemberEmptyState(
                                      icon: Icons.pets_outlined,
                                      title: '还没有宠物伙伴',
                                      message: '领养宠物并完成任务后，这里会显示专属伙伴和亲密度。',
                                    )
                                  : _MemberPetPartner(
                                      compact: widget.embedded,
                                      pet: mainPet,
                                      completionCount: _completions.length,
                                      onTap: () => _openPetDetail(mainPet),
                                    ),
                            ),
                            SizedBox(height: widget.embedded ? 14 : 16),
                            _MemberPanel(
                              compact: widget.embedded,
                              title: '最近互动',
                              child: _completions.isEmpty
                                  ? const _MemberEmptyState(
                                      icon: Icons.schedule_rounded,
                                      title: '还没有互动记录',
                                      message: '完成任务后，这里会按时间展示最近的成长互动。',
                                    )
                                  : Column(
                                      children: [
                                        for (final completion
                                            in _completions.take(3))
                                          Padding(
                                            padding: EdgeInsets.only(
                                              bottom:
                                                  completion ==
                                                      _completions.take(3).last
                                                  ? 0
                                                  : 12,
                                            ),
                                            child: _MemberActivityTile(
                                              compact: widget.embedded,
                                              completion: completion,
                                            ),
                                          ),
                                      ],
                                    ),
                            ),
                            if (canDelete) ...[
                              const SizedBox(height: 16),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: _deleteMember,
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                  ),
                                  label: const Text('删除该成员'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: MemberProfileColors.coral,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _MemberProfileHeader extends StatelessWidget {
  const _MemberProfileHeader({
    required this.embedded,
    required this.canPop,
    required this.onBack,
    required this.onClose,
  });

  final bool embedded;
  final bool canPop;
  final VoidCallback? onBack;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final buttonSize = embedded ? 42.0 : 48.0;
    final iconSize = embedded ? 22.0 : 24.0;
    final titleSize = embedded ? 24.0 : 28.0;

    return Row(
      children: [
        if (embedded)
          SizedBox(width: buttonSize)
        else
          _MemberRoundButton(
            size: buttonSize,
            iconSize: iconSize,
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: canPop ? onBack : null,
          ),
        Expanded(
          child: Text(
            '成员详情',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.w900,
              color: MemberProfileColors.title,
            ),
          ),
        ),
        _MemberRoundButton(
          size: buttonSize,
          iconSize: iconSize,
          icon: embedded ? Icons.close_rounded : Icons.more_horiz_rounded,
          onTap: embedded ? onClose : null,
        ),
      ],
    );
  }
}

class _MemberRoundButton extends StatelessWidget {
  const _MemberRoundButton({
    required this.icon,
    required this.size,
    required this.iconSize,
    this.onTap,
  });

  final IconData icon;
  final double size;
  final double iconSize;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: onTap == null,
      child: Opacity(
        opacity: onTap == null ? 0 : 1,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: Ink(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: MemberProfileColors.surfaceSoft,
                shape: BoxShape.circle,
                border: Border.all(color: MemberProfileColors.border),
              ),
              child: Icon(
                icon,
                color: MemberProfileColors.title,
                size: iconSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MemberIdentityCard extends StatelessWidget {
  const _MemberIdentityCard({
    required this.compact,
    required this.nickname,
    required this.roleLabel,
    required this.avatarUrl,
    required this.canEditAvatar,
    required this.onChangeAvatar,
    required this.hasPetPartner,
  });

  final bool compact;
  final String nickname;
  final String roleLabel;
  final String? avatarUrl;
  final bool canEditAvatar;
  final VoidCallback onChangeAvatar;
  final bool hasPetPartner;

  @override
  Widget build(BuildContext context) {
    final padding = compact ? 16.0 : 20.0;
    final radius = compact ? 26.0 : 30.0;
    final gap = compact ? 14.0 : 18.0;
    final titleSize = compact ? 32.0 : 36.0;
    final heartSize = compact ? 48.0 : 56.0;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: MemberProfileColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: MemberProfileColors.border),
        boxShadow: const [
          BoxShadow(
            color: MemberProfileColors.shadow,
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MemberAvatar(
            compact: compact,
            nickname: nickname,
            avatarUrl: avatarUrl,
            canEditAvatar: canEditAvatar,
            onTap: onChangeAvatar,
          ),
          SizedBox(width: gap),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: compact ? 6 : 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nickname,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w900,
                      color: MemberProfileColors.title,
                    ),
                  ),
                  SizedBox(height: compact ? 8 : 10),
                  _MemberChip(
                    compact: compact,
                    label: roleLabel,
                    background: MemberProfileColors.surfaceSoft,
                    foreground: MemberProfileColors.goldDeep,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: compact ? 8 : 12),
          Container(
            width: heartSize,
            height: heartSize,
            decoration: BoxDecoration(
              color: MemberProfileColors.orangeSoft,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: MemberProfileColors.orange.withValues(alpha: 0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              hasPetPartner ? Icons.favorite_rounded : Icons.favorite_border,
              color: MemberProfileColors.orange,
              size: compact ? 24 : 28,
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({
    required this.compact,
    required this.nickname,
    required this.avatarUrl,
    required this.canEditAvatar,
    required this.onTap,
  });

  final bool compact;
  final String nickname;
  final String? avatarUrl;
  final bool canEditAvatar;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shellSize = compact ? 112.0 : 128.0;
    final shellPadding = compact ? 8.0 : 10.0;
    final avatarSize = compact ? 96.0 : 108.0;
    final cameraSize = compact ? 30.0 : 34.0;

    final child = Container(
      width: shellSize,
      height: shellSize,
      padding: EdgeInsets.all(shellPadding),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: MemberProfileColors.surfaceSoft,
        boxShadow: const [
          BoxShadow(
            color: MemberProfileColors.shadow,
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: UserAvatar(
        nickname: nickname,
        avatarValue: avatarUrl,
        size: avatarSize,
        backgroundColor: const Color(0xFFF8EBDD),
        foregroundColor: MemberProfileColors.title,
        fontSize: compact ? 42 : 48,
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (canEditAvatar)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(999),
              child: child,
            ),
          )
        else
          child,
        if (canEditAvatar)
          Positioned(
            right: 2,
            bottom: 4,
            child: Container(
              width: cameraSize,
              height: cameraSize,
              decoration: BoxDecoration(
                color: MemberProfileColors.orange,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(
                Icons.photo_camera_outlined,
                color: Colors.white,
                size: compact ? 14 : 16,
              ),
            ),
          ),
      ],
    );
  }
}

class _MemberStatsStrip extends StatelessWidget {
  const _MemberStatsStrip({
    required this.compact,
    required this.memberLevel,
    required this.memberPoints,
    required this.completionCount,
  });

  final bool compact;
  final int memberLevel;
  final int memberPoints;
  final int completionCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 14 : 18,
      ),
      decoration: BoxDecoration(
        color: MemberProfileColors.surface,
        borderRadius: BorderRadius.circular(compact ? 24 : 28),
        border: Border.all(color: MemberProfileColors.border),
        boxShadow: const [
          BoxShadow(
            color: MemberProfileColors.shadow,
            blurRadius: 20,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _MemberStatCell(
              compact: compact,
              icon: Icons.star_rounded,
              iconColor: MemberProfileColors.orange,
              iconBackground: MemberProfileColors.orangeSoft,
              value: 'Lv.$memberLevel',
            ),
          ),
          _MemberStatDivider(compact: compact),
          Expanded(
            child: _MemberStatCell(
              compact: compact,
              icon: Icons.stars_rounded,
              iconColor: MemberProfileColors.goldDeep,
              iconBackground: const Color(0xFFFFE6A8),
              value: '$memberPoints积分',
            ),
          ),
          _MemberStatDivider(compact: compact),
          Expanded(
            child: _MemberStatCell(
              compact: compact,
              icon: Icons.assignment_rounded,
              iconColor: const Color(0xFF6694DE),
              iconBackground: MemberProfileColors.blueSoft,
              value: '$completionCount任务',
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberStatCell extends StatelessWidget {
  const _MemberStatCell({
    required this.compact,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.value,
  });

  final bool compact;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: compact ? 36 : 42,
            height: compact ? 36 : 42,
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: compact ? 20 : 24),
          ),
          SizedBox(width: compact ? 8 : 10),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 16 : 18,
                fontWeight: FontWeight.w800,
                color: MemberProfileColors.title,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberStatDivider extends StatelessWidget {
  const _MemberStatDivider({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: compact ? 36 : 42,
      color: MemberProfileColors.border,
    );
  }
}

class _MemberPanel extends StatelessWidget {
  const _MemberPanel({
    required this.compact,
    required this.title,
    required this.child,
  });

  final bool compact;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 16 : 18),
      decoration: BoxDecoration(
        color: MemberProfileColors.surface,
        borderRadius: BorderRadius.circular(compact ? 24 : 28),
        border: Border.all(color: MemberProfileColors.border),
        boxShadow: const [
          BoxShadow(
            color: MemberProfileColors.shadow,
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: compact ? 21 : 24,
              fontWeight: FontWeight.w900,
              color: MemberProfileColors.title,
            ),
          ),
          SizedBox(height: compact ? 14 : 18),
          child,
        ],
      ),
    );
  }
}

class _MemberPetPartner extends StatelessWidget {
  const _MemberPetPartner({
    required this.compact,
    required this.pet,
    required this.completionCount,
    required this.onTap,
  });

  final bool compact;
  final Pet pet;
  final int completionCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final intimacy = _bondScore(pet, completionCount);
    final intimacyPercent = (intimacy * 100).round();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(compact ? 20 : 24),
        child: Ink(
          padding: EdgeInsets.all(compact ? 14 : 16),
          decoration: BoxDecoration(
            color: MemberProfileColors.surfaceSoft,
            borderRadius: BorderRadius.circular(compact ? 20 : 24),
            border: Border.all(color: MemberProfileColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 96 : 112,
                height: compact ? 96 : 112,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEBDC),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: PetAvatar(
                    pet: pet,
                    size: compact ? 76 : 92,
                    showBackground: false,
                  ),
                ),
              ),
              SizedBox(width: compact ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pet.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 22 : 26,
                        fontWeight: FontWeight.w900,
                        color: MemberProfileColors.title,
                      ),
                    ),
                    SizedBox(height: compact ? 8 : 10),
                    _MemberChip(
                      compact: compact,
                      label: '亲密伙伴',
                      background: MemberProfileColors.pinkSoft,
                      foreground: MemberProfileColors.pinkText,
                    ),
                    SizedBox(height: compact ? 14 : 18),
                    Text(
                      '亲密度',
                      style: TextStyle(
                        fontSize: compact ? 14 : 16,
                        fontWeight: FontWeight.w800,
                        color: MemberProfileColors.title,
                      ),
                    ),
                    SizedBox(height: compact ? 10 : 12),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: intimacy,
                              minHeight: compact ? 12 : 14,
                              backgroundColor:
                                  MemberProfileColors.progressTrack,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                MemberProfileColors.progressFill,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: compact ? 12 : 14),
                        Text(
                          '$intimacyPercent%',
                          style: TextStyle(
                            fontSize: compact ? 16 : 18,
                            fontWeight: FontWeight.w800,
                            color: MemberProfileColors.title,
                          ),
                        ),
                      ],
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

class _MemberActivityTile extends StatelessWidget {
  const _MemberActivityTile({required this.compact, required this.completion});

  final bool compact;
  final MemberTaskCompletion completion;

  @override
  Widget build(BuildContext context) {
    final accent = _activityAccent(completion.taskTitle, completion.taskPoints);
    final icon = _activityIcon(completion.taskTitle, completion.taskPoints);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 14 : 16,
        vertical: compact ? 14 : 16,
      ),
      decoration: BoxDecoration(
        color: MemberProfileColors.surfaceSoft,
        borderRadius: BorderRadius.circular(compact ? 18 : 22),
        border: Border.all(color: MemberProfileColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 46 : 54,
            height: compact ? 46 : 54,
            decoration: BoxDecoration(
              color: accent.background,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: accent.foreground,
              size: compact ? 24 : 28,
            ),
          ),
          SizedBox(width: compact ? 12 : 14),
          Expanded(
            child: Text(
              completion.taskTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 16 : 18,
                fontWeight: FontWeight.w800,
                color: MemberProfileColors.title,
              ),
            ),
          ),
          SizedBox(width: compact ? 8 : 12),
          Text(
            _formatRecentTime(completion.createdAt),
            style: TextStyle(
              fontSize: compact ? 13 : 15,
              color: MemberProfileColors.muted,
            ),
          ),
          SizedBox(width: compact ? 6 : 10),
          Icon(
            Icons.chevron_right_rounded,
            color: MemberProfileColors.muted,
            size: compact ? 24 : 28,
          ),
        ],
      ),
    );
  }
}

class _MemberEmptyState extends StatelessWidget {
  const _MemberEmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
      decoration: BoxDecoration(
        color: MemberProfileColors.surfaceSoft,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: MemberProfileColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: MemberProfileColors.greenTint,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: MemberProfileColors.greenTintText,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: MemberProfileColors.title,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: MemberProfileColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberChip extends StatelessWidget {
  const _MemberChip({
    required this.compact,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final bool compact;
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: compact ? 12 : 14,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}

class _ActivityAccent {
  const _ActivityAccent({required this.background, required this.foreground});

  final Color background;
  final Color foreground;
}

_ActivityAccent _activityAccent(String title, int points) {
  final lower = title.toLowerCase();
  if (lower.contains('meal') ||
      title.contains('喂') ||
      title.contains('饭') ||
      title.contains('食')) {
    return const _ActivityAccent(
      background: Color(0xFFFFEDCC),
      foreground: MemberProfileColors.orange,
    );
  }
  if (lower.contains('clean') ||
      lower.contains('groom') ||
      title.contains('洗') ||
      title.contains('清洁') ||
      title.contains('整理')) {
    return const _ActivityAccent(
      background: MemberProfileColors.blueSoft,
      foreground: Color(0xFF6694DE),
    );
  }
  return points >= 0
      ? const _ActivityAccent(
          background: MemberProfileColors.greenTint,
          foreground: MemberProfileColors.greenTintText,
        )
      : const _ActivityAccent(
          background: MemberProfileColors.pinkSoft,
          foreground: MemberProfileColors.pinkText,
        );
}

IconData _activityIcon(String title, int points) {
  final lower = title.toLowerCase();
  if (lower.contains('meal') ||
      title.contains('喂') ||
      title.contains('饭') ||
      title.contains('食')) {
    return Icons.lunch_dining_rounded;
  }
  if (lower.contains('clean') ||
      lower.contains('groom') ||
      title.contains('洗') ||
      title.contains('清洁') ||
      title.contains('整理')) {
    return Icons.cleaning_services_rounded;
  }
  return points >= 100 ? Icons.star_rounded : Icons.task_alt_rounded;
}

String _formatRecentTime(DateTime? time) {
  if (time == null) {
    return '刚刚';
  }

  final now = DateTime.now();
  final currentDay = DateTime(now.year, now.month, now.day);
  final targetDay = DateTime(time.year, time.month, time.day);
  final diffDays = currentDay.difference(targetDay).inDays;
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');

  if (diffDays == 0) {
    return '今天$hour:$minute';
  }
  if (diffDays == 1) {
    return '昨天$hour:$minute';
  }
  return '${time.month}月${time.day}日 $hour:$minute';
}

double _bondScore(Pet pet, int completionCount) {
  final completionsBoost = (completionCount / 10).clamp(0.0, 0.35);
  final levelBoost = (pet.level / 8).clamp(0.0, 0.4);
  return (0.28 + completionsBoost + levelBoost).clamp(0.0, 1.0).toDouble();
}
