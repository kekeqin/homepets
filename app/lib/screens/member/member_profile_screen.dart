import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_error_helper.dart';
import '../../models/pet.dart';
import '../../providers/auth_provider.dart';
import '../../services/member_profile_service.dart';
import '../pet/pet_detail_screen.dart';
import 'models/member_profile_view_data.dart';
import 'widgets/member_avatar_picker_sheet.dart';
import 'widgets/member_profile_badge_grid.dart';
import 'widgets/member_profile_common.dart';
import 'widgets/member_profile_hero.dart';
import 'widgets/member_profile_pet_card.dart';
import 'widgets/member_profile_progress_tile.dart';

class MemberProfileScreen extends ConsumerStatefulWidget {
  const MemberProfileScreen({
    super.key,
    required this.memberId,
    required this.nickname,
    required this.role,
  });

  final int memberId;
  final String nickname;
  final String role;

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
    final user = ref.read(authProvider).user;
    final familyId = user?.familyId;
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
        fallbackMessage: '加载成员档案失败，请稍后重试',
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

  String get _memberTitle {
    if (widget.role == 'admin') {
      return '家庭守护者';
    }
    if (_memberLevel >= 12) {
      return '超凡探险家';
    }
    if (_memberLevel >= 8) {
      return '成长领航员';
    }
    if (_memberLevel >= 4) {
      return '活力探索家';
    }
    return '闪亮新成员';
  }

  Pet? get _mainPet => _pets.isEmpty ? null : _pets.first;

  Future<void> _openPetDetail(Pet pet) async {
    await Navigator.of(
      context,
      rootNavigator: true,
    ).push(MaterialPageRoute(builder: (_) => PetDetailScreen(pet: pet)));
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
    final topPadding = MediaQuery.paddingOf(context).top;
    final mainPet = _mainPet;

    return Scaffold(
      backgroundColor: MemberProfileColors.background,
      body: Stack(
        children: [
          Positioned(
            top: 110,
            left: -40,
            child: MemberProfileGlow(
              size: 150,
              color: MemberProfileColors.gold.withValues(alpha: 0.14),
            ),
          ),
          Positioned(
            top: 240,
            right: -30,
            child: MemberProfileGlow(
              size: 130,
              color: MemberProfileColors.blue.withValues(alpha: 0.22),
            ),
          ),
          Positioned(
            bottom: 160,
            left: -20,
            child: MemberProfileGlow(
              size: 100,
              color: MemberProfileColors.greenSoft.withValues(alpha: 0.7),
            ),
          ),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(
                color: MemberProfileColors.green,
              ),
            )
          else
            RefreshIndicator(
              color: MemberProfileColors.green,
              onRefresh: _loadData,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                children: [
                  Container(
                    padding: EdgeInsets.fromLTRB(18, topPadding + 12, 18, 20),
                    decoration: const BoxDecoration(
                      color: MemberProfileColors.shell,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(34),
                        bottomRight: Radius.circular(34),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: MemberProfileColors.shadow,
                          blurRadius: 18,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        MemberProfileTopButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          onTap: canPop
                              ? () => Navigator.of(context).maybePop()
                              : null,
                        ),
                        const Expanded(
                          child: Text(
                            '成员档案',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: MemberProfileColors.green,
                            ),
                          ),
                        ),
                        const MemberProfileTopButton(
                          icon: Icons.more_horiz_rounded,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 26, 20, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: MemberProfileHero(
                            nickname: widget.nickname,
                            role: widget.role,
                            memberLevel: _memberLevel,
                            memberTitle: _memberTitle,
                            memberPoints: _memberPoints,
                            completionCount: _completions.length,
                            avatarUrl: _avatarUrl,
                            canEditAvatar: _canEditAvatar,
                            onChangeAvatar: _changeAvatar,
                          ),
                        ),
                        if (canDelete) ...[
                          const SizedBox(height: 18),
                          Center(
                            child: OutlinedButton.icon(
                              onPressed: _deleteMember,
                              icon: const Icon(Icons.delete_outline_rounded),
                              label: const Text('删除该成员'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: MemberProfileColors.coral,
                                side: const BorderSide(
                                  color: MemberProfileColors.coral,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 30),
                        const MemberProfileSectionTitle(
                          title: '宠物伙伴',
                          subtitle: '和 TA 一起升级、一起成长',
                        ),
                        const SizedBox(height: 14),
                        if (mainPet == null)
                          const MemberProfileEmptyCard(
                            icon: Icons.pets_outlined,
                            title: '还没有绑定宠物',
                            message: '完成任务、领养伙伴后，这里会出现专属宠物档案。',
                          )
                        else
                          MemberProfilePetCard(
                            pet: mainPet,
                            completionCount: _completions.length,
                            onTap: () => _openPetDetail(mainPet),
                          ),
                        const SizedBox(height: 28),
                        MemberProfileBadgeGrid(
                          memberLevel: _memberLevel,
                          pets: _profile.pets,
                          completions: _completions,
                        ),
                        const SizedBox(height: 28),
                        const MemberProfileSectionTitle(
                          title: '最近进展',
                          subtitle: '最近完成的任务会在这里点亮',
                        ),
                        const SizedBox(height: 14),
                        if (_completions.isEmpty)
                          const MemberProfileEmptyCard(
                            icon: Icons.schedule_rounded,
                            title: '还没有完成记录',
                            message: '完成一项家庭任务后，这里会展示最近的成长动态。',
                          )
                        else
                          ..._completions
                              .take(5)
                              .map(
                                (completion) => MemberProfileProgressTile(
                                  completion: completion,
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
    );
  }
}
