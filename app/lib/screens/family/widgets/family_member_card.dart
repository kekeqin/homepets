import 'package:flutter/material.dart';

import '../../../models/pet_artwork.dart';
import '../models/family_member_view_data.dart';

class FamilyMemberCard extends StatelessWidget {
  const FamilyMemberCard({
    super.key,
    required this.member,
    required this.cardAsset,
    required this.portraitAsset,
    required this.portraitStyle,
    required this.onDetailTap,
  });

  final FamilyMemberViewData member;
  final String cardAsset;
  final String portraitAsset;
  final PortraitStyle portraitStyle;
  final VoidCallback onDetailTap;

  String get _roleText => member.role == 'admin' ? '家长' : '成员';

  String? get _petPreviewAssetPath {
    final petType = member.petType;
    if (petType == null) {
      return null;
    }

    final seed = member.petId ?? member.id;
    final poseIndex = deterministicPetPoseIndex(petType, seed);
    return petAvatarAssetPath(petType, poseIndex);
  }

  String get _petBadgeLabel {
    final petType = member.petType;
    if (petType == null) {
      return member.needsPetSelection ? '待选宠物' : '暂无宠物';
    }
    return petTypeLabel(petType);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onDetailTap,
        borderRadius: BorderRadius.circular(24),
        child: AspectRatio(
          aspectRatio: 385 / 598,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned.fill(
                child: Image.asset(
                  cardAsset,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
              Positioned(
                top: 16,
                left: 14,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: const Color(0xFF694426).withValues(alpha: 0.35),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    child: Text(
                      '${member.nickname} · $_roleText',
                      style: const TextStyle(
                        color: Color(0xFF57351B),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 12,
                top: 40,
                width: 86,
                child: IgnorePointer(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_petPreviewAssetPath != null)
                        Image.asset(
                          _petPreviewAssetPath!,
                          width: 72,
                          height: 72,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        )
                      else
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.82),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(
                                0xFF694426,
                              ).withValues(alpha: 0.28),
                            ),
                          ),
                          child: Icon(
                            member.needsPetSelection
                                ? Icons.pets_outlined
                                : Icons.pets_rounded,
                            color: const Color(0xFF7A5733),
                          ),
                        ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.82),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: const Color(
                              0xFF694426,
                            ).withValues(alpha: 0.24),
                          ),
                        ),
                        child: Text(
                          _petBadgeLabel,
                          style: const TextStyle(
                            color: Color(0xFF57351B),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 30,
                right: 30,
                top: 90,
                bottom: 86,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Transform.translate(
                      offset: Offset(
                        constraints.maxWidth * portraitStyle.dx,
                        constraints.maxHeight * portraitStyle.dy,
                      ),
                      child: Transform.scale(
                        scale: portraitStyle.scale,
                        alignment: Alignment.bottomCenter,
                        child: Image.asset(
                          portraitAsset,
                          fit: BoxFit.contain,
                          alignment: Alignment.bottomCenter,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                left: 72,
                right: 72,
                bottom: 24,
                height: 46,
                child: _DetailTapOverlay(onTap: onDetailTap),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailTapOverlay extends StatelessWidget {
  const _DetailTapOverlay({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFE7D19A).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFF6C482B).withValues(alpha: 0.55),
          width: 1.2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          splashColor: const Color(0xFF7A5733).withValues(alpha: 0.18),
          highlightColor: const Color(0xFF7A5733).withValues(alpha: 0.08),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '人员详情',
                  style: TextStyle(
                    color: Color(0xFF57351B),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.person, size: 13, color: Color(0xFF57351B)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
