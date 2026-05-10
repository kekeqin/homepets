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
  static const text = Color(0xFF684328);
  static const muted = Color(0xFF98745A);
  static const accent = Color(0xFFD99955);
  static const accentDark = Color(0xFFA86C35);
}

Future<void> showFamilyDialog(
  BuildContext context, {
  bool useRootNavigator = true,
  Map<int, String> petAvatarAssetPathsById = const <int, String>{},
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
        minimumSafeArea: const EdgeInsets.fromLTRB(4, 10, 4, 8),
        boxShadow: HomePetsDialogTheme.shellShadow,
        child: FamilyScreen(
          embedded: true,
          petAvatarAssetPathsById: petAvatarAssetPathsById,
          onClose: () => Navigator.of(dialogContext).pop(),
        ),
      );
    },
  );
}

class FamilyScreen extends ConsumerStatefulWidget {
  const FamilyScreen({
    super.key,
    this.embedded = false,
    this.petAvatarAssetPathsById = const <int, String>{},
    this.onClose,
  });

  final bool embedded;
  final Map<int, String> petAvatarAssetPathsById;
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
    return trimmed.isEmpty ? '温暖小家' : trimmed;
  }

  int _petCount(List<FamilyMemberViewData> members) {
    return members.where((member) => member.petType != null).length;
  }

  int _familyPoints(List<FamilyMemberViewData> members) {
    return members.fold(0, (sum, member) => sum + member.points);
  }

  Future<void> _openPetDetail(Pet pet, String? avatarAssetPath) async {
    await showPetDetailDialog(
      context,
      pet: pet,
      avatarAssetPath: avatarAssetPath,
    );
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
          widget.embedded ? 0 : 22,
          widget.embedded ? 0 : 18,
          widget.embedded ? 0 : 22,
          widget.embedded ? 0 : 26,
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
                petAvatarAssetPathsById: widget.petAvatarAssetPathsById,
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
      aspectRatio: 0.61,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x205C3516),
                  blurRadius: 14,
                  offset: Offset(0, 7),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
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
                          left: width * 0.070,
                          right: width * 0.150,
                          top: height * 0.045,
                          height: height * 0.238,
                          child: _QuietFamilyStageHeader(
                            embedded: embedded,
                            title: title,
                            familyPoints: familyPoints,
                            petCount: petCount,
                            memberCount: memberCount,
                            canManageMembers: canManageMembers,
                            addingMember: addingMember,
                            onAddMemberTap: onAddMemberTap,
                            canEditTitle: canEditTitle,
                            updatingTitle: updatingTitle,
                            onEditTitleTap: onEditTitleTap,
                          ),
                        ),
                        Positioned(
                          left: width * 0.040,
                          right: width * 0.040,
                          top: height * 0.252,
                          height: height * 0.704,
                          child: membersPanel,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: const Color(0xFF5F3A20),
                    width: 3.0,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x24523319),
                      blurRadius: 1.2,
                      spreadRadius: -0.2,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Padding(
                padding: const EdgeInsets.all(3.5),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(29),
                    border: Border.all(
                      color: const Color(0x665F3A20),
                      width: 0.8,
                      strokeAlign: BorderSide.strokeAlignInside,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 18,
            right: 18,
            child: _CircleIconButton(
              icon: embedded ? Icons.close_rounded : Icons.arrow_back_rounded,
              tooltip: embedded ? '\u5173\u95ed' : '\u8fd4\u56de\u9996\u9875',
              onTap: onLeadingTap,
            ),
          ),
        ],
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
              child: Image.asset(
                FamilyHomePartAssets.familyIllustration,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
                isAntiAlias: false,
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
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 58),
      child: SizedBox(
        height: 36,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: Image.asset(
                FamilyHomePartAssets.statBadgeFrame,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.medium,
                isAntiAlias: false,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
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
            ),
          ],
        ),
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
        final titleSize = compact ? 38.0 : 44.0;
        final heroWidth = (maxWidth * (maxWidth < 380 ? 0.47 : 0.46))
            .clamp(146.0, compact ? 188.0 : 228.0)
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
                        SizedBox(height: compact ? 8 : 10),
                        SizedBox(
                          height: compact ? 36 : 40,
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
                                SizedBox(width: compact ? 5 : 7),
                                _QuietStatPill(
                                  compact: compact,
                                  iconRegion: FamilySpriteRegions.statPetIcon,
                                  value: '$petCount',
                                ),
                                SizedBox(width: compact ? 5 : 7),
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
                          SizedBox(height: compact ? 11 : 14),
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
                  padding: EdgeInsets.only(top: compact ? 1 : 7),
                  child: SizedBox(
                    width: heroWidth,
                    height: heroHeight,
                    child: Image.asset(
                      FamilyHomePartAssets.familyIllustration,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.medium,
                      isAntiAlias: false,
                    ),
                  ),
                ),
              ],
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
    return SizedBox(
      width: compact ? (isStar ? 74 : 64) : (isStar ? 86 : 74),
      height: compact ? 32 : 36,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(
              FamilyHomePartAssets.statBadgeFrame,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.medium,
              isAntiAlias: false,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10),
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
                        fontSize: compact ? 14 : 15,
                        fontWeight: FontWeight.w900,
                      ),
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

  Widget _buildIcon(bool compact) {
    final isMember = iconRegion == FamilySpriteRegions.statMemberIcon;
    final isPet = iconRegion == FamilySpriteRegions.statPetIcon;
    final assetPath = isMember
        ? FamilyHomePartAssets.memberIcon
        : isPet
        ? FamilyHomePartAssets.petIcon
        : FamilyHomePartAssets.starIcon;
    final iconWidth = compact
        ? (isMember ? 22.0 : 17.0)
        : (isMember ? 24.0 : 19.0);
    final iconHeight = compact
        ? (isMember ? 17.0 : 17.0)
        : (isMember ? 19.0 : 19.0);

    return SizedBox(
      width: iconWidth,
      height: iconHeight,
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        isAntiAlias: false,
      ),
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
          width: compact ? 154 : 178,
          height: compact ? 52 : 60,
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
                          sampleInset: 1,
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
    required this.petAvatarAssetPathsById,
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
  final Map<int, String> petAvatarAssetPathsById;
  final Animation<double> entryAnimation;
  final bool canManageMembers;
  final VoidCallback onAddMemberTap;
  final FamilyPetTap onPetTap;
  final bool Function(FamilyMemberViewData member) canEditAvatar;
  final ValueChanged<FamilyMemberViewData> onAvatarEditTap;
  final int? updatingAvatarMemberId;
  final bool Function(FamilyMemberViewData member) canDeleteMember;
  final ValueChanged<FamilyMemberViewData> onMemberLongPress;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5E4).withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(compact ? 22 : 26),
        border: Border.all(
          color: const Color(0xFFE7C692).withValues(alpha: 0.72),
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          compact ? 9 : 14,
          compact ? 10 : 16,
          compact ? 9 : 14,
          compact ? 12 : 18,
        ),
        child: FamilyMemberGrid(
          members: members,
          petAvatarAssetPathsById: petAvatarAssetPathsById,
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
            width: 46,
            height: 46,
            child: Center(
              child: Image.asset(
                FamilyHomePartAssets.closeButton,
                width: 42,
                height: 42,
                filterQuality: FilterQuality.medium,
                isAntiAlias: false,
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
