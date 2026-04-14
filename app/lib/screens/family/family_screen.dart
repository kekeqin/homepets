import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_error_helper.dart';
import '../../models/pet_artwork.dart';
import '../../providers/auth_provider.dart';
import '../../providers/family_provider.dart';
import '../member/member_detail_screen.dart';
import 'dialogs/add_member_dialog.dart';
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
        fallbackMessage:
            '\u52a0\u8f7d\u5bb6\u5ead\u4fe1\u606f\u5931\u8d25\uff0c\u8bf7\u7a0d\u540e\u91cd\u8bd5',
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '\u53ea\u6709\u5bb6\u957f\u53ef\u4ee5\u6dfb\u52a0\u6210\u5458',
          ),
        ),
      );
      return;
    }

    if (familyState.members.length >= FamilyMemberGrid.maxDisplayMembers) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '\u5f53\u524d\u5bb6\u5ead\u6700\u591a\u652f\u6301 8 \u4f4d\u6210\u5458',
          ),
        ),
      );
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

      String? selectedPetType;
      while (true) {
        if (!mounted) {
          return;
        }

        selectedPetType = await _showPetSelectionDialog(member.nickname);
        if (selectedPetType == null) {
          await _loadFamily();
          return;
        }

        try {
          await notifier.assignMemberPet(
            memberId: member.id,
            petType: selectedPetType,
          );
          break;
        } catch (error) {
          if (!mounted) {
            return;
          }
          showFriendlyApiErrorSnackBar(
            context,
            error,
            fallbackMessage:
                '\u9009\u62e9\u5ba0\u7269\u5931\u8d25\uff0c\u8bf7\u91cd\u8bd5',
          );
        }
      }

      if (!mounted) {
        return;
      }
      final confirmedPetType = selectedPetType;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '\u5df2\u6dfb\u52a0\u6210\u5458\uff1a${member.nickname}\uff0c\u5e76\u9009\u62e9\u4e86${petTypeLabel(confirmedPetType)}',
          ),
        ),
      );

      await _loadFamily();
    } catch (error) {
      if (!mounted) {
        return;
      }
      showFriendlyApiErrorSnackBar(
        context,
        error,
        fallbackMessage:
            '\u6dfb\u52a0\u6210\u5458\u6216\u9009\u62e9\u5ba0\u7269\u5931\u8d25\uff0c\u8bf7\u7a0d\u540e\u91cd\u8bd5',
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
        title: '\u8bf7\u5148\u767b\u5f55',
        message:
            '\u767b\u5f55\u540e\u53ef\u67e5\u770b\u5bb6\u5ead\u6210\u5458\u5e76\u8fdb\u5165\u4eba\u5458\u8be6\u60c5\u9875\u3002',
      );
    }

    if (familyState.loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF74512D)),
      );
    }

    if (!familyState.hasFamily) {
      return const FamilyHintCard(
        title: '\u6682\u672a\u52a0\u5165\u5bb6\u5ead',
        message:
            '\u8bf7\u5148\u521b\u5efa\u5bb6\u5ead\u6216\u901a\u8fc7\u9080\u8bf7\u7801\u52a0\u5165\u5bb6\u5ead\u3002',
      );
    }

    return FamilyMemberGrid(
      members: familyState.members,
      entryAnimation: _entryController,
      onMemberTap: _openMemberDetail,
    );
  }
}
