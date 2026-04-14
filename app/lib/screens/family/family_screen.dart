import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
import 'widgets/family_add_member_button.dart';
import 'widgets/family_hint_card.dart';
import 'widgets/family_member_grid.dart';
import 'widgets/family_top_bar.dart';

class FamilyScreen extends ConsumerStatefulWidget {
  const FamilyScreen({super.key});

  @override
  ConsumerState<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends ConsumerState<FamilyScreen>
    with SingleTickerProviderStateMixin {
  static const _backgroundAsset = 'assets/images/ui/family_link.png';

  bool _addingMember = false;

  late final AnimationController _entryController;
  late final Animation<double> _backgroundOpacity;
  late final Animation<double> _backgroundScale;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1150),
    );
    _backgroundOpacity = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0, 0.42, curve: Curves.easeOut),
    );
    _backgroundScale = Tween<double>(begin: 1.04, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0, 0.54, curve: Curves.easeOutCubic),
      ),
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
      backgroundColor: const Color(0xFFF4E5D2),
      body: Stack(
        children: [
          Positioned.fill(child: _buildBackground()),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                FamilyTopBar(
                  title: familyState.familyName,
                  showRefresh:
                      authState.isAuthenticated && familyState.hasFamily,
                  loading: familyState.loading,
                  onBack: () => context.go('/home'),
                  onRefresh: _loadFamily,
                ),
                Expanded(child: _buildBody(authState, familyState)),
                if (authState.isAuthenticated &&
                    familyState.hasFamily &&
                    authState.user?.isAdmin == true &&
                    !authState.viewOnly)
                  FamilyAddMemberButton(
                    loading: _addingMember || familyState.loading,
                    onTap: () => _onAddMemberTap(authState, familyState),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return AnimatedBuilder(
      animation: _entryController,
      builder: (context, child) {
        return Opacity(
          opacity: _backgroundOpacity.value,
          child: Transform.scale(scale: _backgroundScale.value, child: child),
        );
      },
      child: Image.asset(
        _backgroundAsset,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        filterQuality: FilterQuality.high,
      ),
    );
  }

  Widget _buildBody(AuthState authState, FamilyScreenState familyState) {
    if (!authState.isAuthenticated) {
      return const FamilyHintCard(
        title: '请先登录',
        message: '登录后可查看家庭成员并进入人员详情页。',
      );
    }

    if (familyState.loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF74512D)),
      );
    }

    if (!familyState.hasFamily) {
      return const FamilyHintCard(
        title: '暂未加入家庭',
        message: '请先创建家庭或通过邀请码加入家庭。',
      );
    }

    return FamilyMemberGrid(
      members: familyState.members,
      entryAnimation: _entryController,
      onMemberTap: _openMemberDetail,
    );
  }
}
