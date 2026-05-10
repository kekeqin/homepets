import 'package:flutter/material.dart';

import 'app_modal_shell.dart';

const AppModalLayout _defaultHomePetsDialogLayout = AppModalLayout(
  mobileWidthFactor: 0.84,
  mobileMaxWidth: 360,
  mobileHeightFactor: 0.72,
  mobileMaxHeight: 420,
  tabletWidthFactor: 0.36,
  tabletMaxWidth: 390,
  tabletHeightFactor: 0.58,
  tabletMaxHeight: 460,
);

typedef HomePetsDialogActionsBuilder =
    List<Widget> Function(BuildContext dialogContext);

Future<T?> showHomePetsDialog<T>({
  required BuildContext context,
  required String barrierLabel,
  required String title,
  required WidgetBuilder contentBuilder,
  required HomePetsDialogActionsBuilder actionsBuilder,
  bool useRootNavigator = true,
  bool barrierDismissible = true,
  AppModalLayout layout = _defaultHomePetsDialogLayout,
}) {
  return showAppModalDialog<T>(
    context: context,
    useRootNavigator: useRootNavigator,
    barrierDismissible: barrierDismissible,
    barrierLabel: barrierLabel,
    blurSigma: 6,
    barrierTint: HomePetsDialogTheme.barrierTint,
    beginScale: 0.95,
    beginYOffset: 16,
    pageBuilder: (dialogContext) {
      return HomePetsDialog(
        layout: layout,
        title: title,
        actions: actionsBuilder(dialogContext),
        child: contentBuilder(dialogContext),
      );
    },
  );
}

class HomePetsDialog extends StatelessWidget {
  const HomePetsDialog({
    super.key,
    required this.title,
    required this.child,
    required this.actions,
    this.background,
    this.layout = _defaultHomePetsDialogLayout,
    this.minimumSafeArea = const EdgeInsets.fromLTRB(16, 20, 16, 20),
    this.contentPadding = const EdgeInsets.fromLTRB(24, 24, 24, 22),
  });

  final String title;
  final Widget child;
  final List<Widget> actions;
  final Widget? background;
  final AppModalLayout layout;
  final EdgeInsets minimumSafeArea;
  final EdgeInsets contentPadding;

  @override
  Widget build(BuildContext context) {
    return AppModalShell(
      layout: layout,
      minimumSafeArea: minimumSafeArea,
      borderRadius: HomePetsDialogTheme.borderRadius,
      gradient: background == null ? HomePetsDialogTheme.shellGradient : null,
      border: background == null
          ? Border.all(color: HomePetsDialogTheme.panelBorder, width: 2)
          : null,
      boxShadow: HomePetsDialogTheme.shellShadow,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          if (background != null) Positioned.fill(child: background!),
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
