import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/support_links.dart';
import '../../widgets/app_modal_shell.dart';
import '../../widgets/source_scaled_rrect_border.dart';

const String _aboutFrameAsset = 'assets/images/ui/setup/frame.webp';
const String _aboutCloseButtonAsset = 'assets/images/ui/family/12 (2).webp';
const String _aboutRowAsset = 'assets/images/ui/setup/7 (1).webp';
const String _aboutArrowAsset = 'assets/images/ui/setup/5 (2)_transparent.webp';
const String _aboutPrivacyIconAsset =
    'assets/images/ui/setup/about/icon_privacy.webp';
const String _aboutTermsIconAsset =
    'assets/images/ui/setup/about/icon_terms.webp';
const String _aboutSupportIconAsset =
    'assets/images/ui/setup/about/icon_support.webp';
const String _aboutDeleteIconAsset =
    'assets/images/ui/setup/about/icon_delete.webp';

// Taller than settings: version line + four action rows.
const double _aboutDialogDesignWidth = 441;
const double _aboutDialogDesignHeight = 620;
const double _aboutFrameSourceWidth = 1024;
const double _aboutFrameSourceHeight = 1536;
const double _aboutFrameCropLeft = 53;
const double _aboutFrameCropTop = 118;
const double _aboutFrameCropWidth = 946;
const double _aboutFrameCropHeight = 1159;
const double _aboutFrameDrawWidth =
    _aboutDialogDesignWidth * _aboutFrameSourceWidth / _aboutFrameCropWidth;
const double _aboutFrameDrawHeight =
    _aboutDialogDesignHeight * _aboutFrameSourceHeight / _aboutFrameCropHeight;
const double _aboutFrameDrawLeft =
    -_aboutFrameCropLeft * _aboutDialogDesignWidth / _aboutFrameCropWidth;
const double _aboutFrameDrawTop =
    -_aboutFrameCropTop * _aboutDialogDesignHeight / _aboutFrameCropHeight;

const Color _aboutTextColor = Color(0xFF30251D);

const AppModalLayout _aboutDialogLayout = AppModalLayout(
  mobileWidthFactor: 1.0,
  mobileMaxWidth: 430,
  mobileHeightFactor: 0.90,
  mobileMaxHeight: 680,
  tabletWidthFactor: 0.44,
  tabletMaxWidth: 540,
  tabletHeightFactor: 0.84,
  tabletMaxHeight: 760,
  contentAspectRatio: _aboutDialogDesignWidth / _aboutDialogDesignHeight,
);

/// Actions available from the About dialog (settings-style wood panel).
enum HomeAboutAction { privacy, terms, support, deleteAccount }

Future<HomeAboutAction?> showHomeAboutDialog(
  BuildContext context, {
  bool useRootNavigator = true,
}) {
  return showAppModalDialog<HomeAboutAction>(
    context: context,
    useRootNavigator: useRootNavigator,
    barrierLabel: 'home_about_dialog',
    blurSigma: 6,
    barrierTint: PickStarPetDialogTheme.barrierTint,
    beginScale: 0.96,
    beginYOffset: 16,
    pageBuilder: (dialogContext) {
      return _AboutDialogPanel(
        onClose: () => Navigator.of(dialogContext).pop(),
        onActionSelected: (action) => Navigator.of(dialogContext).pop(action),
      );
    },
  );
}

class _AboutDialogPanel extends StatelessWidget {
  const _AboutDialogPanel({
    required this.onClose,
    required this.onActionSelected,
  });

  final VoidCallback onClose;
  final ValueChanged<HomeAboutAction> onActionSelected;

  @override
  Widget build(BuildContext context) {
    return AppModalShell(
      layout: _aboutDialogLayout,
      minimumSafeArea: PickStarPetDialogGutter.mediumInsets,
      clipChild: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : _aboutDialogDesignWidth;
          final maxHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : _aboutDialogDesignHeight;
          final aspect = _aboutDialogDesignWidth / _aboutDialogDesignHeight;
          final panelWidth = math.min(maxWidth, maxHeight * aspect);
          final panelHeight = panelWidth / aspect;

          return Center(
            child: SizedBox(
              width: panelWidth,
              height: panelHeight,
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: _aboutDialogDesignWidth,
                  height: _aboutDialogDesignHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Positioned.fill(child: _AboutPanelFrame()),
                      Positioned(
                        left: 0,
                        top: 52,
                        right: 0,
                        height: 36,
                        child: Center(
                          child: Text(
                            '拾星小宠  ·  版本 ${SupportLinks.appVersionLabel}',
                            style: const TextStyle(
                              color: _aboutTextColor,
                              fontFamily: 'PickStarPetFont',
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 2,
                        width: 48,
                        height: 48,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onClose,
                          child: Image.asset(
                            _aboutCloseButtonAsset,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                      ),
                      _AboutActionTile(
                        top: 108,
                        title: '隐私政策',
                        iconAsset: _aboutPrivacyIconAsset,
                        onTap: () => onActionSelected(HomeAboutAction.privacy),
                      ),
                      _AboutActionTile(
                        top: 221,
                        title: '用户协议',
                        iconAsset: _aboutTermsIconAsset,
                        onTap: () => onActionSelected(HomeAboutAction.terms),
                      ),
                      _AboutActionTile(
                        top: 334,
                        title: '联系客服',
                        iconAsset: _aboutSupportIconAsset,
                        onTap: () => onActionSelected(HomeAboutAction.support),
                      ),
                      _AboutActionTile(
                        top: 447,
                        title: '删除账号',
                        iconAsset: _aboutDeleteIconAsset,
                        onTap: () =>
                            onActionSelected(HomeAboutAction.deleteAccount),
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

class _AboutPanelFrame extends StatelessWidget {
  const _AboutPanelFrame();

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            left: _aboutFrameDrawLeft,
            top: _aboutFrameDrawTop,
            width: _aboutFrameDrawWidth,
            height: _aboutFrameDrawHeight,
            child: Image.asset(
              _aboutFrameAsset,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.high,
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutActionTile extends StatelessWidget {
  const _AboutActionTile({
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
                  _aboutRowAsset,
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
                        color: _aboutTextColor,
                        fontFamily: 'PickStarPetFont',
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
                    _aboutArrowAsset,
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
