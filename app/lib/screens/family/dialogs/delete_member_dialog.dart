import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../widgets/app_modal_shell.dart';
import '../../../widgets/pickstarpet_button.dart';
import '../../../widgets/source_scaled_rrect_border.dart';
import '../widgets/family_sprite_slice.dart';

const String _deleteMemberDialogAsset =
    'assets/images/ui/sprites/delete_member_dialog_sprites.png';
const Size _deleteMemberDialogSheetSize = Size(1536, 1024);

const Rect _deleteMemberTrashRegion = Rect.fromLTWH(99, 698, 110, 115);
const Rect _deleteMemberIllustrationRegion = Rect.fromLTWH(284, 818, 211, 134);
const Rect _deleteMemberCancelButtonRegion = Rect.fromLTWH(639, 856, 257, 102);
const Rect _deleteMemberConfirmButtonRegion = Rect.fromLTWH(
  1005,
  856,
  258,
  102,
);

const String _deleteMemberTaskPanelAsset = 'assets/images/ui/task/33.png';
const double _deleteMemberTaskPanelSourceWidth = 1149;
const double _deleteMemberTaskPanelSourceHeight = 1369;
const double _deleteMemberTaskPanelVisibleLeftInset = 48;
const double _deleteMemberTaskPanelVisibleRightInset = 51;
const Color _deleteMemberTaskPanelBorderColor = Color(0xFF6A3D20);
const String _deleteMemberFontFamily = 'PickStarPetFont';
const Color _deleteMemberTextColor = Color(0xFF4D3322);
const Color _deleteMemberMutedTextColor = Color(0x7A4D3322);

const double _dialogDesignWidth = _deleteMemberTaskPanelSourceWidth;
const double _dialogDesignHeight = _deleteMemberTaskPanelSourceHeight;

const AppModalLayout _deleteMemberDialogLayout = AppModalLayout(
  mobileWidthFactor: 1.0,
  mobileMaxWidth: 430,
  mobileHeightFactor: 0.76,
  mobileMaxHeight: 560,
  tabletWidthFactor: 0.48,
  tabletMaxWidth: 430,
  tabletHeightFactor: 0.78,
  tabletMaxHeight: 620,
  contentAspectRatio: _dialogDesignWidth / _dialogDesignHeight,
);

const AppModalVisibleFrame _deleteMemberDialogVisibleFrame =
    AppModalVisibleFrame(
      sourceWidth: _deleteMemberTaskPanelSourceWidth,
      leftInset: _deleteMemberTaskPanelVisibleLeftInset,
      rightInset: _deleteMemberTaskPanelVisibleRightInset,
    );

Future<bool> showDeleteMemberDialog(
  BuildContext context, {
  required String memberName,
  bool useRootNavigator = true,
}) async {
  final result = await showAppModalDialog<bool>(
    context: context,
    useRootNavigator: useRootNavigator,
    barrierLabel: 'delete_member_dialog',
    blurSigma: 6,
    barrierTint: const Color(0x5C4D3523),
    beginScale: 0.96,
    beginYOffset: 16,
    pageBuilder: (dialogContext) {
      return _DeleteMemberDialog(
        memberName: memberName,
        onCancel: () => Navigator.of(dialogContext).pop(false),
        onDelete: () => Navigator.of(dialogContext).pop(true),
      );
    },
  );

  return result ?? false;
}

class _DeleteMemberDialog extends StatelessWidget {
  const _DeleteMemberDialog({
    required this.memberName,
    required this.onCancel,
    required this.onDelete,
  });

