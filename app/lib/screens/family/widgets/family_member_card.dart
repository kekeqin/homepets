import 'package:flutter/material.dart';

import '../../../models/pet_artwork.dart';
import '../../../widgets/user_avatar.dart';
import '../models/family_member_view_data.dart';

class FamilyMemberCard extends StatelessWidget {
  const FamilyMemberCard({
    super.key,
    required this.member,
    this.onPetTap,
    this.onAvatarEditTap,
    this.avatarEditBusy = false,
    this.onLongPress,
  });

  final FamilyMemberViewData member;
  final VoidCallback? onPetTap;
  final VoidCallback? onAvatarEditTap;
  final bool avatarEditBusy;
  final VoidCallback? onLongPress;

  int get _fallbackProgressPoints {
    if (member.points <= 0) {
      return 0;
    }

    final remainder = member.points % 60;
    return remainder == 0 ? 60 : remainder;
  }

  double get _progressValue {
    final pet = member.pet;
    if (pet != null) {
      final levelThreshold = pet.levelThreshold;
      if (levelThreshold == null || levelThreshold == 0) {
        return 1.0;
      }
      return pet.progress.clamp(0.0, 1.0);
    }

    if (member.petType == null) {
      return member.points > 0 ? 0.16 : 0.06;
    }

    if (member.points <= 0) {
      return 0.14;
    }

    return (_fallbackProgressPoints / 60).clamp(0.0, 1.0);
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

  String get _petTitle {
    final pet = member.pet;
    if (pet != null) {
      return pet.name;
    }

    final petType = member.petType;
    if (petType != null) {
      return '等待${petTypeLabel(petType)}入住';
    }

    return '还没有宠物';
  }

  String get _petSubtitle {
    final pet = member.pet;
    if (pet != null) {
      return pet.levelName;
    }

    if (member.needsPetSelection) {
      return '先为这位成员选择一只宠物';
    }

    return '完成任务后会在这里开始成长';
  }

  String get _progressLeadingLabel {
    final pet = member.pet;
    if (pet != null) {
      return 'Lv.${pet.level}';
    }

    return member.points > 0 ? '成长值' : '待养成';
  }

  String get _progressTrailingLabel {
    final pet = member.pet;
    if (pet == null) {
      return '$_fallbackProgressPoints/60';
    }

    final levelThreshold = pet.levelThreshold;
    if (levelThreshold == null || levelThreshold == 0) {
      return '已满级';
    }

    return '${pet.experience}/$levelThreshold';
  }

  @override
  Widget build(BuildContext context) {
    final palette = _palette;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompactCard = constraints.maxHeight < 210;
        final isUltraCompactCard = constraints.maxHeight < 186;
        final isWideCard = constraints.maxWidth >= 180;
        final borderRadius = BorderRadius.circular(isWideCard ? 22 : 20);
        final contentPadding = isCompactCard
            ? 10.0
            : (isWideCard ? 14.0 : 12.0);
        final avatarSize = isUltraCompactCard
            ? 38.0
            : (isWideCard ? 46.0 : 42.0);
        final avatarShellRadius = isUltraCompactCard
            ? 14.0
            : (isWideCard ? 17.0 : 15.0);
        final nameFontSize = isUltraCompactCard
            ? 14.0
            : (isWideCard ? 16.0 : 15.0);
        final previewSize = isUltraCompactCard
            ? 50.0
            : (isCompactCard ? 58.0 : (isWideCard ? 82.0 : 72.0));
        final progressHeight = isCompactCard ? 5.0 : (isWideCard ? 7.0 : 6.0);
        final progressFontSize = isCompactCard
            ? 10.5
            : (isWideCard ? 11.5 : 11.0);
        final petTitleFontSize = isCompactCard
            ? 12.5
            : (isWideCard ? 14.0 : 13.0);
        final petSubtitleFontSize = isCompactCard
            ? 10.5
            : (isWideCard ? 11.5 : 11.0);

        final card = DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [palette.backgroundTop, palette.backgroundBottom],
            ),
            borderRadius: borderRadius,
            boxShadow: [
              BoxShadow(
                color: palette.shadow.withValues(alpha: 0.34),
                blurRadius: isWideCard ? 18 : 14,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [palette.wash, Colors.transparent],
                        stops: const [0, 0.7],
                      ),
                      borderRadius: borderRadius,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(contentPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: palette.avatarShell,
                                borderRadius: BorderRadius.circular(
                                  avatarShellRadius,
                                ),
                                border: Border.all(
                                  color: palette.border.withValues(alpha: 0.72),
                                ),
                              ),
                              child: UserAvatar(
                                nickname: member.nickname,
                                avatarValue: member.avatarUrl,
                                size: avatarSize,
                                backgroundColor: const Color(0xFFF8F1E8),
                                foregroundColor: const Color(0xFF7B5432),
                              ),
                            ),
                            if (member.role == 'admin')
                              Positioned(
                                top: -2,
                                right: -2,
                                child: _AdminBadge(accent: palette.accent),
                              ),
                            if (onAvatarEditTap != null)
                              Positioned(
                                right: -4,
                                bottom: -4,
                                child: _AvatarEditBadge(
                                  badgeKey: Key(
                                    'family_member_avatar_edit_button_${member.id}',
                                  ),
                                  accent: palette.accent,
                                  busy: avatarEditBusy,
                                  onTap: onAvatarEditTap!,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  member.nickname,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: palette.text,
                                    fontSize: nameFontSize,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _PointsBadge(
                          points: member.points,
                          accent: palette.accent,
                          compact: isCompactCard,
                        ),
                      ],
                    ),
                    SizedBox(
                      height: isCompactCard ? 8 : (isWideCard ? 12 : 10),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, petConstraints) {
                          final canShowSubtitle =
                              !isCompactCard && petConstraints.maxHeight >= 118;
                          final localPreviewSize =
                              (petConstraints.maxHeight *
                                      (canShowSubtitle ? 0.52 : 0.62))
                                  .clamp(40.0, previewSize)
                                  .toDouble();
                          final localStageGap = petConstraints.maxHeight < 116
                              ? 4.0
                              : (isCompactCard
                                    ? 6.0
                                    : (isWideCard ? 10.0 : 8.0));
                          final localTitleSize = petConstraints.maxHeight < 116
                              ? petTitleFontSize - 1
                              : petTitleFontSize;

                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Center(
                                  child: _PetPreviewBadge(
                                    assetPath: _petPreviewAssetPath,
                                    accentColor: palette.accent,
                                    surfaceColor: const Color(0xFFFFFCF9),
                                    size: localPreviewSize,
                                    badgeKey: Key(
                                      'family_member_pet_button_${member.id}',
                                    ),
                                    onTap: member.pet != null ? onPetTap : null,
                                  ),
                                ),
                              ),
                              SizedBox(height: localStageGap),
                              Text(
                                _petTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: palette.text,
                                  fontSize: localTitleSize,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (canShowSubtitle) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _petSubtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: palette.text.withValues(alpha: 0.56),
                                    fontSize: petSubtitleFontSize,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          _progressLeadingLabel,
                          style: TextStyle(
                            color: palette.text.withValues(alpha: 0.76),
                            fontSize: progressFontSize,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _progressTrailingLabel,
                          style: TextStyle(
                            color: palette.text.withValues(alpha: 0.52),
                            fontSize: progressFontSize,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: _progressValue,
                        minHeight: progressHeight,
                        backgroundColor: const Color(0xFFF1E6DA),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          palette.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

        if (onLongPress == null) {
          return card;
        }

        return GestureDetector(
          onLongPress: onLongPress,
          behavior: HitTestBehavior.opaque,
          child: card,
        );
      },
    );
  }
}

class _AdminBadge extends StatelessWidget {
  const _AdminBadge({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: Icon(Icons.star_rounded, size: 12, color: accent),
    );
  }
}

class _AvatarEditBadge extends StatelessWidget {
  const _AvatarEditBadge({
    required this.badgeKey,
    required this.accent,
    required this.busy,
    required this.onTap,
  });

