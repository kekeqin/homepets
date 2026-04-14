import 'package:flutter/material.dart';

import '../../../models/pet_artwork.dart';

Future<String?> showPetSelectionDialog(
  BuildContext context, {
  required String nickname,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PetSelectionDialog(nickname: nickname),
  );
}

class PetSelectionDialog extends StatefulWidget {
  const PetSelectionDialog({super.key, required this.nickname});

  final String nickname;

  @override
  State<PetSelectionDialog> createState() => _PetSelectionDialogState();
}

class _PetSelectionDialogState extends State<PetSelectionDialog> {
  String? _selectedType;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: const Color(0xFFF8EED8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '选择宠物',
          style: TextStyle(
            color: Color(0xFF5A3A21),
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '为${widget.nickname}选择 1 种展示宠物',
                style: const TextStyle(color: Color(0xFF6C4C33), fontSize: 14),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: selectablePetTypes.map(_buildOption).toList(),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF7A5733),
              foregroundColor: Colors.white,
            ),
            onPressed: _selectedType == null
                ? null
                : () => Navigator.of(context).pop(_selectedType),
            child: const Text('确认选择'),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(String petType) {
    final selected = _selectedType == petType;
    final poseIndex = deterministicPetPoseIndex(petType, petType.hashCode);
    final assetPath = petAvatarAssetPath(petType, poseIndex);

    return GestureDetector(
      onTap: () => setState(() => _selectedType = petType),
      child: Container(
        width: 92,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFF7A5733) : Colors.transparent,
            width: 2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(assetPath, width: 56, height: 56, fit: BoxFit.contain),
            const SizedBox(height: 6),
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
}
