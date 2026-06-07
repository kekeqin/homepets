import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class AppModalLayout {
  const AppModalLayout({
    required this.mobileWidthFactor,
    required this.mobileMaxWidth,
    required this.mobileHeightFactor,
    required this.mobileMaxHeight,
    required this.tabletWidthFactor,
    required this.tabletMaxWidth,
    required this.tabletHeightFactor,
    required this.tabletMaxHeight,
    this.contentAspectRatio,
    this.tabletBreakpoint = 900,
  });

  final double mobileWidthFactor;
  final double mobileMaxWidth;
  final double mobileHeightFactor;
  final double mobileMaxHeight;
  final double tabletWidthFactor;
  final double tabletMaxWidth;
  final double tabletHeightFactor;
  final double tabletMaxHeight;
  final double? contentAspectRatio;
  final double tabletBreakpoint;

  bool isTablet(Size size) => size.width >= tabletBreakpoint;

  double panelWidth(Size size) {
    if (isTablet(size)) {
      return math.min(size.width * tabletWidthFactor, tabletMaxWidth);
    }
    return math.min(size.width * mobileWidthFactor, mobileMaxWidth);
  }

  double panelMaxHeight(Size size) {
    if (isTablet(size)) {
      return math.min(size.height * tabletHeightFactor, tabletMaxHeight);
    }
    return math.min(size.height * mobileHeightFactor, mobileMaxHeight);
  }

  double effectivePanelWidth(Size size, EdgeInsets minimumSafeArea) {
    final maxWidth = panelWidth(size);
    final aspectRatio = contentAspectRatio;
    if (aspectRatio == null || aspectRatio <= 0) {
      return maxWidth;
    }

    final availableHeight = math.max(
      0.0,
      size.height - minimumSafeArea.top - minimumSafeArea.bottom,
    );
    final maxHeight = math.min(panelMaxHeight(size), availableHeight);
    return math.min(maxWidth, maxHeight * aspectRatio);
  }
}

class AppModalVisibleFrame {
  const AppModalVisibleFrame({
    required this.sourceWidth,
    required this.leftInset,
    required this.rightInset,
  });

  final double sourceWidth;
  final double leftInset;
  final double rightInset;
}

class _ResolvedModalHorizontal {
  const _ResolvedModalHorizontal({
    required this.panelWidth,
    required this.safeLeft,
    required this.safeRight,
    required this.offsetX,
  });

  final double panelWidth;
  final double safeLeft;
  final double safeRight;
  final double offsetX;
}

class AppModalLayouts {
  static const petDetail = AppModalLayout(
    mobileWidthFactor: 1.0,
    mobileMaxWidth: 448,
    mobileHeightFactor: 0.90,
    mobileMaxHeight: 700,
    tabletWidthFactor: 0.45,
    tabletMaxWidth: 448,
    tabletHeightFactor: 0.90,
    tabletMaxHeight: 760,
    contentAspectRatio: 499 / 793,
  );

  static const family = AppModalLayout(
    mobileWidthFactor: 1.0,
    mobileMaxWidth: 470,
    mobileHeightFactor: 0.99,
    mobileMaxHeight: 900,
    tabletWidthFactor: 0.52,
    tabletMaxWidth: 620,
    tabletHeightFactor: 0.96,
    tabletMaxHeight: 940,
    contentAspectRatio: 0.64,
  );

  static const taskPanel = AppModalLayout(
    mobileWidthFactor: 0.72,
    mobileMaxWidth: 360,
    mobileHeightFactor: 0.64,
    mobileMaxHeight: 520,
    tabletWidthFactor: 0.38,
    tabletMaxWidth: 420,
    tabletHeightFactor: 0.72,
    tabletMaxHeight: 620,
  );

  static const paywall = AppModalLayout(
    mobileWidthFactor: 1.0,
    mobileMaxWidth: 540,
    mobileHeightFactor: 0.88,
    mobileMaxHeight: 780,
    tabletWidthFactor: 0.46,
    tabletMaxWidth: 560,
    tabletHeightFactor: 0.86,
    tabletMaxHeight: 820,
    contentAspectRatio: 760 / 1320,
  );
}

class HomePetsDialogTheme {
  const HomePetsDialogTheme._();

  static const surfaceTop = Color(0xFFFFF4E5);
  static const surfaceBottom = Color(0xFFF3E0C4);
  static const panelBorder = Color(0xFFE1C7A7);
  static const primaryText = Color(0xFF684328);
  static const secondaryText = Color(0xFF98745A);
  static const accent = Color(0xFFD99955);
  static const accentDark = Color(0xFFA86C35);
  static const sage = Color(0xFF8DA66A);
  static const shadow = Color(0x28604429);
  static const barrierTint = Color(0x32674A30);
  static const borderRadius = BorderRadius.all(Radius.circular(28));
  static const closeIconAsset = 'assets/images/ui/close_icon_simple.png';

  static const shellGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surfaceTop, surfaceBottom],
  );

  static const shellShadow = [
    BoxShadow(color: shadow, blurRadius: 30, offset: Offset(0, 14)),
  ];
}

class HomePetsDialogGutter {
  const HomePetsDialogGutter._();

  static const double large = 20;
  static const double medium = 32;
  static const double small = 48;

  static const largeInsets = EdgeInsets.fromLTRB(large, 12, large, 12);
  static const mediumInsets = EdgeInsets.fromLTRB(medium, 20, medium, 20);
  static const smallInsets = EdgeInsets.fromLTRB(small, 20, small, 20);
}

