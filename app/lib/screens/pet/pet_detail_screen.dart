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
              child: ClipRect(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(
                    sigmaX: 8.0 * backdropOpacity,
                    sigmaY: 8.0 * backdropOpacity,
                  ),
                  child: const SizedBox.expand(),
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
      backgroundColor: const Color(0xFFDCE5EA),
      body: PetDetailView(
        pet: pet,
        onClose: () => Navigator.of(context).maybePop(),
      ),
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
    final panelWidth = math.min(size.width * (isTablet ? 0.45 : 0.98), 448.0);
    final panelMaxHeight = math.min(
      size.height * 0.9,
      isTablet ? 760.0 : 700.0,
    );

    return SafeArea(
      child: Center(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {},
          child: SizedBox(
            width: panelWidth,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: panelMaxHeight),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF20303A).withValues(alpha: 0.22),
                      blurRadius: 26,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: PetDetailView(
                  pet: pet,
                  embedded: true,
                  onClose: onClose,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
