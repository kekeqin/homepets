import 'package:flutter/material.dart';

import '../../../widgets/app_modal_shell.dart';
import '../widgets/family_sprite_slice.dart';

const String _deleteMemberDialogAsset =
    'assets/images/ui/sprites/delete_member_dialog_sprites.png';
const Size _deleteMemberDialogSheetSize = Size(1536, 1024);

const Rect _deleteMemberPanelRegion = Rect.fromLTWH(798, 49, 619, 605);
const Rect _deleteMemberTrashRegion = Rect.fromLTWH(99, 698, 110, 115);
const Rect _deleteMemberTitleRegion = Rect.fromLTWH(317, 733, 196, 49);
const Rect _deleteMemberQuestionPrefixRegion = Rect.fromLTWH(634, 750, 210, 30);
const Rect _deleteMemberQuestionSuffixRegion = Rect.fromLTWH(905, 750, 78, 30);
const Rect _deleteMemberWarningRegion = Rect.fromLTWH(1068, 733, 404, 68);
const Rect _deleteMemberIllustrationRegion = Rect.fromLTWH(284, 818, 211, 134);
const Rect _deleteMemberCancelButtonRegion = Rect.fromLTWH(639, 856, 257, 102);
const Rect _deleteMemberConfirmButtonRegion = Rect.fromLTWH(
  1005,
  856,
  258,
  102,
);

const double _dialogDesignWidth = 619;
const double _dialogDesignHeight = 605;

const AppModalLayout _deleteMemberDialogLayout = AppModalLayout(
  mobileWidthFactor: 0.92,
  mobileMaxWidth: 430,
  mobileHeightFactor: 0.76,
  mobileMaxHeight: 420,
  tabletWidthFactor: 0.48,
  tabletMaxWidth: 560,
  tabletHeightFactor: 0.78,
  tabletMaxHeight: 560,
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
      minimumSafeArea: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      clipChild: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final targetHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : _dialogDesignHeight;

          return SizedBox(
            width: constraints.maxWidth,
            height: targetHeight,
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: _dialogDesignWidth,
                height: _dialogDesignHeight,
                child: Stack(
                  children: [
                    const Positioned.fill(
                      child: FamilySpriteSlice(
                        assetPath: _deleteMemberDialogAsset,
                        sheetSize: _deleteMemberDialogSheetSize,
                        region: _deleteMemberPanelRegion,
                        fit: BoxFit.fill,
                        sampleInset: 0,
                      ),
                    ),
                    const Positioned(
                      left: 255,
                      top: 18,
                      width: 110,
                      height: 115,
                      child: FamilySpriteSlice(
                        assetPath: _deleteMemberDialogAsset,
                        sheetSize: _deleteMemberDialogSheetSize,
                        region: _deleteMemberTrashRegion,
                        fit: BoxFit.contain,
                        sampleInset: 0,
                      ),
                    ),
                    const Positioned(
                      left: 211,
                      top: 136,
                      width: 196,
                      height: 49,
                      child: FamilySpriteSlice(
                        assetPath: _deleteMemberDialogAsset,
                        sheetSize: _deleteMemberDialogSheetSize,
                        region: _deleteMemberTitleRegion,
                        fit: BoxFit.contain,
                        sampleInset: 0,
                      ),
                    ),
                    Positioned(
                      left: 134,
                      top: 205,
                      width: 350,
                      height: 32,
                      child: _DeleteMemberQuestionRow(memberName: memberName),
                    ),
                    const Positioned(
                      left: 107,
                      top: 255,
                      width: 404,
                      height: 68,
                      child: FamilySpriteSlice(
                        assetPath: _deleteMemberDialogAsset,
                        sheetSize: _deleteMemberDialogSheetSize,
                        region: _deleteMemberWarningRegion,
                        fit: BoxFit.contain,
                        sampleInset: 0,
                      ),
                    ),
                    const Positioned(
                      left: 204,
                      top: 350,
                      width: 211,
                      height: 134,
                      child: FamilySpriteSlice(
                        assetPath: _deleteMemberDialogAsset,
                        sheetSize: _deleteMemberDialogSheetSize,
                        region: _deleteMemberIllustrationRegion,
                        fit: BoxFit.contain,
                        sampleInset: 0,
                      ),
                    ),
                    Positioned(
                      left: 49,
                      top: 479,
                      width: 257,
                      height: 102,
                      child: _DeleteMemberActionButton(
                        semanticLabel: '取消',
                        region: _deleteMemberCancelButtonRegion,
                        onPressed: onCancel,
                      ),
                    ),
                    Positioned(
                      left: 316,
                      top: 479,
                      width: 258,
                      height: 102,
                      child: _DeleteMemberActionButton(
                        semanticLabel: '删除',
                        region: _deleteMemberConfirmButtonRegion,
                        onPressed: onDelete,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DeleteMemberQuestionRow extends StatelessWidget {
  const _DeleteMemberQuestionRow({required this.memberName});

  final String memberName;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned(
          left: 0,
          top: 0,
          width: 210,
          height: 30,
          child: FamilySpriteSlice(
            assetPath: _deleteMemberDialogAsset,
            sheetSize: _deleteMemberDialogSheetSize,
            region: _deleteMemberQuestionPrefixRegion,
            fit: BoxFit.contain,
            alignment: Alignment.centerLeft,
            sampleInset: 0,
          ),
        ),
        Positioned(
          left: 210,
          top: 0,
          width: 72,
          height: 30,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                memberName,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF4A2E1F),
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
        const Positioned(
          right: 0,
          top: 0,
          width: 78,
          height: 30,
          child: FamilySpriteSlice(
            assetPath: _deleteMemberDialogAsset,
            sheetSize: _deleteMemberDialogSheetSize,
            region: _deleteMemberQuestionSuffixRegion,
            fit: BoxFit.contain,
            alignment: Alignment.centerRight,
            sampleInset: 0,
          ),
        ),
      ],
    );
  }
}

class _DeleteMemberActionButton extends StatefulWidget {
  const _DeleteMemberActionButton({
    required this.semanticLabel,
    required this.region,
    required this.onPressed,
  });

  final String semanticLabel;
  final Rect region;
  final VoidCallback onPressed;

  @override
  State<_DeleteMemberActionButton> createState() =>
      _DeleteMemberActionButtonState();
}

class _DeleteMemberActionButtonState extends State<_DeleteMemberActionButton> {
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
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1,
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOutCubic,
          child: FamilySpriteSlice(
            assetPath: _deleteMemberDialogAsset,
            sheetSize: _deleteMemberDialogSheetSize,
            region: widget.region,
            fit: BoxFit.contain,
            sampleInset: 0,
          ),
        ),
      ),
    );
  }
}
