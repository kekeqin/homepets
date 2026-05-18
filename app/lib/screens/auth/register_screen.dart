import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/app_modal_shell.dart';
import '../../widgets/homepets_primary_button.dart';
import '../../widgets/homepets_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  static const submitButtonKey = Key('register_submit_button');
  static const loginButtonKey = Key('register_login_button');

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  static const String _backgroundAsset = 'assets/images/ui/login/login-bg.png';

  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _localError;
  bool _hideAuthErrorAfterEdit = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_handleInputChanged);
    _passwordController.addListener(_handleInputChanged);
    _nicknameController.addListener(_handleInputChanged);
  }

  @override
  void dispose() {
    _phoneController.removeListener(_handleInputChanged);
    _passwordController.removeListener(_handleInputChanged);
    _nicknameController.removeListener(_handleInputChanged);
    _phoneController.dispose();
    _passwordController.dispose();
    _nicknameController.dispose();
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
    if (_nicknameController.text.trim().isEmpty) {
      return '\u8bf7\u8f93\u5165\u6635\u79f0';
    }
    if (_phoneController.text.trim().length < 11) {
      return '\u8bf7\u8f93\u5165\u6709\u6548\u624b\u673a\u53f7';
    }
    if (_passwordController.text.length < 6) {
      return '\u5bc6\u7801\u81f3\u5c11 6 \u4f4d';
    }
    return null;
  }

  Future<void> _register() async {
    final inputError = _inputErrorMessage();
    final formIsValid = _formKey.currentState?.validate() ?? false;
    if (inputError != null || !formIsValid) {
      setState(() {
        _localError =
            inputError ??
            '\u8bf7\u68c0\u67e5\u6635\u79f0\u3001\u624b\u673a\u53f7\u548c\u5bc6\u7801';
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
        .register(
          _phoneController.text.trim(),
          _passwordController.text,
          _nicknameController.text.trim(),
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
                    math.max(18, constraints.maxHeight * 0.23),
                    22,
                    24,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: math.max(0, constraints.maxHeight * 0.60),
                    ),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: _RegisterPanel(
                        formKey: _formKey,
                        nicknameController: _nicknameController,
                        phoneController: _phoneController,
                        passwordController: _passwordController,
                        authState: authState,
                        visibleError: visibleError,
                        onRegister: _register,
                        onLogin: () => context.go('/login'),
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

class _RegisterPanel extends StatelessWidget {
  const _RegisterPanel({
    required this.formKey,
    required this.nicknameController,
    required this.phoneController,
    required this.passwordController,
    required this.authState,
    required this.visibleError,
    required this.onRegister,
    required this.onLogin,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nicknameController;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final AuthState authState;
  final String? visibleError;
  final Future<void> Function() onRegister;
  final VoidCallback onLogin;

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
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
          child: Form(
            key: formKey,
            child: AutofillGroup(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _RegisterPanelHeader(),
                  const SizedBox(height: 22),
                  HomePetsTextField(
                    controller: nicknameController,
                    hintText: '\u6635\u79f0',
                    icon: Icons.person_outline_rounded,
                    textInputAction: TextInputAction.next,
                    maxLength: 20,
                    autofillHints: const [AutofillHints.nickname],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '\u8bf7\u8f93\u5165\u6635\u79f0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
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
                  const SizedBox(height: 12),
                  HomePetsTextField(
                    controller: passwordController,
                    hintText: '\u5bc6\u7801',
                    icon: Icons.lock_outline_rounded,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    onFieldSubmitted: (_) {
                      if (!authState.isLoading) {
                        onRegister();
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
                        ? const SizedBox(height: 18)
                        : Padding(
                            key: ValueKey(visibleError),
                            padding: const EdgeInsets.only(top: 7, bottom: 1),
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
                    key: RegisterScreen.submitButtonKey,
                    label: authState.isLoading
                        ? '\u6ce8\u518c\u4e2d'
                        : '\u6ce8\u518c',
                    onPressed: authState.isLoading ? null : onRegister,
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: TextButton(
                      key: RegisterScreen.loginButtonKey,
                      onPressed: onLogin,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF4D3623),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        minimumSize: const Size(120, 40),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        '\u5df2\u6709\u8d26\u53f7\uff1f\u53bb\u767b\u5f55',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
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

class _RegisterPanelHeader extends StatelessWidget {
  const _RegisterPanelHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text(
          '\u52a0\u5165\u5bb6\u5ead',
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
          '\u4e00\u8d77\u5f00\u59cb\u7167\u987e\u5c0f\u5ba0\u7269',
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
