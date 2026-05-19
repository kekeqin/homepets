import 'package:flutter/material.dart';

const String userAvatarAssetBasePath =
    'assets/images/ui/Change profile picture';
const String userDefaultAvatarAssetPath = '$userAvatarAssetBasePath/16.png';
const String userDadAvatarAssetPath = '$userAvatarAssetBasePath/11.png';
const String userMomAvatarAssetPath = '$userAvatarAssetBasePath/14.png';
const String userBoyAvatarAssetPath = '$userAvatarAssetBasePath/15.png';
const String userGirlAvatarAssetPath = '$userAvatarAssetBasePath/18.png';
const String userMomYellowAvatarAssetPath =
    '$userAvatarAssetBasePath/13 (1).png';
const String userBoyGreenAvatarAssetPath = '$userAvatarAssetBasePath/12.png';
const String userGirlBobAvatarAssetPath = '$userAvatarAssetBasePath/17.png';

const List<String> presetAvatarEmojis = <String>[
  '🐶',
  '🐱',
  '🐼',
  '🐸',
  '🐰',
  '🦊',
  '🐻',
  '🐯',
];

const String _emojiAvatarPrefix = 'emoji:';

String? userAvatarEmojiFromValue(String? avatarValue) {
  if (avatarValue == null || avatarValue.isEmpty) {
    return null;
  }
  if (!avatarValue.startsWith(_emojiAvatarPrefix)) {
    return null;
  }
  return avatarValue.substring(_emojiAvatarPrefix.length);
}

String userAvatarValueFromEmoji(String emoji) {
  return '$_emojiAvatarPrefix$emoji';
}

bool isNetworkAvatarValue(String? avatarValue) {
  if (avatarValue == null) {
    return false;
  }
  final value = avatarValue.trim();
  return value.startsWith('https://') || value.startsWith('http://');
}

bool isAssetAvatarValue(String? avatarValue) {
  if (avatarValue == null) {
    return false;
  }
  return avatarValue.trim().startsWith('assets/');
}

String? normalizedUserAvatarAssetValue(String? avatarValue) {
  final value = avatarValue?.trim();
  if (value == null || value.isEmpty) {
    return null;
  }

  return switch (value) {
    'assets/images/ui/sprites/avatar_edit_default_avatar.png' =>
      userDefaultAvatarAssetPath,
    'assets/images/ui/sprites/avatar_edit_dad_avatar.png' =>
      userDadAvatarAssetPath,
    'assets/images/ui/sprites/avatar_edit_mom_avatar.png' =>
      userMomAvatarAssetPath,
    'assets/images/ui/sprites/avatar_edit_boy_avatar.png' =>
      userBoyAvatarAssetPath,
    'assets/images/ui/sprites/avatar_edit_girl_avatar.png' =>
      userGirlAvatarAssetPath,
    'assets/images/ui/sprites/avatar_edit_cat_avatar.png' =>
      userMomYellowAvatarAssetPath,
    'assets/images/ui/sprites/avatar_edit_dog_avatar.png' =>
      userBoyGreenAvatarAssetPath,
    'assets/images/ui/sprites/avatar_edit_rabbit_avatar.png' =>
      userGirlBobAvatarAssetPath,
    _ when value.startsWith('emoji:') => userDefaultAvatarAssetPath,
    _ => value,
  };
}

bool isPresetUserAvatarAssetValue(String? avatarValue) {
  final value = avatarValue?.trim();
  return value != null && value.startsWith('$userAvatarAssetBasePath/');
}

String? normalizedPresetUserAvatarAssetValue(String? avatarValue) {
  final normalizedValue = normalizedUserAvatarAssetValue(avatarValue);
  if (!isPresetUserAvatarAssetValue(normalizedValue)) {
    return null;
  }
  return normalizedValue;
}

