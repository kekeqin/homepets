import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_error_helper.dart';
import '../../models/pet.dart';
import '../../providers/auth_provider.dart';
import '../../providers/family_provider.dart';
import '../../widgets/app_modal_shell.dart';
import '../member/widgets/member_avatar_picker_sheet.dart';
import '../pet/pet_detail_screen.dart';
import 'dialogs/add_member_flow_dialog.dart';
import 'dialogs/delete_member_dialog.dart';
import 'models/family_member_view_data.dart';
import 'models/family_screen_state.dart';
import 'widgets/family_hint_card.dart';
import 'widgets/family_member_grid.dart';
import 'widgets/family_sprite_slice.dart';

class _FamilyPalette {
  static const pageTop = Color(0xFFFFF0DC);
  static const pageBottom = Color(0xFFF1DDBF);
  static const stageBorder = Color(0xFFE1C7A7);
  static const sectionTop = Color(0xFFFFF7EA);
  static const sectionBottom = Color(0xFFF6E5CC);
  static const sectionLine = Color(0xFFE7D0B1);
  static const chip = Color(0xFFFFF2DE);
  static const chipBorder = Color(0xFFE2C7A4);
  static const text = Color(0xFF684328);
  static const muted = Color(0xFF98745A);
  static const accent = Color(0xFFD99955);
  static const accentDark = Color(0xFFA86C35);
}

Future<void> showFamilyDialog(
  BuildContext context, {
  bool useRootNavigator = true,
}) {
  return showAppModalDialog<void>(
    context: context,
    useRootNavigator: useRootNavigator,
    barrierLabel: 'family_overlay',
    blurSigma: 7,
    barrierTint: HomePetsDialogTheme.barrierTint,
    transitionDuration: const Duration(milliseconds: 220),
    beginScale: 0.96,
    beginYOffset: 16,
    pageBuilder: (dialogContext) {
      return AppModalShell(
        layout: AppModalLayouts.family,
        minimumSafeArea: const EdgeInsets.fromLTRB(8, 10, 8, 8),
        boxShadow: HomePetsDialogTheme.shellShadow,
        child: FamilyScreen(
          embedded: true,
          onClose: () => Navigator.of(dialogContext).pop(),
        ),
      );
    },
  );
}

class FamilyScreen extends ConsumerStatefulWidget {
  const FamilyScreen({super.key, this.embedded = false, this.onClose});

  final bool embedded;
  final VoidCallback? onClose;

