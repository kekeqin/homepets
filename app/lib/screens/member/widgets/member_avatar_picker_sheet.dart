import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../widgets/user_avatar.dart';

const String _defaultAvatarValue = userDefaultAvatarAssetPath;

const List<_AvatarOption> _avatarOptions = <_AvatarOption>[
  _AvatarOption(
    key: 'default',
    label: '默认',
    avatarValue: userDefaultAvatarAssetPath,
  ),
  _AvatarOption(key: 'dad', label: '爸爸', avatarValue: userDadAvatarAssetPath),
  _AvatarOption(key: 'mom', label: '妈妈', avatarValue: userMomAvatarAssetPath),
  _AvatarOption(key: 'boy', label: '男孩', avatarValue: userBoyAvatarAssetPath),
  _AvatarOption(key: 'girl', label: '女孩', avatarValue: userGirlAvatarAssetPath),
  _AvatarOption(
    key: 'mom_yellow',
    label: '妈妈',
    avatarValue: userMomYellowAvatarAssetPath,
  ),
  _AvatarOption(
    key: 'boy_green',
    label: '男孩',
    avatarValue: userBoyGreenAvatarAssetPath,
  ),
  _AvatarOption(
    key: 'girl_bob',
    label: '女孩',
    avatarValue: userGirlBobAvatarAssetPath,
  ),
];

const String _cancelText = '取消';
const String _saveText = '保存';
const String _titleText = '更换头像';
const Color _pickerBackgroundTop = Color(0xFFFFF0DC);
const Color _pickerBackgroundBottom = Color(0xFFF1DDBF);
const Color _pickerBorder = Color(0xFFE1C7A7);

Future<String?> showMemberAvatarPickerSheet(
  BuildContext context, {
  required String nickname,
  required String? initialAvatarValue,
}) async {
  String? selectedOptionKey = _optionKeyForValue(initialAvatarValue);

  final pickedAvatar = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x24000000),
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          final previewAvatarValue = _previewAvatarValue(
            selectedOptionKey: selectedOptionKey,
            initialAvatarValue: initialAvatarValue,
          );

          return SafeArea(
            top: false,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                width: double.infinity,
                height: _sheetHeightFor(MediaQuery.sizeOf(context).height),
                child: _AvatarPickerPanel(
                  nickname: nickname,
                  previewAvatarValue: previewAvatarValue,
                  selectedOptionKey: selectedOptionKey,
                  onCancel: () => Navigator.of(sheetContext).pop(),
                  onSave: () {
                    Navigator.of(sheetContext).pop(
                      _avatarValueForSave(
                        selectedOptionKey: selectedOptionKey,
                        initialAvatarValue: initialAvatarValue,
                      ),
                    );
                  },
                  onSelectOption: (option) {
                    setModalState(() => selectedOptionKey = option.key);
                  },
                ),
              ),
            ),
          );
        },
      );
    },
  );

  return pickedAvatar ?? initialAvatarValue;
}

double _sheetHeightFor(double screenHeight) {
  final factor = screenHeight < 700
      ? 0.86
      : screenHeight < 860
      ? 0.76
      : 0.70;
  return math.min(screenHeight * factor, 760.0);
}

String _avatarValueForSave({
  required String? selectedOptionKey,
  required String? initialAvatarValue,
}) {
  final option = _avatarOptionForKey(selectedOptionKey);
  if (option != null) {
    return option.avatarValue;
  }

  final normalizedInitial = initialAvatarValue?.trim();
  if (normalizedInitial != null && normalizedInitial.isNotEmpty) {
    return normalizedPresetUserAvatarAssetValue(normalizedInitial) ??
        _defaultAvatarValue;
  }

  return _defaultAvatarValue;
}

String _previewAvatarValue({
  required String? selectedOptionKey,
  required String? initialAvatarValue,
}) {
  final option = _avatarOptionForKey(selectedOptionKey);
  if (option != null) {
    return option.avatarValue;
  }

  final normalizedInitial = initialAvatarValue?.trim();
  if (normalizedInitial != null && normalizedInitial.isNotEmpty) {
    return normalizedPresetUserAvatarAssetValue(normalizedInitial) ??
        _defaultAvatarValue;
  }

  return _defaultAvatarValue;
}

String? _optionKeyForValue(String? avatarValue) {
  final normalized = normalizedPresetUserAvatarAssetValue(avatarValue);
  if (normalized == null || normalized.isEmpty) {
    return 'default';
  }

  for (final option in _avatarOptions) {
    if (option.matches(normalized)) {
      return option.key;
    }
  }
  return null;
}

