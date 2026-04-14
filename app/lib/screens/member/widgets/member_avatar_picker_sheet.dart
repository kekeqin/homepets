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
                  const Text(
                    '更换头像',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: MemberProfileColors.text,
                    ),
                  ),
                  const SizedBox(height: 12),
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
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          child: const Text('取消'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.of(
                            sheetContext,
                          ).pop(selectedAvatarValue),
                          child: const Text('保存'),
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
          color: selected ? const Color(0xFFE1F7D8) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? const Color(0xFF006B1B) : const Color(0xFFE3D7B8),
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
                    ? const Color(0xFF006B1B)
                    : const Color(0xFF755700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
