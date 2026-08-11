import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../widgets/app_modal_shell.dart';
import '../../widgets/pickstarpet_button.dart';
import '../../widgets/pickstarpet_text_field.dart';
import '../../widgets/public_id_row.dart';

const String _editFrameAsset = 'assets/images/ui/setup/frame.webp';
const String _editBackButtonAsset =
    'assets/images/ui/setup/about/icon_back.webp';

const double _editDialogDesignWidth = 441;
// Tight to content — no large empty gap above/below the action buttons.
const double _editDialogDesignHeightCompact = 360;
const double _editDialogDesignHeightWithFamily = 430;
const double _editFrameSourceWidth = 1024;
const double _editFrameSourceHeight = 1536;
const double _editFrameCropLeft = 53;
const double _editFrameCropTop = 118;
const double _editFrameCropWidth = 946;
const double _editFrameCropHeight = 1159;

const Color _editTextColor = Color(0xFF30251D);
const Color _editMutedColor = Color(0xFF6F563D);

AppModalLayout _editDialogLayout(double designHeight) {
  return AppModalLayout(
    mobileWidthFactor: 1.0,
    mobileMaxWidth: 420,
    mobileHeightFactor: 0.72,
    mobileMaxHeight: designHeight + 24,
    tabletWidthFactor: 0.40,
    tabletMaxWidth: 500,
    tabletHeightFactor: 0.62,
    tabletMaxHeight: designHeight + 40,
    contentAspectRatio: _editDialogDesignWidth / designHeight,
  );
}

/// Result returned when the user confirms profile edits.
class EditProfileDialogResult {
  const EditProfileDialogResult({
    required this.nickname,
    this.familyName,
  });

  final String nickname;
  final String? familyName;
}

/// Settings-style wood panel for viewing public ID and editing nickname
/// (and optional family name).
Future<EditProfileDialogResult?> showEditProfileDialog(
  BuildContext context, {
  required String publicId,
  required String initialNickname,
  String? initialFamilyName,
  bool showFamilyNameField = false,
  VoidCallback? onPublicIdCopied,
  bool useRootNavigator = true,
}) {
  return showAppModalDialog<EditProfileDialogResult>(
    context: context,
    useRootNavigator: useRootNavigator,
    barrierLabel: 'edit_profile_dialog',
    blurSigma: 6,
    barrierTint: PickStarPetDialogTheme.barrierTint,
    beginScale: 0.96,
    beginYOffset: 16,
    pageBuilder: (dialogContext) {
      return _EditProfileDialogPanel(
        publicId: publicId,
        initialNickname: initialNickname,
        initialFamilyName: initialFamilyName ?? '',
        showFamilyNameField: showFamilyNameField,
        onPublicIdCopied: onPublicIdCopied,
        onCancel: () => Navigator.of(dialogContext).pop(),
        onSaved: (result) => Navigator.of(dialogContext).pop(result),
      );
    },
  );
}

class _EditProfileDialogPanel extends StatefulWidget {
  const _EditProfileDialogPanel({
    required this.publicId,
    required this.initialNickname,
    required this.initialFamilyName,
    required this.showFamilyNameField,
    required this.onCancel,
    required this.onSaved,
    this.onPublicIdCopied,
  });

  final String publicId;
  final String initialNickname;
  final String initialFamilyName;
  final bool showFamilyNameField;
  final VoidCallback onCancel;
  final ValueChanged<EditProfileDialogResult> onSaved;
  final VoidCallback? onPublicIdCopied;

  @override
  State<_EditProfileDialogPanel> createState() =>
      _EditProfileDialogPanelState();
}

class _EditProfileDialogPanelState extends State<_EditProfileDialogPanel> {
  late final TextEditingController _nicknameController;
  late final TextEditingController _familyNameController;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(text: widget.initialNickname);
    _familyNameController = TextEditingController(
      text: widget.initialFamilyName,
    );
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _familyNameController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final nickname = _nicknameController.text.trim();
    final familyName = _familyNameController.text.trim();

    if (nickname.isEmpty) {
      setState(() => _errorText = '请输入昵称');
      return;
    }

    if (widget.showFamilyNameField && familyName.isEmpty) {
      setState(() => _errorText = '请输入家庭名称');
      return;
    }