  final String memberName;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return AppModalShell(
      layout: _deleteMemberDialogLayout,
      minimumSafeArea: PickStarPetDialogGutter.mediumInsets,
      visibleFrame: _deleteMemberDialogVisibleFrame,
      clipChild: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final panelSize = constraints.biggest;
          final width = panelSize.width;
          final height = panelSize.height;
          final cancelButtonAspectRatio =
              _deleteMemberCancelButtonRegion.width /
              _deleteMemberCancelButtonRegion.height;
          final deleteButtonAspectRatio =
              _deleteMemberConfirmButtonRegion.width /
              _deleteMemberConfirmButtonRegion.height;
          final buttonGap = width * 0.035;
          final buttonMaxGroupWidth = width * 0.70;
          final buttonHeight = math.min(
            height * 0.112,
            (buttonMaxGroupWidth - buttonGap) /
                (cancelButtonAspectRatio + deleteButtonAspectRatio),
          );
          final cancelButtonWidth = buttonHeight * cancelButtonAspectRatio;
          final deleteButtonWidth = buttonHeight * deleteButtonAspectRatio;
          final buttonGroupWidth =
              cancelButtonWidth + buttonGap + deleteButtonWidth;
          final buttonLeft = (width - buttonGroupWidth) * 0.5;
          final questionFontSize = memberName.runes.length > 5
              ? width * 0.041
              : width * 0.046;

          return SizedBox(
            width: width,
            height: height,
            child: Stack(
              children: [
                const Positioned.fill(
                  child: _DeleteMemberTaskPanelBackground(),
                ),
                Positioned(
                  top: height * 0.052,
                  left: width * 0.5 - width * 0.086,
                  width: width * 0.172,
                  height: height * 0.185,
                  child: const FamilySpriteSlice(
                    assetPath: _deleteMemberDialogAsset,
                    sheetSize: _deleteMemberDialogSheetSize,
                    region: _deleteMemberTrashRegion,
                    fit: BoxFit.contain,
                    sampleInset: 0,
                  ),
                ),
                Positioned(
                  top: height * 0.255,
                  left: width * 0.18,
                  right: width * 0.18,
                  height: height * 0.072,
                  child: Center(
                    child: Text(
                      '删除成员',
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _deleteMemberTextColor,
                        fontFamily: _deleteMemberFontFamily,
                        fontSize: width * 0.078,
                        fontWeight: FontWeight.w900,
                        height: 1,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: height * 0.374,
                  left: width * 0.09,
                  right: width * 0.09,
                  height: height * 0.088,
                  child: Center(
                    child: Text(
                      '确认删除 $memberName 吗？',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _deleteMemberTextColor,
                        fontFamily: _deleteMemberFontFamily,
                        fontSize: questionFontSize,
                        fontWeight: FontWeight.w900,
                        height: 1.12,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: height * 0.486,
                  left: width * 0.12,
                  right: width * 0.12,
                  height: height * 0.056,
                  child: Center(
                    child: Text(
                      '删除后无法恢复',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _deleteMemberMutedTextColor,
                        fontFamily: _deleteMemberFontFamily,
                        fontSize: width * 0.04,
                        fontWeight: FontWeight.w800,
                        height: 1,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: height * 0.585,
                  left: width * 0.305,
                  width: width * 0.39,
                  height: height * 0.18,
                  child: const FamilySpriteSlice(
                    assetPath: _deleteMemberDialogAsset,
                    sheetSize: _deleteMemberDialogSheetSize,
                    region: _deleteMemberIllustrationRegion,
                    fit: BoxFit.contain,
                    sampleInset: 0,
                  ),
                ),
                Positioned(
                  left: buttonLeft,
                  bottom: height * 0.074,
                  width: cancelButtonWidth,
                  height: buttonHeight,
                  child: PickStarPetButton(
                    label: '取消',
                    variant: PickStarPetButtonVariant.secondary,
                    width: cancelButtonWidth,
                    height: buttonHeight,
                    onPressed: onCancel,
                  ),
                ),
                Positioned(
                  left: buttonLeft + cancelButtonWidth + buttonGap,
                  bottom: height * 0.074,
                  width: deleteButtonWidth,
                  height: buttonHeight,
                  child: PickStarPetButton(
                    label: '删除',
                    width: deleteButtonWidth,
                    height: buttonHeight,
                    onPressed: onDelete,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DeleteMemberTaskPanelBackground extends StatelessWidget {
  const _DeleteMemberTaskPanelBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: const [
        Image(
          image: AssetImage(_deleteMemberTaskPanelAsset),
          fit: BoxFit.fill,
          filterQuality: FilterQuality.high,
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: SourceScaledRRectBorder(
              sourceSize: Size(1149, 1369),
              sourceRect: Rect.fromLTRB(48, 43, 1098, 1315),
              sourceRadius: Radius.elliptical(58, 64),
              color: _deleteMemberTaskPanelBorderColor,
              strokeWidth: 2.4,
            ),
          ),
        ),
      ],
    );
  }
}
