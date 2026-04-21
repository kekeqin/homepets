import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';

import '../../core/api_error_helper.dart';
import '../../models/pet_artwork.dart';
import '../../providers/auth_provider.dart';
import '../../providers/family_provider.dart';
import '../member/member_detail_screen.dart';
import 'dialogs/add_member_dialog.dart';
import 'dialogs/pet_name_dialog.dart';
import 'dialogs/pet_selection_dialog.dart';
import 'models/family_member_view_data.dart';
import 'models/family_screen_state.dart';
import 'widgets/family_hint_card.dart';
import 'widgets/family_member_grid.dart';

class FamilyScreen extends ConsumerStatefulWidget {
  const FamilyScreen({super.key});

  @override
  ConsumerState<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends ConsumerState<FamilyScreen>
    with SingleTickerProviderStateMixin {
  static const _heroBackgroundAsset = 'assets/images/ui/home_bg.png';
  static const _heroAsset = 'assets/images/ui/family_man_trim.png';
  static const _footerAsset = 'assets/images/ui/family_footer.png';

  bool _addingMember = false;

  late final AnimationController _entryController;
  late final Animation<double> _contentOpacity;
  late final Animation<Offset> _heroOffset;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    );
    _contentOpacity = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );
    _heroOffset = Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero)
        .animate(
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
      _playEntryAnimation();
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

  void _playEntryAnimation() {
    if (!mounted) {
      return;
    }
    _entryController.forward(from: 0);
  }

  Future<void> _openMemberDetail(FamilyMemberViewData member) async {
    await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => MemberDetailScreen(
          memberId: member.id,
          nickname: member.nickname,
          role: member.role,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    await _loadFamily();
  }

  Future<String?> _showAddMemberDialog() async {
    return showAddMemberDialog(context);
  }

  Future<String?> _showPetSelectionDialog(String nickname) async {
    return showPetSelectionDialog(context, nickname: nickname);
  }

  Future<String?> _showPetNameDialog({
    required String memberNickname,
    required String petType,
  }) async {
    return showPetNameDialog(
      context,
      memberNickname: memberNickname,
      petType: petType,
    );
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

    if (familyState.members.length >= FamilyMemberGrid.maxDisplayMembers) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('当前家庭最多支持 8 位成员')));
      return;
    }

    final nickname = await _showAddMemberDialog();
    if (nickname == null) {
      return;
    }

    setState(() {
      _addingMember = true;
    });

    try {
      final notifier = ref.read(familyProvider.notifier);
      final member = await notifier.addMember(nickname);
      if (!mounted) {
        return;
      }

      while (true) {
        if (!mounted) {
          return;
        }

        final selectedPetType = await _showPetSelectionDialog(member.nickname);
        if (selectedPetType == null) {
          await _loadFamily();
          return;
        }

        final petName = await _showPetNameDialog(
          memberNickname: member.nickname,
          petType: selectedPetType,
        );
        if (petName == null) {
          await _loadFamily();
          return;
        }

        try {
          await notifier.assignMemberPet(
            memberId: member.id,
            petType: selectedPetType,
            petName: petName,
          );
          if (!mounted) {
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '已添加成员：${member.nickname}，并领养了${petTypeLabel(selectedPetType)}“$petName”',
              ),
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
        }
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      showFriendlyApiErrorSnackBar(
        context,
        error,
        fallbackMessage: '添加成员或选择宠物失败，请稍后重试',
      );
    } finally {
      if (mounted) {
        setState(() {
          _addingMember = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final familyState = ref.watch(familyProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F0E8),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              _heroBackgroundAsset,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              filterQuality: FilterQuality.high,
            ),
          ),
          SafeArea(bottom: false, child: _buildBody(authState, familyState)),
        ],
      ),
    );
  }

  Widget _buildBody(AuthState authState, FamilyScreenState familyState) {
    if (!authState.isAuthenticated) {
      return const FamilyHintCard(
        title: '请先登录',
        message: '登录后就能看到全家的成员卡片和宠物成长状态。',
      );
    }

    if (familyState.loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFD79353)),
      );
    }

    if (!familyState.hasFamily) {
      return const FamilyHintCard(
        title: '暂未加入家庭',
        message: '先创建家庭或通过邀请码加入，家庭页才会显示完整内容。',
      );
    }

    final canManageMembers =
        authState.user?.isAdmin == true && !authState.viewOnly;
    return RefreshIndicator(
      color: const Color(0xFFD79353),
      onRefresh: _loadFamily,
      child: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
        children: [
          FadeTransition(
            opacity: _contentOpacity,
            child: SlideTransition(
              position: _heroOffset,
              child: Column(
                children: [
                  _FamilyHeroCard(
                    canAddMembers: canManageMembers,
                    addingMember: _addingMember,
                    onBack: () => context.go('/home'),
                    onAddMember: () => _onAddMemberTap(authState, familyState),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -18),
                    child: _FamilyContentPanel(
                      members: familyState.members,
                      entryAnimation: _entryController,
                      onMemberTap: _openMemberDetail,
                      canAddMembers: canManageMembers,
                      onAddMemberTap: () =>
                          _onAddMemberTap(authState, familyState),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FamilyHeroCard extends StatelessWidget {
  const _FamilyHeroCard({
    required this.canAddMembers,
    required this.addingMember,
    required this.onBack,
    required this.onAddMember,
  });

  final bool canAddMembers;
  final bool addingMember;
  final VoidCallback onBack;
  final VoidCallback onAddMember;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final heroCardHeight = (screenWidth * 0.82).clamp(300.0, 400.0).toDouble();

    return SizedBox(
      height: heroCardHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 4,
            left: 8,
            child: _HeroIconButton(
              icon: Icons.arrow_back_rounded,
              onTap: onBack,
              tooltip: '返回主页',
            ),
          ),
          if (canAddMembers)
            Positioned(
              top: 4,
              right: 8,
              child: _HeroIconButton(
                icon: addingMember
                    ? Icons.hourglass_top_rounded
                    : Icons.add_rounded,
                onTap: addingMember ? null : onAddMember,
                tooltip: '添加成员',
                filled: true,
              ),
            ),
          Positioned.fill(
            top: 40,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final heroWidthFactor = switch (screenWidth) {
                  < 360 => 1.12,
                  < 430 => 1.04,
                  < 600 => 0.9,
                  _ => 0.76,
                };
                final heroWidth = constraints.maxWidth * heroWidthFactor;

                return IgnorePointer(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Transform.translate(
                      offset: const Offset(0, 44),
                      child: Image.asset(
                        _FamilyScreenState._heroAsset,
                        width: heroWidth,
                        fit: BoxFit.fitWidth,
                        alignment: Alignment.topCenter,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroIconButton extends StatelessWidget {
  const _HeroIconButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String tooltip;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = filled
        ? const Color(0xFFEAA35E)
        : Colors.white.withValues(alpha: 0.9);
    final foregroundColor = filled ? Colors.white : const Color(0xFF8A5E3A);

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: filled ? Colors.transparent : const Color(0xFFEEDCC7),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: foregroundColor, size: 20),
        ),
      ),
    );
  }
}

class _FamilyContentPanel extends StatelessWidget {
  const _FamilyContentPanel({
    required this.members,
    required this.entryAnimation,
    required this.onMemberTap,
    required this.canAddMembers,
    required this.onAddMemberTap,
  });

  final List<FamilyMemberViewData> members;
  final Animation<double> entryAnimation;
  final ValueChanged<FamilyMemberViewData> onMemberTap;
  final bool canAddMembers;
  final VoidCallback onAddMemberTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFFCF8).withValues(alpha: 0.62),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: const Color(0xFFF3E4D3).withValues(alpha: 0.72),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0E000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 24, 14, 16),
            child: Column(
              children: [
                FamilyMemberGrid(
                  members: members,
                  entryAnimation: entryAnimation,
                  onMemberTap: onMemberTap,
                  canAddMembers: canAddMembers,
                  onAddMemberTap: onAddMemberTap,
                ),
                if (members.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _FamilySummaryActions(
                    canAddMembers: canAddMembers,
                    onAddMemberTap: onAddMemberTap,
                  ),
                  const SizedBox(height: 12),
                  const _FamilyFootnoteCard(
                    footerAsset: _FamilyScreenState._footerAsset,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FamilySummaryActions extends StatelessWidget {
  const _FamilySummaryActions({
    required this.canAddMembers,
    required this.onAddMemberTap,
  });

  final bool canAddMembers;
  final VoidCallback onAddMemberTap;

  @override
  Widget build(BuildContext context) {
    return _SummaryActionChip(
      label: '添加成员',
      icon: Icons.person_add_alt_1_rounded,
      highlight: canAddMembers,
      onTap: onAddMemberTap,
    );
  }
}

class _SummaryActionChip extends StatelessWidget {
  const _SummaryActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
    this.highlight = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = highlight
        ? const Color(0xFFDD8F45)
        : const Color(0xFF9A6D47);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color:
                (highlight ? const Color(0xFFFFE7CE) : const Color(0xFFF8EBDD))
                    .withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: foregroundColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: foregroundColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FamilyFootnoteCard extends StatelessWidget {
  const _FamilyFootnoteCard({required this.footerAsset});

  final String footerAsset;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Image.asset(
        footerAsset,
        width: double.infinity,
        fit: BoxFit.fitWidth,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}