    setState(() => _errorText = null);
    widget.onSaved(
      EditProfileDialogResult(
        nickname: nickname,
        familyName: widget.showFamilyNameField ? familyName : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final designHeight = widget.showFamilyNameField
        ? _editDialogDesignHeightWithFamily
        : _editDialogDesignHeightCompact;
    final frameDrawW =
        _editDialogDesignWidth * _editFrameSourceWidth / _editFrameCropWidth;
    final frameDrawH =
        designHeight * _editFrameSourceHeight / _editFrameCropHeight;
    final frameDrawL =
        -_editFrameCropLeft * _editDialogDesignWidth / _editFrameCropWidth;
    final frameDrawT =
        -_editFrameCropTop * designHeight / _editFrameCropHeight;

    return AppModalShell(
      layout: _editDialogLayout(designHeight),
      minimumSafeArea: PickStarPetDialogGutter.mediumInsets,
      clipChild: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : _editDialogDesignWidth;
          final maxHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : designHeight;
          final aspect = _editDialogDesignWidth / designHeight;
          final panelWidth = math.min(maxWidth, maxHeight * aspect);
          final panelHeight = panelWidth / aspect;

          return Center(
            child: SizedBox(
              width: panelWidth,
              height: panelHeight,
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: _editDialogDesignWidth,
                  height: designHeight,
                  child: Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      Positioned.fill(
                        child: _EditPanelFrame(
                          drawLeft: frameDrawL,
                          drawTop: frameDrawT,
                          drawWidth: frameDrawW,
                          drawHeight: frameDrawH,
                        ),
                      ),
                      Positioned(
                        left: 30,
                        top: 30,
                        right: 30,
                        // Leave room for bottom action buttons.
                        bottom: 84,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              '编辑资料',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _editTextColor,
                                fontFamily: 'PickStarPetFont',
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                height: 1.05,
                              ),
                            ),
                            const SizedBox(height: 10),
                            PublicIdRow(
                              publicId: widget.publicId,
                              labelColor: _editMutedColor,
                              valueColor: _editTextColor,
                              onCopied: widget.onPublicIdCopied,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '这个名字会显示在家庭成员和任务记录里。',
                              style: TextStyle(
                                color: _editMutedColor,
                                fontFamily: 'PickStarPetFont',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              '昵称',
                              style: TextStyle(
                                color: _editTextColor,
                                fontFamily: 'PickStarPetFont',
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 5),
                            PickStarPetTextField(
                              controller: _nicknameController,
                              hintText: '请输入昵称',
                              icon: Icons.person_outline_rounded,
                              height: 52,
                              maxLength: 20,
                              textInputAction: widget.showFamilyNameField
                                  ? TextInputAction.next
                                  : TextInputAction.done,
                              onFieldSubmitted: (_) {
                                if (widget.showFamilyNameField) {
                                  FocusScope.of(context).nextFocus();
                                } else {
                                  _handleSave();
                                }
                              },
                            ),
                            if (widget.showFamilyNameField) ...[
                              const SizedBox(height: 10),
                              const Text(
                                '家庭名称',
                                style: TextStyle(
                                  color: _editTextColor,
                                  fontFamily: 'PickStarPetFont',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 5),
                              PickStarPetTextField(
                                controller: _familyNameController,
                                hintText: '请输入家庭名称',
                                icon: Icons.home_outlined,
                                height: 52,
                                maxLength: 30,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _handleSave(),
                              ),
                            ],
                            if (_errorText != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                _errorText!,
                                style: const TextStyle(
                                  color: Color(0xFFB54A3A),
                                  fontFamily: 'PickStarPetFont',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Positioned(
                        left: 30,
                        right: 30,
                        bottom: 24,
                        child: Row(
                          children: [
                            Expanded(
                              child: PickStarPetButton(
                                label: '取消',
                                variant: PickStarPetButtonVariant.secondary,
                                height: 48,
                                onPressed: widget.onCancel,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: PickStarPetButton(
                                label: '保存',
                                height: 48,
                                onPressed: _handleSave,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Above content so the hit target is not covered.
                      Positioned(
                        top: 22,
                        left: 22,
                        width: 40,
                        height: 40,
                        child: Semantics(
                          button: true,
                          label: '返回',
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: widget.onCancel,
                            child: Image.asset(
                              _editBackButtonAsset,
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

class _EditPanelFrame extends StatelessWidget {
  const _EditPanelFrame({
    required this.drawLeft,
    required this.drawTop,
    required this.drawWidth,
    required this.drawHeight,
  });

  final double drawLeft;
  final double drawTop;
  final double drawWidth;
  final double drawHeight;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            left: drawLeft,
            top: drawTop,
            width: drawWidth,
            height: drawHeight,
            child: Image.asset(
              _editFrameAsset,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.high,
            ),
          ),
        ],
      ),
    );
  }
}
