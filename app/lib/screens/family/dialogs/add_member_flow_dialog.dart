import 'package:flutter/material.dart';

import '../../../models/pet_artwork.dart';

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

Future<AddMemberFlowResult?> showAddMemberFlowDialog(BuildContext context) {
  return showDialog<AddMemberFlowResult>(
    context: context,
    builder: (_) => const AddMemberFlowDialog(),
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

  String? _selectedPetType;
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
    return AlertDialog(
      backgroundColor: const Color(0xFFF8EED8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
      title: const Text(
        '添加成员',
        style: TextStyle(
          color: Color(0xFF5A3A21),
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                key: const Key('family_add_member_nickname_field'),
                controller: _nicknameController,
                maxLength: 20,
                autofocus: true,
                onChanged: (_) {
                  if (_nicknameError != null) {
                    setState(() => _nicknameError = null);
                  }
                },
                decoration: _inputDecoration(
                  labelText: '成员昵称',
                  hintText: '例如：小宝',
                  errorText: _nicknameError,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '选择宠物',
                style: TextStyle(
                  color: Color(0xFF5A3A21),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '为新成员挑选一种展示宠物，并提前取好名字。',
                style: TextStyle(
                  color: const Color(0xFF6C4C33).withValues(alpha: 0.9),
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final petType in selectablePetTypes)
                    _buildPetOption(petType),
                ],
              ),
              if (_petTypeError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _petTypeError!,
                  style: const TextStyle(
                    color: Color(0xFFB0483D),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                key: const Key('family_add_member_pet_name_field'),
                controller: _petNameController,
                maxLength: 20,
                onChanged: (_) {
                  _petNameDirty = true;
                  if (_petNameError != null) {
                    setState(() => _petNameError = null);
                  }
                },
                decoration: _inputDecoration(
                  labelText: '宠物名字',
                  hintText: '例如：团团',
                  errorText: _petNameError,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          key: const Key('family_add_member_submit_button'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF7A5733),
            foregroundColor: Colors.white,
          ),
          onPressed: _submit,
          child: const Text('确认添加'),
        ),
      ],
    );
  }

  Widget _buildPetOption(String petType) {
    final selected = _selectedPetType == petType;
    final poseIndex = deterministicPetPoseIndex(petType, petType.hashCode);
    final assetPath = petAvatarAssetPath(petType, poseIndex);

    return GestureDetector(
      key: Key('family_add_member_pet_type_$petType'),
      onTap: () => _selectPetType(petType),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 98,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFFFF8EF)
              : Colors.white.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFF7A5733) : const Color(0xFFE6D6C2),
            width: selected ? 1.8 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0x22000000,
              ).withValues(alpha: selected ? 0.12 : 0.06),
              blurRadius: selected ? 10 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                shape: BoxShape.circle,
              ),
              child: Image.asset(assetPath, fit: BoxFit.contain),
            ),
            const SizedBox(height: 8),
            Text(
              petTypeLabel(petType),
              style: TextStyle(
                color: selected
                    ? const Color(0xFF7A5733)
                    : const Color(0xFF6C4C33),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String labelText,
    required String hintText,
    required String? errorText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      errorText: errorText,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.72),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: const Color(0xFF7A5733).withValues(alpha: 0.4),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: const Color(0xFF7A5733).withValues(alpha: 0.4),
        ),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: Color(0xFF7A5733), width: 1.3),
      ),
    );
  }
}
