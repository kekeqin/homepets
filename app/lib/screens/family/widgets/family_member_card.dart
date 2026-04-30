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
    this.onPetTap,
    this.onAvatarEditTap,
    this.avatarEditBusy = false,
    this.onLongPress,
  });

  final FamilyMemberViewData member;
  final int? displaySlot;
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
    final pet = member.pet;
    final petType = pet?.petType ?? member.petType;
    if (petType == null) {
      return null;
    }

    final seed = pet?.id ?? member.petId ?? member.id;
    final poseIndex = deterministicPetPoseIndex(petType, seed);
    return petAvatarAssetPath(petType, poseIndex);
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
      return '$_fallbackProgressPoints / 60';
    }

    final levelThreshold = pet.levelThreshold;
    if (levelThreshold == null || levelThreshold == 0) {
      return '已满级';
    }
    return '${pet.experience} / $levelThreshold';
  }

  _MemberCardStyle get _style {
    if (displaySlot != null) {
      return switch (displaySlot! % 4) {
        0 => _MemberCardStyle.warm,
        1 => _MemberCardStyle.green,
        2 => _MemberCardStyle.blue,
        _ => _MemberCardStyle.pink,
      };
    }

    if (member.petType == null && member.pet == null) {
      return _MemberCardStyle.pink;
    }

    final nickname = member.nickname;
    if (nickname.contains('爸') || nickname.contains('爷')) {
      return _MemberCardStyle.blue;
    }
    if (nickname.contains('宝') || nickname.contains('孩')) {
      return _MemberCardStyle.green;
    }

    return switch (member.pet?.petType ?? member.petType) {
      'rabbit' || 'turtle' => _MemberCardStyle.green,
      'hamster' => _MemberCardStyle.blue,
      _ => _MemberCardStyle.warm,
    };
  }

  Rect get _fallbackPortraitRegion {
    final nickname = member.nickname;
    if (nickname.contains('奶') || nickname.contains('婆')) {
      return FamilySpriteRegions.avatarGrandma;
    }
    if (nickname.contains('爸') || nickname.contains('爷')) {
      return FamilySpriteRegions.avatarDad;
    }
    if (nickname.contains('宝') ||
        nickname.contains('孩') ||
        nickname.contains('小')) {
      return FamilySpriteRegions.avatarChild;
    }
    if (nickname.contains('妈')) {
      return FamilySpriteRegions.avatarMom;
    }
    if (displaySlot != null) {
      return switch (displaySlot! % 4) {
        0 => FamilySpriteRegions.avatarMom,
        1 => FamilySpriteRegions.avatarChild,
        2 => FamilySpriteRegions.avatarDad,
        _ => FamilySpriteRegions.avatarGrandma,
      };
    }
    if (member.role == 'admin') {
      return FamilySpriteRegions.avatarDad;
    }
    return FamilySpriteRegions.avatarMom;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final style = _style;
        final shortestSide = math.min(
          constraints.maxWidth,
          constraints.maxHeight,
        );
        final scale = (shortestSide / 190).clamp(0.66, 0.94).toDouble();
        final cornerRadius = 24 * scale;
        final padding = EdgeInsets.fromLTRB(
          9 * scale,
          8 * scale,
          9 * scale,
          8 * scale,
        );
        final avatarSize = (43 * scale).clamp(29.0, 44.0).toDouble();
        final nameSize = (16 * scale).clamp(11.2, 16.0).toDouble();
        final scoreWidth = (58 * scale).clamp(44.0, 62.0).toDouble();
        final scoreHeight = (27 * scale).clamp(21.0, 29.0).toDouble();
        final labelHeight = (31 * scale).clamp(23.0, 33.0).toDouble();
        final progressHeight = (10 * scale).clamp(7.0, 10.0).toDouble();
        final metaSize = (12 * scale).clamp(9.0, 12.0).toDouble();

        final card = DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [style.backgroundTop, style.backgroundBottom],
            ),
            borderRadius: BorderRadius.circular(cornerRadius),
            border: Border.all(color: style.border, width: 1.15 * scale),
            boxShadow: [
              BoxShadow(
                color: style.outline.withValues(alpha: 0.06),
                blurRadius: 6 * scale,
                offset: Offset(0, 2 * scale),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(cornerRadius),
                      gradient: RadialGradient(
                        center: const Alignment(-0.18, -0.38),
                        radius: 1.04,
                        colors: [style.highlight, Colors.transparent],
                        stops: const [0, 1],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: padding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: avatarSize,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _MemberPortraitButton(
                            member: member,
                            size: avatarSize,
                            fallbackRegion: _fallbackPortraitRegion,
                            busy: avatarEditBusy,
                            onTap: onAvatarEditTap,
                          ),
                          SizedBox(width: 7 * scale),
                          Expanded(
                            child: Text(
                              member.nickname,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: style.text,
                                fontSize: nameSize,
                                height: 1,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          SizedBox(width: 3 * scale),
                          _PointsBadge(
                            points: member.points,
                            width: scoreWidth,
                            height: scoreHeight,
                            scale: scale,
                            outlineColor: style.outline,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 2 * scale),
                    Expanded(
                      child: _PetStage(
                        assetPath: _petPreviewAssetPath,
                        title: _petTitle,
                        labelHeight: labelHeight,
                        textColor: style.text,
                        accentColor: style.accent,
                        seatColor: style.seatColor,
                        seatBorderColor: style.seatBorderColor,
                        scale: scale,
                        badgeKey: Key('family_member_pet_button_${member.id}'),
                        onTap: member.pet != null ? onPetTap : null,
                      ),
                    ),
                    SizedBox(height: 3 * scale),
                    _ProgressFooter(
                      leadingLabel: _progressLeadingLabel,
                      trailingLabel: _progressTrailingLabel,
                      value: _progressValue,
                      accentColor: style.accent,
                      textColor: style.text,
                      progressHeight: progressHeight,
                      metaSize: metaSize,
                      scale: scale,
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

class _MemberPortraitButton extends StatelessWidget {
  const _MemberPortraitButton({
    required this.member,
    required this.size,
    required this.fallbackRegion,
    required this.busy,
    required this.onTap,
  });

  final FamilyMemberViewData member;
  final double size;
  final Rect fallbackRegion;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final avatarValue = member.avatarUrl;
    final hasNetworkAvatar =
        avatarValue != null &&
        avatarValue.trim().isNotEmpty &&
        isNetworkAvatarValue(avatarValue);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('family_member_avatar_edit_button_${member.id}'),
        onTap: busy ? null : onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFFCF3), Color(0xFFFFECCC)],
              ),
              border: Border.all(color: const Color(0xFF9B6D3D), width: 1.0),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x128A5A2C),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(size * 0.055),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipOval(
                    child: hasNetworkAvatar
                        ? UserAvatar(
                            nickname: member.nickname,
                            avatarValue: avatarValue,
                            size: size,
                            backgroundColor: const Color(0xFFFFF5E9),
                            foregroundColor: const Color(0xFF7B5432),
                          )
                        : FamilySpriteSlice(region: fallbackRegion),
                  ),
                  if (busy)
                    Center(
                      child: SizedBox(
                        width: size * 0.36,
                        height: size * 0.36,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFA86C35),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PetStage extends StatelessWidget {
  const _PetStage({
    required this.assetPath,
    required this.title,
    required this.labelHeight,
    required this.textColor,
    required this.accentColor,
    required this.seatColor,
    required this.seatBorderColor,
    required this.scale,
    required this.badgeKey,
    this.onTap,
  });

  final String? assetPath;
  final String title;
  final double labelHeight;
  final Color textColor;
  final Color accentColor;
  final Color seatColor;
  final Color seatBorderColor;
  final double scale;
  final Key badgeKey;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final labelWidth = math.min(constraints.maxWidth * 0.78, 120 * scale);
        final resolvedLabelHeight = math.min(
          labelHeight,
          math.max(18 * scale, constraints.maxHeight * 0.32),
        );
        final stageGap = 2 * scale;
        final stageAreaHeight = math.max(
          0.0,
          constraints.maxHeight - resolvedLabelHeight - stageGap,
        );
        final stageSize = [
          stageAreaHeight,
          constraints.maxWidth * 0.80,
          116 * scale,
        ].reduce(math.min);
        final petSize = math.min(stageSize * 0.98, stageAreaHeight * 0.98);

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    bottom: 0,
                    width: stageSize,
                    height: stageSize,
                    child: _PetCircleStage(
                      color: seatColor,
                      borderColor: seatBorderColor,
                      scale: scale,
                    ),
                  ),
                  Positioned(
                    bottom: stageSize * 0.055,
                    child: _PetPreviewButton(
                      key: badgeKey,
                      assetPath: assetPath,
                      size: petSize,
                      onTap: onTap,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: stageGap),
            SizedBox(
              width: labelWidth,
              height: resolvedLabelHeight,
              child: _PetNameLabel(
                text: title,
                textColor: textColor,
                borderColor: accentColor.withValues(alpha: 0.62),
                scale: scale,
              ),
            ),
          ],
        );
      },
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
          ? const FamilySpriteSlice(
              region: FamilySpriteRegions.emptyPetPaw,
              sampleInset: 2,
            )
          : Image.asset(
              assetPath!,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
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

class _PetNameLabel extends StatelessWidget {
  const _PetNameLabel({
    required this.text,
    required this.textColor,
    required this.borderColor,
    required this.scale,
  });

  final String text;
  final Color textColor;
  final Color borderColor;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFFF7), Color(0xFFFFF0CE)],
        ),
        borderRadius: BorderRadius.circular(16 * scale),
        border: Border.all(color: borderColor, width: 1.05 * scale),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.13),
            blurRadius: 4 * scale,
            offset: Offset(0, 1.5 * scale),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 9 * scale),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              text,
              maxLines: 1,
              style: TextStyle(
                color: textColor,
                fontSize: 13.5 * scale,
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

class _ProgressFooter extends StatelessWidget {
  const _ProgressFooter({
    required this.leadingLabel,
    required this.trailingLabel,
    required this.value,
    required this.accentColor,
    required this.textColor,
    required this.progressHeight,
    required this.metaSize,
    required this.scale,
  });

  final String leadingLabel;
  final String trailingLabel;
  final double value;
  final Color accentColor;
  final Color textColor;
  final double progressHeight;
  final double metaSize;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: math.max(28 * scale, progressHeight + 16 * scale),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            width: double.infinity,
            child: FamilySpriteProgressBar(
              value: value,
              height: progressHeight,
            ),
          ),
          SizedBox(height: 3 * scale),
          Row(
            children: [
              Text(
                leadingLabel,
                maxLines: 1,
                style: TextStyle(
                  color: accentColor,
                  fontSize: metaSize,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Flexible(
                flex: 2,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    trailingLabel,
                    maxLines: 1,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.82),
                      fontSize: metaSize,
                      height: 1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PointsBadge extends StatelessWidget {
  const _PointsBadge({
    required this.points,
    required this.width,
    required this.height,
    required this.scale,
    required this.outlineColor,
  });

  final int points;
  final double width;
  final double height;
  final double scale;
  final Color outlineColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFCF3), Color(0xFFFFEFD2)],
          ),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: const Color(0xFF8D5B2E),
            width: 1.05 * scale,
          ),
          boxShadow: [
            BoxShadow(
              color: outlineColor.withValues(alpha: 0.10),
              blurRadius: 4 * scale,
              offset: Offset(0, 2 * scale),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 5 * scale),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 15 * scale,
                height: 15 * scale,
                child: const FamilySpriteSlice(
                  region: FamilySpriteRegions.starIcon,
                  sampleInset: 2,
                ),
              ),
              SizedBox(width: 2 * scale),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '$points',
                    maxLines: 1,
                    style: TextStyle(
                      color: const Color(0xFF704524),
                      fontSize: 12.6 * scale,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberCardStyle {
  const _MemberCardStyle({
    required this.backgroundTop,
    required this.backgroundBottom,
    required this.border,
    required this.outline,
    required this.text,
    required this.accent,
    required this.highlight,
    required this.seatColor,
    required this.seatBorderColor,
  });

  static const warm = _MemberCardStyle(
    backgroundTop: Color(0xFFFFF7E6),
    backgroundBottom: Color(0xFFFFE7BF),
    border: Color(0xFFE4B36F),
    outline: Color(0xFF8D6037),
    text: Color(0xFF6B4224),
    accent: Color(0xFF789541),
    highlight: Color(0x38FFFFFF),
    seatColor: Color(0xFFFFF2CA),
    seatBorderColor: Color(0xFFE1B96F),
  );

  static const green = _MemberCardStyle(
    backgroundTop: Color(0xFFFCFBDD),
    backgroundBottom: Color(0xFFEFF3C8),
    border: Color(0xFFC9CA82),
    outline: Color(0xFF81713A),
    text: Color(0xFF5C5E31),
    accent: Color(0xFF769642),
    highlight: Color(0x34FFFFFF),
    seatColor: Color(0xFFFFF5C9),
    seatBorderColor: Color(0xFFD3C36F),
  );

  static const blue = _MemberCardStyle(
    backgroundTop: Color(0xFFF9FCFC),
    backgroundBottom: Color(0xFFE7F0F3),
    border: Color(0xFFC5D2D6),
    outline: Color(0xFF7D6844),
    text: Color(0xFF5B5D51),
    accent: Color(0xFF789544),
    highlight: Color(0x30FFFFFF),
    seatColor: Color(0xFFFFF2D2),
    seatBorderColor: Color(0xFFD5B77C),
  );

  static const pink = _MemberCardStyle(
    backgroundTop: Color(0xFFFFF1EA),
    backgroundBottom: Color(0xFFFFDDD3),
    border: Color(0xFFE9B29F),
    outline: Color(0xFF926044),
    text: Color(0xFF75482F),
    accent: Color(0xFF9B7949),
    highlight: Color(0x30FFFFFF),
    seatColor: Color(0xFFFFF1D1),
    seatBorderColor: Color(0xFFD8B783),
  );

  final Color backgroundTop;
  final Color backgroundBottom;
  final Color border;
  final Color outline;
  final Color text;
  final Color accent;
  final Color highlight;
  final Color seatColor;
  final Color seatBorderColor;
}

class _PetCircleStage extends StatelessWidget {
  const _PetCircleStage({
    required this.color,
    required this.borderColor,
    required this.scale,
  });

  final Color color;
  final Color borderColor;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.92),
            color.withValues(alpha: 0.74),
          ],
        ),
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 1.0 * scale),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.10),
            blurRadius: 6 * scale,
            offset: Offset(0, 2 * scale),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 10 * scale,
            right: 10 * scale,
            top: 8 * scale,
            height: 13 * scale,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: Colors.white.withValues(alpha: 0.24),
              ),
            ),
          ),
          Positioned(
            left: 18 * scale,
            right: 18 * scale,
            bottom: 12 * scale,
            height: 8 * scale,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: borderColor.withValues(alpha: 0.16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