Future<T?> showAppModalDialog<T>({
  required BuildContext context,
  required Widget Function(BuildContext dialogContext) pageBuilder,
  required String barrierLabel,
  bool useRootNavigator = true,
  bool barrierDismissible = true,
  Duration transitionDuration = const Duration(milliseconds: 240),
  double beginScale = 0.94,
  double beginYOffset = 18,
  double blurSigma = 0,
  Color barrierTint = Colors.transparent,
}) {
  return showGeneralDialog<T>(
    context: context,
    useRootNavigator: useRootNavigator,
    barrierLabel: barrierLabel,
    barrierDismissible: barrierDismissible,
    barrierColor: Colors.transparent,
    transitionDuration: transitionDuration,
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return pageBuilder(dialogContext);
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final progress = Curves.easeInOutCubicEmphasized.transform(
        animation.value,
      );
      final backdropOpacity = Curves.easeOutCubic.transform(animation.value);
      final panelScale = ui.lerpDouble(beginScale, 1.0, progress)!;
      final panelTranslateY = ui.lerpDouble(beginYOffset, 0, progress)!;

      return Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: barrierDismissible
                  ? () => Navigator.of(context).maybePop()
                  : null,
              child: ClipRect(
                child: blurSigma > 0
                    ? BackdropFilter(
                        filter: ui.ImageFilter.blur(
                          sigmaX: blurSigma * backdropOpacity,
                          sigmaY: blurSigma * backdropOpacity,
                        ),
                        child: ColoredBox(
                          color: Color.lerp(
                            Colors.transparent,
                            barrierTint,
                            backdropOpacity,
                          )!,
                          child: const SizedBox.expand(),
                        ),
                      )
                    : ColoredBox(
                        color: Color.lerp(
                          Colors.transparent,
                          barrierTint,
                          backdropOpacity,
                        )!,
                        child: const SizedBox.expand(),
                      ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              ignoring: animation.value == 0,
              child: Opacity(
                opacity: backdropOpacity,
                child: Transform.translate(
                  offset: Offset(0, panelTranslateY),
                  child: Transform.scale(scale: panelScale, child: child),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

class AppModalShell extends StatelessWidget {
  const AppModalShell({
    super.key,
    required this.layout,
    required this.child,
    this.minimumSafeArea = HomePetsDialogGutter.mediumInsets,
    this.visibleFrame,
    this.borderRadius = const BorderRadius.all(Radius.circular(30)),
    this.backgroundColor,
    this.gradient,
    this.border,
    this.boxShadow,
    this.clipChild = true,
  });

  final AppModalLayout layout;
  final Widget child;
  final EdgeInsets minimumSafeArea;
  final AppModalVisibleFrame? visibleFrame;
  final BorderRadius borderRadius;
  final Color? backgroundColor;
  final Gradient? gradient;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  final bool clipChild;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final horizontal = _resolveHorizontal(size);
    final aspectRatio = layout.contentAspectRatio;
    final panelHeight = aspectRatio == null || aspectRatio <= 0
        ? null
        : horizontal.panelWidth / aspectRatio;

    Widget current = child;
    if (clipChild) {
      current = ClipRRect(borderRadius: borderRadius, child: current);
    }

    if (backgroundColor != null ||
        gradient != null ||
        border != null ||
        boxShadow != null) {
      current = DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          gradient: gradient,
          borderRadius: borderRadius,
          border: border,
          boxShadow: boxShadow,
        ),
        child: current,
      );
    }

    current = Material(type: MaterialType.transparency, child: current);

    return SafeArea(
      minimum: EdgeInsets.fromLTRB(
        horizontal.safeLeft,
        minimumSafeArea.top,
        horizontal.safeRight,
        minimumSafeArea.bottom,
      ),
      child: Center(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {},
          child: Transform.translate(
            offset: Offset(horizontal.offsetX, 0),
            child: SizedBox(
              width: horizontal.panelWidth,
              height: panelHeight,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: layout.panelMaxHeight(size),
                ),
                child: current,
              ),
            ),
          ),
        ),
      ),
    );
  }

  _ResolvedModalHorizontal _resolveHorizontal(Size size) {
    final layoutWidth = layout.effectivePanelWidth(size, minimumSafeArea);
    final frame = visibleFrame;
    if (frame == null || frame.sourceWidth <= 0) {
      return _ResolvedModalHorizontal(
        panelWidth: layoutWidth,
        safeLeft: minimumSafeArea.left,
        safeRight: minimumSafeArea.right,
        offsetX: 0,
      );
    }

    final visibleSourceWidth =
        frame.sourceWidth - frame.leftInset - frame.rightInset;
    if (visibleSourceWidth <= 0) {
      return _ResolvedModalHorizontal(
        panelWidth: layoutWidth,
        safeLeft: minimumSafeArea.left,
        safeRight: minimumSafeArea.right,
        offsetX: 0,
      );
    }

    final visibleWidthRatio = visibleSourceWidth / frame.sourceWidth;
    final targetVisibleWidth = math.max(
      0.0,
      size.width - minimumSafeArea.left - minimumSafeArea.right,
    );
    final widthForVisibleGutters = targetVisibleWidth / visibleWidthRatio;
    final panelWidth = math.min(layoutWidth, widthForVisibleGutters);
    final scaledLeftInset = panelWidth * frame.leftInset / frame.sourceWidth;
    final scaledRightInset = panelWidth * frame.rightInset / frame.sourceWidth;

    return _ResolvedModalHorizontal(
      panelWidth: panelWidth,
      safeLeft: 0,
      safeRight: 0,
      offsetX: (scaledRightInset - scaledLeftInset) / 2,
    );
  }
}
