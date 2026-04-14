import 'package:flutter/material.dart';

import '../../../widgets/user_avatar.dart';
import 'member_profile_common.dart';

class MemberProfileHero extends StatelessWidget {
  const MemberProfileHero({
    super.key,
    required this.nickname,
    required this.role,
    required this.memberLevel,
    required this.memberTitle,
    required this.memberPoints,
    required this.completionCount,
    required this.avatarUrl,
    required this.canEditAvatar,
    required this.onChangeAvatar,
  });

  final String nickname;
  final String role;
  final int memberLevel;
  final String memberTitle;
  final int memberPoints;
  final int completionCount;
  final String? avatarUrl;
  final bool canEditAvatar;
  final VoidCallback onChangeAvatar;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 146,
              height: 146,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MemberProfileColors.card,
                boxShadow: [
                  BoxShadow(
                    color: MemberProfileColors.gold.withValues(alpha: 0.18),
                    blurRadius: 22,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: MemberProfileColors.line, width: 2),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF536A60), Color(0xFF2E3F39)],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: UserAvatar(
                    nickname: nickname,
                    avatarValue: avatarUrl,
                    size: 110,
                    backgroundColor: const Color(0xFF2F4138),
                    foregroundColor: const Color(0xFFF8E3B2),
                    fontSize: 54,
                  ),
                ),
              ),
            ),
            Positioned(
              right: -2,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: MemberProfileColors.gold,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(
                  'Lv. $memberLevel',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: MemberProfileColors.goldDeep,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          nickname,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 36,
            height: 1,
            fontWeight: FontWeight.w900,
            color: MemberProfileColors.goldDeep,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          memberTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: MemberProfileColors.green,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            _InfoChip(
              label: role == 'admin' ? '家长成员' : '家庭成员',
              background: MemberProfileColors.cardSoft,
              foreground: MemberProfileColors.text,
            ),
            _InfoChip(
              label: '$memberPoints 积分',
              background: MemberProfileColors.gold.withValues(alpha: 0.22),
              foreground: MemberProfileColors.goldDeep,
            ),
            _InfoChip(
              label: '$completionCount 次任务',
              background: MemberProfileColors.greenSoft,
              foreground: MemberProfileColors.green,
            ),
          ],
        ),
        if (canEditAvatar) ...[
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onChangeAvatar,
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text('更换头像'),
            style: OutlinedButton.styleFrom(
              foregroundColor: MemberProfileColors.green,
              side: const BorderSide(color: MemberProfileColors.green),
            ),
          ),
        ],
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: foreground,
        ),
      ),
    );
  }
}
