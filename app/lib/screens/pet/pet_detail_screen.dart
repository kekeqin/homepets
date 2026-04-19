import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../models/pet.dart';
import 'widgets/pet_detail_view.dart';

Future<void> showPetDetailDialog(
  BuildContext context, {
  required Pet pet,
  bool useRootNavigator = true,
}) {
  return showGeneralDialog<void>(
    context: context,
    useRootNavigator: useRootNavigator,
    barrierLabel: '宠物详情',
    barrierDismissible: true,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return _PetDetailDialogSheet(
        pet: pet,
        onClose: () => Navigator.of(dialogContext).pop(),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final progress = Curves.easeInOutCubicEmphasized.transform(
        animation.value,
      );
      final backdropOpacity = Curves.easeOutCubic.transform(animation.value);
      final panelScale = ui.lerpDouble(0.92, 1.0, progress)!;
      final panelTranslateY = ui.lerpDouble(22, 0, progress)!;

      return Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.36 * backdropOpacity),
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(
                      sigmaX: 5.0 * backdropOpacity,
                      sigmaY: 5.0 * backdropOpacity,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              ignoring: animation.value == 0,
              child: Opacity(
                opacity: backdropOpacity,
                child: Transform.translate(
                  offset: Offset(0, panelTranslateY),
                  child: Transform.scale(scale: panelScale, child: child),
                ),
              ),
            ),
          ),
        ],
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
      backgroundColor: const Color(0xFFF8EEDF),
      appBar: AppBar(
        title: const Text(
          '宠物详情',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: const Color(0xFFF8EEDF),
        foregroundColor: const Color(0xFF664625),
        surfaceTintColor: const Color(0xFFF8EEDF),
        scrolledUnderElevation: 0,
      ),
      body: PetDetailView(pet: pet),
    );
  }
}

class _PetDetailDialogSheet extends StatelessWidget {
  const _PetDetailDialogSheet({required this.pet, required this.onClose});

  final Pet pet;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isTablet = size.width >= 900;
    final panelWidth = math.min(size.width * (isTablet ? 0.58 : 0.92), 620.0);
    final panelHeight = math.min(size.height * 0.82, isTablet ? 760.0 : 680.0);

    return SafeArea(
      child: Center(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {},
          child: SizedBox(
            width: panelWidth,
            height: panelHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3A2514).withValues(alpha: 0.22),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: PetDetailView(pet: pet, embedded: true, onClose: onClose),
            ),
          ),
        ),
      ),
    );
  }
}
