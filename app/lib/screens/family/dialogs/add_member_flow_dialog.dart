import 'package:flutter/material.dart';

import '../../../models/pet_artwork.dart';
import '../../../widgets/app_modal_shell.dart';
import '../widgets/family_sprite_slice.dart';

class AddMemberFlowResult {
  const AddMemberFlowResult({
    required this.nickname,
    required this.petType,
    required this.petName,
  });

  final String nickname;
  final String petType;
  final String petName;
}

class SelectPetFlowResult {
  const SelectPetFlowResult({required this.petType, required this.petName});

  final String petType;
  final String petName;
}

Future<AddMemberFlowResult?> showAddMemberFlowDialog(BuildContext context) {
  return showDialog<AddMemberFlowResult>(
    context: context,
    barrierColor: const Color(0x4D5A3A21),
    builder: (_) => const AddMemberFlowDialog(),
  );
}

Future<SelectPetFlowResult?> showSelectPetFlowDialog(
  BuildContext context, {
  required String memberName,
}) {
  return showDialog<SelectPetFlowResult>(
    context: context,
    barrierColor: const Color(0x4D5A3A21),
    builder: (_) => SelectPetFlowDialog(memberName: memberName),
  );
}

class AddMemberFlowDialog extends StatefulWidget {
  const AddMemberFlowDialog({super.key});

  @override
  State<AddMemberFlowDialog> createState() => _AddMemberFlowDialogState();
}

class _AddMemberFlowDialogState extends State<AddMemberFlowDialog> {
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _petNameController = TextEditingController();

  String? _selectedPetType = selectablePetTypes.first;
  String? _nicknameError;
  String? _petTypeError;
  String? _petNameError;
  bool _petNameDirty = false;

  @override
  void dispose() {
    _nicknameController.dispose();
    _petNameController.dispose();
    super.dispose();
  }

  void _selectPetType(String petType) {
    final previousType = _selectedPetType;
    final previousDefault = previousType == null
        ? null
        : petTypeLabel(previousType);

    setState(() {
      _selectedPetType = petType;
      _petTypeError = null;
      if (!_petNameDirty ||
          _petNameController.text.trim().isEmpty ||
          _petNameController.text.trim() == previousDefault) {
        _petNameController.text = petTypeLabel(petType);
        _petNameController.selection = TextSelection.fromPosition(
          TextPosition(offset: _petNameController.text.length),
        );
        _petNameError = null;
        _petNameDirty = false;
      }
    });
  }

