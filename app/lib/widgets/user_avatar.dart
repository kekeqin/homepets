import 'package:flutter/material.dart';

const String userAvatarAssetBasePath = 'assets/images/ui/family';
const String userDefaultAvatarAssetPath = '$userAvatarAssetBasePath/8.png';
const String userDadAvatarAssetPath = '$userAvatarAssetBasePath/9.png';
const String userMomAvatarAssetPath =
    '$userAvatarAssetBasePath/avatar_adult_male_reference_style.png';
const String userBoyAvatarAssetPath = '$userAvatarAssetBasePath/12.png';
const String userGirlAvatarAssetPath = '$userAvatarAssetBasePath/11.png';
const String userMomYellowAvatarAssetPath =
    '$userAvatarAssetBasePath/6 (1).png';
const String userBoyGreenAvatarAssetPath = '$userAvatarAssetBasePath/13.png';
const String userGirlBobAvatarAssetPath = '$userAvatarAssetBasePath/7 (1).png';

const Set<String> _presetUserAvatarAssetPaths = <String>{
  userDefaultAvatarAssetPath,
  userDadAvatarAssetPath,
  userMomAvatarAssetPath,
  userBoyAvatarAssetPath,
  userGirlAvatarAssetPath,
  userMomYellowAvatarAssetPath,
  userBoyGreenAvatarAssetPath,
  userGirlBobAvatarAssetPath,
};

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
    'assets/images/ui/Change profile picture/16.png' =>
      userDefaultAvatarAssetPath,
    'assets/images/ui/Change profile picture/11.png' => userDadAvatarAssetPath,
    'assets/images/ui/Change profile picture/14.png' => userMomAvatarAssetPath,
    'assets/images/ui/Change profile picture/15.png' => userBoyAvatarAssetPath,
    'assets/images/ui/Change profile picture/18.png' => userGirlAvatarAssetPath,
    'assets/images/ui/Change profile picture/13 (1).png' =>
      userMomYellowAvatarAssetPath,
    'assets/images/ui/Change profile picture/12.png' =>
      userBoyGreenAvatarAssetPath,
    'assets/images/ui/Change profile picture/17.png' =>
      userGirlBobAvatarAssetPath,
    'assets/images/ui/family/5-(2).png' => userBoyAvatarAssetPath,
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
  return value != null && _presetUserAvatarAssetPaths.contains(value);
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
        offset: Offset(-0.014, 0.010),
        scale: 1.033,
      ),
      userBoyGreenAvatarAssetPath => const _AvatarAssetTransform(
        offset: Offset(-0.015, 0.031),
        scale: 1.062,
      ),
      userMomYellowAvatarAssetPath => const _AvatarAssetTransform(
        offset: Offset(-0.009, 0.025),
        scale: 0.952,
      ),
      userMomAvatarAssetPath => const _AvatarAssetTransform(
        offset: Offset(-0.014, 0.021),
        scale: 1.029,
      ),
      userBoyAvatarAssetPath => const _AvatarAssetTransform(
        offset: Offset(-0.017, 0.016),
        scale: 1.083,
      ),
      userDefaultAvatarAssetPath => const _AvatarAssetTransform(
        offset: Offset(-0.015, 0.022),
        scale: 1.033,
      ),
      userGirlBobAvatarAssetPath => const _AvatarAssetTransform(
        offset: Offset(0, 0),
        scale: 1,
      ),
      userGirlAvatarAssetPath => const _AvatarAssetTransform(
        offset: Offset(-0.015, -0.005),
        scale: 1.150,
      ),
      _ => const _AvatarAssetTransform(),
    };
  }
}
