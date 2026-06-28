import 'package:flutter/material.dart';

import 'app_modal_shell.dart';

const AppModalLayout _defaultPickStarPetDialogLayout = AppModalLayout(
  mobileWidthFactor: 1.0,
  mobileMaxWidth: 360,
  mobileHeightFactor: 0.72,
  mobileMaxHeight: 420,
  tabletWidthFactor: 0.36,
  tabletMaxWidth: 390,
  tabletHeightFactor: 0.58,
  tabletMaxHeight: 460,
);

typedef PickStarPetDialogActionsBuilder =
    List<Widget> Function(BuildContext dialogContext);

const Color _homePetsDialogInnerBorder = Color(0xFFFFF8E8);
const BorderRadius _homePetsDialogInnerBorderRadius = BorderRadius.all(
  Radius.circular(23),
);

Future<T?> showPickStarPetDialog<T>({
  required BuildContext context,
  required String barrierLabel,
  required String title,
  required WidgetBuilder contentBuilder,
  required PickStarPetDialogActionsBuilder actionsBuilder,
  bool useRootNavigator = true,
  bool barrierDismissible = true,
  AppModalLayout layout = _defaultPickStarPetDialogLayout,
  EdgeInsets minimumSafeArea = PickStarPetDialogGutter.mediumInsets,
  bool showInnerBorder = true,
}) {
  return showAppModalDialog<T>(
    context: context,
    useRootNavigator: useRootNavigator,
    barrierDismissible: barrierDismissible,
    barrierLabel: barrierLabel,
    blurSigma: 6,
    barrierTint: PickStarPetDialogTheme.barrierTint,
    beginScale: 0.95,
    beginYOffset: 16,
    pageBuilder: (dialogContext) {
      return PickStarPetDialog(
        layout: layout,
        minimumSafeArea: minimumSafeArea,
        title: title,
        actions: actionsBuilder(dialogContext),
        showInnerBorder: showInnerBorder,
        child: contentBuilder(dialogContext),
      );
    },
  );
}

class PickStarPetDialog extends StatelessWidget {
  const PickStarPetDialog({
    super.key,
    required this.title,
    required this.child,
    required this.actions,
    this.background,
    this.layout = _defaultPickStarPetDialogLayout,
    this.minimumSafeArea = PickStarPetDialogGutter.mediumInsets,
    this.contentPadding = const EdgeInsets.fromLTRB(24, 24, 24, 22),
    this.showInnerBorder = true,
  });

  final String title;
  final Widget child;
  final List<Widget> actions;
  final Widget? background;
  final AppModalLayout layout;
  final EdgeInsets minimumSafeArea;
  final EdgeInsets contentPadding;
  final bool showInnerBorder;

  @override
  Widget build(BuildContext context) {
    return AppModalShell(
      layout: layout,
      minimumSafeArea: minimumSafeArea,
      borderRadius: PickStarPetDialogTheme.borderRadius,
      backgroundColor: background == null ? null : Colors.transparent,
      gradient: background == null
          ? PickStarPetDialogTheme.shellGradient
          : null,
      border: background == null
          ? Border.all(
              color: PickStarPetDialogTheme.outerBorderColor,
              width: PickStarPetDialogTheme.outerBorderWidth,
            )
          : null,
      boxShadow: PickStarPetDialogTheme.shellShadow,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          if (background != null) Positioned.fill(child: background!),
          if (background == null && showInnerBorder)
            Positioned.fill(
              child: IgnorePointer(
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: _homePetsDialogInnerBorderRadius,
                      border: Border.all(
                        color: _homePetsDialogInnerBorder,
                        width: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: contentPadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                    color: Color(0xFF4D3623),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 20),
                child,
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    for (var index = 0; index < actions.length; index++) ...[
                      if (index > 0) const SizedBox(width: 12),
                      Flexible(child: actions[index]),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
