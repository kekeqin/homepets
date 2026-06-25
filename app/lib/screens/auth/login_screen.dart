import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../core/ui/adaptive_design_layout.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_modal_shell.dart';
import '../../widgets/pickstarpet_primary_button.dart';
import '../../widgets/pickstarpet_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  static const submitButtonKey = Key('login_submit_button');
  static const sendCodeButtonKey = Key('login_send_code_button');
  static const appleButtonKey = Key('login_apple_button');
  static const panelKey = Key('login_panel');
  static const designSize = Size(430, 932);
  static const minimumInsets = EdgeInsets.fromLTRB(16, 18, 16, 24);
  static const loginPanelRect = Rect.fromLTWH(30, 455, 370, 382);
  static const loginPanelWithAppleRect = Rect.fromLTWH(30, 405, 370, 444);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  static const String _backgroundAsset = 'assets/images/ui/login/login-bg.png';
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  Timer? _resendTimer;
  String? _localError;
  String? _localNotice;
  bool _hideAuthErrorAfterEdit = false;
  bool _isSendingCode = false;
  bool _hasSentCode = false;
  bool _appleSignInAvailable = false;
  int _resendSeconds = 0;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_handleInputChanged);
    _codeController.addListener(_handleInputChanged);
    _loadAppleSignInAvailability();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _phoneController.removeListener(_handleInputChanged);
    _codeController.removeListener(_handleInputChanged);
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _handleInputChanged() {
    if (_localError == null &&
        _localNotice == null &&
        _hideAuthErrorAfterEdit) {
      return;
    }

    setState(() {
      _localError = null;
      _localNotice = null;
      _hideAuthErrorAfterEdit = true;
    });
  }

  String? _phoneErrorMessage() {
    if (_phoneController.text.trim().length != 11) {
      return '\u8bf7\u8f93\u5165\u6709\u6548\u624b\u673a\u53f7';
    }
    return null;
  }

  String? _inputErrorMessage() {
    final phoneError = _phoneErrorMessage();
    if (phoneError != null) {
      return phoneError;
    }
    if (_codeController.text.trim().isEmpty) {
      return '\u8bf7\u8f93\u5165\u77ed\u4fe1\u9a8c\u8bc1\u7801';
    }
    if (_codeController.text.trim().length < 4) {
      return '\u9a8c\u8bc1\u7801\u81f3\u5c11 4 \u4f4d';
    }
    return null;
  }

  Future<void> _sendCode() async {
    final phoneError = _phoneErrorMessage();
    if (phoneError != null) {
      setState(() {
        _localError = phoneError;
        _localNotice = null;
        _hideAuthErrorAfterEdit = false;
      });
      return;
    }

    setState(() {
      _localError = null;
      _localNotice = null;
      _hideAuthErrorAfterEdit = false;
      _isSendingCode = true;
    });
    FocusScope.of(context).unfocus();

    final sendResult = await ref
        .read(authProvider.notifier)
        .sendSmsCode(_phoneController.text.trim());
    if (!mounted) {
      return;
    }

    final devCode = sendResult?.devCode;
    if (devCode != null) {
      _codeController.text = devCode;
    }

    setState(() {
      _isSendingCode = false;
      _localNotice = devCode == null ? null : '开发验证码：$devCode';
      _hideAuthErrorAfterEdit = false;
    });

    if (sendResult != null) {
      _startCountdown(sendResult.cooldownSeconds);
    }
  }

  Future<void> _login() async {
    final inputError = _inputErrorMessage();
    final formIsValid = _formKey.currentState?.validate() ?? false;
    if (inputError != null || !formIsValid) {
      setState(() {
        _localError =
            inputError ??
            '\u8bf7\u68c0\u67e5\u624b\u673a\u53f7\u548c\u9a8c\u8bc1\u7801';
        _localNotice = null;
        _hideAuthErrorAfterEdit = false;
      });
      return;
    }

    setState(() {
      _localError = null;
      _localNotice = null;
      _hideAuthErrorAfterEdit = false;
    });
    FocusScope.of(context).unfocus();
    await ref
        .read(authProvider.notifier)
        .login(_phoneController.text.trim(), _codeController.text.trim());
  }

  Future<void> _loginWithApple() async {
    setState(() {
      _localError = null;
      _localNotice = null;
      _hideAuthErrorAfterEdit = false;
    });
    FocusScope.of(context).unfocus();
    await ref.read(authProvider.notifier).loginWithApple();
  }

  Future<void> _loadAppleSignInAvailability() async {
    final available = await ref.read(appleSignInServiceProvider).isAvailable();
    if (!mounted) {
      return;
    }
    setState(() => _appleSignInAvailable = available);
  }

  void _startCountdown(int seconds) {
    _resendTimer?.cancel();
    if (seconds <= 0) {
      setState(() {
        _hasSentCode = true;
        _resendSeconds = 0;
      });
      return;
    }

    setState(() {
      _hasSentCode = true;
      _resendSeconds = seconds;
    });
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendSeconds <= 1) {
        timer.cancel();
        setState(() => _resendSeconds = 0);
        return;
      }
      setState(() => _resendSeconds--);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final visibleError =
        _localError ?? (_hideAuthErrorAfterEdit ? null : authState.error);
    final visibleNotice = visibleError == null ? _localNotice : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF6E2BC),
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          AdaptiveDesignLayout(
            designSize: LoginScreen.designSize,
            fit: AdaptiveDesignFit.cover,
            useViewPadding: false,
            builder: (context, geometry) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fromRect(
                    rect: geometry.designRect,
                    child: Image.asset(
                      _backgroundAsset,
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ],
              );
            },
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.02),
                  const Color(0x4DF4C77A),
                ],
                stops: const [0, 0.58, 1],
              ),
            ),
          ),
          AdaptiveDesignLayout(
            designSize: LoginScreen.designSize,
            minimumInsets: LoginScreen.minimumInsets,
            builder: (context, geometry) {
              final panelRect = _appleSignInAvailable
                  ? LoginScreen.loginPanelWithAppleRect
                  : LoginScreen.loginPanelRect;
              final panelScreenRect = geometry.toScreenRect(panelRect);
              final keyboardShift = _keyboardPanelShift(
                context: context,
                geometry: geometry,
                panelScreenRect: panelScreenRect,
              );
              final shiftedPanelRect = panelScreenRect.shift(
                Offset(0, keyboardShift),
              );
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fromRect(
                    rect: shiftedPanelRect,
                    child: FittedBox(
                      fit: BoxFit.fill,
                      child: SizedBox(
                        width: panelRect.width,
                        height: panelRect.height,
                        child: _LoginPanel(
                          key: LoginScreen.panelKey,
                          panelWidth: panelRect.width,
                          formKey: _formKey,
                          phoneController: _phoneController,
                          codeController: _codeController,
                          authState: authState,
                          visibleError: visibleError,
                          visibleNotice: visibleNotice,
                          onLogin: _login,
                          onAppleLogin: _loginWithApple,
                          onSendCode: _sendCode,
                          sendCodeLabel: _sendCodeLabel,
                          showAppleLogin: _appleSignInAvailable,
                          canSendCode:
                              !_isSendingCode &&
                              _resendSeconds == 0 &&
                              !authState.isLoading,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String get _sendCodeLabel {
    if (_isSendingCode) {
      return '\u53d1\u9001\u4e2d';
    }
    if (_resendSeconds > 0) {
      return '${_resendSeconds}s';
    }
    return _hasSentCode
        ? '\u91cd\u65b0\u53d1\u9001'
        : '\u83b7\u53d6\u9a8c\u8bc1\u7801';
  }

  double _keyboardPanelShift({
    required BuildContext context,
    required AdaptiveDesignLayoutGeometry geometry,
    required Rect panelScreenRect,
  }) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    if (keyboardInset <= 0) {
      return 0;
    }

    final keyboardTop = MediaQuery.sizeOf(context).height - keyboardInset;
    final desiredShift = keyboardTop - 16 - panelScreenRect.bottom;
    if (desiredShift >= 0) {
      return 0;
    }

    final topLimitShift = geometry.safeBounds.top + 12 - panelScreenRect.top;
    return math.max(desiredShift, topLimitShift);
  }
}

class _LoginPanel extends StatelessWidget {
  const _LoginPanel({
    super.key,
    required this.panelWidth,
    required this.formKey,
    required this.phoneController,
    required this.codeController,
    required this.authState,
    required this.visibleError,
    required this.visibleNotice,
    required this.onLogin,
    required this.onAppleLogin,
    required this.onSendCode,
    required this.sendCodeLabel,
    required this.showAppleLogin,
    required this.canSendCode,
  });

  final double panelWidth;
  final GlobalKey<FormState> formKey;
  final TextEditingController phoneController;
  final TextEditingController codeController;
  final AuthState authState;
  final String? visibleError;
  final String? visibleNotice;
  final Future<void> Function() onLogin;
  final Future<void> Function() onAppleLogin;
  final Future<void> Function() onSendCode;
  final String sendCodeLabel;
  final bool showAppleLogin;
  final bool canSendCode;

  @override
  Widget build(BuildContext context) {
    final visibleMessage = visibleError ?? visibleNotice;
    final isErrorMessage = visibleError != null;

    return SizedBox(
      width: panelWidth,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: PickStarPetDialogTheme.shellGradient,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFF4A2C1B), width: 2.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x32604429),
              blurRadius: 22,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 18),
          child: Form(
            key: formKey,
            child: AutofillGroup(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _LoginPanelHeader(),
                  const SizedBox(height: 20),
                  PickStarPetTextField(
                    controller: phoneController,
                    hintText: '\u624b\u673a\u53f7',
                    icon: Icons.phone_android_rounded,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().length != 11) {
                        return '\u8bf7\u8f93\u5165\u6709\u6548\u624b\u673a\u53f7';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: PickStarPetTextField(
                          controller: codeController,
                          hintText: '\u9a8c\u8bc1\u7801',
                          icon: Icons.sms_outlined,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.oneTimeCode],
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(8),
                          ],
                          onFieldSubmitted: (_) {
                            if (!authState.isLoading) {
                              onLogin();
                            }
                          },
                          validator: (value) {
                            final code = value?.trim() ?? '';
                            if (code.isEmpty) {
                              return '\u8bf7\u8f93\u5165\u77ed\u4fe1\u9a8c\u8bc1\u7801';
                            }
                            if (code.length < 4) {
                              return '\u9a8c\u8bc1\u7801\u81f3\u5c11 4 \u4f4d';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      _SendCodeButton(
                        key: LoginScreen.sendCodeButtonKey,
                        label: sendCodeLabel,
                        onPressed: canSendCode ? onSendCode : null,
                      ),
                    ],
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    child: visibleMessage == null
                        ? const SizedBox(height: 18)
                        : Padding(
                            key: ValueKey(visibleMessage),
                            padding: const EdgeInsets.only(top: 6, bottom: 2),
                            child: Text(
                              visibleMessage,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isErrorMessage
                                    ? const Color(0xFFB53A2D)
                                    : const Color(0xFF6B8F3E),
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                  ),
                  PickStarPetPrimaryButton(
                    key: LoginScreen.submitButtonKey,
                    label: authState.isLoading
                        ? '\u767b\u5f55\u4e2d'
                        : '\u9a8c\u8bc1\u767b\u5f55',
                    onPressed: authState.isLoading ? null : onLogin,
                    height: 54,
                  ),
                  if (showAppleLogin) ...[
                    const SizedBox(height: 12),
                    SignInWithAppleButton(
                      key: LoginScreen.appleButtonKey,
                      text: '\u4f7f\u7528 Apple \u767b\u5f55',
                      height: 50,
                      borderRadius: BorderRadius.circular(16),
                      onPressed: authState.isLoading ? null : onAppleLogin,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginPanelHeader extends StatelessWidget {
  const _LoginPanelHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text(
          '\u624b\u673a\u767b\u5f55',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF3E2A1F),
            fontSize: 34,
            fontWeight: FontWeight.w900,
            height: 1,
            letterSpacing: 0,
          ),
        ),
        SizedBox(height: 10),
        Text(
          '\u548c\u5bb6\u4eba\u4e00\u8d77\u7167\u987e\u5c0f\u5ba0\u7269',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF4D3623),
            fontSize: 19,
            fontWeight: FontWeight.w800,
            height: 1.1,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _SendCodeButton extends StatefulWidget {
  const _SendCodeButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  State<_SendCodeButton> createState() => _SendCodeButtonState();
}

class _SendCodeButtonState extends State<_SendCodeButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

  void _setPressed(bool pressed) {
    if (!_enabled || _pressed == pressed) {
      return;
    }
    setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    Widget button = AnimatedOpacity(
      duration: const Duration(milliseconds: 120),
      opacity: _enabled ? 1 : 0.54,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOutCubic,
        scale: _pressed ? 0.97 : 1,
        child: SizedBox(
          width: 116,
          height: 64,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4DC),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF4A2C1B), width: 2.3),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x185E3A20),
                  blurRadius: 7,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: const TextStyle(
                      color: Color(0xFF4D3623),
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    button = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onPressed,
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      child: button,
    );

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      child: button,
    );
  }
}