String userAvatarFallbackText(String? nickname) {
  final trimmed = nickname?.trim() ?? '';
  if (trimmed.isEmpty) {
    return '我';
  }
  return trimmed.characters.first;
}

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.nickname,
    required this.avatarValue,
    required this.size,
    this.backgroundColor = const Color(0xFFFFE8C2),
    this.foregroundColor = const Color(0xFF755700),
    this.border,
    this.fontSize,
    this.fontWeight = FontWeight.w800,
  });

  final String? nickname;
  final String? avatarValue;
  final double size;
  final Color backgroundColor;
  final Color foregroundColor;
  final BoxBorder? border;
  final double? fontSize;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: border,
      ),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    final normalizedAvatarValue = normalizedUserAvatarAssetValue(avatarValue);
    final emoji = userAvatarEmojiFromValue(normalizedAvatarValue);
    if (emoji != null) {
      return Center(
        child: Text(emoji, style: TextStyle(fontSize: fontSize ?? size * 0.54)),
      );
    }
    if (isNetworkAvatarValue(normalizedAvatarValue)) {
      return Image.network(
        normalizedAvatarValue!.trim(),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildFallback(),
      );
    }
    if (isAssetAvatarValue(normalizedAvatarValue)) {
      return CenteredAvatarAsset(
        assetPath: normalizedAvatarValue!.trim(),
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => _buildFallback(),
      );
    }
    return _buildFallback();
  }

  Widget _buildFallback() {
    return Center(
      child: Text(
        userAvatarFallbackText(nickname),
        style: TextStyle(
          fontSize: fontSize ?? size * 0.42,
          fontWeight: fontWeight,
          color: foregroundColor,
        ),
      ),
    );
  }
}

class CenteredAvatarAsset extends StatelessWidget {
  const CenteredAvatarAsset({
    super.key,
    required this.assetPath,
    this.fit = BoxFit.contain,
    this.errorBuilder,
  });

  final String assetPath;
  final BoxFit fit;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) {
    final transform = _AvatarAssetTransform.forPath(assetPath);
    return FractionalTranslation(
      translation: transform.offset,
      child: Transform.scale(
        scale: transform.scale,
        child: Image.asset(assetPath, fit: fit, errorBuilder: errorBuilder),
      ),
    );
  }
}

class _AvatarAssetTransform {
  const _AvatarAssetTransform({this.offset = Offset.zero, this.scale = 1});

  final Offset offset;
  final double scale;

  static _AvatarAssetTransform forPath(String assetPath) {
    return switch (assetPath.trim()) {
      userDadAvatarAssetPath => const _AvatarAssetTransform(
        offset: Offset(-0.01, -0.05),
        scale: 1.08,
      ),
      userBoyGreenAvatarAssetPath => const _AvatarAssetTransform(
        offset: Offset(0.02, -0.05),
        scale: 1.08,
      ),
      userMomYellowAvatarAssetPath => const _AvatarAssetTransform(
        offset: Offset(0.01, -0.04),
        scale: 1.08,
      ),
      userMomAvatarAssetPath => const _AvatarAssetTransform(
        offset: Offset(0.05, -0.02),
        scale: 1.08,
      ),
      userBoyAvatarAssetPath => const _AvatarAssetTransform(
        offset: Offset(-0.04, -0.02),
        scale: 1.08,
      ),
      userDefaultAvatarAssetPath => const _AvatarAssetTransform(
        offset: Offset(0, -0.03),
        scale: 1.08,
      ),
      userGirlBobAvatarAssetPath => const _AvatarAssetTransform(
        offset: Offset(0, -0.04),
        scale: 1.08,
      ),
      userGirlAvatarAssetPath => const _AvatarAssetTransform(
        offset: Offset(-0.03, -0.03),
        scale: 1.08,
      ),
      'assets/images/ui/family/5-(2).png' => const _AvatarAssetTransform(
        offset: Offset(0, -0.02),
        scale: 1.18,
      ),
      'assets/images/ui/family/6 (1).png' => const _AvatarAssetTransform(
        offset: Offset(0, -0.02),
        scale: 1.12,
      ),
      'assets/images/ui/family/7 (1).png' => const _AvatarAssetTransform(
        offset: Offset(0, -0.01),
        scale: 1.13,
      ),
      'assets/images/ui/family/avatar_adult_male_reference_style.png' =>
        const _AvatarAssetTransform(offset: Offset(0, -0.01), scale: 1.72),
      _ => const _AvatarAssetTransform(),
    };
  }
}
