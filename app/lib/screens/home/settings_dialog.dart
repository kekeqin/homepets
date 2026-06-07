import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../widgets/app_modal_shell.dart';
import '../../widgets/source_scaled_rrect_border.dart';

const String _settingsFrameAsset = 'assets/images/ui/setup/frame.png';
const String _settingsCloseButtonAsset =
    'assets/images/ui/setup/close_button_transparent.png';
const String _settingsEditProfileInputAsset =
    'assets/images/ui/setup/7 (1).png';
const String _settingsEditProfileIconAsset =
    'assets/images/ui/setup/contact_notebook_pencil_transparent.png';
const String _settingsInputArrowAsset =
    'assets/images/ui/setup/5 (2)_transparent.png';
const String _settingsAboutIconAsset =
    'assets/images/ui/setup/question_bubble_transparent.png';
const String _settingsLogoutIconAsset =
    'assets/images/ui/setup/wooden_door_transparent.png';
const double _settingsDialogDesignWidth = 441;
const double _settingsDialogDesignHeight = 512;
const double _settingsFrameSourceWidth = 1024;
const double _settingsFrameSourceHeight = 1536;
const double _settingsFrameCropLeft = 53;
const double _settingsFrameCropTop = 118;
const double _settingsFrameCropWidth = 946;
const double _settingsFrameCropHeight = 1159;
const double _settingsFrameDrawWidth =
    _settingsDialogDesignWidth *
    _settingsFrameSourceWidth /
    _settingsFrameCropWidth;
const double _settingsFrameDrawHeight =
    _settingsDialogDesignHeight *
    _settingsFrameSourceHeight /
    _settingsFrameCropHeight;
const double _settingsFrameDrawLeft =
    -_settingsFrameCropLeft *
    _settingsDialogDesignWidth /
    _settingsFrameCropWidth;
const double _settingsFrameDrawTop =
    -_settingsFrameCropTop *
    _settingsDialogDesignHeight /
    _settingsFrameCropHeight;

const Color _settingsTextColor = Color(0xFF30251D);

const AppModalLayout _settingsDialogLayout = AppModalLayout(
  mobileWidthFactor: 1.0,
  mobileMaxWidth: 430,
  mobileHeightFactor: 0.86,
  mobileMaxHeight: 560,
  tabletWidthFactor: 0.44,
  tabletMaxWidth: 540,
  tabletHeightFactor: 0.80,
  tabletMaxHeight: 660,
  contentAspectRatio: _settingsDialogDesignWidth / _settingsDialogDesignHeight,
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
      minimumSafeArea: HomePetsDialogGutter.mediumInsets,
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
                      const Positioned.fill(child: _SettingsPanelFrame()),
                      const Positioned(
                        left: 0,
                        top: 36,
                        right: 0,
                        height: 48,
                        child: Center(
                          child: Text(
                            '设置',
                            style: TextStyle(
                              color: _settingsTextColor,
                              fontFamily: 'HomePetsFont',
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 340,
                        top: -28,
                        width: 132,
                        height: 132,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onClose,
                          child: Image.asset(
                            _settingsCloseButtonAsset,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                      ),
                      _SettingsActionTile(
                        top: 116,
                        title: '编辑资料',
                        iconAsset: _settingsEditProfileIconAsset,
                        onTap: () =>
                            onActionSelected(HomeSettingsAction.editProfile),
                      ),
                      _SettingsActionTile(
                        top: 229,
                        title: '关于',
                        iconAsset: _settingsAboutIconAsset,
                        onTap: () => onActionSelected(HomeSettingsAction.about),
                      ),
                      _SettingsActionTile(
                        top: 344,
                        title: '退出登录',
                        iconAsset: _settingsLogoutIconAsset,
                        onTap: () =>
                            onActionSelected(HomeSettingsAction.logout),
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

class _SettingsPanelFrame extends StatelessWidget {
  const _SettingsPanelFrame();

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            left: _settingsFrameDrawLeft,
            top: _settingsFrameDrawTop,
            width: _settingsFrameDrawWidth,
            height: _settingsFrameDrawHeight,
            child: Image.asset(
              _settingsFrameAsset,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.high,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  const _SettingsActionTile({
    required this.top,
    required this.title,
    required this.iconAsset,
    required this.onTap,
  });

  final double top;
  final String title;
  final String iconAsset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 34,
      top: top,
      width: 373,
      height: 100,
      child: Semantics(
        button: true,
        label: title,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                Image.asset(
                  _settingsEditProfileInputAsset,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.high,
                ),
                const Positioned.fill(
                  child: IgnorePointer(
                    child: SourceScaledRRectBorder(
                      sourceSize: Size(409, 97),
                      sourceRect: Rect.fromLTRB(6, 4, 403, 91),
                      sourceRadius: Radius.elliptical(16, 18),
                      strokeWidth: 2.1,
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: -1,
                  width: 102,
                  height: 102,
                  child: Image.asset(
                    iconAsset,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                Positioned(
                  left: 96,
                  top: 0,
                  bottom: 0,
                  right: 68,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _settingsTextColor,
                        fontFamily: 'HomePetsFont',
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 23,
                  top: 24,
                  width: 24,
                  height: 52,
                  child: Image.asset(
                    _settingsInputArrowAsset,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
