import 'package:flutter/material.dart';

import '../models/member_profile_view_data.dart';
import 'member_profile_common.dart';

class MemberProfileProgressTile extends StatelessWidget {
  const MemberProfileProgressTile({super.key, required this.completion});

  final MemberTaskCompletion completion;

  @override
  Widget build(BuildContext context) {
    final accent = _activityColor(completion.taskTitle, completion.taskPoints);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: MemberProfileColors.card,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: MemberProfileColors.shadow,
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.16),
                shape: BoxShape.circle,
                border: Border.all(color: accent.withValues(alpha: 0.25)),
              ),
              child: Icon(
                _activityIcon(completion.taskTitle, completion.taskPoints),
                color: accent,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    completion.taskTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: MemberProfileColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '已完成任务 · ${_taskTypeLabel(completion.taskType)}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: accent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatTime(completion.createdAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: MemberProfileColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${completion.taskPoints >= 0 ? '+' : ''}${completion.taskPoints}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: completion.taskPoints >= 0
                        ? accent
                        : MemberProfileColors.coral,
                  ),
                ),
                const Text(
                  '积分',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: MemberProfileColors.muted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _formatTime(DateTime? time) {
  if (time == null) {
    return '刚刚完成';
  }

  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) {
    return '刚刚完成';
  }
  if (diff.inMinutes < 60) {
    return '${diff.inMinutes} 分钟前完成';
  }
  if (diff.inHours < 24) {
    return '${diff.inHours} 小时前完成';
  }
  if (diff.inDays < 7) {
    return '${diff.inDays} 天前完成';
  }
  return '${time.month}月${time.day}日完成';
}

IconData _activityIcon(String title, int points) {
  final lower = title.toLowerCase();
  if (lower.contains('meal') ||
      title.contains('餐') ||
      title.contains('喂') ||
      title.contains('饭')) {
    return Icons.restaurant_rounded;
  }
  if (lower.contains('groom') ||
      title.contains('洗') ||
      title.contains('整理') ||
      title.contains('清洁')) {
    return Icons.brush_rounded;
  }
  if (lower.contains('explore') ||
      title.contains('探') ||
      title.contains('远足')) {
    return Icons.explore_rounded;
  }
  return points >= 100 ? Icons.star_rounded : Icons.check_rounded;
}

Color _activityColor(String title, int points) {
  final lower = title.toLowerCase();
  if (lower.contains('meal') || title.contains('餐') || title.contains('喂')) {
    return MemberProfileColors.green;
  }
  if (lower.contains('groom') || title.contains('洗') || title.contains('整理')) {
    return MemberProfileColors.goldDeep;
  }
  if (lower.contains('explore') || title.contains('探')) {
    return MemberProfileColors.blueText;
  }
  return points >= 100 ? MemberProfileColors.coral : MemberProfileColors.text;
}

String _taskTypeLabel(String rawType) {
  return switch (rawType) {
    'limited' => '限时任务',
    'challenge' => '挑战任务',
    _ => '日常任务',
  };
}
