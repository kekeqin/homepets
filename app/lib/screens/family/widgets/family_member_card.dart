import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../models/pet_artwork.dart';
import '../../../widgets/user_avatar.dart';
import '../models/family_member_view_data.dart';
import 'family_sprite_slice.dart';

class FamilyMemberCard extends StatelessWidget {
  const FamilyMemberCard({
    super.key,
    required this.member,
    this.displaySlot,
    this.petAvatarAssetPath,
    this.onPetTap,
    this.onAvatarEditTap,
    this.avatarEditBusy = false,
    this.onLongPress,
  });

  final FamilyMemberViewData member;
  final int? displaySlot;
  final String? petAvatarAssetPath;
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
    if (petAvatarAssetPath != null) {
      return petAvatarAssetPath;
    }

    final pet = member.pet;
    final petType = pet?.petType ?? member.petType;
    if (petType == null) {
      return null;
    }

    final seed = pet?.id ?? member.petId ?? member.id;
    return defaultHomePetDetailAvatarAssetPath(petType, seed);
  }

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

  String get _petLevelLabel {
    final pet = member.pet;
    if (pet != null) {
      return 'Lv.${pet.level}';
    }

    return member.points > 0 ? '成长值' : '待养成';
  }

  String get _portraitAssetPath {
    final normalizedAvatar = normalizedPresetUserAvatarAssetValue(
      member.avatarUrl,
    );
    if (normalizedAvatar != null) {
      return normalizedAvatar;
    }

    final nickname = member.nickname;
    if (nickname.contains('爸') || nickname.contains('爷')) {
      return FamilyPopupAssets.boyPortrait;
    }
    if (nickname.contains('妈') || nickname.contains('奶')) {
      return FamilyPopupAssets.girlPortrait;
    }
    if (displaySlot != null) {
      return switch (displaySlot! % 4) {
        0 =>
          member.role == 'admin'
              ? FamilyPopupAssets.boyPortrait
              : FamilyPopupAssets.girlPortrait,
        1 => FamilyPopupAssets.adultFemalePortrait,
        2 => FamilyPopupAssets.childPortrait,
        _ => FamilyPopupAssets.girlPortrait,
      };
    }
    return member.role == 'admin'
        ? FamilyPopupAssets.boyPortrait
        : FamilyPopupAssets.childPortrait;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final shortestSide = math.min(
          constraints.maxWidth,
          constraints.maxHeight,
        );
        final scale = (shortestSide / 170).clamp(0.74, 1.16).toDouble();
        final cornerRadius = 18 * scale;
        final padding = EdgeInsets.fromLTRB(
          9 * scale,
          9 * scale,
          9 * scale,
          8 * scale,
        );
        final namePlateHeight = (34 * scale).clamp(28.0, 42.0).toDouble();
        final footerHeight = (52 * scale).clamp(42.0, 64.0).toDouble();
        final petIconSize = (34 * scale).clamp(26.0, 42.0).toDouble();

        final card = DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(cornerRadius),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F3D210C),
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(cornerRadius - 2),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    FamilyPopupAssets.cardPanel,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.medium,
                    isAntiAlias: true,
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                ),
                Padding(
                  padding: padding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: namePlateHeight,
                        child: _NamePlate(name: member.nickname, scale: scale),
                      ),
                      Expanded(
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned.fill(
                              top: 1 * scale,
                              bottom: -2 * scale,
                              child: _MemberPortraitButton(
                                member: member,
                                assetPath: _portraitAssetPath,
                                busy: avatarEditBusy,
                                onTap: onAvatarEditTap,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: footerHeight,
                        child: _PetFooter(
                          memberId: member.id,
                          petAssetPath: _petPreviewAssetPath,
                          petTitle: _petTitle,
                          levelLabel: _petLevelLabel,
                          progressValue: _progressValue,
                          petIconSize: petIconSize,
                          scale: scale,
                          onTap: member.pet != null ? onPetTap : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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

class _NamePlate extends StatelessWidget {
  const _NamePlate({required this.name, required this.scale});

  final String name;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFEF6).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16 * scale),
        border: Border.all(color: const Color(0xFFF2A12A), width: 1.4 * scale),
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8 * scale),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              name,
              maxLines: 1,
              style: TextStyle(
                color: const Color(0xFF3E230F),
                fontSize: 25 * scale,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MemberPortraitButton extends StatelessWidget {
  const _MemberPortraitButton({
    required this.member,
    required this.assetPath,
    required this.busy,
    required this.onTap,
  });

  final FamilyMemberViewData member;
  final String assetPath;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: FractionallySizedBox(
            widthFactor: 0.82,
            heightFactor: 1.05,
            child: Image.asset(
              assetPath,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => UserAvatar(
                nickname: member.nickname,
                avatarValue: member.avatarUrl,
                size: 96,
                backgroundColor: const Color(0x00FFFFFF),
                foregroundColor: const Color(0xFF7B5432),
              ),
            ),
          ),
        ),
        if (busy)
          const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFA86C35),
              ),
            ),
          ),
      ],
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('family_member_avatar_edit_button_${member.id}'),
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: child,
      ),
    );
  }
}

class _PetFooter extends StatelessWidget {
  const _PetFooter({
    required this.memberId,
    required this.petAssetPath,
    required this.petTitle,
    required this.levelLabel,
    required this.progressValue,
    required this.petIconSize,
    required this.scale,
    this.onTap,
  });

  final int memberId;
  final String? petAssetPath;
  final String petTitle;
  final String levelLabel;
  final double progressValue;
  final double petIconSize;
  final double scale;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF3).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(15 * scale),
        border: Border.all(color: const Color(0xFFF3A52F), width: 1.2 * scale),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          7 * scale,
          5 * scale,
          7 * scale,
          5 * scale,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final iconSize = math.min(
              petIconSize,
              (constraints.maxWidth * 0.30).clamp(20.0, petIconSize),
            );
            final gap = (5 * scale).clamp(2.0, 7.0).toDouble();

            return Row(
              children: [
                _PetPreviewButton(
                  key: Key('family_member_pet_button_$memberId'),
                  assetPath: petAssetPath,
                  size: iconSize,
                  onTap: onTap,
                ),
                SizedBox(width: gap),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: (16 * scale).clamp(10.0, 19.0).toDouble(),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                petTitle,
                                maxLines: 1,
                                style: TextStyle(
                                  color: const Color(0xFF3F230D),
                                  fontSize: 15 * scale,
                                  height: 1,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(width: 5 * scale),
                              Text(
                                levelLabel,
                                maxLines: 1,
                                style: TextStyle(
                                  color: const Color(0xFF3F230D),
                                  fontSize: 14 * scale,
                                  height: 1,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 5 * scale),
                      FamilySpriteProgressBar(
                        value: progressValue,
                        height: (10 * scale).clamp(7.0, 12.0).toDouble(),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PetPreviewButton extends StatelessWidget {
  const _PetPreviewButton({
    super.key,
    required this.assetPath,
    required this.size,
    this.onTap,
  });

  final String? assetPath;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = SizedBox(
      width: size,
      height: size,
      child: assetPath == null
          ? const Icon(Icons.pets_rounded, color: Color(0xFF6E3B10), size: 26)
          : Image.asset(
              assetPath!,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
              isAntiAlias: true,
            ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: child,
      ),
    );
  }
}
