import 'package:flutter/material.dart';

import '../../../widgets/user_avatar.dart';
import 'member_profile_ipad_common.dart';

class MemberProfileIpadOverviewPanel extends StatelessWidget {
  const MemberProfileIpadOverviewPanel({
    super.key,
    required this.avatarEmoji,
    required this.avatarValue,
    required this.nickname,
    required this.role,
    required this.points,
    required this.canDelete,
    required this.canEditAvatar,
    required this.onEditAvatar,
    required this.onDelete,
  });

  final String avatarEmoji;
  final String? avatarValue;
  final String nickname;
  final String role;
  final int points;
  final bool canDelete;
  final bool canEditAvatar;
  final VoidCallback onEditAvatar;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == 'admin';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: MemberProfileIpadColors.card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              color: MemberProfileIpadColors.cardSoft,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Container(
                  width: 150,
                  height: 150,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF8E9),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: UserAvatar(
                      nickname: nickname,
                      avatarValue:
                          avatarValue ?? userAvatarValueFromEmoji(avatarEmoji),
                      size: 120,
                      backgroundColor: const Color(0xFFFFF8E9),
                      foregroundColor: const Color(0xFF755700),
                      fontSize: 52,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  nickname,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: MemberProfileIpadColors.text,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    MemberProfileIpadPill(
                      label: isAdmin ? '家长成员' : '家庭成员',
                      background: isAdmin
                          ? MemberProfileIpadColors.gold
                          : MemberProfileIpadColors.blue,
                      foreground: isAdmin
                          ? MemberProfileIpadColors.goldText
                          : MemberProfileIpadColors.blueText,
                    ),
                    MemberProfileIpadPill(
                      label: '$points 分',
                      background: MemberProfileIpadColors.greenSoft,
                      foreground: MemberProfileIpadColors.green,
                    ),
                  ],
                ),
                if (canEditAvatar) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: onEditAvatar,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('更换头像'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: MemberProfileIpadColors.green,
                      side: const BorderSide(
                        color: MemberProfileIpadColors.green,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '成员档案',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: MemberProfileIpadColors.text,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '保留成员积分、宠物列表、删除成员和任务记录等原有功能，同时将布局调整为更适合平板的大卡片样式。',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: MemberProfileIpadColors.muted,
            ),
          ),
          if (canDelete) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('删除该成员'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: MemberProfileIpadColors.coralText,
                  side: const BorderSide(
                    color: MemberProfileIpadColors.coralText,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
