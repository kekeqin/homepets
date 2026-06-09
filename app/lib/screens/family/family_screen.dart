import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_error_helper.dart';
import '../../models/pet.dart';
import '../../providers/auth_provider.dart';
import '../../providers/family_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/app_modal_shell.dart';
import '../member/widgets/member_avatar_picker_sheet.dart';
import '../paywall/paywall_screen.dart';
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
  static const deepBrown = Color(0xFF3F230D);
}

const AppModalVisibleFrame _familyDialogVisibleFrame = AppModalVisibleFrame(
  sourceWidth: 1149,
  leftInset: 48,
  rightInset: 51,
);

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
        minimumSafeArea: const EdgeInsets.fromLTRB(
          HomePetsDialogGutter.large,
          10,
          HomePetsDialogGutter.large,
          8,
        ),
        visibleFrame: _familyDialogVisibleFrame,
        clipChild: false,
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
  static const _topNoticeDuration = Duration(milliseconds: 1800);
  bool _addingMember = false;
  int? _updatingAvatarMemberId;
  int? _deletingMemberId;
  int? _selectingPetMemberId;
  bool _didAutoPromptCurrentUserPet = false;
  bool _paywallDialogVisible = false;
  OverlayEntry? _topNoticeEntry;

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
    _topNoticeEntry?.remove();
    _topNoticeEntry = null;
    _entryController.dispose();
    super.dispose();
  }

  void _showTopNotice(String message) {
    _topNoticeEntry?.remove();
    _topNoticeEntry = null;

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    final topPadding = MediaQuery.paddingOf(context).top;
    final noticeEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: topPadding + 14,
          left: 16,
          right: 16,
          child: SafeArea(
            bottom: false,
            child: _FamilyTopNoticeCard(message: message),
          ),
        );
      },
    );

    _topNoticeEntry = noticeEntry;
    overlay.insert(noticeEntry);
    Future<void>.delayed(_topNoticeDuration, () {
      if (_topNoticeEntry != noticeEntry) {
        return;
      }
      noticeEntry.remove();
      _topNoticeEntry = null;
    });
  }

  Future<void> _loadFamily() async {
    try {
      await ref.read(familyProvider.notifier).loadFamily();
      if (mounted) {
        _entryController.forward(from: 0);
        _maybePromptCurrentUserPetSelection();
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

  bool get _isReadOnlyAfterTrial {
    return ref.read(coreMutationBlockedProvider);
  }

  void _showMembershipRequiredPaywall() {
    if (!mounted || _paywallDialogVisible) {
      return;
    }
    unawaited(_openPaywallDialog());
  }

  Future<void> _openPaywallDialog() async {
    _paywallDialogVisible = true;
    try {
      await showPaywallDialog(context);
    } finally {
      _paywallDialogVisible = false;
    }
  }

  bool _memberHasPet(FamilyMemberViewData member) {
    return member.pet != null || member.petId != null;
  }

  FamilyMemberViewData? _currentUserMemberWithoutPet(
    AuthState authState,
    FamilyScreenState familyState,
  ) {
    final user = authState.user;
    if (user == null || familyState.loading || !familyState.hasFamily) {
      return null;
    }

    for (final member in familyState.members) {
      if (member.id == user.id &&
          (member.needsPetSelection || !_memberHasPet(member))) {
        return member;
      }
    }
    return null;
  }

  void _maybePromptCurrentUserPetSelection() {
    if (!mounted ||
        _isReadOnlyAfterTrial ||
        _didAutoPromptCurrentUserPet ||
        _selectingPetMemberId != null) {
      return;
    }
    final member = _currentUserMemberWithoutPet(
      ref.read(authProvider),
      ref.read(familyProvider),
    );
    if (member == null) {
      return;
    }

    _didAutoPromptCurrentUserPet = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _selectingPetMemberId != null) {
        return;
      }
      _onMissingPetTap(ref.read(authProvider), member, autoPrompt: true);
    });
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
    return trimmed.isEmpty ? '家庭小屋' : trimmed;
  }

  int _petCount(List<FamilyMemberViewData> members) {
    return members.where((member) => member.petType != null).length;
  }

  Future<void> _openPetDetail(Pet pet, String? avatarAssetPath) async {
    await showPetDetailDialog(
      context,
      pet: pet,
      avatarAssetPath: avatarAssetPath,
    );
  }

  bool _canEditAvatarForMember(
    AuthState authState,
    FamilyMemberViewData member, {
    bool ignoreTrialBlock = false,
  }) {
    if (!ignoreTrialBlock && _isReadOnlyAfterTrial) {
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
    if (_isReadOnlyAfterTrial || user == null || !user.isAdmin) {
      return false;
    }
    return user.id != member.id;
  }

  bool _canDeleteMemberIgnoringTrial(
    AuthState authState,
    FamilyMemberViewData member,
  ) {
    final user = authState.user;
    if (user == null || !user.isAdmin) {
      return false;
    }
    return user.id != member.id;
  }

  bool _canAssignPetForMember(
    AuthState authState,
    FamilyMemberViewData member,
  ) {
    if (_isReadOnlyAfterTrial || _selectingPetMemberId != null) {
      return false;
    }

    final user = authState.user;
    if (user == null) {
      return false;
    }

    return user.id == member.id || user.isAdmin;
  }

  Future<void> _onMissingPetTap(
    AuthState authState,
    FamilyMemberViewData member, {
    bool autoPrompt = false,
  }) async {
    if (_isReadOnlyAfterTrial) {
      if (!autoPrompt) {
        _showMembershipRequiredPaywall();
      }
      return;
    }

    if (!_canAssignPetForMember(authState, member)) {
      if (!autoPrompt) {
        _showTopNotice('请家长为成员选择宠物');
      }
      return;
    }

    final draft = await showSelectPetFlowDialog(
      context,
      memberName: member.nickname,
    );
    if (draft == null) {
      return;
    }

    setState(() => _selectingPetMemberId = member.id);

    try {
      await ref
          .read(familyProvider.notifier)
          .assignMemberPet(
            memberId: member.id,
            petType: draft.petType,
            petName: draft.petName,
          );
      await _loadFamily();
      if (!mounted) {
        return;
      }
      if (authState.user?.id == member.id) {
        await ref.read(authProvider.notifier).refreshUser();
      }
      if (!mounted) {
        return;
      }
      _showTopNotice('${member.nickname} 已领养 ${draft.petName}');
    } catch (error) {
      if (!mounted) {
        return;
      }
      await _loadFamily();
      if (!mounted) {
        return;
      }
      showFriendlyApiErrorSnackBar(
        context,
        error,
        fallbackMessage: '选择宠物失败，请稍后重试',
      );
    } finally {
      if (mounted && _selectingPetMemberId == member.id) {
        setState(() => _selectingPetMemberId = null);
      }
    }
  }

  Future<void> _onAvatarEditTap(
    AuthState authState,
    FamilyMemberViewData member,
  ) async {
    if (_isReadOnlyAfterTrial) {
      _showMembershipRequiredPaywall();
      return;
    }

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
      _showTopNotice('头像已更新');
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
    if (_isReadOnlyAfterTrial) {
      _showMembershipRequiredPaywall();
      return;
    }

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
      if (!mounted) {
        return;
      }
      _showTopNotice('已删除${member.nickname}');
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
    if (_isReadOnlyAfterTrial) {
      _showMembershipRequiredPaywall();
      return;
    }

    final canManageMembers = user?.isAdmin == true;
    if (!canManageMembers || user?.familyId == null) {
      _showTopNotice('只有家长可以添加成员');
      return;
    }

    if (familyState.members.length >= _maxMembers) {
      _showTopNotice('当前家庭最多支持 8 位成员');
      return;
    }

    final draft = await _showAddMemberFlowDialog();
    if (draft == null) {
      return;
    }

    setState(() => _addingMember = true);

    try {
      final notifier = ref.read(familyProvider.notifier);
      final member = await notifier.addMemberWithPet(
        nickname: draft.nickname,
        petType: draft.petType,
        petName: draft.petName,
      );
      if (!mounted) {
        return;
      }

      _showTopNotice('已添加${member.nickname}，并领养了${draft.petName}');
    } catch (error) {
      if (!mounted) {
        return;
      }
      await _loadFamily();
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
    final readOnlyAfterTrial = ref.watch(coreMutationBlockedProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybePromptCurrentUserPetSelection();
    });

    if (widget.embedded) {
      return _buildBody(
        authState,
        familyState,
        readOnlyAfterTrial: readOnlyAfterTrial,
      );
    }

    final content = DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_FamilyPalette.pageTop, _FamilyPalette.pageBottom],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: _buildBody(
          authState,
          familyState,
          readOnlyAfterTrial: readOnlyAfterTrial,
        ),
      ),
    );

    return Scaffold(backgroundColor: _FamilyPalette.pageBottom, body: content);
  }

  Widget _buildBody(
    AuthState authState,
    FamilyScreenState familyState, {
    required bool readOnlyAfterTrial,
  }) {
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
    final familyTitle = _familyTitle(familyState.familyName);
    final canManageMembers = authState.user?.isAdmin == true;

    void onAddMemberTap() {
      _onAddMemberTap(authState, familyState);
    }

    return RefreshIndicator(
      color: _FamilyPalette.accentDark,
      onRefresh: _loadFamily,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = widget.embedded ? 0.0 : 22.0;
          final verticalPadding = widget.embedded ? 0.0 : 18.0;
          final availableWidth = (constraints.maxWidth - horizontalPadding * 2)
              .clamp(0.0, double.infinity)
              .toDouble();
          final availableHeight =
              constraints.hasBoundedHeight && constraints.maxHeight.isFinite
              ? (constraints.maxHeight - verticalPadding * 2)
                    .clamp(0.0, double.infinity)
                    .toDouble()
              : double.infinity;
          const stageAspectRatio = 0.64;
          final heightFromWidth = availableWidth / stageAspectRatio;
          final stageHeight = availableHeight.isFinite
              ? math.min(heightFromWidth, availableHeight)
              : heightFromWidth;

          final stage = SizedBox(
            height: stageHeight,
            child: FadeTransition(
              opacity: _contentOpacity,
              child: SlideTransition(
                position: _contentOffset,
                child: _FamilyStageCard(
                  embedded: widget.embedded,
                  title: familyTitle,
                  petCount: petCount,
                  memberCount: members.length,
                  canManageMembers: canManageMembers,
                  addingMember: _addingMember,
                  onLeadingTap: _handleLeadingAction,
                  onAddMemberTap: onAddMemberTap,
                  membersPanel: _FamilyMembersPanel(
                    compact: widget.embedded,
                    members: members,
                    petAvatarAssetPathsById: widget.petAvatarAssetPathsById,
                    entryAnimation: _entryController,
                    canManageMembers: canManageMembers,
                    onAddMemberTap: onAddMemberTap,
                    onPetTap: _openPetDetail,
                    onMissingPetTap: (member) =>
                        _onMissingPetTap(authState, member),
                    canEditAvatar: (member) => _canEditAvatarForMember(
                      authState,
                      member,
                      ignoreTrialBlock: readOnlyAfterTrial,
                    ),
                    onAvatarEditTap: (member) =>
                        _onAvatarEditTap(authState, member),
                    updatingAvatarMemberId: _updatingAvatarMemberId,
                    canDeleteMember: (member) => readOnlyAfterTrial
                        ? _canDeleteMemberIgnoringTrial(authState, member)
                        : _canDeleteMember(authState, member),
                    onMemberLongPress: (member) =>
                        _onMemberLongPress(authState, member),
                  ),
                ),
              ),
            ),
          );

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              widget.embedded ? 0 : verticalPadding,
              horizontalPadding,
              widget.embedded ? 0 : verticalPadding + 8,
            ),
            child: Align(alignment: Alignment.topCenter, child: stage),
          );
        },
      ),
    );
  }
}

