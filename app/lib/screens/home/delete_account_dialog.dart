import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/support_links.dart';
import '../../widgets/app_modal_shell.dart';
import '../../widgets/pickstarpet_button.dart';
import '../../widgets/pickstarpet_text_field.dart';

const String _deleteFrameAsset = 'assets/images/ui/setup/frame.webp';

const double _deleteDialogDesignWidth = 441;
const double _deleteDialogDesignHeight = 700;
const double _deleteFrameSourceWidth = 1024;
const double _deleteFrameSourceHeight = 1536;
const double _deleteFrameCropLeft = 53;
const double _deleteFrameCropTop = 118;
const double _deleteFrameCropWidth = 946;
const double _deleteFrameCropHeight = 1159;
const double _deleteFrameDrawWidth =
    _deleteDialogDesignWidth * _deleteFrameSourceWidth / _deleteFrameCropWidth;
const double _deleteFrameDrawHeight =
    _deleteDialogDesignHeight *
    _deleteFrameSourceHeight /
    _deleteFrameCropHeight;
const double _deleteFrameDrawLeft =
    -_deleteFrameCropLeft * _deleteDialogDesignWidth / _deleteFrameCropWidth;
const double _deleteFrameDrawTop =
    -_deleteFrameCropTop * _deleteDialogDesignHeight / _deleteFrameCropHeight;

const Color _deleteTextColor = Color(0xFF30251D);
const Color _deleteMutedColor = Color(0xFF6F563D);
const Color _deleteDangerColor = Color(0xFFB54A3A);

const AppModalLayout _deleteDialogLayout = AppModalLayout(
  mobileWidthFactor: 1.0,
  mobileMaxWidth: 430,
  mobileHeightFactor: 0.92,
  mobileMaxHeight: 760,
  tabletWidthFactor: 0.46,
  tabletMaxWidth: 540,
  tabletHeightFactor: 0.86,
  tabletMaxHeight: 820,
  contentAspectRatio: _deleteDialogDesignWidth / _deleteDialogDesignHeight,
);

const List<String> _deleteRiskLines = [
  '删除后将无法再登录该账号。',
  '家庭成员、宠物成长、任务与积分等数据通常会被一并清除，且无法恢复。',
  '若你是家庭管理员，整户家庭相关数据也可能受到影响。',
  '进行中的会员订阅不会因删号自动退款，需在应用商店自行管理。',
  '提交后需人工核实处理，请确保专属 ID 填写正确。',
];

/// Settings-style wood panel to confirm account deletion by public ID.
///
/// Returns `true` when the user confirms with a matching ID and the delete
/// request email flow is started; `false` when cancelled.
Future<bool> showDeleteAccountDialog(
  BuildContext context, {
  required String expectedPublicId,
  bool useRootNavigator = true,
}) async {
  final result = await showAppModalDialog<bool>(
    context: context,
    useRootNavigator: useRootNavigator,
    barrierLabel: 'delete_account_dialog',
    blurSigma: 6,
    barrierTint: PickStarPetDialogTheme.barrierTint,
    beginScale: 0.96,
    beginYOffset: 16,
    pageBuilder: (dialogContext) {
      return _DeleteAccountDialogPanel(
        expectedPublicId: expectedPublicId.trim(),
        onCancel: () => Navigator.of(dialogContext).pop(false),
        onConfirmed: () => Navigator.of(dialogContext).pop(true),
      );
    },
  );
  return result == true;
}

class _DeleteAccountDialogPanel extends StatefulWidget {
  const _DeleteAccountDialogPanel({
    required this.expectedPublicId,
    required this.onCancel,
    required this.onConfirmed,
  });

  final String expectedPublicId;
  final VoidCallback onCancel;
  final VoidCallback onConfirmed;

  @override
  State<_DeleteAccountDialogPanel> createState() =>
      _DeleteAccountDialogPanelState();
}

