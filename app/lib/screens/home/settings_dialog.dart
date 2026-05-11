import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../widgets/app_modal_shell.dart';
import '../family/widgets/family_sprite_slice.dart';

const String _settingsDialogAsset = 'assets/images/ui/setup.png';
const Size _settingsDialogSheetSize = Size(1448, 1086);
const Rect _settingsDialogPanelRegion = Rect.fromLTWH(22, 22, 441, 512);
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
      backgroundColor: HomePetsDialogTheme.surfaceTop,
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
                        child: FamilySpriteSlice(
                          assetPath: _settingsDialogAsset,
                          sheetSize: _settingsDialogSheetSize,
                          region: _settingsDialogPanelRegion,
                          fit: BoxFit.fill,
                          sampleInset: 1,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                      Positioned(
                        left: 347,
                        top: 10,
                        width: 74,
                        height: 74,
                        child: _SettingsActionButton(
                          semanticLabel: '关闭设置',
                          borderRadius: BorderRadius.circular(999),
                          onPressed: onClose,
                        ),
                      ),
                      Positioned(
                        left: 22,
                        top: 93,
                        width: 397,
                        height: 100,
                        child: _SettingsActionButton(
                          semanticLabel: '编辑资料',
                          borderRadius: BorderRadius.circular(24),
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
                          semanticLabel: '关于',
                          borderRadius: BorderRadius.circular(24),
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
                          semanticLabel: '退出登录',
                          borderRadius: BorderRadius.circular(24),
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

class _SettingsActionButton extends StatefulWidget {
  const _SettingsActionButton({
    required this.semanticLabel,
    required this.borderRadius,
    required this.onPressed,
  });

  final String semanticLabel;
  final BorderRadius borderRadius;
  final VoidCallback onPressed;

  @override
  State<_SettingsActionButton> createState() => _SettingsActionButtonState();
}

class _SettingsActionButtonState extends State<_SettingsActionButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) {
      return;
    }
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 90),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: _pressed ? const Color(0x14FFFFFF) : Colors.transparent,
              borderRadius: widget.borderRadius,
            ),
          ),
        ),
      ),
    );
  }
}
