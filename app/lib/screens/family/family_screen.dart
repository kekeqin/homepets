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
import 'models/family_member_view_data.dart';
import 'models/family_screen_state.dart';
import 'widgets/family_hint_card.dart';
import 'widgets/family_member_grid.dart';

class _FamilyPalette {
  static const pageTop = Color(0xFFF7ECE0);
  static const pageBottom = Color(0xFFF0E1D0);
  static const shellShadow = Color(0x1F6F4721);
  static const stageTop = Color(0xFFFFFBF6);
  static const stageBottom = Color(0xFFF7EEE2);
  static const stageBorder = Color(0xFFE9D8C6);
  static const sectionTop = Color(0xFFFFFCF8);
  static const sectionBottom = Color(0xFFFAF2E7);
  static const sectionLine = Color(0xFFF0E3D5);
  static const chip = Color(0xFFFFFCF8);
  static const chipBorder = Color(0xFFE8D8C6);
  static const text = Color(0xFF73461F);
  static const muted = Color(0xFF9A6F4D);
  static const accent = Color(0xFFE4A259);
  static const accentDark = Color(0xFFBD762E);
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
    barrierTint: const Color(0x32674A30),
    transitionDuration: const Duration(milliseconds: 220),
    beginScale: 0.96,
    beginYOffset: 16,
    pageBuilder: (dialogContext) {
      return AppModalShell(
        layout: AppModalLayouts.family,
        minimumSafeArea: const EdgeInsets.fromLTRB(14, 24, 14, 18),
        borderRadius: const BorderRadius.all(Radius.circular(28)),
        backgroundColor: Colors.transparent,
        boxShadow: const [
          BoxShadow(
            color: _FamilyPalette.shellShadow,
            blurRadius: 34,
            offset: Offset(0, 16),
          ),
        ],
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
  static const _heroAsset = 'assets/images/ui/family_man_trim.png';
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
    return showDialog<String>(
      context: context,
      builder: (_) => _FamilyNameEditDialog(initialName: initialName),
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

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除成员'),
        content: Text('确认删除“${member.nickname}”吗？该成员名下的宠物也会一起删除。'),
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

    setState(() => _deletingMemberId = member.id);

    try {
      await ref.read(familyProvider.notifier).deleteMember(memberId: member.id);
      await _loadFamily();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('已删除 ${member.nickname}')));
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
          SnackBar(
            content: Text('已添加 ${member.nickname}，并领养了 ${draft.petName}'),
          ),
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
    final cardRadius = BorderRadius.circular(embedded ? 30 : 34);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_FamilyPalette.stageTop, _FamilyPalette.stageBottom],
        ),
        borderRadius: cardRadius,
        border: Border.all(color: _FamilyPalette.stageBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0x166B3608),
            blurRadius: embedded ? 22 : 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: cardRadius,
        child: Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x80FFFFFF), Color(0x00FFFFFF)],
                    stops: [0, 0.46],
                  ),
                ),
              ),
            ),
            Positioned(
              top: -42,
              left: -22,
              child: _StageGlowOrb(
                size: embedded ? 104 : 122,
                color: const Color(0x26FFD9B3),
              ),
            ),
            Positioned(
              top: embedded ? 74 : 88,
              right: -18,
              child: _StageGlowOrb(
                size: embedded ? 88 : 98,
                color: const Color(0x1FDCECCE),
              ),
            ),
            Positioned(
              top: embedded ? 28 : 34,
              right: embedded ? 62 : 68,
              child: IgnorePointer(
                child: Opacity(
                  opacity: embedded ? 0.46 : 0.42,
                  child: Image.asset(
                    _FamilyScreenState._heroAsset,
                    height: embedded ? 70 : 80,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                embedded ? 14 : 20,
                embedded ? 14 : 20,
                embedded ? 14 : 20,
                embedded ? 14 : 18,
              ),
              child: Column(
                children: [
                  _QuietFamilyStageHeader(
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
                  SizedBox(height: embedded ? 14 : 18),
                  membersPanel,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StageGlowOrb extends StatelessWidget {
  const _StageGlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
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
              spacing: 8,
              runSpacing: 8,
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
            child: Image.asset(
              _FamilyScreenState._heroAsset,
              height: heroHeight,
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
              filterQuality: FilterQuality.high,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _FamilyPalette.chip,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _FamilyPalette.chipBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
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
    final trailingWidth = embedded ? 38.0 : 44.0;
    final titleSize = embedded ? 21.0 : 24.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _CircleIconButton(
              icon: embedded ? Icons.close_rounded : Icons.arrow_back_rounded,
              tooltip: embedded ? '关闭' : '返回首页',
              onTap: onLeadingTap,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _FamilyPalette.text,
                        fontSize: titleSize,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                      ),
                    ),
                  ),
                  if (canEditTitle) ...[
                    const SizedBox(width: 6),
                    _HeaderEditButton(
                      busy: updatingTitle,
                      onTap: onEditTitleTap,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            canManageMembers
                ? _HeroAddButton(
                    compact: embedded,
                    busy: addingMember,
                    onTap: onAddMemberTap,
                  )
                : SizedBox(width: trailingWidth, height: trailingWidth),
          ],
        ),
        const SizedBox(height: 12),
        Padding(
          padding: EdgeInsets.only(right: embedded ? 82 : 96),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _QuietStatPill(
                compact: embedded,
                icon: Icons.family_restroom_rounded,
                value: '$memberCount',
              ),
              _QuietStatPill(
                compact: embedded,
                icon: Icons.pets_rounded,
                value: '$petCount',
              ),
              _QuietStatPill(
                compact: embedded,
                icon: Icons.auto_awesome_rounded,
                value: '$familyPoints',
              ),
            ],
          ),
        ),
      ],
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
        child: Ink(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.78),
            shape: BoxShape.circle,
            border: Border.all(color: _FamilyPalette.sectionLine),
          ),
          child: Center(
            child: busy
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _FamilyPalette.muted,
                    ),
                  )
                : const Icon(
                    Icons.edit_rounded,
                    size: 14,
                    color: _FamilyPalette.muted,
                  ),
          ),
        ),
      ),
    );
  }
}

