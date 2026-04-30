import 'package:flutter/material.dart';

import '../../../models/pet.dart';
import '../models/member_profile_view_data.dart';
import 'member_profile_common.dart';

class MemberProfileBadgeGrid extends StatelessWidget {
  const MemberProfileBadgeGrid({
    super.key,
    required this.memberLevel,
    required this.pets,
    required this.completions,
  });

  final int memberLevel;
  final List<Pet> pets;
  final List<MemberTaskCompletion> completions;

  @override
  Widget build(BuildContext context) {
    final badges = _buildBadges();

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 24) / 3;
        return Wrap(
          spacing: 12,
          runSpacing: 18,
          children: badges.map((badge) {
            final unlocked = badge.unlocked;
            return SizedBox(
              width: itemWidth,
              child: Column(
                children: [
                  Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: unlocked
                          ? MemberProfileColors.card
                          : Colors.transparent,
                      border: Border.all(
                        color: unlocked
                            ? Colors.transparent
                            : MemberProfileColors.line,
                        width: 1.4,
                      ),
                      boxShadow: unlocked
                          ? const [
                              BoxShadow(
                                color: MemberProfileColors.shadow,
                                blurRadius: 14,
                                offset: Offset(0, 8),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: unlocked
                              ? badge.color
                              : MemberProfileColors.cardSoft.withValues(
                                  alpha: 0.6,
                                ),
                        ),
                        child: Icon(
                          unlocked ? badge.icon : Icons.lock_outline_rounded,
                          color: unlocked
                              ? badge.iconColor
                              : MemberProfileColors.muted,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    unlocked ? badge.label : '未解锁',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: unlocked
                          ? MemberProfileColors.text
                          : MemberProfileColors.muted,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  List<_MemberBadgeData> _buildBadges() {
    final hasEarlyBird = completions.any((completion) {
      final time = completion.createdAt;
      return time != null && time.hour < 9;
    });

    return <_MemberBadgeData>[
      _MemberBadgeData(
        label: '任务达人',
        icon: Icons.task_alt_rounded,
        unlocked: completions.isNotEmpty,
        color: MemberProfileColors.gold,
        iconColor: MemberProfileColors.goldDeep,
      ),
      _MemberBadgeData(
        label: '早起小能手',
        icon: Icons.wb_sunny_rounded,
        unlocked: hasEarlyBird,
        color: const Color(0xFFC9EF9F),
        iconColor: const Color(0xFF4F7E0E),
      ),
      _MemberBadgeData(
        label: '宠物知音',
        icon: Icons.pets_rounded,
        unlocked: pets.isNotEmpty,
        color: const Color(0xFFBEDAF6),
        iconColor: MemberProfileColors.blueText,
      ),
      _MemberBadgeData(
        label: '成长新星',
        icon: Icons.auto_awesome_rounded,
        unlocked: memberLevel >= 5,
        color: const Color(0xFFF3D7C6),
        iconColor: MemberProfileColors.coral,
      ),
      _MemberBadgeData(
        label: '稳定输出',
        icon: Icons.bolt_rounded,
        unlocked: completions.length >= 5,
        color: const Color(0xFFF5E1AB),
        iconColor: MemberProfileColors.goldDeep,
      ),
      _MemberBadgeData(
        label: '闪耀传说',
        icon: Icons.workspace_premium_rounded,
        unlocked: memberLevel >= 10,
        color: const Color(0xFFD8EDCB),
        iconColor: MemberProfileColors.green,
      ),
    ];
  }
}

class _MemberBadgeData {
  const _MemberBadgeData({
    required this.label,
    required this.icon,
    required this.unlocked,
    required this.color,
    required this.iconColor,
  });

  final String label;
  final IconData icon;
  final bool unlocked;
  final Color color;
  final Color iconColor;
}
