import 'package:flutter/material.dart';

import '../../../widgets/user_avatar.dart';
import 'member_profile_common.dart';

Future<String?> showMemberAvatarPickerSheet(
  BuildContext context, {
  required String nickname,
  required String? initialAvatarValue,
}) {
  String? selectedAvatarValue = initialAvatarValue;
  return showModalBottomSheet<String?>(
    context: context,
    backgroundColor: MemberProfileColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF8A7356),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('取消'),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            '更换头像',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: MemberProfileColors.text,
                            ),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.of(sheetContext).pop(selectedAvatarValue),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF9B6415),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('保存'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(
                    height: 1,
                    thickness: 0.8,
                    color: Color(0x1AA87500),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: UserAvatar(
                      nickname: nickname,
                      avatarValue: selectedAvatarValue,
                      size: 78,
                      backgroundColor: const Color(0xFFFFE8C2),
                      foregroundColor: const Color(0xFF755700),
                      border: Border.all(
                        color: const Color(0x33A87500),
                        width: 2,
                      ),
                      fontSize: 32,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _AvatarOptionChip(
                        label: '默认',
                        selected: selectedAvatarValue == null,
                        onTap: () {
                          setModalState(() => selectedAvatarValue = null);
                        },
                        child: UserAvatar(
                          nickname: nickname,
                          avatarValue: null,
                          size: 42,
                          border: Border.all(
                            color: const Color(0x33A87500),
                            width: 1.4,
                          ),
                        ),
                      ),
                      for (final emoji in presetAvatarEmojis)
                        _AvatarOptionChip(
                          label: emoji,
                          selected:
                              selectedAvatarValue ==
                              userAvatarValueFromEmoji(emoji),
                          onTap: () {
                            setModalState(
                              () => selectedAvatarValue =
                                  userAvatarValueFromEmoji(emoji),
                            );
                          },
                          child: Center(
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 28),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class _AvatarOptionChip extends StatelessWidget {
  const _AvatarOptionChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 72,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF1E7D2) : const Color(0xFFFFF7EA),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? const Color(0xFFD99955) : const Color(0xFFE2CBAA),
            width: selected ? 2 : 1.2,
          ),
        ),
        child: Column(
          children: [
            SizedBox(width: 42, height: 42, child: child),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected
                    ? const Color(0xFFA86C35)
                    : const Color(0xFF6B4328),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
