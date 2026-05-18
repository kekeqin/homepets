import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/app_modal_shell.dart';
import '../../widgets/homepets_primary_button.dart';
import '../../widgets/homepets_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  static const submitButtonKey = Key('login_submit_button');
  static const registerButtonKey = Key('login_register_button');
  static const forgotPasswordButtonKey = Key('login_forgot_password_button');

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  static const String _backgroundAsset = 'assets/images/ui/login/login-bg.png';

  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _localError;
  bool _hideAuthErrorAfterEdit = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_handleInputChanged);
    _passwordController.addListener(_handleInputChanged);
  }

  @override
  void dispose() {
    _phoneController.removeListener(_handleInputChanged);
    _passwordController.removeListener(_handleInputChanged);
    _phoneController.dispose();
    _passwordController.dispose();
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

  String? _inputErrorMessage() {
    if (_phoneController.text.trim().length < 11) {
      return '\u8bf7\u8f93\u5165\u6709\u6548\u624b\u673a\u53f7';
    }
    if (_passwordController.text.length < 6) {
      return '\u5bc6\u7801\u81f3\u5c11 6 \u4f4d';
    }
    return null;
  }

  Future<void> _login() async {
    final inputError = _inputErrorMessage();
    final formIsValid = _formKey.currentState?.validate() ?? false;
    if (inputError != null || !formIsValid) {
      setState(() {
        _localError =
            inputError ??
            '\u8bf7\u68c0\u67e5\u624b\u673a\u53f7\u548c\u5bc6\u7801';
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
        .login(_phoneController.text.trim(), _passwordController.text);
  }

  void _showForgotPasswordMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '\u8bf7\u8054\u7cfb\u5bb6\u5ead\u7ba1\u7406\u5458\u91cd\u7f6e\u5bc6\u7801',
        ),
      ),
    );
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
                        passwordController: _passwordController,
                        authState: authState,
                        visibleError: visibleError,
                        onLogin: _login,
                        onRegister: () => context.go('/register'),
                        onForgotPassword: _showForgotPasswordMessage,
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
}

class _LoginPanel extends StatelessWidget {
  const _LoginPanel({
    required this.formKey,
    required this.phoneController,
    required this.passwordController,
    required this.authState,
    required this.visibleError,
    required this.onLogin,
    required this.onRegister,
    required this.onForgotPassword,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final AuthState authState;
  final String? visibleError;
  final Future<void> Function() onLogin;
  final VoidCallback onRegister;
  final VoidCallback onForgotPassword;

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
                    hintText: '\u624b\u673a\u53f7 / \u8d26\u53f7',
                    icon: Icons.phone_android_rounded,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.username],
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.trim().length < 11) {
                        return '\u8bf7\u8f93\u5165\u6709\u6548\u624b\u673a\u53f7';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  HomePetsTextField(
                    controller: passwordController,
                    hintText: '\u5bc6\u7801',
                    icon: Icons.lock_outline_rounded,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onFieldSubmitted: (_) {
                      if (!authState.isLoading) {
                        onLogin();
                      }
                    },
                    validator: (value) {
                      if (value == null || value.length < 6) {
                        return '\u5bc6\u7801\u81f3\u5c11 6 \u4f4d';
                      }
                      return null;
                    },
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
                        : '\u767b\u5f55',
                    onPressed: authState.isLoading ? null : onLogin,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _LoginTextAction(
                        key: LoginScreen.registerButtonKey,
                        label: '\u6ce8\u518c\u8d26\u53f7',
                        onPressed: onRegister,
                      ),
                      const Spacer(),
                      _LoginTextAction(
                        key: LoginScreen.forgotPasswordButtonKey,
                        label: '\u5fd8\u8bb0\u5bc6\u7801\uff1f',
                        onPressed: onForgotPassword,
                      ),
                    ],
                  ),
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
          '\u6b22\u8fce\u56de\u5bb6',
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

class _LoginTextAction extends StatelessWidget {
  const _LoginTextAction({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF4D3623),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        minimumSize: const Size(80, 40),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