class _DeleteAccountDialogPanelState extends State<_DeleteAccountDialogPanel> {
  late final TextEditingController _idController;
  String? _errorText;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController();
  }

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  bool _matchesExpected(String raw) {
    final expected = widget.expectedPublicId.trim().toUpperCase();
    final input = raw.trim().toUpperCase();
    if (expected.isEmpty || input.isEmpty) {
      return false;
    }
    return input == expected;
  }

  Future<void> _handleConfirm() async {
    if (_submitting) {
      return;
    }

    final input = _idController.text;
    if (widget.expectedPublicId.trim().isEmpty) {
      setState(() {
        _errorText = '暂未获取到专属 ID，请稍后重试或联系客服';
      });
      return;
    }

    if (!_matchesExpected(input)) {
      setState(() {
        _errorText = '专属 ID 不正确，请核对后再试';
      });
      return;
    }

    setState(() {
      _errorText = null;
      _submitting = true;
    });

    try {
      await SupportLinks.openDeleteAccountEmail(
        context,
        publicId: widget.expectedPublicId.trim().toUpperCase(),
      );
      if (!mounted) {
        return;
      }
      widget.onConfirmed();
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppModalShell(
      layout: _deleteDialogLayout,
      minimumSafeArea: PickStarPetDialogGutter.mediumInsets,
      clipChild: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : _deleteDialogDesignWidth;
          final maxHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : _deleteDialogDesignHeight;
          final aspect = _deleteDialogDesignWidth / _deleteDialogDesignHeight;
          final panelWidth = math.min(maxWidth, maxHeight * aspect);
          final panelHeight = panelWidth / aspect;

          return Center(
            child: SizedBox(
              width: panelWidth,
              height: panelHeight,
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: _deleteDialogDesignWidth,
                  height: _deleteDialogDesignHeight,
                  child: Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      const Positioned.fill(child: _DeletePanelFrame()),
                      Positioned(
                        left: 36,
                        top: 40,
                        right: 36,
                        bottom: 36,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              '删除账号',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _deleteTextColor,
                                fontFamily: 'PickStarPetFont',
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                height: 1.05,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Expanded(
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const Text(
                                      '删除账号前请仔细阅读以下风险：',
                                      style: TextStyle(
                                        color: _deleteDangerColor,
                                        fontFamily: 'PickStarPetFont',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        height: 1.35,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    for (final line in _deleteRiskLines) ...[
                                      _RiskLine(text: line),
                                      const SizedBox(height: 8),
                                    ],
                                    const SizedBox(height: 12),
                                    const Text(
                                      '请输入你的专属 ID 以确认删除',
                                      style: TextStyle(
                                        color: _deleteTextColor,
                                        fontFamily: 'PickStarPetFont',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        height: 1.3,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      widget.expectedPublicId.trim().isEmpty
                                          ? '可在「编辑资料」中查看专属 ID'
                                          : '专属 ID 可在「编辑资料」中查看或复制',
                                      style: const TextStyle(
                                        color: _deleteMutedColor,
                                        fontFamily: 'PickStarPetFont',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        height: 1.3,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    PickStarPetTextField(
                                      controller: _idController,
                                      hintText: '请输入专属 ID',
                                      height: 58,
                                      textInputAction: TextInputAction.done,
                                      keyboardType: TextInputType.text,
                                      maxLength: 16,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                          RegExp(r'[A-Za-z0-9]'),
                                        ),
                                        _UpperCaseTextFormatter(),
                                      ],
                                      onFieldSubmitted: (_) {
                                        _handleConfirm();
                                      },
                                    ),
                                    if (_errorText != null) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        _errorText!,
                                        style: const TextStyle(
                                          color: _deleteDangerColor,
                                          fontFamily: 'PickStarPetFont',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: PickStarPetButton(
                                    label: '取消',
                                    variant: PickStarPetButtonVariant.secondary,
                                    height: 52,
                                    onPressed: _submitting
                                        ? null
                                        : widget.onCancel,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: PickStarPetButton(
                                    label: _submitting ? '处理中…' : '确定',
                                    height: 52,
                                    onPressed: _submitting
                                        ? null
                                        : _handleConfirm,
                                  ),
                                ),
                              ],
                            ),
                          ],
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

class _RiskLine extends StatelessWidget {
  const _RiskLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Icon(
            Icons.warning_amber_rounded,
            size: 16,
            color: _deleteDangerColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: _deleteMutedColor,
              fontFamily: 'PickStarPetFont',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _DeletePanelFrame extends StatelessWidget {
  const _DeletePanelFrame();

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            left: _deleteFrameDrawLeft,
            top: _deleteFrameDrawTop,
            width: _deleteFrameDrawWidth,
            height: _deleteFrameDrawHeight,
            child: Image.asset(
              _deleteFrameAsset,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.high,
            ),
          ),
        ],
      ),
    );
  }
}

class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