  final Key badgeKey;
  final Color accent;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: badgeKey,
        onTap: busy ? null : onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: accent.withValues(alpha: 0.24)),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.18),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: busy
                ? SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.8,
                      color: accent,
                    ),
                  )
                : Icon(Icons.edit_rounded, size: 12, color: accent),
          ),
        ),
      ),
    );
  }
}

class _PointsBadge extends StatelessWidget {
  const _PointsBadge({
    required this.points,
    required this.accent,
    required this.compact,
  });

  final int points;
  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 9,
        vertical: compact ? 5 : 6,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Text(
        '$points',
        style: TextStyle(
          color: accent,
          fontSize: compact ? 11 : 11.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PetPreviewBadge extends StatelessWidget {
  const _PetPreviewBadge({
    required this.assetPath,
    required this.accentColor,
    required this.surfaceColor,
    required this.size,
    this.badgeKey,
    this.onTap,
  });

  final String? assetPath;
  final Color accentColor;
  final Color surfaceColor;
  final double size;
  final Key? badgeKey;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.16),
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.15, -0.2),
          radius: 0.96,
          colors: [surfaceColor, Colors.white],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: assetPath == null
          ? Icon(
              Icons.pets_rounded,
              size: size * 0.38,
              color: accentColor.withValues(alpha: 0.78),
            )
          : Image.asset(
              assetPath!,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
    );

    if (onTap == null) {
      return badge;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: badgeKey,
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: badge,
      ),
    );
  }
}

