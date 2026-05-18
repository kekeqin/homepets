import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HomePetsTextField extends StatelessWidget {
  const HomePetsTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.icon,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.enabled = true,
    this.height = 64,
    this.maxLength,
    this.inputFormatters,
    this.validator,
    this.onFieldSubmitted,
    this.autofillHints,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData? icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool enabled;
  final double height;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onFieldSubmitted;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const _HomePetsTextFieldBackground(),
          Padding(
            padding: EdgeInsets.fromLTRB(icon == null ? 22 : 20, 0, 22, 0),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: const Color(0xFF4A2C1B), size: 28),
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    keyboardType: keyboardType,
                    textInputAction: textInputAction,
                    obscureText: obscureText,
                    enabled: enabled,
                    maxLength: maxLength,
                    inputFormatters: inputFormatters,
                    validator: validator,
                    onFieldSubmitted: onFieldSubmitted,
                    autofillHints: autofillHints,
                    cursorColor: const Color(0xFF4A2C1B),
                    maxLines: 1,
                    style: const TextStyle(
                      color: Color(0xFF4D3623),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                    decoration: InputDecoration(
                      hintText: hintText,
                      hintStyle: const TextStyle(
                        color: Color(0xA36F563D),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                      counterText: '',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      isCollapsed: true,
                      errorStyle: const TextStyle(fontSize: 0, height: 0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomePetsTextFieldBackground extends StatelessWidget {
  const _HomePetsTextFieldBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF4A2C1B), width: 2.4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x185E3A20),
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
          BoxShadow(
            color: Color(0x33FFFFFF),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
    );
  }
}
