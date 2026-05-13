import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../widgets/app_modal_shell.dart';

const String _settingsDialogPanelAsset =
    'assets/images/ui/setup/setup_panel.png';
const double _settingsDialogDesignWidth = 441;
const double _settingsDialogDesignHeight = 512;

const AppModalLayout _settingsDialogLayout = AppModalLayout(
  mobileWidthFactor: 0.94,
  mobileMaxWidth: 430,
  mobileHeightFactor: 0.86,
  mobileMaxHeight: 560,
  tabletWidthFactor: 0.44,
  tabletMaxWidth: 540,
  tabletHeightFactor: 0.80,
  tabletMaxHeight: 660,
);

enum HomeSettingsAction { editProfile, about, logout }

Future<HomeSettingsAction?> showSettingsDialog(
  BuildContext context, {
  bool useRootNavigator = true,
}) {
  return showAppModalDialog<HomeSettingsAction>(
    context: context,
    useRootNavigator: useRootNavigator,
    barrierLabel: 'settings_dialog',
    blurSigma: 6,
    barrierTint: HomePetsDialogTheme.barrierTint,
    beginScale: 0.96,
    beginYOffset: 16,
    pageBuilder: (dialogContext) {
      return _SettingsDialogPanel(
        onClose: () => Navigator.of(dialogContext).pop(),
        onActionSelected: (action) => Navigator.of(dialogContext).pop(action),
      );
    },
  );
}

class _SettingsDialogPanel extends StatelessWidget {
  const _SettingsDialogPanel({
    required this.onClose,
    required this.onActionSelected,
  });

  final VoidCallback onClose;
  final ValueChanged<HomeSettingsAction> onActionSelected;

  @override
  Widget build(BuildContext context) {
    return AppModalShell(
      layout: _settingsDialogLayout,
      minimumSafeArea: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      clipChild: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : _settingsDialogDesignWidth;
          final maxHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : _settingsDialogDesignHeight;
          final aspect =
              _settingsDialogDesignWidth / _settingsDialogDesignHeight;
          final panelWidth = math.min(maxWidth, maxHeight * aspect);
          final panelHeight = panelWidth / aspect;

          return Center(
            child: SizedBox(
              width: panelWidth,
              height: panelHeight,
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: _settingsDialogDesignWidth,
                  height: _settingsDialogDesignHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Positioned.fill(
                        child: Image(
                          image: AssetImage(_settingsDialogPanelAsset),
                          fit: BoxFit.fill,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                      Positioned(
                        left: 347,
                        top: 10,
                        width: 74,
                        height: 74,
                        child: _SettingsActionButton(
                          semanticLabel: '\u5173\u95ed\u8bbe\u7f6e',
                          onPressed: onClose,
                        ),
                      ),
                      Positioned(
                        left: 22,
                        top: 93,
                        width: 397,
                        height: 100,
                        child: _SettingsActionButton(
                          semanticLabel: '\u7f16\u8f91\u8d44\u6599',
                          onPressed: () =>
                              onActionSelected(HomeSettingsAction.editProfile),
                        ),
                      ),
                      Positioned(
                        left: 22,
                        top: 202,
                        width: 397,
                        height: 100,
                        child: _SettingsActionButton(
                          semanticLabel: '\u5173\u4e8e',
                          onPressed: () =>
                              onActionSelected(HomeSettingsAction.about),
                        ),
                      ),
                      Positioned(
                        left: 22,
                        top: 311,
                        width: 397,
                        height: 100,
                        child: _SettingsActionButton(
                          semanticLabel: '\u9000\u51fa\u767b\u5f55',
                          onPressed: () =>
                              onActionSelected(HomeSettingsAction.logout),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SettingsActionButton extends StatelessWidget {
  const _SettingsActionButton({
    required this.semanticLabel,
    required this.onPressed,
  });

  final String semanticLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onPressed,
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}
