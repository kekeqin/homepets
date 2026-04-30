import 'package:flutter/material.dart';

import '../core/ui/sprite_atlas.dart';

enum HomePetsButtonVariant { primary, secondary }

const SpriteAtlasAsset _homePetsButtonAtlasAsset = SpriteAtlasAsset(
  imageAsset: 'assets/images/ui/sprites/edit_task_sheet_clean_alpha.png',
  metadataAsset: 'assets/images/ui/sprites/edit_task_sheet_clean_alpha.json',
);

class HomePetsButton extends StatefulWidget {
  const HomePetsButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = HomePetsButtonVariant.primary,
    this.height = 48,
    this.width,
    this.textStyle,
    this.semanticsLabel,
    this.labelPadding = const EdgeInsets.symmetric(horizontal: 14),
  });

  final String label;
  final VoidCallback? onPressed;
  final HomePetsButtonVariant variant;
  final double height;
  final double? width;
  final TextStyle? textStyle;
  final String? semanticsLabel;
  final EdgeInsets labelPadding;

  @override
  State<HomePetsButton> createState() => _HomePetsButtonState();
}

class _HomePetsButtonState extends State<HomePetsButton> {
  bool _pressed = false;

  String get _backgroundFrameName {
    switch (widget.variant) {
      case HomePetsButtonVariant.primary:
        return 'save_button_bg.png';
      case HomePetsButtonVariant.secondary:
        return 'cancel_button_bg.png';
    }
  }

  bool get _enabled => widget.onPressed != null;

  void _setPressed(bool pressed) {
    if (!_enabled || _pressed == pressed) {
      return;
    }
    setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    final defaultTextColor = widget.variant == HomePetsButtonVariant.primary
        ? const Color(0xFF4D3623)
        : const Color(0xFF70513A);
    final fallbackColor = widget.variant == HomePetsButtonVariant.primary
        ? const Color(0xFFFFB65A)
        : const Color(0xFFFFF1D7);

    Widget button = SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: _enabled ? 1 : 0.52,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOutCubic,
          scale: _pressed ? 0.975 : 1,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _HomePetsButtonBackground(
                frameName: _backgroundFrameName,
                fallbackColor: fallbackColor,
              ),
              Padding(
                padding: widget.labelPadding,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style:
                          widget.textStyle ??
                          TextStyle(
                            color: defaultTextColor,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            height: 1,
                            letterSpacing: 0,
                          ),
                    ),
                  ),
                ),
              ),
            ],
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
      label: widget.semanticsLabel ?? widget.label,
      child: button,
    );
  }
}

class _HomePetsButtonBackground extends StatelessWidget {
  const _HomePetsButtonBackground({
    required this.frameName,
    required this.fallbackColor,
  });

  final String frameName;
  final Color fallbackColor;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SpriteAtlas>(
      future: _homePetsButtonAtlasAsset.load(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final atlas = snapshot.requireData;
          return SpriteFrameImage(
            imageAsset: atlas.imageAsset,
            sheetSize: atlas.sheetSize,
            frame: atlas.frame(frameName),
            fit: BoxFit.fill,
          );
        }

        return DecoratedBox(
          decoration: BoxDecoration(
            color: fallbackColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFF5E3E25), width: 2),
          ),
        );
      },
    );
  }
}
