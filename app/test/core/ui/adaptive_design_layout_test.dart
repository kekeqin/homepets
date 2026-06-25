import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pickstarpet/core/ui/adaptive_design_layout.dart';

void main() {
  group('AdaptiveDesignLayoutGeometry', () {
    test('contains a matching design viewport without offset', () {
      final geometry = AdaptiveDesignLayoutGeometry.resolve(
        viewportSize: const Size(430, 932),
        designSize: const Size(430, 932),
      );

      expect(geometry.scale, 1);
      expect(geometry.designRect, const Rect.fromLTWH(0, 0, 430, 932));
      expect(
        geometry.toScreenRect(const Rect.fromLTWH(30, 520, 370, 340)),
        const Rect.fromLTWH(30, 520, 370, 340),
      );
    });

    test('uses uniform contain scaling with centered letterboxing', () {
      final geometry = AdaptiveDesignLayoutGeometry.resolve(
        viewportSize: const Size(390, 844),
        designSize: const Size(430, 932),
      );

      expect(geometry.scale, closeTo(844 / 932, 0.0001));
      expect(geometry.designRect.left, closeTo(0.3004, 0.001));
      expect(geometry.designRect.top, 0);

      final screenRect = geometry.toScreenRect(
        const Rect.fromLTWH(30, 520, 370, 340),
      );
      expect(screenRect.left, closeTo(27.47, 0.01));
      expect(screenRect.top, closeTo(470.90, 0.01));
      expect(screenRect.width, closeTo(335.06, 0.01));
      expect(screenRect.height, closeTo(307.90, 0.01));
    });

    test('uses safe area and minimum insets as the available bounds', () {
      final geometry = AdaptiveDesignLayoutGeometry.resolve(
        viewportSize: const Size(430, 932),
        designSize: const Size(430, 932),
        viewPadding: const EdgeInsets.fromLTRB(0, 44, 0, 34),
        minimumInsets: const EdgeInsets.all(16),
      );

      expect(geometry.safeBounds, const Rect.fromLTWH(16, 44, 398, 854));
      expect(geometry.scale, closeTo(854 / 932, 0.0001));
      expect(geometry.designRect.left, closeTo(17.99, 0.01));
      expect(geometry.designRect.top, 44);
    });

    test('supports cover scaling for full-bleed artwork', () {
      final geometry = AdaptiveDesignLayoutGeometry.resolve(
        viewportSize: const Size(390, 844),
        designSize: const Size(430, 932),
        fit: AdaptiveDesignFit.cover,
      );

      expect(geometry.scale, closeTo(390 / 430, 0.0001));
      expect(geometry.designRect.top, closeTo(-0.65, 0.01));
      expect(geometry.designRect.height, closeTo(845.30, 0.01));
    });

    test('maps screen offsets back into design coordinates', () {
      final geometry = AdaptiveDesignLayoutGeometry.resolve(
        viewportSize: const Size(390, 844),
        designSize: const Size(430, 932),
      );
      final screenOffset = geometry.toScreenOffset(const Offset(215, 466));

      expect(geometry.toDesignOffset(screenOffset).dx, closeTo(215, 0.0001));
      expect(geometry.toDesignOffset(screenOffset).dy, closeTo(466, 0.0001));
    });
  });
}
