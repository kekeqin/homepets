import 'package:flutter/material.dart';

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
  return avatarValue.startsWith('https://') || avatarValue.startsWith('http://');
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
    final emoji = userAvatarEmojiFromValue(avatarValue);
    if (emoji != null) {
      return Center(
        child: Text(
          emoji,
          style: TextStyle(fontSize: fontSize ?? size * 0.54),
        ),
      );
    }
    if (isNetworkAvatarValue(avatarValue)) {
      return Image.network(
        avatarValue!,
        fit: BoxFit.cover,
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
