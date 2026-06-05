import 'dart:math' as math;

import 'package:flutter/widgets.dart';

enum AdaptiveDesignFit { contain, cover }

class AdaptiveDesignLayoutGeometry {
  const AdaptiveDesignLayoutGeometry({
    required this.viewportSize,
    required this.designSize,
    required this.safeBounds,
    required this.designRect,
    required this.scale,
    required this.alignment,
    required this.fit,
  });

  final Size viewportSize;
  final Size designSize;
  final Rect safeBounds;
  final Rect designRect;
  final double scale;
  final Alignment alignment;
  final AdaptiveDesignFit fit;

  Size get scaledDesignSize => designRect.size;
  Offset get designOrigin => designRect.topLeft;

  static AdaptiveDesignLayoutGeometry resolve({
    required Size viewportSize,
    required Size designSize,
    EdgeInsets viewPadding = EdgeInsets.zero,
    EdgeInsets minimumInsets = EdgeInsets.zero,
    AdaptiveDesignFit fit = AdaptiveDesignFit.contain,
    Alignment alignment = Alignment.center,
  }) {
    final safeBounds = _resolveSafeBounds(
      viewportSize: viewportSize,
      viewPadding: viewPadding,
      minimumInsets: minimumInsets,
    );

    if (designSize.width <= 0 ||
        designSize.height <= 0 ||
        safeBounds.width <= 0 ||
        safeBounds.height <= 0) {
      return AdaptiveDesignLayoutGeometry(
        viewportSize: viewportSize,
        designSize: designSize,
        safeBounds: safeBounds,
        designRect: safeBounds,
        scale: 1,
        alignment: alignment,
        fit: fit,
      );
    }

    final scaleX = safeBounds.width / designSize.width;
    final scaleY = safeBounds.height / designSize.height;
    final scale = switch (fit) {
      AdaptiveDesignFit.contain => math.min(scaleX, scaleY),
      AdaptiveDesignFit.cover => math.max(scaleX, scaleY),
    };
    final scaledSize = Size(
      designSize.width * scale,
      designSize.height * scale,
    );
    final spareOffset = Offset(
      safeBounds.width - scaledSize.width,
      safeBounds.height - scaledSize.height,
    );
    final origin = safeBounds.topLeft + alignment.alongOffset(spareOffset);

    return AdaptiveDesignLayoutGeometry(
      viewportSize: viewportSize,
      designSize: designSize,
      safeBounds: safeBounds,
      designRect: origin & scaledSize,
      scale: scale,
      alignment: alignment,
      fit: fit,
    );
  }

  Offset toScreenOffset(Offset designOffset) {
    return Offset(
      designRect.left + designOffset.dx * scale,
      designRect.top + designOffset.dy * scale,
    );
  }

  Offset toDesignOffset(Offset screenOffset) {
    return Offset(
      (screenOffset.dx - designRect.left) / scale,
      (screenOffset.dy - designRect.top) / scale,
    );
  }

  Size toScreenSize(Size designSize) {
    return Size(designSize.width * scale, designSize.height * scale);
  }

  Rect toScreenRect(Rect designRect) {
    final topLeft = toScreenOffset(designRect.topLeft);
    final size = toScreenSize(designRect.size);
    return topLeft & size;
  }
}

class AdaptiveDesignLayout extends StatelessWidget {
  const AdaptiveDesignLayout({
    super.key,
    required this.designSize,
    required this.builder,
    this.fit = AdaptiveDesignFit.contain,
    this.alignment = Alignment.center,
    this.minimumInsets = EdgeInsets.zero,
    this.useViewPadding = true,
  });

  final Size designSize;
  final AdaptiveDesignFit fit;
  final Alignment alignment;
  final EdgeInsets minimumInsets;
  final bool useViewPadding;
  final Widget Function(
    BuildContext context,
    AdaptiveDesignLayoutGeometry geometry,
  )
  builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportSize = Size(
          constraints.hasBoundedWidth && constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width,
          constraints.hasBoundedHeight && constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : MediaQuery.sizeOf(context).height,
        );
        final geometry = AdaptiveDesignLayoutGeometry.resolve(
          viewportSize: viewportSize,
          designSize: designSize,
          viewPadding: useViewPadding
              ? MediaQuery.paddingOf(context)
              : EdgeInsets.zero,
          minimumInsets: minimumInsets,
          fit: fit,
          alignment: alignment,
        );
        return builder(context, geometry);
      },
    );
  }
}

class AdaptiveDesignPositioned extends StatelessWidget {
  const AdaptiveDesignPositioned({
    super.key,
    required this.geometry,
    required this.designRect,
    required this.child,
  });

  final AdaptiveDesignLayoutGeometry geometry;
  final Rect designRect;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned.fromRect(
      rect: geometry.toScreenRect(designRect),
      child: FittedBox(
        fit: BoxFit.fill,
        child: SizedBox(
          width: designRect.width,
          height: designRect.height,
          child: child,
        ),
      ),
    );
  }
}

Rect _resolveSafeBounds({
  required Size viewportSize,
  required EdgeInsets viewPadding,
  required EdgeInsets minimumInsets,
}) {
  final left = math.max(viewPadding.left, minimumInsets.left);
  final top = math.max(viewPadding.top, minimumInsets.top);
  final right = math.max(viewPadding.right, minimumInsets.right);
  final bottom = math.max(viewPadding.bottom, minimumInsets.bottom);
  final width = math.max(0.0, viewportSize.width - left - right);
  final height = math.max(0.0, viewportSize.height - top - bottom);
  return Rect.fromLTWH(left, top, width, height);
}
