import 'package:flutter/material.dart';

import 'member_profile_ipad_common.dart';

class MemberProfileIpadActivityRow extends StatelessWidget {
  const MemberProfileIpadActivityRow({
    super.key,
    required this.title,
    required this.taskTypeLabel,
    required this.points,
    required this.timeLabel,
  });

  final String title;
  final String taskTypeLabel;
  final int points;
  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    final isPositive = points >= 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MemberProfileIpadColors.cardSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isPositive
                  ? MemberProfileIpadColors.greenSoft
                  : MemberProfileIpadColors.coral,
              borderRadius: BorderRadius.circular(999),
            ),
            alignment: Alignment.center,
            child: Icon(
              isPositive ? Icons.arrow_upward_rounded : Icons.remove_rounded,
              color: isPositive
                  ? MemberProfileIpadColors.green
                  : MemberProfileIpadColors.coralText,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: MemberProfileIpadColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (isPositive
                                ? MemberProfileIpadColors.green
                                : MemberProfileIpadColors.coralText)
                            .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '已完成任务 · $taskTypeLabel',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isPositive
                          ? MemberProfileIpadColors.green
                          : MemberProfileIpadColors.coralText,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  timeLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: MemberProfileIpadColors.muted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isPositive ? '+' : ''}$points',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: isPositive
                  ? MemberProfileIpadColors.green
                  : MemberProfileIpadColors.coralText,
            ),
          ),
        ],
      ),
    );
  }
}