  @override
  ConsumerState<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends ConsumerState<FamilyScreen>
    with SingleTickerProviderStateMixin {
  static const _maxMembers = FamilyMemberGrid.maxDisplayMembers;

  bool _addingMember = false;
  int? _updatingAvatarMemberId;
  bool _updatingFamilyName = false;
  int? _deletingMemberId;

  late final AnimationController _entryController;
  late final Animation<double> _contentOpacity;
  late final Animation<Offset> _contentOffset;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
    _contentOpacity = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );
    _contentOffset =
        Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero).animate(
          CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
        );

    Future<void>.microtask(_loadFamily);
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  Future<void> _loadFamily() async {
    try {
      await ref.read(familyProvider.notifier).loadFamily();
      if (mounted) {
        _entryController.forward(from: 0);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      showFriendlyApiErrorSnackBar(
        context,
        error,
        fallbackMessage: '加载家庭信息失败，请稍后重试',
      );
    }
  }

  Future<AddMemberFlowResult?> _showAddMemberFlowDialog() async {
    return showAddMemberFlowDialog(context);
  }

  void _handleLeadingAction() {
    if (widget.embedded) {
      final onClose = widget.onClose;
      if (onClose != null) {
        onClose();
        return;
      }
      Navigator.of(context).maybePop();
      return;
    }

    context.go('/home');
  }

  String _familyTitle(String familyName) {
    final trimmed = familyName.trim();
    if (trimmed.isEmpty) {
      return '家庭';
    }
    return trimmed;
  }

  int _petCount(List<FamilyMemberViewData> members) {
    return members.where((member) => member.petType != null).length;
  }

  int _familyPoints(List<FamilyMemberViewData> members) {
    return members.fold(0, (sum, member) => sum + member.points);
  }

  Future<void> _openPetDetail(Pet pet) async {
    await showPetDetailDialog(context, pet: pet);
  }

  bool _canEditFamilyTitle(AuthState authState) {
    final user = authState.user;
    if (authState.viewOnly || user == null) {
      return false;
    }
    return user.isAdmin;
  }

  bool _canEditAvatarForMember(
    AuthState authState,
    FamilyMemberViewData member,
  ) {
    if (authState.viewOnly) {
      return false;
    }

    final user = authState.user;
    if (user == null) {
      return false;
    }

    if (user.id == member.id) {
      return true;
    }

    return user.isAdmin;
  }

  bool _canDeleteMember(AuthState authState, FamilyMemberViewData member) {
    final user = authState.user;
    if (authState.viewOnly || user == null || !user.isAdmin) {
      return false;
    }
    return user.id != member.id;
  }

  Future<String?> _showFamilyNameDialog(String initialName) async {
    return showAppModalDialog<String>(
      context: context,
      barrierLabel: 'edit_family_name_dialog',
      blurSigma: 6,
      barrierTint: const Color(0x544D3523),
      beginScale: 0.96,
      beginYOffset: 16,
      pageBuilder: (dialogContext) {
        return _FamilyNameEditDialog(
          initialName: initialName,
          onCancel: () => Navigator.of(dialogContext).pop(),
          onSubmit: (value) => Navigator.of(dialogContext).pop(value),
        );
      },
    );
  }

  Future<void> _onFamilyTitleEditTap(
    AuthState authState,
    FamilyScreenState familyState,
  ) async {
    if (_updatingFamilyName || !_canEditFamilyTitle(authState)) {
      return;
    }

    final initialName = familyState.familyName.trim();
    final nextName = await _showFamilyNameDialog(initialName);
    final trimmedName = nextName?.trim();
    if (!mounted || trimmedName == null || trimmedName == initialName) {
      return;
    }

    setState(() => _updatingFamilyName = true);

    try {
      await ref.read(familyProvider.notifier).updateFamilyName(trimmedName);
      await _loadFamily();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('家庭名称已更新')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      showFriendlyApiErrorSnackBar(
        context,
        error,
        fallbackMessage: '家庭名称更新失败，请稍后重试',
      );
    } finally {
      if (mounted) {
        setState(() => _updatingFamilyName = false);
      }
    }
  }

  Future<void> _onAvatarEditTap(
    AuthState authState,
    FamilyMemberViewData member,
  ) async {
    if (_updatingAvatarMemberId != null ||
        !_canEditAvatarForMember(authState, member)) {
      return;
    }

    final pickedAvatar = await showMemberAvatarPickerSheet(
      context,
      nickname: member.nickname,
      initialAvatarValue: member.avatarUrl,
    );
    if (!mounted || pickedAvatar == member.avatarUrl) {
      return;
    }

    setState(() => _updatingAvatarMemberId = member.id);

    try {
      await ref
          .read(familyProvider.notifier)
          .updateMemberAvatar(memberId: member.id, avatarUrl: pickedAvatar);
      await _loadFamily();
      if (authState.user?.id == member.id) {
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
    } finally {
      if (mounted && _updatingAvatarMemberId == member.id) {
        setState(() => _updatingAvatarMemberId = null);
      }
    }
  }

  Future<void> _onMemberLongPress(
    AuthState authState,
    FamilyMemberViewData member,
  ) async {
    if (_deletingMemberId != null || !_canDeleteMember(authState, member)) {
      return;
    }

    final confirm = await showDeleteMemberDialog(
      context,
      memberName: member.nickname,
    );
    if (!confirm) {
      return;
    }

    setState(() => _deletingMemberId = member.id);

    try {
      await ref.read(familyProvider.notifier).deleteMember(memberId: member.id);
      await _loadFamily();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('已删除${member.nickname}')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      showFriendlyApiErrorSnackBar(
        context,
        error,
        fallbackMessage: '删除成员失败，请稍后重试',
      );
    } finally {
      if (mounted && _deletingMemberId == member.id) {
        setState(() => _deletingMemberId = null);
      }
    }
  }

  Future<void> _onAddMemberTap(
    AuthState authState,
    FamilyScreenState familyState,
  ) async {
    if (familyState.loading || _addingMember) {
      return;
    }

    final user = authState.user;
    final canManageMembers = user?.isAdmin == true && !authState.viewOnly;
    if (!canManageMembers || user?.familyId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('只有家长可以添加成员')));
      return;
    }

    if (familyState.members.length >= _maxMembers) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('当前家庭最多支持 8 位成员')));
      return;
    }

    final draft = await _showAddMemberFlowDialog();
    if (draft == null) {
      return;
    }

    setState(() => _addingMember = true);

    try {
      final notifier = ref.read(familyProvider.notifier);
      final member = await notifier.addMember(draft.nickname);
      if (!mounted) {
        return;
      }

      try {
        await notifier.assignMemberPet(
          memberId: member.id,
          petType: draft.petType,
          petName: draft.petName,
        );
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已添加${member.nickname}，并领养了${draft.petName}')),
        );
        await _loadFamily();
        return;
      } catch (error) {
        if (!mounted) {
          return;
        }
        showFriendlyApiErrorSnackBar(
          context,
          error,
          fallbackMessage: '选择宠物失败，请重试',
        );
        await _loadFamily();
        return;
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      showFriendlyApiErrorSnackBar(
        context,
        error,
        fallbackMessage: '添加成员失败，请稍后重试',
      );
    } finally {
      if (mounted) {
        setState(() => _addingMember = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final familyState = ref.watch(familyProvider);

    if (widget.embedded) {
      return _buildBody(authState, familyState);
    }

    final content = DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_FamilyPalette.pageTop, _FamilyPalette.pageBottom],
        ),
      ),
      child: SafeArea(bottom: false, child: _buildBody(authState, familyState)),
    );

    return Scaffold(backgroundColor: _FamilyPalette.pageBottom, body: content);
  }

  Widget _buildBody(AuthState authState, FamilyScreenState familyState) {
    if (!authState.isAuthenticated) {
      return const FamilyHintCard(title: '请先登录', message: '登录后可查看家庭成员。');
    }

    if (familyState.loading) {
      return const Center(
        child: CircularProgressIndicator(color: _FamilyPalette.accentDark),
      );
    }

    if (!familyState.hasFamily) {
      return const FamilyHintCard(title: '暂未加入家庭', message: '先创建家庭或通过邀请码加入吧。');
    }

    final members = familyState.members;
    final petCount = _petCount(members);
    final familyPoints = _familyPoints(members);
    final familyTitle = _familyTitle(familyState.familyName);
    final canManageMembers =
        authState.user?.isAdmin == true && !authState.viewOnly;

    void onAddMemberTap() {
      _onAddMemberTap(authState, familyState);
    }

    return RefreshIndicator(
      color: _FamilyPalette.accentDark,
      onRefresh: _loadFamily,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(
          widget.embedded ? 6 : 22,
          widget.embedded ? 4 : 18,
          widget.embedded ? 6 : 22,
          widget.embedded ? 10 : 26,
        ),
        child: FadeTransition(
          opacity: _contentOpacity,
          child: SlideTransition(
            position: _contentOffset,
            child: _FamilyStageCard(
              embedded: widget.embedded,
              title: familyTitle,
              familyPoints: familyPoints,
              petCount: petCount,
              memberCount: members.length,
              canManageMembers: canManageMembers,
              addingMember: _addingMember,
              onLeadingTap: _handleLeadingAction,
              onAddMemberTap: onAddMemberTap,
              canEditTitle: _canEditFamilyTitle(authState),
              updatingTitle: _updatingFamilyName,
              onEditTitleTap: () =>
                  _onFamilyTitleEditTap(authState, familyState),
              membersPanel: _FamilyMembersPanel(
                compact: widget.embedded,
                members: members,
                entryAnimation: _entryController,
                canManageMembers: canManageMembers,
                onAddMemberTap: onAddMemberTap,
                onPetTap: _openPetDetail,
                canEditAvatar: (member) =>
                    _canEditAvatarForMember(authState, member),
                onAvatarEditTap: (member) =>
                    _onAvatarEditTap(authState, member),
                updatingAvatarMemberId: _updatingAvatarMemberId,
                canDeleteMember: (member) =>
                    _canDeleteMember(authState, member),
                onMemberLongPress: (member) =>
                    _onMemberLongPress(authState, member),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FamilyStageCard extends StatelessWidget {
  const _FamilyStageCard({
    required this.embedded,
    required this.title,
    required this.familyPoints,
    required this.petCount,
    required this.memberCount,
    required this.canManageMembers,
    required this.addingMember,
    required this.onLeadingTap,
    required this.onAddMemberTap,
    required this.canEditTitle,
    required this.updatingTitle,
    required this.onEditTitleTap,
    required this.membersPanel,
  });

  final bool embedded;
  final String title;
  final int familyPoints;
  final int petCount;
  final int memberCount;
  final bool canManageMembers;
  final bool addingMember;
  final VoidCallback onLeadingTap;
  final VoidCallback onAddMemberTap;
  final bool canEditTitle;
  final bool updatingTitle;
  final VoidCallback onEditTitleTap;
  final Widget membersPanel;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.592,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: Color(0x205C3516),
              blurRadius: 14,
              offset: Offset(0, 7),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: FamilySpritePanel(
            skin: FamilySpriteSkins.outerPanel,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final height = constraints.maxHeight;

                return Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Positioned(
                      left: width * 0.058,
                      right: width * 0.048,
                      top: height * 0.038,
                      height: height * 0.218,
                      child: _QuietFamilyStageHeader(
                        embedded: embedded,
                        title: title,
                        familyPoints: familyPoints,
                        petCount: petCount,
                        memberCount: memberCount,
                        canManageMembers: canManageMembers,
                        addingMember: addingMember,
                        onLeadingTap: onLeadingTap,
                        onAddMemberTap: onAddMemberTap,
                        canEditTitle: canEditTitle,
                        updatingTitle: updatingTitle,
                        onEditTitleTap: onEditTitleTap,
                      ),
                    ),
                    Positioned(
                      left: width * 0.032,
                      right: width * 0.032,
                      top: height * 0.268,
                      height: height * 0.696,
                      child: membersPanel,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _FamilyStageHeader extends StatelessWidget {
  const _FamilyStageHeader({
    required this.embedded,
    required this.title,
    required this.familyPoints,
    required this.petCount,
    required this.memberCount,
    required this.canManageMembers,
    required this.addingMember,
    required this.onLeadingTap,
    required this.onAddMemberTap,
  });

  final bool embedded;
  final String title;
  final int familyPoints;
  final int petCount;
  final int memberCount;
  final bool canManageMembers;
  final bool addingMember;
  final VoidCallback onLeadingTap;
  final VoidCallback onAddMemberTap;

  @override
  Widget build(BuildContext context) {
    final trailingWidth = embedded ? 40.0 : 46.0;

    return Row(
      children: [
        _CircleIconButton(
          icon: embedded ? Icons.close_rounded : Icons.arrow_back_rounded,
          tooltip: embedded ? '关闭' : '返回首页',
          onTap: onLeadingTap,
        ),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _FamilyPalette.text,
              fontSize: embedded ? 24 : 28,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
        ),
        canManageMembers
            ? _HeroAddButton(
                compact: embedded,
                busy: addingMember,
                onTap: onAddMemberTap,
              )
            : SizedBox(width: trailingWidth, height: trailingWidth),
      ],
    );
  }
}

// ignore: unused_element
class _FamilySnapshotPanel extends StatelessWidget {
  const _FamilySnapshotPanel({
    required this.embedded,
    required this.familyPoints,
    required this.petCount,
    required this.memberCount,
  });

  final bool embedded;
  final int familyPoints;
  final int petCount;
  final int memberCount;

  @override
  Widget build(BuildContext context) {
    final heroHeight = embedded ? 84.0 : 104.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        embedded ? 14 : 18,
        embedded ? 14 : 16,
        embedded ? 14 : 18,
        embedded ? 14 : 16,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_FamilyPalette.sectionTop, _FamilyPalette.sectionBottom],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _FamilyPalette.stageBorder),
      ),
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          Padding(
            padding: EdgeInsets.only(right: heroHeight * 0.9),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _FamilyStatPill(
                  icon: Icons.family_restroom_rounded,
                  value: '$memberCount',
                ),
                _FamilyStatPill(icon: Icons.pets_rounded, value: '$petCount'),
                _FamilyStatPill(
                  icon: Icons.auto_awesome_rounded,
                  value: '$familyPoints',
                ),
              ],
            ),
          ),
          IgnorePointer(
            child: SizedBox(
              height: heroHeight,
              width: heroHeight * 1.18,
              child: const FamilySpriteSlice(
                region: FamilySpriteRegions.heroIllustration,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _FamilyStatPill extends StatelessWidget {
  const _FamilyStatPill({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      constraints: const BoxConstraints(minWidth: 58),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _FamilyPalette.chip,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _FamilyPalette.chipBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: _FamilyPalette.muted),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              color: _FamilyPalette.text,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuietFamilyStageHeader extends StatelessWidget {
  const _QuietFamilyStageHeader({
    required this.embedded,
    required this.title,
    required this.familyPoints,
    required this.petCount,
    required this.memberCount,
    required this.canManageMembers,
    required this.addingMember,
    required this.onLeadingTap,
    required this.onAddMemberTap,
    required this.canEditTitle,
    required this.updatingTitle,
    required this.onEditTitleTap,
  });

  final bool embedded;
  final String title;
  final int familyPoints;
  final int petCount;
  final int memberCount;
  final bool canManageMembers;
  final bool addingMember;
  final VoidCallback onLeadingTap;
  final VoidCallback onAddMemberTap;
  final bool canEditTitle;
  final bool updatingTitle;
  final VoidCallback onEditTitleTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final compact = embedded || maxWidth < 430;
        final titleSize = compact ? 30.0 : 34.0;
        final heroWidth = (maxWidth * (maxWidth < 380 ? 0.39 : 0.41))
            .clamp(112.0, compact ? 142.0 : 190.0)
            .toDouble();
        final heroHeight = heroWidth / 1.18;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: compact ? 0 : 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: _FamilyPalette.text,
                                  fontSize: titleSize,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                ),
                              ),
                            ),
                            if (canEditTitle) ...[
                              SizedBox(width: compact ? 3 : 5),
                              _HeaderEditButton(
                                busy: updatingTitle,
                                onTap: onEditTitleTap,
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: compact ? 6 : 9),
                        SizedBox(
                          height: compact ? 27 : 31,
                          child: FittedBox(
                            alignment: Alignment.centerLeft,
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _QuietStatPill(
                                  compact: compact,
                                  iconRegion:
                                      FamilySpriteRegions.statMemberIcon,
                                  value: '$memberCount',
                                ),
                                SizedBox(width: compact ? 4 : 6),
                                _QuietStatPill(
                                  compact: compact,
                                  iconRegion: FamilySpriteRegions.statPetIcon,
                                  value: '$petCount',
                                ),
                                SizedBox(width: compact ? 4 : 6),
                                _QuietStatPill(
                                  compact: compact,
                                  iconRegion: FamilySpriteRegions.starIcon,
                                  value: '$familyPoints',
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (canManageMembers) ...[
                          SizedBox(height: compact ? 7 : 10),
                          _HeroAddButton(
                            compact: compact,
                            busy: addingMember,
                            onTap: onAddMemberTap,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                SizedBox(width: compact ? 4 : 10),
                Padding(
                  padding: EdgeInsets.only(top: compact ? 4 : 8),
                  child: SizedBox(
                    width: heroWidth,
                    height: heroHeight,
                    child: const FamilySpriteSlice(
                      region: FamilySpriteRegions.heroIllustration,
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: embedded ? -4 : -5,
              right: embedded ? -6 : -7,
              child: _CircleIconButton(
                icon: embedded ? Icons.close_rounded : Icons.arrow_back_rounded,
                tooltip: embedded ? '\u5173\u95ed' : '\u8fd4\u56de\u9996\u9875',
                onTap: onLeadingTap,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HeaderEditButton extends StatelessWidget {
  const _HeaderEditButton({required this.busy, required this.onTap});

  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          width: 24,
          height: 23,
          child: busy
              ? const Center(
                  child: SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.7,
                      color: _FamilyPalette.muted,
                    ),
                  ),
                )
              : const FamilySpriteSlice(region: FamilySpriteRegions.editIcon),
        ),
      ),
    );
  }
}

class _QuietStatPill extends StatelessWidget {
  const _QuietStatPill({
    required this.compact,
    required this.iconRegion,
    required this.value,
  });

  final bool compact;
  final Rect iconRegion;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isStar = iconRegion == FamilySpriteRegions.starIcon;
    return Container(
      width: compact ? (isStar ? 56 : 46) : (isStar ? 68 : 56),
      height: compact ? 27 : 31,
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFBF0), Color(0xFFFFF0D8)],
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFF8D5B2E),
          width: compact ? 1.0 : 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x168A5A2C),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildIcon(compact),
          SizedBox(width: compact ? 2 : 4),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                style: TextStyle(
                  color: _FamilyPalette.text,
                  fontSize: compact ? 12 : 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon(bool compact) {
    final size = compact ? 14.0 : 16.0;
    final icon = iconRegion == FamilySpriteRegions.statMemberIcon
        ? Icons.groups_rounded
        : iconRegion == FamilySpriteRegions.statPetIcon
        ? Icons.pets_rounded
        : Icons.star_rounded;
    final color = iconRegion == FamilySpriteRegions.starIcon
        ? const Color(0xFFFFC943)
        : const Color(0xFF8A6438);

    return SizedBox(
      width: size,
      height: size,
      child: Icon(icon, size: size, color: color),
    );
  }
}

class _HeroAddButton extends StatelessWidget {
  const _HeroAddButton({
    required this.compact,
    required this.busy,
    required this.onTap,
  });

  final bool compact;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          width: compact ? 128 : 154,
          height: compact ? 42 : 50,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const FamilySpriteSlice(
                region: FamilySpriteRegions.addMemberButton,
              ),
              if (busy)
                Center(
                  child: SizedBox(
                    width: compact ? 15 : 18,
                    height: compact ? 15 : 18,
                    child: CircularProgressIndicator(
                      strokeWidth: compact ? 1.7 : 1.9,
                      color: _FamilyPalette.accentDark,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

const String _familyNameDialogAsset =
    'assets/images/ui/sprites/edit_family_name_dialog_sprites_clean.png';
const Size _familyNameDialogSheetSize = Size(1448, 1086);

const Rect _familyNameDialogPanelRegion = Rect.fromLTWH(749, 82, 647, 406);
const Rect _familyNameDialogTitleRegion = Rect.fromLTWH(62, 622, 238, 38);
const Rect _familyNameDialogFieldLabelRegion = Rect.fromLTWH(412, 625, 99, 24);
const Rect _familyNameDialogInputBoxRegion = Rect.fromLTWH(743, 615, 275, 48);
const Rect _familyNameDialogHelperTextRegion = Rect.fromLTWH(90, 807, 144, 23);
const Rect _familyNameDialogBottomCancelRegion = Rect.fromLTWH(
  495,
  1001,
  58,
  29,
);
const Rect _familyNameDialogBottomSaveRegion = Rect.fromLTWH(624, 971, 190, 73);

const double _familyNameDialogDesignWidth = 647;
const double _familyNameDialogDesignHeight = 406;
const AppModalLayout _familyNameDialogLayout = AppModalLayout(
  mobileWidthFactor: 0.92,
  mobileMaxWidth: 430,
  mobileHeightFactor: 0.52,
  mobileMaxHeight: 300,
  tabletWidthFactor: 0.48,
  tabletMaxWidth: 560,
  tabletHeightFactor: 0.46,
  tabletMaxHeight: 390,
);

class _FamilyNameEditDialog extends StatefulWidget {
  const _FamilyNameEditDialog({
    required this.initialName,
    required this.onCancel,
    required this.onSubmit,
  });

  final String initialName;
  final VoidCallback onCancel;
  final ValueChanged<String> onSubmit;

  @override
  State<_FamilyNameEditDialog> createState() => _FamilyNameEditDialogState();
}

class _FamilyNameEditDialogState extends State<_FamilyNameEditDialog> {
  static const _maxLength = 30;

  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() => _errorText = '家庭名称不能为空');
      return;
    }
    widget.onSubmit(value);
  }

  void _handleChanged(String value) {
    if (_errorText != null) {
      setState(() => _errorText = null);
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AppModalShell(
      layout: _familyNameDialogLayout,
      minimumSafeArea: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      clipChild: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : _familyNameDialogDesignWidth;
          final maxHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : _familyNameDialogDesignHeight;
          final aspect =
              _familyNameDialogDesignWidth / _familyNameDialogDesignHeight;
          final dialogWidth = math.min(maxWidth, maxHeight * aspect);
          final dialogHeight = dialogWidth / aspect;

          return Center(
            child: SizedBox(
              width: dialogWidth,
              height: dialogHeight,
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: _familyNameDialogDesignWidth,
                  height: _familyNameDialogDesignHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Positioned.fill(
                        child: FamilySpriteSlice(
                          assetPath: _familyNameDialogAsset,
                          sheetSize: _familyNameDialogSheetSize,
                          region: _familyNameDialogPanelRegion,
                          fit: BoxFit.fill,
                          sampleInset: 0,
                        ),
                      ),
                      const Positioned(
                        left: 50,
                        top: 47,
                        width: 238,
                        height: 38,
                        child: FamilySpriteSlice(
                          assetPath: _familyNameDialogAsset,
                          sheetSize: _familyNameDialogSheetSize,
                          region: _familyNameDialogTitleRegion,
                          fit: BoxFit.contain,
                          alignment: Alignment.centerLeft,
                          sampleInset: 0,
                        ),
                      ),
                      const Positioned(
                        left: 52,
                        top: 116,
                        width: 99,
                        height: 24,
                        child: FamilySpriteSlice(
                          assetPath: _familyNameDialogAsset,
                          sheetSize: _familyNameDialogSheetSize,
                          region: _familyNameDialogFieldLabelRegion,
                          fit: BoxFit.contain,
                          alignment: Alignment.centerLeft,
                          sampleInset: 0,
                        ),
                      ),
                      const Positioned(
                        left: 52,
                        top: 153,
                        width: 520,
                        height: 86,
                        child: FamilySpriteSlice(
                          assetPath: _familyNameDialogAsset,
                          sheetSize: _familyNameDialogSheetSize,
                          region: _familyNameDialogInputBoxRegion,
                          fit: BoxFit.fill,
                          sampleInset: 0,
                        ),
                      ),
                      Positioned(
                        left: 74,
                        top: 167,
                        width: 476,
                        height: 58,
                        child: _FamilyNameTextField(
                          controller: _controller,
                          maxLength: _maxLength,
                          onChanged: _handleChanged,
                          onSubmitted: _submit,
                        ),
                      ),
                      Positioned(
                        left: 52,
                        top: 258,
                        width: 220,
                        height: 28,
                        child: _FamilyNameHelperText(errorText: _errorText),
                      ),
                      Positioned(
                        right: 52,
                        top: 256,
                        width: 110,
                        height: 32,
                        child: _FamilyNameCharCount(
                          count: _controller.text.length,
                          maxLength: _maxLength,
                        ),
                      ),
                      Positioned(
                        left: 247,
                        top: 301,
                        width: 322,
                        height: 97,
                        child: _FamilyNameDialogActions(
                          onCancel: widget.onCancel,
                          onSave: _submit,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FamilyNameTextField extends StatelessWidget {
  const _FamilyNameTextField({
    required this.controller,
    required this.maxLength,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final int maxLength;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const Key('family_name_edit_field'),
      controller: controller,
      autofocus: true,
      maxLength: maxLength,
      maxLines: 1,
      textInputAction: TextInputAction.done,
      style: const TextStyle(
        color: Color(0xFF4A3527),
        fontSize: 31,
        fontWeight: FontWeight.w900,
        height: 1.1,
      ),
      cursorColor: const Color(0xFF6E4B2C),
      cursorWidth: 2.4,
      onChanged: onChanged,
      onSubmitted: (_) => onSubmitted(),
      buildCounter:
          (
            context, {
            required currentLength,
            required isFocused,
            required maxLength,
          }) {
            return const SizedBox.shrink();
          },
      decoration: const InputDecoration(
        isCollapsed: true,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: EdgeInsets.only(top: 12),
        counterText: '',
      ),
    );
  }
}

class _FamilyNameHelperText extends StatelessWidget {
  const _FamilyNameHelperText({required this.errorText});

  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final error = errorText;
    if (error != null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          error,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFFB95740),
            fontSize: 22,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      );
    }

    return const Align(
      alignment: Alignment.centerLeft,
      child: FamilySpriteSlice(
        assetPath: _familyNameDialogAsset,
        sheetSize: _familyNameDialogSheetSize,
        region: _familyNameDialogHelperTextRegion,
        fit: BoxFit.contain,
        alignment: Alignment.centerLeft,
        sampleInset: 0,
      ),
    );
  }
}

class _FamilyNameCharCount extends StatelessWidget {
  const _FamilyNameCharCount({required this.count, required this.maxLength});

  final int count;
  final int maxLength;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        '$count / $maxLength',
        maxLines: 1,
        style: const TextStyle(
          color: Color(0xFF9A7D60),
          fontSize: 24,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class _FamilyNameDialogActions extends StatefulWidget {
  const _FamilyNameDialogActions({
    required this.onCancel,
    required this.onSave,
  });

  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  State<_FamilyNameDialogActions> createState() =>
      _FamilyNameDialogActionsState();
}

class _FamilyNameDialogActionsState extends State<_FamilyNameDialogActions> {
  bool _savePressed = false;

  void _setSavePressed(bool value) {
    if (_savePressed == value) {
      return;
    }
    setState(() => _savePressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const Positioned(
          left: 0,
          top: 51,
          width: 58,
          height: 29,
          child: FamilySpriteSlice(
            assetPath: _familyNameDialogAsset,
            sheetSize: _familyNameDialogSheetSize,
            region: _familyNameDialogBottomCancelRegion,
            fit: BoxFit.contain,
            alignment: Alignment.centerLeft,
            sampleInset: 0,
          ),
        ),
        Positioned(
          left: 129,
          top: 21,
          width: 190,
          height: 73,
          child: AnimatedScale(
            scale: _savePressed ? 0.97 : 1,
            duration: const Duration(milliseconds: 90),
            curve: Curves.easeOutCubic,
            child: const FamilySpriteSlice(
              assetPath: _familyNameDialogAsset,
              sheetSize: _familyNameDialogSheetSize,
              region: _familyNameDialogBottomSaveRegion,
              fit: BoxFit.contain,
              sampleInset: 0,
            ),
          ),
        ),
        Positioned(
          left: 0,
          top: 42,
          width: 104,
          height: 58,
          child: Semantics(
            button: true,
            label: '取消',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onCancel,
            ),
          ),
        ),
        Positioned(
          left: 119,
          top: 14,
          width: 202,
          height: 76,
          child: Semantics(
            button: true,
            label: '保存',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) => _setSavePressed(true),
              onTapUp: (_) => _setSavePressed(false),
              onTapCancel: () => _setSavePressed(false),
              onTap: widget.onSave,
            ),
          ),
        ),
      ],
    );
  }
}

class _FamilyMembersPanel extends StatelessWidget {
  const _FamilyMembersPanel({
    required this.compact,
    required this.members,
    required this.entryAnimation,
    required this.canManageMembers,
    required this.onAddMemberTap,
    required this.onPetTap,
    required this.canEditAvatar,
    required this.onAvatarEditTap,
    required this.updatingAvatarMemberId,
    required this.canDeleteMember,
    required this.onMemberLongPress,
  });

  final bool compact;
  final List<FamilyMemberViewData> members;
  final Animation<double> entryAnimation;
  final bool canManageMembers;
  final VoidCallback onAddMemberTap;
  final ValueChanged<Pet> onPetTap;
  final bool Function(FamilyMemberViewData member) canEditAvatar;
  final ValueChanged<FamilyMemberViewData> onAvatarEditTap;
  final int? updatingAvatarMemberId;
  final bool Function(FamilyMemberViewData member) canDeleteMember;
  final ValueChanged<FamilyMemberViewData> onMemberLongPress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 1 : 2),
      child: FamilySpritePanel(
        skin: FamilySpriteSkins.contentPanel,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            compact ? 12 : 16,
            compact ? 10 : 14,
            compact ? 12 : 16,
            compact ? 14 : 16,
          ),
          child: FamilyMemberGrid(
            members: members,
            entryAnimation: entryAnimation,
            canAddMembers: canManageMembers,
            onAddMemberTap: onAddMemberTap,
            onPetTap: onPetTap,
            canEditAvatar: canEditAvatar,
            onAvatarEditTap: onAvatarEditTap,
            updatingAvatarMemberId: updatingAvatarMemberId,
            canDeleteMember: canDeleteMember,
            onMemberLongPress: onMemberLongPress,
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _FamilyActionBar extends StatelessWidget {
  const _FamilyActionBar({
    required this.canManageMembers,
    required this.onAddMemberTap,
    required this.onRefresh,
  });

  final bool canManageMembers;
  final VoidCallback onAddMemberTap;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final buttonStyle = FilledButton.styleFrom(
      backgroundColor: const Color(0xFFF8E6D1),
      foregroundColor: _FamilyPalette.text,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      elevation: 0,
      padding: const EdgeInsets.symmetric(vertical: 16),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
    );

    if (!canManageMembers) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () => onRefresh(),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('刷新家庭'),
          style: buttonStyle,
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: onAddMemberTap,
            icon: const Icon(Icons.add_rounded),
            label: const Text('添加成员'),
            style: buttonStyle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: () => onRefresh(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('刷新'),
            style: buttonStyle,
          ),
        ),
      ],
    );
  }
}

// ignore: unused_element
class _FamilyWarmthNote extends StatelessWidget {
  const _FamilyWarmthNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFAF5), Color(0xFFFFF2E7)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1DECE)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.favorite_border_rounded,
              color: _FamilyPalette.accent,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              '家人和宠物的每一次互动，都会留下温暖的成长记录。',
              style: TextStyle(
                color: _FamilyPalette.muted,
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (icon == Icons.close_rounded) {
      return Tooltip(
        message: tooltip,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Center(
              child: Image.asset(
                HomePetsDialogTheme.closeIconAsset,
                width: 34,
                height: 34,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        ),
      );
    }

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.84),
            shape: BoxShape.circle,
            border: Border.all(color: _FamilyPalette.sectionLine),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F6B3608),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: _FamilyPalette.muted, size: 18),
        ),
      ),
    );
  }
}