class _FamilyTopNoticeCard extends StatelessWidget {
  const _FamilyTopNoticeCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.topCenter,
        child: Material(
          color: Colors.transparent,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _FamilyPalette.deepBrown.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFFFE4B5).withValues(alpha: 0.52),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
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
    required this.petCount,
    required this.memberCount,
    required this.canManageMembers,
    required this.addingMember,
    required this.onLeadingTap,
    required this.onAddMemberTap,
    required this.membersPanel,
  });

  final bool embedded;
  final String title;
  final int petCount;
  final int memberCount;
  final bool canManageMembers;
  final bool addingMember;
  final VoidCallback onLeadingTap;
  final VoidCallback onAddMemberTap;
  final Widget membersPanel;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.64,
      child: Stack(
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(
              FamilyPopupAssets.mainPanel,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.medium,
              isAntiAlias: true,
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Image.asset(
                FamilyPopupAssets.mainPanelOutline,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.medium,
                isAntiAlias: true,
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = constraints.maxHeight;
              final titleWidth = (width * 0.32).clamp(132.0, 210.0).toDouble();
              final titleHeight = titleWidth / 3.03;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: width * 0.070,
                    top: height * 0.058,
                    child: canManageMembers
                        ? _HeroAddButton(
                            compact: embedded || width < 430,
                            busy: addingMember,
                            onTap: onAddMemberTap,
                          )
                        : SizedBox(width: width * 0.15, height: width * 0.15),
                  ),
                  Positioned(
                    top: height * 0.055,
                    left: (width - titleWidth) / 2,
                    width: titleWidth,
                    height: titleHeight,
                    child: _FamilyTitleText(title: title),
                  ),
                  Positioned(
                    left: width * 0.055,
                    right: width * 0.055,
                    top: height * 0.158,
                    bottom: height * 0.062,
                    child: membersPanel,
                  ),
                ],
              );
            },
          ),
          Positioned(
            top: 0,
            right: 2,
            child: _CircleIconButton(
              icon: embedded ? Icons.close_rounded : Icons.arrow_back_rounded,
              tooltip: embedded ? '关闭' : '返回首页',
              onTap: onLeadingTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _FamilyTitleText extends StatelessWidget {
  const _FamilyTitleText({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final displayTitle = title.trim().isEmpty ? '家庭小屋' : title.trim();

    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          displayTitle,
          maxLines: 1,
          style: const TextStyle(
            color: _FamilyPalette.deepBrown,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            height: 1,
            shadows: [
              Shadow(
                color: Color(0x66FFFFFF),
                offset: Offset(0, 1.5),
                blurRadius: 0.2,
              ),
              Shadow(
                color: Color(0x33A86C35),
                offset: Offset(0, 2.5),
                blurRadius: 0.4,
              ),
            ],
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
          width: compact ? 50 : 58,
          height: compact ? 50 : 58,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                FamilyPopupAssets.addButton,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
                isAntiAlias: true,
              ),
              Positioned(
                left: compact ? 7 : 8,
                right: compact ? 7 : 8,
                bottom: compact ? 4 : 5,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '添加',
                    maxLines: 1,
                    style: TextStyle(
                      color: const Color(0xFF3F230D),
                      fontSize: compact ? 14 : 16,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
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

class _FamilyMembersPanel extends StatelessWidget {
  const _FamilyMembersPanel({
    required this.compact,
    required this.members,
    required this.petAvatarAssetPathsById,
    required this.entryAnimation,
    required this.canManageMembers,
    required this.onAddMemberTap,
    required this.onPetTap,
    required this.onMissingPetTap,
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
  final ValueChanged<FamilyMemberViewData> onMissingPetTap;
  final bool Function(FamilyMemberViewData member) canEditAvatar;
  final ValueChanged<FamilyMemberViewData> onAvatarEditTap;
  final int? updatingAvatarMemberId;
  final bool Function(FamilyMemberViewData member) canDeleteMember;
  final ValueChanged<FamilyMemberViewData> onMemberLongPress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 4),
      child: FamilyMemberGrid(
        members: members,
        petAvatarAssetPathsById: petAvatarAssetPathsById,
        entryAnimation: entryAnimation,
        canAddMembers: canManageMembers,
        onAddMemberTap: onAddMemberTap,
        onPetTap: onPetTap,
        onMissingPetTap: onMissingPetTap,
        canEditAvatar: canEditAvatar,
        onAvatarEditTap: onAvatarEditTap,
        updatingAvatarMemberId: updatingAvatarMemberId,
        canDeleteMember: canDeleteMember,
        onMemberLongPress: onMemberLongPress,
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
            width: 48,
            height: 48,
            child: Center(
              child: Image.asset(
                FamilyPopupAssets.closeButton,
                width: 44,
                height: 44,
                filterQuality: FilterQuality.medium,
                isAntiAlias: true,
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