class _QuietStatPill extends StatelessWidget {
  const _QuietStatPill({
    required this.compact,
    required this.icon,
    required this.value,
  });

  final bool compact;
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 7 : 8,
      ),
      decoration: BoxDecoration(
        color: _FamilyPalette.chip.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _FamilyPalette.chipBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F8F673E),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 15 : 16, color: _FamilyPalette.muted),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              color: _FamilyPalette.text,
              fontSize: compact ? 13 : 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
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
    final buttonSize = compact ? 38.0 : 44.0;
    final iconSize = compact ? 20.0 : 22.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF0B668), _FamilyPalette.accent],
            ),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: _FamilyPalette.accent.withValues(alpha: 0.22),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : Icon(Icons.add_rounded, color: Colors.white, size: iconSize),
          ),
        ),
      ),
    );
  }
}

class _FamilyNameEditDialog extends StatefulWidget {
  const _FamilyNameEditDialog({required this.initialName});

  final String initialName;

  @override
  State<_FamilyNameEditDialog> createState() => _FamilyNameEditDialogState();
}

class _FamilyNameEditDialogState extends State<_FamilyNameEditDialog> {
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
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('修改家庭名称'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 30,
        onChanged: (_) {
          if (_errorText != null) {
            setState(() => _errorText = null);
          }
        },
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          labelText: '家庭名称',
          hintText: '例如：宠物岛',
          errorText: _errorText,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _submit, child: const Text('保存')),
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
      padding: EdgeInsets.only(bottom: compact ? 0 : 2),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          compact ? 6 : 8,
          compact ? 6 : 8,
          compact ? 6 : 8,
          compact ? 8 : 10,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(compact ? 26 : 30),
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
