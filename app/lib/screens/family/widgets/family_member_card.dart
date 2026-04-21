import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../models/pet_artwork.dart';
import '../../../widgets/user_avatar.dart';
import '../models/family_member_view_data.dart';

class FamilyMemberCard extends StatelessWidget {
  const FamilyMemberCard({
    super.key,
    required this.member,
    required this.onDetailTap,
  });

  final FamilyMemberViewData member;
  final VoidCallback onDetailTap;

  double get _progressValue {
    if (member.points <= 0) {
      return member.petType == null ? 0.24 : 0.38;
    }
    final progress = 0.24 + (math.sqrt(member.points.toDouble()) / 18);
    return progress.clamp(0.24, 0.9);
  }

  String? get _petPreviewAssetPath {
    final petType = member.petType;
    if (petType == null) {
      return null;
    }

    final seed = member.petId ?? member.id;
    final poseIndex = deterministicPetPoseIndex(petType, seed);
    return petAvatarAssetPath(petType, poseIndex);
  }

  @override
  Widget build(BuildContext context) {
    final avatarBorderColor = const Color(0xFFE9D9C6);
    final progressColor = member.petType == null
        ? const Color(0xFFD9CBB8)
        : const Color(0xFFDAA05A);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onDetailTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xD8FFFDFC), Color(0xCCFFF9F2)],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFF1E2D3).withValues(alpha: 0.72),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 17, 16, 17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    UserAvatar(
                      nickname: member.nickname,
                      avatarValue: member.avatarUrl,
                      size: 68,
                      backgroundColor: const Color(0xFFF8EFE4),
                      foregroundColor: const Color(0xFF7B5432),
                      border: Border.all(color: avatarBorderColor),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        member.nickname,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF734C2B),
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _PetBadge(assetPath: _petPreviewAssetPath),
                    const SizedBox(width: 14),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: _progressValue,
                          minHeight: 11,
                          backgroundColor: const Color(0xFFF0E6DA),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progressColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PetBadge extends StatelessWidget {
  const _PetBadge({required this.assetPath});

  final String? assetPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6EC),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE3D0BC)),
      ),
      child: assetPath == null
          ? const Icon(Icons.pets_rounded, size: 24, color: Color(0xFFC89A62))
          : Image.asset(
              assetPath!,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
    );
  }
}
