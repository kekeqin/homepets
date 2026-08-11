import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../widgets/app_modal_shell.dart';
import '../../widgets/pickstarpet_button.dart';

const String _logoutFrameAsset = 'assets/images/ui/setup/frame.webp';
const String _logoutBackButtonAsset =
    'assets/images/ui/setup/about/icon_back.webp';
const String _logoutDoorIconAsset =
    'assets/images/ui/setup/wooden_door_transparent.webp';

const double _logoutDialogDesignWidth = 441;
// Keep panel height tight to title + icon + copy + buttons.
const double _logoutDialogDesignHeight = 328;
const double _logoutFrameSourceWidth = 1024;
const double _logoutFrameSourceHeight = 1536;
const double _logoutFrameCropLeft = 53;
const double _logoutFrameCropTop = 118;
const double _logoutFrameCropWidth = 946;
const double _logoutFrameCropHeight = 1159;
const double _logoutFrameDrawWidth =
    _logoutDialogDesignWidth * _logoutFrameSourceWidth / _logoutFrameCropWidth;
const double _logoutFrameDrawHeight =
    _logoutDialogDesignHeight *
    _logoutFrameSourceHeight /
    _logoutFrameCropHeight;
const double _logoutFrameDrawLeft =
    -_logoutFrameCropLeft * _logoutDialogDesignWidth / _logoutFrameCropWidth;
const double _logoutFrameDrawTop =
    -_logoutFrameCropTop * _logoutDialogDesignHeight / _logoutFrameCropHeight;

const Color _logoutTextColor = Color(0xFF30251D);
const Color _logoutMutedColor = Color(0xFF6F563D);

const AppModalLayout _logoutDialogLayout = AppModalLayout(
  mobileWidthFactor: 1.0,
  mobileMaxWidth: 400,
  mobileHeightFactor: 0.52,
  mobileMaxHeight: 380,
  tabletWidthFactor: 0.36,
  tabletMaxWidth: 460,
  tabletHeightFactor: 0.46,
  tabletMaxHeight: 420,
  contentAspectRatio: _logoutDialogDesignWidth / _logoutDialogDesignHeight,
);

/// Settings-style wood panel to confirm logout.
///
/// Returns `true` when the user confirms logout; `false` when cancelled.
Future<bool> showLogoutConfirmDialog(
  BuildContext context, {
  bool useRootNavigator = true,
}) async {
  final result = await showAppModalDialog<bool>(
    context: context,
    useRootNavigator: useRootNavigator,
    barrierLabel: 'logout_confirm_dialog',
    blurSigma: 6,
    barrierTint: PickStarPetDialogTheme.barrierTint,
    beginScale: 0.96,
    beginYOffset: 16,
    pageBuilder: (dialogContext) {
      return _LogoutConfirmDialogPanel(
        onCancel: () => Navigator.of(dialogContext).pop(false),
        onConfirm: () => Navigator.of(dialogContext).pop(true),
      );
    },
  );
  return result == true;
}

class _LogoutConfirmDialogPanel extends StatelessWidget {
  const _LogoutConfirmDialogPanel({
    required this.onCancel,
    required this.onConfirm,
  });

  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return AppModalShell(
      layout: _logoutDialogLayout,
      minimumSafeArea: PickStarPetDialogGutter.mediumInsets,
      clipChild: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : _logoutDialogDesignWidth;
          final maxHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : _logoutDialogDesignHeight;
          final aspect = _logoutDialogDesignWidth / _logoutDialogDesignHeight;
          final panelWidth = math.min(maxWidth, maxHeight * aspect);
          final panelHeight = panelWidth / aspect;

          return Center(
            child: SizedBox(
              width: panelWidth,
              height: panelHeight,
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: _logoutDialogDesignWidth,
                  height: _logoutDialogDesignHeight,
                  child: Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      const Positioned.fill(child: _LogoutPanelFrame()),
                      Positioned(
                        left: 30,
                        top: 28,
                        right: 30,
                        // Leave room for bottom action buttons.
                        bottom: 82,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              '退出登录',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _logoutTextColor,
                                fontFamily: 'PickStarPetFont',
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                height: 1.05,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Center(
                              child: Image.asset(
                                _logoutDoorIconAsset,
                                width: 72,
                                height: 72,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              '确定要退出当前账号吗？',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _logoutTextColor,
                                fontFamily: 'PickStarPetFont',
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              '退出后需要重新登录，才能继续管理家庭和宠物。',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _logoutMutedColor,
                                fontFamily: 'PickStarPetFont',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        left: 30,
                        right: 30,
                        bottom: 22,
                        child: Row(
                          children: [
                            Expanded(
                              child: PickStarPetButton(
                                label: '取消',
                                variant: PickStarPetButtonVariant.secondary,
                                height: 48,
                                onPressed: onCancel,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: PickStarPetButton(
                                label: '确认退出',
                                height: 48,
                                onPressed: onConfirm,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 20,
                        left: 20,
                        width: 38,
                        height: 38,
                        child: Semantics(
                          button: true,
                          label: '返回',
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: onCancel,
                            child: Image.asset(
                              _logoutBackButtonAsset,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
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

class _LogoutPanelFrame extends StatelessWidget {
  const _LogoutPanelFrame();

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            left: _logoutFrameDrawLeft,
            top: _logoutFrameDrawTop,
            width: _logoutFrameDrawWidth,
            height: _logoutFrameDrawHeight,
            child: Image.asset(
              _logoutFrameAsset,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.high,
            ),
          ),
        ],
      ),
    );
  }
}