  void _submit() {
    final nickname = _nicknameController.text.trim();
    final petType = _selectedPetType;
    final petName = _petNameController.text.trim();

    setState(() {
      _nicknameError = nickname.isEmpty ? '成员昵称不能为空' : null;
      _petTypeError = petType == null ? '请选择一种宠物' : null;
      _petNameError = petName.isEmpty ? '宠物名字不能为空' : null;
    });

    if (_nicknameError != null ||
        _petTypeError != null ||
        _petNameError != null) {
      return;
    }

    Navigator.of(context).pop(
      AddMemberFlowResult(
        nickname: nickname,
        petType: petType!,
        petName: petName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final dense = viewportHeight < 900;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: HomePetsDialogGutter.medium,
        vertical: 14,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dense ? 354 : 374,
          maxHeight: viewportHeight * (dense ? 0.88 : 0.90),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_AddMemberPalette.paperTop, _AddMemberPalette.paper],
                ),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: _AddMemberPalette.ink, width: 1.8),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x2A5A3A21),
                    blurRadius: 28,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    dense ? 18 : 24,
                    dense ? 18 : 26,
                    dense ? 18 : 24,
                    dense ? 16 : 22,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: _DialogTitle(dense: dense)),
                      SizedBox(height: dense ? 14 : 24),
                      _SectionLabel(text: '成员名称', dense: dense),
                      SizedBox(height: dense ? 8 : 10),
                      TextField(
                        key: const Key('family_add_member_nickname_field'),
                        controller: _nicknameController,
                        maxLength: 20,
                        autofocus: true,
                        textInputAction: TextInputAction.next,
                        style: _addMemberInputTextStyle,
                        onChanged: (_) {
                          if (_nicknameError != null) {
                            setState(() => _nicknameError = null);
                          }
                        },
                        decoration: _addMemberInputDecoration(
                          dense: dense,
                          hintText: '小宝',
                          errorText: _nicknameError,
                        ),
                      ),
                      _DashedDivider(dense: dense),
                      _SectionLabel(text: '选择宠物', dense: dense),
                      SizedBox(height: dense ? 8 : 12),
                      _PetOptionGrid(
                        dense: dense,
                        twoRowLayout: true,
                        selectedPetType: _selectedPetType,
                        onSelect: _selectPetType,
                      ),
                      if (_petTypeError != null) ...[
                        const SizedBox(height: 8),
                        Center(child: _ErrorText(_petTypeError!)),
                      ],
                      _DashedDivider(dense: dense),
                      _SectionLabel(text: '宠物名字', dense: dense),
                      SizedBox(height: dense ? 6 : 10),
                      TextField(
                        key: const Key('family_add_member_pet_name_field'),
                        controller: _petNameController,
                        maxLength: 20,
                        textInputAction: TextInputAction.done,
                        style: _addMemberInputTextStyle,
                        onChanged: (_) {
                          _petNameDirty = true;
                          if (_petNameError != null) {
                            setState(() => _petNameError = null);
                          }
                        },
                        onSubmitted: (_) => _submit(),
                        decoration: _addMemberInputDecoration(
                          dense: dense,
                          hintText: '团团',
                          errorText: _petNameError,
                        ),
                      ),
                      SizedBox(height: dense ? 12 : 22),
                      Row(
                        children: [
                          Expanded(
                            flex: 8,
                            child: _DialogActionButton(
                              label: '取消',
                              dense: dense,
                              variant: _DialogActionButtonVariant.secondary,
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 13,
                            child: _DialogActionButton(
                              key: const Key('family_add_member_submit_button'),
                              label: '确认添加',
                              dense: dense,
                              variant: _DialogActionButtonVariant.primary,
                              onPressed: _submit,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: dense ? -14 : -16,
              right: dense ? -12 : -14,
              child: _DialogCloseButton(
                key: const Key('family_add_member_close_button'),
                dense: dense,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SelectPetFlowDialog extends StatefulWidget {
  const SelectPetFlowDialog({super.key, required this.memberName});

  final String memberName;

  @override
  State<SelectPetFlowDialog> createState() => _SelectPetFlowDialogState();
}

class _SelectPetFlowDialogState extends State<SelectPetFlowDialog> {
  final TextEditingController _petNameController = TextEditingController(
    text: petTypeLabel(selectablePetTypes.first),
  );

  String _selectedPetType = selectablePetTypes.first;
  String? _petNameError;
  bool _petNameDirty = false;

  @override
  void dispose() {
    _petNameController.dispose();
    super.dispose();
  }

  void _selectPetType(String petType) {
    final previousDefault = petTypeLabel(_selectedPetType);

    setState(() {
      _selectedPetType = petType;
      if (!_petNameDirty ||
          _petNameController.text.trim().isEmpty ||
          _petNameController.text.trim() == previousDefault) {
        _petNameController.text = petTypeLabel(petType);
        _petNameController.selection = TextSelection.fromPosition(
          TextPosition(offset: _petNameController.text.length),
        );
        _petNameError = null;
        _petNameDirty = false;
      }
    });
  }

  void _submit() {
    final petName = _petNameController.text.trim();

    setState(() {
      _petNameError = petName.isEmpty ? '宠物名字不能为空' : null;
    });

    if (_petNameError != null) {
      return;
    }

    Navigator.of(
      context,
    ).pop(SelectPetFlowResult(petType: _selectedPetType, petName: petName));
  }

  @override
  Widget build(BuildContext context) {
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final dense = viewportHeight < 900;
    final memberName = widget.memberName.trim().isEmpty
        ? '这个成员'
        : widget.memberName.trim();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: HomePetsDialogGutter.medium,
        vertical: 14,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dense ? 354 : 374,
          maxHeight: viewportHeight * (dense ? 0.88 : 0.90),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_AddMemberPalette.paperTop, _AddMemberPalette.paper],
                ),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: _AddMemberPalette.ink, width: 1.8),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x2A5A3A21),
                    blurRadius: 28,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    dense ? 18 : 24,
                    dense ? 18 : 26,
                    dense ? 18 : 24,
                    dense ? 16 : 22,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: _SelectPetDialogTitle(
                          memberName: memberName,
                          dense: dense,
                        ),
                      ),
                      SizedBox(height: dense ? 14 : 24),
                      _SectionLabel(text: '选择宠物', dense: dense),
                      SizedBox(height: dense ? 8 : 12),
                      _PetOptionGrid(
                        dense: dense,
                        twoRowLayout: true,
                        selectedPetType: _selectedPetType,
                        onSelect: _selectPetType,
                      ),
                      _DashedDivider(dense: dense),
                      _SectionLabel(text: '宠物名字', dense: dense),
                      SizedBox(height: dense ? 6 : 10),
                      TextField(
                        key: const Key('family_select_pet_name_field'),
                        controller: _petNameController,
                        maxLength: 20,
                        autofocus: true,
                        textInputAction: TextInputAction.done,
                        style: _addMemberInputTextStyle,
                        onChanged: (_) {
                          _petNameDirty = true;
                          if (_petNameError != null) {
                            setState(() => _petNameError = null);
                          }
                        },
                        onSubmitted: (_) => _submit(),
                        decoration: _addMemberInputDecoration(
                          dense: dense,
                          hintText: '团团',
                          errorText: _petNameError,
                        ),
                      ),
                      SizedBox(height: dense ? 12 : 22),
                      Row(
                        children: [
                          Expanded(
                            flex: 8,
                            child: _DialogActionButton(
                              label: '稍后',
                              dense: dense,
                              variant: _DialogActionButtonVariant.secondary,
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 13,
                            child: _DialogActionButton(
                              key: const Key('family_select_pet_submit_button'),
                              label: '确认领养',
                              dense: dense,
                              variant: _DialogActionButtonVariant.primary,
                              onPressed: _submit,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: dense ? -14 : -16,
              right: dense ? -12 : -14,
              child: _DialogCloseButton(
                key: const Key('family_select_pet_close_button'),
                dense: dense,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddMemberPalette {
  const _AddMemberPalette._();

  static const paperTop = Color(0xFFFFF8E9);
  static const paper = Color(0xFFFFF0D8);
  static const card = Color(0xFFFFF8EC);
  static const ink = Color(0xFF5A3A21);
  static const line = Color(0xFF9B7A5C);
  static const mutedLine = Color(0xFFE3CBAE);
  static const labelPill = Color(0xFFFFEED8);
  static const sage = Color(0xFFB7BE72);
  static const sageDark = Color(0xFF767B33);
  static const error = Color(0xFFB0483D);
}

const TextStyle _addMemberInputTextStyle = TextStyle(
  color: _AddMemberPalette.ink,
  fontSize: 17,
  fontWeight: FontWeight.w800,
);

InputDecoration _addMemberInputDecoration({
  required bool dense,
  required String hintText,
  required String? errorText,
}) {
  final borderRadius = BorderRadius.circular(18);

  return InputDecoration(
    hintText: hintText,
    errorText: errorText,
    counterText: '',
    isDense: true,
    hintStyle: TextStyle(
      color: _AddMemberPalette.ink.withValues(alpha: 0.38),
      fontSize: dense ? 15 : 16,
      fontWeight: FontWeight.w900,
    ),
    errorStyle: const TextStyle(
      color: _AddMemberPalette.error,
      fontSize: 12,
      fontWeight: FontWeight.w800,
    ),
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.42),
    contentPadding: EdgeInsets.symmetric(
      horizontal: dense ? 15 : 17,
      vertical: dense ? 10 : 14,
    ),
    border: OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: const BorderSide(color: _AddMemberPalette.line, width: 1.6),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: const BorderSide(color: _AddMemberPalette.line, width: 1.6),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: const BorderSide(color: _AddMemberPalette.ink, width: 1.8),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: const BorderSide(color: _AddMemberPalette.error, width: 1.6),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: const BorderSide(color: _AddMemberPalette.error, width: 1.8),
    ),
  );
}

class _DialogTitle extends StatelessWidget {
  const _DialogTitle({required this.dense});

  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Text(
      '添加成员',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: _AddMemberPalette.ink,
        fontSize: dense ? 26 : 30,
        fontWeight: FontWeight.w900,
        height: 1,
      ),
    );
  }
}

class _SelectPetDialogTitle extends StatelessWidget {
  const _SelectPetDialogTitle({required this.memberName, required this.dense});

  final String memberName;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '选择宠物',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _AddMemberPalette.ink,
            fontSize: dense ? 22 : 26,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        SizedBox(height: dense ? 5 : 7),
        Text(
          '给 $memberName 选择一位伙伴',
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _AddMemberPalette.ink.withValues(alpha: 0.68),
            fontSize: dense ? 11.5 : 13,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text, required this.dense});

  final String text;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: _AddMemberPalette.ink,
        fontSize: dense ? 16 : 20,
        fontWeight: FontWeight.w900,
        height: 1.1,
      ),
    );
  }
}

class _PetOptionGrid extends StatelessWidget {
  const _PetOptionGrid({
    required this.dense,
    this.twoRowLayout = false,
    required this.selectedPetType,
    required this.onSelect,
  });

  final bool dense;
  final bool twoRowLayout;
  final String? selectedPetType;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 300;
        final spacing = twoRowLayout
            ? (compact ? 8.0 : 10.0)
            : (compact ? 9.0 : 12.0);
        final cardWidth = twoRowLayout
            ? ((constraints.maxWidth - spacing * 2) / 3)
                  .clamp(74.0, dense ? 86.0 : 92.0)
                  .toDouble()
            : compact
            ? 82.0
            : 92.0;
        final cardHeight = twoRowLayout
            ? (dense ? 80.0 : 90.0)
            : dense
            ? 86.0
            : (compact ? 108.0 : 118.0);

        return SizedBox(
          width: double.infinity,
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: spacing,
            runSpacing: twoRowLayout
                ? (dense ? 8 : 10)
                : (dense ? 10 : (compact ? 12 : 16)),
            children: [
              for (final petType in selectablePetTypes)
                _PetOptionCard(
                  width: cardWidth,
                  height: cardHeight,
                  petType: petType,
                  selected: selectedPetType == petType,
                  onTap: () => onSelect(petType),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _PetOptionCard extends StatelessWidget {
  const _PetOptionCard({
    required this.width,
    required this.height,
    required this.petType,
    required this.selected,
    required this.onTap,
  });

  final double width;
  final double height;
  final String petType;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final poseIndex = deterministicPetPoseIndex(petType, petType.hashCode);
    final assetPath = petAvatarAssetPath(petType, poseIndex);
    final dense = height < 100;

    return Semantics(
      button: true,
      selected: selected,
      label: '选择${petTypeLabel(petType)}',
      child: GestureDetector(
        key: Key('family_add_member_pet_type_$petType'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                width: width,
                height: height,
                padding: EdgeInsets.fromLTRB(
                  7,
                  dense ? 5 : 7,
                  7,
                  dense ? 7 : 9,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFFFFF8D8)
                      : _AddMemberPalette.card.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(dense ? 20 : 22),
                  border: Border.all(
                    color: selected
                        ? _AddMemberPalette.sageDark
                        : _AddMemberPalette.mutedLine,
                    width: selected ? 2.2 : 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: selected ? 1 : 3),
                        child: Image.asset(
                          assetPath,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
                    SizedBox(height: dense ? 3 : 5),
                    Container(
                      width: double.infinity,
                      height: dense ? 22 : 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _AddMemberPalette.labelPill.withValues(
                          alpha: 0.82,
                        ),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: _AddMemberPalette.line.withValues(alpha: 0.3),
                          width: 1.2,
                        ),
                      ),
                      child: Text(
                        petTypeLabel(petType),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _AddMemberPalette.ink,
                          fontSize: dense ? 12 : 13,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Positioned(
                  top: dense ? -7 : -9,
                  right: dense ? -5 : -7,
                  child: Container(
                    width: dense ? 24 : 28,
                    height: dense ? 24 : 28,
                    decoration: BoxDecoration(
                      color: _AddMemberPalette.sage,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _AddMemberPalette.sageDark,
                        width: 1.4,
                      ),
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: dense ? 17 : 20,
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

enum _DialogActionButtonVariant { primary, secondary }

class _DialogActionButton extends StatelessWidget {
  const _DialogActionButton({
    super.key,
    required this.label,
    required this.dense,
    required this.variant,
    required this.onPressed,
  });

  final String label;
  final bool dense;
  final _DialogActionButtonVariant variant;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final primary = variant == _DialogActionButtonVariant.primary;
    final radius = BorderRadius.circular(24);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: radius,
        child: Ink(
          height: dense ? 42 : 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: primary
                  ? const [Color(0xFFC7CE82), Color(0xFFAEB762)]
                  : const [Color(0xFFFFF4E3), Color(0xFFFFE7CA)],
            ),
            borderRadius: radius,
            border: Border.all(
              color: primary
                  ? _AddMemberPalette.sageDark
                  : _AddMemberPalette.line.withValues(alpha: 0.48),
              width: primary ? 1.7 : 1.4,
            ),
            boxShadow: primary
                ? const [
                    BoxShadow(
                      color: Color(0x286E7437),
                      offset: Offset(0, 3),
                      blurRadius: 8,
                      spreadRadius: -2,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _AddMemberPalette.ink,
                fontSize: dense ? 17 : 19,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogCloseButton extends StatelessWidget {
  const _DialogCloseButton({
    super.key,
    required this.dense,
    required this.onPressed,
  });

  final bool dense;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final hitSize = dense ? 48.0 : 52.0;
    final visualSize = dense ? 42.0 : 46.0;

    return Tooltip(
      message: '关闭',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: SizedBox(
          width: hitSize,
          height: hitSize,
          child: Center(
            child: Image.asset(
              FamilyPopupAssets.closeButton,
              width: visualSize,
              height: visualSize,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              isAntiAlias: true,
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider({required this.dense});

  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: dense ? 10 : 20),
      child: SizedBox(
        height: 2,
        width: double.infinity,
        child: const CustomPaint(painter: _DashedDividerPainter()),
      ),
    );
  }
}

class _DashedDividerPainter extends CustomPainter {
  const _DashedDividerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 10.0;
    const dashGap = 7.0;
    final paint = Paint()
      ..color = _AddMemberPalette.mutedLine
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2;

    var startX = 0.0;
    final y = size.height / 2;
    while (startX < size.width) {
      final endX = (startX + dashWidth).clamp(0.0, size.width);
      canvas.drawLine(Offset(startX, y), Offset(endX, y), paint);
      startX += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedDividerPainter oldDelegate) => false;
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _AddMemberPalette.error,
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
