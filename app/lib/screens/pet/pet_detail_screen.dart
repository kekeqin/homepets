import 'package:flutter/material.dart';

import '../../models/pet.dart';
import '../../widgets/app_modal_shell.dart';
import 'widgets/pet_detail_view.dart';

Future<void> showPetDetailDialog(
  BuildContext context, {
  required Pet pet,
  String? avatarAssetPath,
  bool useRootNavigator = true,
}) {
  return showAppModalDialog<void>(
    context: context,
    useRootNavigator: useRootNavigator,
    barrierLabel: '宠物详情',
    blurSigma: 7,
    barrierTint: const Color(0x32674A30),
    transitionDuration: const Duration(milliseconds: 260),
    beginScale: 0.92,
    beginYOffset: 22,
    pageBuilder: (dialogContext) {
      return AppModalShell(
        layout: AppModalLayouts.petDetail,
        minimumSafeArea: const EdgeInsets.fromLTRB(12, 16, 12, 16),
        boxShadow: [
          BoxShadow(
            color: const Color(0x28604429),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
        clipChild: false,
        child: PetDetailView(
          pet: pet,
          avatarAssetPath: avatarAssetPath,
          embedded: true,
          onClose: () => Navigator.of(dialogContext).pop(),
        ),
      );
    },
  );
}

class PetDetailScreen extends StatelessWidget {
  const PetDetailScreen({super.key, required this.pet, this.avatarAssetPath});

  final Pet pet;
  final String? avatarAssetPath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDCE5EA),
      body: PetDetailView(
        pet: pet,
        avatarAssetPath: avatarAssetPath,
        onClose: () => Navigator.of(context).maybePop(),
      ),
    );
  }
}
