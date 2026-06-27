import 'package:flutter/material.dart';

class PickStarPetPrimaryButton extends StatefulWidget {
  const PickStarPetPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 58,
    this.textStyle,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;
  final TextStyle? textStyle;

  @override
  State<PickStarPetPrimaryButton> createState() =>
      _PickStarPetPrimaryButtonState();
}

class _PickStarPetPrimaryButtonState extends State<PickStarPetPrimaryButton> {
  static const Duration _feedbackHoldDuration = Duration(milliseconds: 90);

  bool _pressed = false;
  bool _tapPending = false;

  bool get _enabled => widget.onPressed != null;
  bool get _canTap => _enabled && !_tapPending;

  void _setPressed(bool pressed) {
    if (!_enabled || _pressed == pressed) {
      return;
    }
    setState(() => _pressed = pressed);
  }

  void _handleTap() {
    if (!_canTap) {
      return;
    }
    Feedback.forTap(context);
    setState(() {
      _pressed = true;
      _tapPending = true;
    });
    Future<void>.delayed(_feedbackHoldDuration, () {
      if (!mounted) {
        return;
      }
      setState(() {
        _pressed = false;
        _tapPending = false;
      });
      widget.onPressed?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget button = AnimatedOpacity(
      duration: const Duration(milliseconds: 120),
      opacity: _enabled ? (_pressed ? 0.80 : 1) : 0.56,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOutCubic,
        scale: _pressed ? 0.92 : 1,
        child: SizedBox(
          height: widget.height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFC66D), Color(0xFFFFA94E)],
              ),
              borderRadius: BorderRadius.circular(widget.height / 2),
              border: Border.all(color: const Color(0xFF4A2C1B), width: 2.4),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x265E3A20),
                  blurRadius: 9,
                  offset: Offset(0, 4),
                ),
                BoxShadow(
                  color: Color(0x44FFFFFF),
                  blurRadius: 6,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                widget.label,
                textAlign: TextAlign.center,
                style:
                    widget.textStyle ??
                    const TextStyle(
                      color: Color(0xFF4D3623),
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      height: 1,
                      letterSpacing: 0,
                    ),
              ),
            ),
          ),
        ),
      ),
    );

    button = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _canTap ? _handleTap : null,
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () {
        if (!_tapPending) {
          _setPressed(false);
        }
      },
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
