import 'package:flutter/material.dart';

import '../../models/pet.dart';
import '../../widgets/app_modal_shell.dart';
import 'widgets/pet_detail_view.dart';

Future<void> showPetDetailDialog(
  BuildContext context, {
  required Pet pet,
  bool useRootNavigator = true,
}) {
  return showAppModalDialog<void>(
    context: context,
    useRootNavigator: useRootNavigator,
    barrierLabel: '宠物详情',
    transitionDuration: const Duration(milliseconds: 260),
    beginScale: 0.92,
    beginYOffset: 22,
    pageBuilder: (dialogContext) {
      return AppModalShell(
        layout: AppModalLayouts.petDetail,
        minimumSafeArea: const EdgeInsets.fromLTRB(12, 16, 12, 16),
        backgroundColor: Colors.transparent,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF20303A).withValues(alpha: 0.22),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
        clipChild: false,
        child: PetDetailView(
          pet: pet,
          embedded: true,
          onClose: () => Navigator.of(dialogContext).pop(),
        ),
      );
    },
  );
}

class PetDetailScreen extends StatelessWidget {
  const PetDetailScreen({super.key, required this.pet});

  final Pet pet;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDCE5EA),
      body: PetDetailView(
        pet: pet,
        onClose: () => Navigator.of(context).maybePop(),
      ),
    );
  }
}
