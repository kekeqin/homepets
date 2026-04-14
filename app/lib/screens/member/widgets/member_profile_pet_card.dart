import 'package:flutter/material.dart';

import '../../../models/pet.dart';
import '../../../widgets/pet_avatar.dart';
import 'member_profile_common.dart';

class MemberProfilePetCard extends StatelessWidget {
  const MemberProfilePetCard({
    super.key,
    required this.pet,
    required this.completionCount,
    required this.onTap,
  });

  final Pet pet;
  final int completionCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE7C47E), Color(0xFFD2A85D)],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [
              BoxShadow(
                color: MemberProfileColors.shadow,
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4EB85A),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.9),
                        width: 2,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2F4138),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Center(child: PetAvatar(pet: pet, size: 52)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6DDB79),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _petStage(pet),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF245629),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pet.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: MemberProfileColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '专属伙伴',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: Color(0xFFFDF8EA),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _MetricBar(
                      label: '亲密度',
                      value: _bondScore(pet, completionCount),
                      color: MemberProfileColors.green,
                    ),
                    const SizedBox(height: 10),
                    _MetricBar(
                      label: '成长值',
                      value: _growthScore(pet),
                      color: MemberProfileColors.blueText,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricBar extends StatelessWidget {
  const _MetricBar({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final percent = (value * 100).round().clamp(0, 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: Color(0xFF8C6A2D),
                ),
              ),
            ),
            Text(
              '$percent%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: 7,
            backgroundColor: Colors.white.withValues(alpha: 0.55),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

String _petStage(Pet pet) {
  if (pet.isEgg) {
    return '宠物蛋';
  }
  return switch (pet.level) {
    1 => '幼崽期',
    2 => '少年期',
    3 => '进阶期',
    4 => '闪耀期',
    _ => '传奇期',
  };
}

double _bondScore(Pet pet, int completionCount) {
  final completionsBoost = (completionCount / 10).clamp(0.0, 0.35);
  final levelBoost = (pet.level / 8).clamp(0.0, 0.4);
  return (0.28 + completionsBoost + levelBoost).clamp(0.0, 1.0).toDouble();
}

double _growthScore(Pet pet) {
  if (pet.levelThreshold == null || pet.levelThreshold == 0) {
    return 1;
  }
  return (pet.experience / pet.levelThreshold!).clamp(0.0, 1.0).toDouble();
}
