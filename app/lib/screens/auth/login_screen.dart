import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/app_modal_shell.dart';
import '../../widgets/homepets_primary_button.dart';
import '../../widgets/homepets_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  static const submitButtonKey = Key('login_submit_button');
  static const sendCodeButtonKey = Key('login_send_code_button');
  static const appleButtonKey = Key('login_apple_button');

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  static const String _backgroundAsset = 'assets/images/ui/login/login-bg.png';
  static const int _countdownSeconds = 60;

  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  Timer? _resendTimer;
  String? _localError;
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
    if (_localError == null && _hideAuthErrorAfterEdit) {
      return;
    }

    setState(() {
      _localError = null;
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
        _hideAuthErrorAfterEdit = false;
      });
      return;
    }

    setState(() {
      _localError = null;
      _hideAuthErrorAfterEdit = false;
      _isSendingCode = true;
    });
    FocusScope.of(context).unfocus();

    final success = await ref
        .read(authProvider.notifier)
        .sendSmsCode(_phoneController.text.trim());
    if (!mounted) {
      return;
    }

    setState(() {
      _isSendingCode = false;
      _hideAuthErrorAfterEdit = !success;
    });

    if (success) {
      _startCountdown();
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
        _hideAuthErrorAfterEdit = false;
      });
      return;
    }

    setState(() {
      _localError = null;
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

  void _startCountdown() {
    _resendTimer?.cancel();
    setState(() {
      _hasSentCode = true;
      _resendSeconds = _countdownSeconds;
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

    return Scaffold(
      backgroundColor: const Color(0xFFF6E2BC),
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            _backgroundAsset,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            filterQuality: FilterQuality.high,
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
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    22,
                    math.max(18, constraints.maxHeight * 0.27),
                    22,
                    24,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: math.max(0, constraints.maxHeight * 0.54),
                    ),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: _LoginPanel(
                        formKey: _formKey,
                        phoneController: _phoneController,
                        codeController: _codeController,
                        authState: authState,
                        visibleError: visibleError,
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
                );
              },
            ),
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
}

class _LoginPanel extends StatelessWidget {
  const _LoginPanel({
    required this.formKey,
    required this.phoneController,
    required this.codeController,
    required this.authState,
    required this.visibleError,
    required this.onLogin,
    required this.onAppleLogin,
    required this.onSendCode,
    required this.sendCodeLabel,
    required this.showAppleLogin,
    required this.canSendCode,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController phoneController;
  final TextEditingController codeController;
  final AuthState authState;
  final String? visibleError;
  final Future<void> Function() onLogin;
  final Future<void> Function() onAppleLogin;
  final Future<void> Function() onSendCode;
  final String sendCodeLabel;
  final bool showAppleLogin;
  final bool canSendCode;

  @override
  Widget build(BuildContext context) {
    final panelWidth = math.min(MediaQuery.sizeOf(context).width * 0.86, 430.0);

    return SizedBox(
      width: panelWidth,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: HomePetsDialogTheme.shellGradient,
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
          padding: const EdgeInsets.fromLTRB(28, 30, 28, 26),
          child: Form(
            key: formKey,
            child: AutofillGroup(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _LoginPanelHeader(),
                  const SizedBox(height: 26),
                  HomePetsTextField(
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
                        child: HomePetsTextField(
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
                    child: visibleError == null
                        ? const SizedBox(height: 20)
                        : Padding(
                            key: ValueKey(visibleError),
                            padding: const EdgeInsets.only(top: 8, bottom: 2),
                            child: Text(
                              visibleError!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFFB53A2D),
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                  ),
                  HomePetsPrimaryButton(
                    key: LoginScreen.submitButtonKey,
                    label: authState.isLoading
                        ? '\u767b\u5f55\u4e2d'
                        : '\u9a8c\u8bc1\u767b\u5f55',
                    onPressed: authState.isLoading ? null : onLogin,
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
            fontSize: 36,
            fontWeight: FontWeight.w900,
            height: 1,
            letterSpacing: 0,
          ),
        ),
        SizedBox(height: 12),
        Text(
          '\u548c\u5bb6\u4eba\u4e00\u8d77\u7167\u987e\u5c0f\u5ba0\u7269',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF4D3623),
            fontSize: 20,
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
