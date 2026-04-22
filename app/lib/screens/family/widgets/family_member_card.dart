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

  int get _progressPoints {
    if (member.points <= 0) {
      return 0;
    }
    final remainder = member.points % 60;
    return remainder == 0 ? 60 : remainder;
  }

  double get _progressValue {
    if (member.petType == null) {
      return member.points > 0 ? 0.18 : 0.08;
    }
    if (member.points <= 0) {
      return 0.18;
    }
    return (_progressPoints / 60).clamp(0.0, 1.0);
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

  _MemberPalette get _palette => _MemberPalette.fromMember(member);

  @override
  Widget build(BuildContext context) {
    final palette = _palette;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideCard = constraints.maxWidth >= 180;
        final borderRadius = BorderRadius.circular(isWideCard ? 22 : 20);
        final contentPadding = isWideCard ? 14.0 : 12.0;
        final avatarSize = isWideCard ? 46.0 : 40.0;
        final avatarShellRadius = isWideCard ? 16.0 : 14.0;
        final nameFontSize = isWideCard ? 16.0 : 15.0;
        final badgeSize = isWideCard ? 26.0 : 24.0;
        final iconSize = isWideCard ? 13.0 : 12.0;
        final progressHeight = isWideCard ? 11.0 : 10.0;
        final previewSize = isWideCard ? 38.0 : 34.0;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onDetailTap,
            borderRadius: borderRadius,
            child: Ink(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: borderRadius,
                border: Border.all(color: palette.border, width: 1.3),
                boxShadow: [
                  BoxShadow(
                    color: palette.shadow,
                    blurRadius: isWideCard ? 16 : 14,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(contentPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2.5),
                          decoration: BoxDecoration(
                            color: palette.avatarShell,
                            borderRadius: BorderRadius.circular(
                              avatarShellRadius,
                            ),
                          ),
                          child: UserAvatar(
                            nickname: member.nickname,
                            avatarValue: member.avatarUrl,
                            size: avatarSize,
                            backgroundColor: const Color(0xFFF8EFE4),
                            foregroundColor: const Color(0xFF7B5432),
                            border: Border.all(color: palette.avatarBorder),
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            member.nickname,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: palette.text,
                              fontSize: nameFontSize,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (member.role == 'admin')
                          Container(
                            width: badgeSize,
                            height: badgeSize,
                            decoration: BoxDecoration(
                              color: palette.badge,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.star_rounded,
                              color: palette.accent,
                              size: iconSize,
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        _PetPreviewBadge(
                          assetPath: _petPreviewAssetPath,
                          accentColor: palette.accent,
                          size: previewSize,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: _progressValue,
                              minHeight: progressHeight,
                              backgroundColor: const Color(0xFFF6EADF),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                palette.accent,
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
      },
    );
  }
}

class _PetPreviewBadge extends StatelessWidget {
  const _PetPreviewBadge({
    required this.assetPath,
    required this.accentColor,
    required this.size,
  });

  final String? assetPath;
  final Color accentColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.1),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7EF),
        borderRadius: BorderRadius.circular(size * 0.32),
        border: Border.all(color: const Color(0xFFF3E0CF)),
      ),
      child: assetPath == null
          ? Icon(Icons.pets_rounded, size: size * 0.46, color: accentColor)
          : Image.asset(
              assetPath!,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
    );
  }
}

class _MemberPalette {
  const _MemberPalette({
    required this.accent,
    required this.text,
    required this.border,
    required this.shadow,
    required this.badge,
    required this.avatarShell,
    required this.avatarBorder,
  });

  factory _MemberPalette.fromMember(FamilyMemberViewData member) {
    if (member.role == 'admin') {
      return const _MemberPalette(
        accent: Color(0xFFCF8A3C),
        text: Color(0xFF6A3B13),
        border: Color(0xFFF0D5B7),
        shadow: Color(0x16D4A06A),
        badge: Color(0xFFFFF0DD),
        avatarShell: Color(0xFFFFF7EE),
        avatarBorder: Color(0xFFE8D2BB),
      );
    }

    return switch (member.petType) {
      'cat' => const _MemberPalette(
        accent: Color(0xFFCC8B5E),
        text: Color(0xFF724629),
        border: Color(0xFFF1DCCC),
        shadow: Color(0x14C99063),
        badge: Color(0xFFFFF1E3),
        avatarShell: Color(0xFFFFF8F2),
        avatarBorder: Color(0xFFEAD7C9),
      ),
      'rabbit' => const _MemberPalette(
        accent: Color(0xFF84A961),
        text: Color(0xFF4C603D),
        border: Color(0xFFDDE9D1),
        shadow: Color(0x1489B56A),
        badge: Color(0xFFF1F8EA),
        avatarShell: Color(0xFFF7FBF2),
        avatarBorder: Color(0xFFD6E4C8),
      ),
      'hamster' => const _MemberPalette(
        accent: Color(0xFFCD9154),
        text: Color(0xFF764A26),
        border: Color(0xFFF0DEC9),
        shadow: Color(0x14D49A63),
        badge: Color(0xFFFFF3E5),
        avatarShell: Color(0xFFFFF8F1),
        avatarBorder: Color(0xFFE8D8C4),
      ),
      'turtle' => const _MemberPalette(
        accent: Color(0xFF6D9974),
        text: Color(0xFF47624C),
        border: Color(0xFFD9E7DD),
        shadow: Color(0x1490B59A),
        badge: Color(0xFFF0F8F2),
        avatarShell: Color(0xFFF4FAF5),
        avatarBorder: Color(0xFFD4E1D5),
      ),
      _ => const _MemberPalette(
        accent: Color(0xFFCD9154),
        text: Color(0xFF764A26),
        border: Color(0xFFF0DEC9),
        shadow: Color(0x14D49A63),
        badge: Color(0xFFFFF3E5),
        avatarShell: Color(0xFFFFF8F1),
        avatarBorder: Color(0xFFE8D8C4),
      ),
    };
  }

  final Color accent;
  final Color text;
  final Color border;
  final Color shadow;
  final Color badge;
  final Color avatarShell;
  final Color avatarBorder;
}
