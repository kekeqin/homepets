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
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 344),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFF5E5), Color(0xFFF8EAD0)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFFD8A2), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5A3A21).withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        '添加成员',
                        style: TextStyle(
                          color: Color(0xFF5A3A21),
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const _SectionLabel(text: '成员名称'),
                    const SizedBox(height: 6),
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
                        hintText: '小宝',
                        errorText: _nicknameError,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const _SectionLabel(text: '选择宠物'),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final petType in selectablePetTypes)
                            _buildPetOption(petType),
                        ],
                      ),
                    ),
                    if (_petTypeError != null) ...[
                      const SizedBox(height: 8),
                      Center(child: _ErrorText(_petTypeError!)),
                    ],
                    const SizedBox(height: 12),
                    const _SectionLabel(text: '宠物名字'),
                    const SizedBox(height: 6),
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
                        hintText: '团团',
                        errorText: _petNameError,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF8A7356),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            child: const Text('取消'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            key: const Key('family_add_member_submit_button'),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF9B6415),
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(40),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              elevation: 0,
                            ),
                            onPressed: _submit,
                            child: const Text('确认添加'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: _DialogCloseButton(
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
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
        width: 78,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFFFF1D8)
              : Colors.white.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: selected ? const Color(0xFF9B6415) : const Color(0xFFE6D6C2),
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0x22000000,
              ).withValues(alpha: selected ? 0.12 : 0.06),
              blurRadius: selected ? 8 : 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 42,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                shape: BoxShape.circle,
              ),
              child: Image.asset(assetPath, fit: BoxFit.contain),
            ),
            const SizedBox(height: 6),
            Text(
              petTypeLabel(petType),
              style: TextStyle(
                color: selected
                    ? const Color(0xFF7A5733)
                    : const Color(0xFF6C4C33),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            if (selected) ...[
              const SizedBox(height: 3),
              const Icon(
                Icons.check_circle_rounded,
                size: 14,
                color: Color(0xFF2E7D32),
              ),
            ],
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required String? errorText,
  }) {
    return InputDecoration(
      hintText: hintText,
      errorText: errorText,
      counterStyle: TextStyle(
        color: const Color(0xFF7A5733).withValues(alpha: 0.56),
        fontSize: 11,
      ),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.82),
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: const Color(0xFF7A5733).withValues(alpha: 0.22),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: const Color(0xFF7A5733).withValues(alpha: 0.22),
        ),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(15)),
        borderSide: BorderSide(color: Color(0xFF9B6415), width: 1.4),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF5A3A21),
        fontSize: 14,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _DialogCloseButton extends StatelessWidget {
  const _DialogCloseButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFF3DC),
      shape: const CircleBorder(
        side: BorderSide(color: Color(0xFFFFC982), width: 1.2),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: const SizedBox(
          width: 30,
          height: 30,
          child: Icon(Icons.close_rounded, size: 18, color: Color(0xFF8A5414)),
        ),
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFFB0483D),
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
