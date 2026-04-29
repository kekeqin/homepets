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
        final scale = (shortestSide / 170).clamp(0.66, 1.0).toDouble();
        final cornerRadius = 24 * scale;
        final padding = EdgeInsets.fromLTRB(
          12 * scale,
          11 * scale,
          12 * scale,
          10 * scale,
        );
        final avatarSize = 38 * scale;
        final nameSize = 16 * scale;
        final scoreWidth = 68 * scale;
        final scoreHeight = 30 * scale;
        final labelHeight = 34 * scale;
        final progressHeight = 11 * scale;
        final metaSize = 10.8 * scale;

        final card = DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [style.backgroundTop, style.backgroundBottom],
            ),
            borderRadius: BorderRadius.circular(cornerRadius),
            border: Border.all(color: style.border, width: 1.05 * scale),
            boxShadow: [
              BoxShadow(
                color: style.outline.withValues(alpha: 0.10),
                blurRadius: 12 * scale,
                offset: Offset(0, 4 * scale),
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
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _HandDrawnCardBorderPainter(
                      color: style.outline,
                      radius: cornerRadius,
                      scale: scale,
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
                          SizedBox(width: 8 * scale),
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
                          SizedBox(width: 5 * scale),
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
                    SizedBox(height: 4 * scale),
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
                    SizedBox(height: 5 * scale),
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

class _HandDrawnCardBorderPainter extends CustomPainter {
  const _HandDrawnCardBorderPainter({
    required this.color,
    required this.radius,
    required this.scale,
  });

  final Color color;
  final double radius;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) {
      return;
    }

    final inset = 1.1 * scale;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    );
    final outer = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final inner = RRect.fromRectAndRadius(
      rect.deflate(2.1 * scale).shift(Offset(0.35 * scale, -0.25 * scale)),
      Radius.circular(math.max(0, radius - 3 * scale)),
    );

    final paint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 1.55 * scale
      ..color = color.withValues(alpha: 0.70);

    canvas.drawRRect(outer, paint);

    paint
      ..strokeWidth = 0.75 * scale
      ..color = color.withValues(alpha: 0.25);
    canvas.drawRRect(inner, paint);
  }

  @override
  bool shouldRepaint(covariant _HandDrawnCardBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.radius != radius ||
        oldDelegate.scale != scale;
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
              border: Border.all(color: const Color(0xFF9B6D3D), width: 1.2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A8A5A2C),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(size * 0.08),
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
        final labelWidth = math.min(constraints.maxWidth * 0.82, 128 * scale);
        final resolvedLabelHeight = math.min(
          labelHeight,
          math.max(20 * scale, constraints.maxHeight * 0.34),
        );
        final stageGap = 3 * scale;
        final stageAreaHeight = math.max(
          0.0,
          constraints.maxHeight - resolvedLabelHeight - stageGap,
        );
        final stageSize = [
          stageAreaHeight,
          constraints.maxWidth * 0.72,
          106 * scale,
        ].reduce(math.min);
        final petSize = math.min(stageSize * 0.92, stageAreaHeight);

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
                    bottom: stageSize * 0.08,
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
        borderRadius: BorderRadius.circular(18 * scale),
        border: Border.all(color: borderColor, width: 1.35 * scale),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.13),
            blurRadius: 5 * scale,
            offset: Offset(0, 2 * scale),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12 * scale),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              text,
              maxLines: 1,
              style: TextStyle(
                color: textColor,
                fontSize: 15.5 * scale,
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
      height: math.max(22 * scale, progressHeight + 8 * scale),
      child: Row(
        children: [
          Container(
            constraints: BoxConstraints(minWidth: 32 * scale),
            height: 18 * scale,
            padding: EdgeInsets.symmetric(horizontal: 6 * scale),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.56),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.38),
                width: 1 * scale,
              ),
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  leadingLabel,
                  maxLines: 1,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: metaSize,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 5 * scale),
          Expanded(
            child: FamilySpriteProgressBar(
              value: value,
              height: progressHeight,
            ),
          ),
          SizedBox(width: 5 * scale),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 58 * scale),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                trailingLabel,
                maxLines: 1,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.78),
                  fontSize: metaSize,
                  height: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
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
            colors: [Color(0xFFFFFBF1), Color(0xFFFFF1DC)],
          ),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: outlineColor, width: 1.25 * scale),
          boxShadow: [
            BoxShadow(
              color: outlineColor.withValues(alpha: 0.10),
              blurRadius: 4 * scale,
              offset: Offset(0, 2 * scale),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 7 * scale),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 18 * scale,
                height: 18 * scale,
                child: const FamilySpriteSlice(
                  region: FamilySpriteRegions.starIcon,
                  sampleInset: 2,
                ),
              ),
              SizedBox(width: 3 * scale),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '$points',
                    maxLines: 1,
                    style: TextStyle(
                      color: const Color(0xFF704524),
                      fontSize: 13.5 * scale,
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
    backgroundTop: Color(0xFFFFFAEA),
    backgroundBottom: Color(0xFFFFE8BE),
    border: Color(0xFFEEC27B),
    outline: Color(0xFF986538),
    text: Color(0xFF6B4224),
    accent: Color(0xFF789541),
    highlight: Color(0x38FFFFFF),
    seatColor: Color(0xFFFFF2CA),
    seatBorderColor: Color(0xFFE1B96F),
  );

  static const green = _MemberCardStyle(
    backgroundTop: Color(0xFFFAFADB),
    backgroundBottom: Color(0xFFEFF3BE),
    border: Color(0xFFC5C971),
    outline: Color(0xFF8A7538),
    text: Color(0xFF5C5E31),
    accent: Color(0xFF769642),
    highlight: Color(0x34FFFFFF),
    seatColor: Color(0xFFFFF5C9),
    seatBorderColor: Color(0xFFD3C36F),
  );

  static const blue = _MemberCardStyle(
    backgroundTop: Color(0xFFF6FAFC),
    backgroundBottom: Color(0xFFE5EEF2),
    border: Color(0xFFC1D0D6),
    outline: Color(0xFF846A42),
    text: Color(0xFF5B5D51),
    accent: Color(0xFF789544),
    highlight: Color(0x30FFFFFF),
    seatColor: Color(0xFFFFF2D2),
    seatBorderColor: Color(0xFFD5B77C),
  );

  static const pink = _MemberCardStyle(
    backgroundTop: Color(0xFFFFF5EC),
    backgroundBottom: Color(0xFFFFDFD5),
    border: Color(0xFFEFB6A5),
    outline: Color(0xFF9A6548),
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
        border: Border.all(color: borderColor, width: 1.2 * scale),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.14),
            blurRadius: 8 * scale,
            offset: Offset(0, 3 * scale),
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
