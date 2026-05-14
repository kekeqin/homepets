import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_error_helper.dart';
import '../../models/pet.dart';
import '../../providers/auth_provider.dart';
import '../../providers/family_provider.dart';
import '../../services/member_profile_service.dart';
import '../family/dialogs/delete_member_dialog.dart';
import '../pet/pet_detail_screen.dart';
import 'models/member_profile_view_data.dart';
import 'widgets/member_avatar_picker_sheet.dart';
import 'widgets/member_profile_ipad_activity_row.dart';
import 'widgets/member_profile_ipad_common.dart';
import 'widgets/member_profile_ipad_overview_panel.dart';
import 'widgets/member_profile_ipad_pet_card.dart';

class MemberProfileIpadScreen extends ConsumerStatefulWidget {
  const MemberProfileIpadScreen({
    super.key,
    required this.memberId,
    required this.nickname,
    required this.role,
  });

  final int memberId;
  final String nickname;
  final String role;

  @override
  ConsumerState<MemberProfileIpadScreen> createState() =>
      _MemberProfileIpadScreenState();
}

class _MemberProfileIpadScreenState
    extends ConsumerState<MemberProfileIpadScreen> {
  MemberProfileViewData _profile = MemberProfileViewData.empty;
  bool _loading = true;
  DateTime? _joinDate;

  MemberProfileService get _profileService =>
      MemberProfileService(ref.read(apiClientProvider));

  List<Pet> get _pets => _profile.pets;
  List<MemberTaskCompletion> get _completions => _profile.completions;
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
        _joinDate = null;
        _loading = false;
      });
      return;
    }

    try {
      final profile = await _profileService.loadProfile(
        familyId: familyId,
        memberId: widget.memberId,
      );
      DateTime? joinDate;
      if (profile.completions.isNotEmpty) {
        joinDate = profile.completions.last.createdAt;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _profile = profile;
        _joinDate = joinDate;
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
    final confirm = await showDeleteMemberDialog(
      context,
      memberName: widget.nickname,
    );
    /*
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除成员'),
        content: Text('确认删除“${widget.nickname}”吗？该成员名下宠物也会一起删除。'),
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
    */
    if (!confirm) {
      return;
    }

    final familyId = ref.read(authProvider).user?.familyId;
    if (familyId == null) {
      return;
    }

    try {
      await ref
          .read(familyProvider.notifier)
          .deleteMember(memberId: widget.memberId);
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

  String _joinDateText() {
    if (_joinDate == null) {
      return '暂无';
    }
    return '${_joinDate!.year}/${_joinDate!.month}/${_joinDate!.day}';
  }

  String _formatActivityTime(DateTime? time) {
    if (time == null) {
      return '';
    }
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '${time.month}/${time.day} $hour:$minute';
  }

  String _taskTypeLabel(String rawType) {
    return switch (rawType) {
      'limited' => '限时任务',
      'challenge' => '挑战任务',
      _ => '日常任务',
    };
  }

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
    final avatarEmoji = _pets.isNotEmpty
        ? _pets.first.displayEmoji
        : (widget.role == 'admin' ? '👨' : '🧒');

    return Scaffold(
      backgroundColor: MemberProfileIpadColors.background,
      appBar: AppBar(
        leading: Navigator.of(context).canPop()
            ? IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
              )
            : null,
        title: const Text('成员详情'),
        backgroundColor: MemberProfileIpadColors.background,
        foregroundColor: MemberProfileIpadColors.text,
        surfaceTintColor: MemberProfileIpadColors.background,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 28),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: MemberProfileIpadColors.shell,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: MemberProfileIpadOverviewPanel(
                          avatarEmoji: avatarEmoji,
                          avatarValue: _avatarUrl,
                          nickname: widget.nickname,
                          role: widget.role,
                          points: _memberPoints,
                          canDelete: canDelete,
                          canEditAvatar: _canEditAvatar,
                          onEditAvatar: _changeAvatar,
                          onDelete: _deleteMember,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 5,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: MemberProfileIpadMetricCard(
                                    label: '完成任务',
                                    value: '${_completions.length}',
                                    background: MemberProfileIpadColors.blue,
                                    foreground:
                                        MemberProfileIpadColors.blueText,
                                    icon: Icons.task_alt_rounded,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: MemberProfileIpadMetricCard(
                                    label: '当前积分',
                                    value: '$_memberPoints',
                                    background: MemberProfileIpadColors.gold,
                                    foreground:
                                        MemberProfileIpadColors.goldText,
                                    icon: Icons.bolt_rounded,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: MemberProfileIpadMetricCard(
                                    label: '加入时间',
                                    value: _joinDateText(),
                                    background:
                                        MemberProfileIpadColors.greenSoft,
                                    foreground: MemberProfileIpadColors.green,
                                    icon: Icons.calendar_month_rounded,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            MemberProfileIpadPanelCard(
                              title: '宠物伙伴',
                              child: _pets.isEmpty
                                  ? const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 26,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '还没有宠物伙伴',
                                          style: TextStyle(
                                            color:
                                                MemberProfileIpadColors.muted,
                                          ),
                                        ),
                                      ),
                                    )
                                  : GridView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 3,
                                            crossAxisSpacing: 12,
                                            mainAxisSpacing: 12,
                                            childAspectRatio: 0.98,
                                          ),
                                      itemCount: _pets.length,
                                      itemBuilder: (context, index) {
                                        final pet = _pets[index];
                                        return MemberProfileIpadPetCard(
                                          pet: pet,
                                          onTap: () => _openPetDetail(pet),
                                        );
                                      },
                                    ),
                            ),
                            const SizedBox(height: 16),
                            MemberProfileIpadPanelCard(
                              title: '最近记录',
                              child: _completions.isEmpty
                                  ? const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 26,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '还没有完成记录',
                                          style: TextStyle(
                                            color:
                                                MemberProfileIpadColors.muted,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Column(
                                      children: _completions
                                          .map(
                                            (completion) => Padding(
                                              padding: const EdgeInsets.only(
                                                top: 10,
                                              ),
                                              child:
                                                  MemberProfileIpadActivityRow(
                                                    title: completion.taskTitle,
                                                    taskTypeLabel:
                                                        _taskTypeLabel(
                                                          completion.taskType,
                                                        ),
                                                    points:
                                                        completion.taskPoints,
                                                    timeLabel:
                                                        _formatActivityTime(
                                                          completion.createdAt,
                                                        ),
                                                  ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