_AvatarOption? _avatarOptionForKey(String? key) {
  if (key == null) {
    return null;
  }

  for (final option in _avatarOptions) {
    if (option.key == key) {
      return option;
    }
  }
  return null;
}

class _AvatarPickerPanel extends StatelessWidget {
  const _AvatarPickerPanel({
    required this.nickname,
    required this.previewAvatarValue,
    required this.selectedOptionKey,
    required this.onCancel,
    required this.onSave,
    required this.onSelectOption,
  });

  final String nickname;
  final String previewAvatarValue;
  final String? selectedOptionKey;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final ValueChanged<_AvatarOption> onSelectOption;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.height < 700;
    final horizontalPadding = size.width < 390 ? 16.0 : 22.0;
    final previewSize = compact ? 118.0 : 148.0;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_pickerBackgroundTop, _pickerBackgroundBottom],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
        border: Border.all(color: _pickerBorder, width: 1.8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1C000000),
            blurRadius: 24,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                compact ? 16 : 18,
                horizontalPadding,
                0,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 76,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: onCancel,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF6A4A2A),
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 40),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          textStyle: TextStyle(
                            fontSize: compact ? 18 : 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        child: const Text(_cancelText),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _titleText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: compact ? 20 : 22,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF5C3B20),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 76,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: onSave,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFCB8D18),
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 40),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          textStyle: TextStyle(
                            fontSize: compact ? 18 : 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        child: const Text(_saveText),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                10,
                horizontalPadding,
                0,
              ),
              child: const SizedBox(
                height: 8,
                width: double.infinity,
                child: CustomPaint(painter: _AvatarPickerDividerPainter()),
              ),
            ),
            SizedBox(height: compact ? 12 : 18),
            Container(
              width: previewSize + 14,
              height: previewSize + 14,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFF1D6),
                border: Border.all(color: const Color(0xFF8A623A), width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 14,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: UserAvatar(
                nickname: nickname,
                avatarValue: previewAvatarValue,
                size: previewSize,
                backgroundColor: const Color(0xFFFFF2D9),
                foregroundColor: const Color(0xFF6E4C2B),
                fontSize: compact ? 44 : 52,
              ),
            ),
            SizedBox(height: compact ? 14 : 20),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxGridWidth = math.min(constraints.maxWidth, 560.0);
                  return Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxGridWidth),
                      child: GridView.builder(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          0,
                          horizontalPadding,
                          compact ? 16 : 22,
                        ),
                        physics: const ClampingScrollPhysics(),
                        itemCount: _avatarOptions.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 1,
                            ),
                        itemBuilder: (context, index) {
                          final option = _avatarOptions[index];
                          final selected = option.key == selectedOptionKey;
                          return _AvatarOptionCard(
                            option: option,
                            selected: selected,
                            onTap: () => onSelectOption(option),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarOptionCard extends StatelessWidget {
  const _AvatarOptionCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _AvatarOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? const Color(0xFFD99A18)
        : const Color(0xFFE2CBAA);
    final backgroundColor = selected
        ? const Color(0xFFFFF8E8)
        : const Color(0xFFFFFBF7);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor, width: selected ? 2.4 : 1.4),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x1FD99A18),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ]
                : const [],
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFF2D8),
                  border: Border.all(
                    color: const Color(0xFF8A623A),
                    width: 1.2,
                  ),
                ),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: ClipOval(
                    child: CenteredAvatarAsset(
                      assetPath: option.avatarValue,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) =>
                          _AvatarCardFallback(label: option.label),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarCardFallback extends StatelessWidget {
  const _AvatarCardFallback({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFF8EC),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: Color(0xFF5C3B20),
        ),
      ),
    );
  }
}

class _AvatarPickerDividerPainter extends CustomPainter {
  const _AvatarPickerDividerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD8A553)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const dashWidth = 18.0;
    const gapWidth = 8.0;
    final y = size.height / 2;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, y),
        Offset(math.min(x + dashWidth, size.width), y),
        paint,
      );
      x += dashWidth + gapWidth;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AvatarOption {
  const _AvatarOption({
    required this.key,
    required this.label,
    required this.avatarValue,
  });

  final String key;
  final String label;
  final String avatarValue;

  bool matches(String value) => value == avatarValue;
}