class _MemberPalette {
  const _MemberPalette({
    required this.accent,
    required this.text,
    required this.border,
    required this.backgroundTop,
    required this.backgroundBottom,
    required this.shadow,
    required this.wash,
    required this.avatarShell,
  });

  factory _MemberPalette.fromMember(FamilyMemberViewData member) {
    if (member.role == 'admin') {
      return const _MemberPalette(
        accent: Color(0xFFCF8A3C),
        text: Color(0xFF6A3B13),
        border: Color(0xFFF0D8BE),
        backgroundTop: Color(0xFFFFF3E4),
        backgroundBottom: Color(0xFFFFFBF4),
        shadow: Color(0x1EBB8960),
        wash: Color(0x40F1D1AC),
        avatarShell: Color(0xFFFFF7EE),
      );
    }

    return switch (member.petType) {
      'cat' => const _MemberPalette(
        accent: Color(0xFFCC8B5E),
        text: Color(0xFF724629),
        border: Color(0xFFF0DDCC),
        backgroundTop: Color(0xFFFFF2E8),
        backgroundBottom: Color(0xFFFFFCF6),
        shadow: Color(0x1CC58D63),
        wash: Color(0x38ECCAB2),
        avatarShell: Color(0xFFFFF8F2),
      ),
      'rabbit' => const _MemberPalette(
        accent: Color(0xFF84A961),
        text: Color(0xFF4C603D),
        border: Color(0xFFDDE8D2),
        backgroundTop: Color(0xFFF0F8E8),
        backgroundBottom: Color(0xFFFBFDF7),
        shadow: Color(0x1A83A763),
        wash: Color(0x3EDDEBCB),
        avatarShell: Color(0xFFF7FBF2),
      ),
      'hamster' => const _MemberPalette(
        accent: Color(0xFFCD9154),
        text: Color(0xFF764A26),
        border: Color(0xFFF0DFC9),
        backgroundTop: Color(0xFFF5EFFB),
        backgroundBottom: Color(0xFFFCF9FF),
        shadow: Color(0x1CCB9560),
        wash: Color(0x36E0D1F3),
        avatarShell: Color(0xFFFFF8F1),
      ),
      'turtle' => const _MemberPalette(
        accent: Color(0xFF7EA9C7),
        text: Color(0xFF50657A),
        border: Color(0xFFDDE8F0),
        backgroundTop: Color(0xFFF1F6FC),
        backgroundBottom: Color(0xFFFBFDFF),
        shadow: Color(0x1A7A9AB8),
        wash: Color(0x3BDDE9F6),
        avatarShell: Color(0xFFF4FAF5),
      ),
      _ => const _MemberPalette(
        accent: Color(0xFFCD9154),
        text: Color(0xFF764A26),
        border: Color(0xFFF0DFC9),
        backgroundTop: Color(0xFFFFF4EA),
        backgroundBottom: Color(0xFFFFFCF6),
        shadow: Color(0x1CCB9560),
        wash: Color(0x38F2D4AF),
        avatarShell: Color(0xFFFFF8F1),
      ),
    };
  }

  final Color accent;
  final Color text;
  final Color border;
  final Color backgroundTop;
  final Color backgroundBottom;
  final Color shadow;
  final Color wash;
  final Color avatarShell;
}
