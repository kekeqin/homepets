import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'member_profile_screen.dart';
import 'widgets/member_profile_common.dart';

Future<void> showMemberDetailDialog(
  BuildContext context, {
  required int memberId,
  required String nickname,
  required String role,
  bool useRootNavigator = true,
}) {
  return showGeneralDialog<void>(
    context: context,
    useRootNavigator: useRootNavigator,
    barrierLabel: '\u6210\u5458\u8be6\u60c5',
    barrierDismissible: true,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return _MemberDetailDialogSheet(
        memberId: memberId,
        nickname: nickname,
        role: role,
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final progress = Curves.easeInOutCubicEmphasized.transform(
        animation.value,
      );
      final backdropOpacity = Curves.easeOutCubic.transform(animation.value);
      final panelScale = ui.lerpDouble(0.94, 1.0, progress)!;
      final panelTranslateY = ui.lerpDouble(18, 0, progress)!;

      return Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).maybePop(),
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

class MemberDetailScreen extends StatelessWidget {
  const MemberDetailScreen({
    super.key,
    required this.memberId,
    required this.nickname,
    required this.role,
    this.embedded = false,
  });

  final int memberId;
  final String nickname;
  final String role;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return MemberProfileScreen(
      memberId: memberId,
      nickname: nickname,
      role: role,
      embedded: embedded,
    );
  }
}

class _MemberDetailDialogSheet extends StatelessWidget {
  const _MemberDetailDialogSheet({
    required this.memberId,
    required this.nickname,
    required this.role,
  });

  final int memberId;
  final String nickname;
  final String role;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isTablet = size.width >= 900;
    final panelWidth = math.min(
      size.width * (isTablet ? 0.68 : 0.9),
      isTablet ? 860.0 : 500.0,
    );
    final panelMaxHeight = math.min(
      size.height * (isTablet ? 0.88 : 0.84),
      isTablet ? 920.0 : 780.0,
    );
    final borderRadius = BorderRadius.circular(isTablet ? 34 : 30);

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 24, 16, 24),
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
                  color: MemberProfileColors.surface,
                  borderRadius: borderRadius,
                  border: Border.all(color: MemberProfileColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x33292A18),
                      blurRadius: 48,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: borderRadius,
                  child: MemberDetailScreen(
                    memberId: memberId,
                    nickname: nickname,
                    role: role,
                    embedded: true,
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
