import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FamilySpriteSheet {
  const FamilySpriteSheet._();

  static const assetPath =
      'assets/images/ui/sprites/family_home_sprite_clean.png';
  static const sheetSize = Size(1024, 1536);

  static Future<ui.Image>? _imageFuture;

  static Future<ui.Image> loadImage() {
    return _imageFuture ??= _loadImage();
  }

  static Future<ui.Image> _loadImage() async {
    final bytes = await rootBundle.load(assetPath);
    final buffer = Uint8List.view(
      bytes.buffer,
      bytes.offsetInBytes,
      bytes.lengthInBytes,
    );
    final codec = await ui.instantiateImageCodec(buffer);
    final frame = await codec.getNextFrame();
    return frame.image;
  }
}

class FamilySpriteRegions {
  const FamilySpriteRegions._();

  static const Rect outerPanel = Rect.fromLTWH(40, 41, 357, 310);
  static const Rect contentPanel = Rect.fromLTWH(34, 373, 467, 568);
  static const Rect heroIllustration = Rect.fromLTWH(721, 104, 286, 241);
  static const Rect addMemberButton = Rect.fromLTWH(415, 258, 215, 70);
  static const Rect editIcon = Rect.fromLTWH(679, 55, 47, 45);

  static const Rect statMemberIcon = Rect.fromLTWH(427, 176, 44, 30);
  static const Rect statPetIcon = Rect.fromLTWH(539, 174, 40, 34);
  static const Rect starIcon = Rect.fromLTWH(483, 997, 34, 36);

  static const Rect avatarMom = Rect.fromLTWH(50, 955, 87, 91);
  static const Rect avatarChild = Rect.fromLTWH(158, 956, 85, 90);
  static const Rect avatarDad = Rect.fromLTWH(265, 955, 85, 89);
  static const Rect avatarGrandma = Rect.fromLTWH(366, 956, 79, 89);

  static const Rect emptyPetPaw = Rect.fromLTWH(476, 1085, 133, 180);
  static const Rect petShadow = Rect.fromLTWH(612, 1317, 158, 22);
  static const Rect petNameLabel = Rect.fromLTWH(641, 1083, 124, 43);
  static const Rect progressTrack = Rect.fromLTWH(810, 1087, 176, 20);
  static const Rect progressFill = Rect.fromLTWH(812, 1129, 111, 17);
  static const Rect pageDotActive = Rect.fromLTWH(439, 1318, 25, 25);
  static const Rect pageDotInactive = Rect.fromLTWH(508, 1319, 24, 24);
}

class FamilySpriteSkins {
  const FamilySpriteSkins._();

  static const outerPanel = FamilySpritePanelSkin(
    frame: FamilySpriteRegions.outerPanel,
    fill: Rect.fromLTWH(114, 104, 38, 38),
    insets: EdgeInsets.fromLTRB(42, 42, 42, 42),
  );

  static const contentPanel = FamilySpritePanelSkin(
    frame: FamilySpriteRegions.contentPanel,
    fill: Rect.fromLTWH(83, 431, 36, 36),
    insets: EdgeInsets.fromLTRB(30, 30, 30, 30),
  );

  static const statPill = FamilySpritePanelSkin(
    frame: Rect.fromLTWH(410, 159, 94, 60),
    fill: Rect.fromLTWH(477, 181, 12, 12),
    insets: EdgeInsets.fromLTRB(22, 16, 22, 16),
  );

  static const scoreBadge = FamilySpritePanelSkin(
    frame: Rect.fromLTWH(475, 987, 93, 49),
    fill: Rect.fromLTWH(530, 1005, 14, 14),
    insets: EdgeInsets.fromLTRB(22, 13, 20, 13),
  );

  static const petNameLabel = FamilySpritePanelSkin(
    frame: FamilySpriteRegions.petNameLabel,
    fill: Rect.fromLTWH(692, 1097, 12, 12),
    insets: EdgeInsets.fromLTRB(22, 12, 22, 12),
  );

  static const memberCardWarm = FamilySpritePanelSkin(
    frame: Rect.fromLTWH(515, 369, 232, 295),
    fill: Rect.fromLTWH(532, 445, 24, 24),
    insets: EdgeInsets.fromLTRB(20, 20, 20, 20),
  );

  static const memberCardGreen = FamilySpritePanelSkin(
    frame: Rect.fromLTWH(759, 369, 233, 290),
    fill: Rect.fromLTWH(779, 450, 24, 24),
    insets: EdgeInsets.fromLTRB(20, 20, 20, 20),
  );

  static const memberCardBlue = FamilySpritePanelSkin(
    frame: Rect.fromLTWH(516, 667, 230, 278),
    fill: Rect.fromLTWH(538, 750, 24, 24),
    insets: EdgeInsets.fromLTRB(20, 20, 20, 20),
  );

  static const memberCardPink = FamilySpritePanelSkin(
    frame: Rect.fromLTWH(757, 666, 235, 281),
    fill: Rect.fromLTWH(779, 747, 24, 24),
    insets: EdgeInsets.fromLTRB(20, 20, 20, 20),
  );
}

class FamilySpriteSlice extends StatelessWidget {
  const FamilySpriteSlice({
    super.key,
    required this.region,
    this.assetPath = FamilySpriteSheet.assetPath,
    this.sheetSize = FamilySpriteSheet.sheetSize,
    this.fit = BoxFit.fill,
    this.alignment = Alignment.center,
    this.sampleInset = 1,
    this.filterQuality = FilterQuality.high,
  });

  final Rect region;
  final String assetPath;
  final Size sheetSize;
  final BoxFit fit;
  final Alignment alignment;
  final double sampleInset;
  final FilterQuality filterQuality;

  @override
  Widget build(BuildContext context) {
    final resolvedRegion = _deflateSafely(region, sampleInset);

    return FittedBox(
      fit: fit,
      alignment: alignment,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: resolvedRegion.width,
        height: resolvedRegion.height,
        child: ClipRect(
          child: OverflowBox(
            minWidth: sheetSize.width,
            maxWidth: sheetSize.width,
            minHeight: sheetSize.height,
            maxHeight: sheetSize.height,
            alignment: Alignment.topLeft,
            child: Transform.translate(
              offset: Offset(-resolvedRegion.left, -resolvedRegion.top),
              child: Image.asset(
                assetPath,
                width: sheetSize.width,
                height: sheetSize.height,
                fit: BoxFit.fill,
                alignment: Alignment.topLeft,
                filterQuality: filterQuality,
                isAntiAlias: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FamilySpritePanelSkin {
  const FamilySpritePanelSkin({
    required this.frame,
    required this.fill,
    required this.insets,
    this.sampleInset = 1,
  });

  final Rect frame;
  final Rect fill;
  final EdgeInsets insets;
  final double sampleInset;
}

class FamilySpritePanel extends StatelessWidget {
  const FamilySpritePanel({
    super.key,
    required this.skin,
    this.padding = EdgeInsets.zero,
    this.child,
  });

  final FamilySpritePanelSkin skin;
  final EdgeInsetsGeometry padding;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ui.Image>(
      future: FamilySpriteSheet.loadImage(),
      builder: (context, snapshot) {
        final image = snapshot.data;

        return Stack(
          fit: StackFit.passthrough,
          children: [
            if (image != null)
              Positioned.fill(
                child: CustomPaint(
                  painter: _FamilySpritePanelPainter(image: image, skin: skin),
                ),
              ),
            if (child != null)
              Padding(padding: padding, child: child!)
            else
              const SizedBox.expand(),
          ],
        );
      },
    );
  }
}

class FamilySpriteProgressBar extends StatelessWidget {
  const FamilySpriteProgressBar({
    super.key,
    required this.value,
    this.height = 14,
  });

  final double value;
  final double height;

  @override
  Widget build(BuildContext context) {
    final clampedValue = value.clamp(0.0, 1.0).toDouble();

    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const FamilySpriteSlice(region: FamilySpriteRegions.progressTrack),
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: clampedValue,
            child: const FamilySpriteSlice(
              region: FamilySpriteRegions.progressFill,
            ),
          ),
        ],
      ),
    );
  }
}

class _FamilySpritePanelPainter extends CustomPainter {
  const _FamilySpritePanelPainter({required this.image, required this.skin});

  final ui.Image image;
  final FamilySpritePanelSkin skin;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) {
      return;
    }

    final paint = Paint()
      ..filterQuality = FilterQuality.high
      ..isAntiAlias = true;
    final frame = _deflateSafely(skin.frame, skin.sampleInset);
    final fill = _deflateSafely(skin.fill, 0.5);

    canvas.drawImageRect(image, fill, Offset.zero & size, paint);

    final destLeft = skin.insets.left.clamp(0.0, size.width / 2).toDouble();
    final destTop = skin.insets.top.clamp(0.0, size.height / 2).toDouble();
    final destRight = skin.insets.right.clamp(0.0, size.width / 2).toDouble();
    final destBottom = skin.insets.bottom
        .clamp(0.0, size.height / 2)
        .toDouble();

    final srcLeft = skin.insets.left.clamp(0.0, frame.width / 2).toDouble();
    final srcTop = skin.insets.top.clamp(0.0, frame.height / 2).toDouble();
    final srcRight = skin.insets.right.clamp(0.0, frame.width / 2).toDouble();
    final srcBottom = skin.insets.bottom
        .clamp(0.0, frame.height / 2)
        .toDouble();

    final destCenterWidth = (size.width - destLeft - destRight)
        .clamp(0.0, double.infinity)
        .toDouble();
    final destCenterHeight = (size.height - destTop - destBottom)
        .clamp(0.0, double.infinity)
        .toDouble();
    final srcCenterWidth = (frame.width - srcLeft - srcRight)
        .clamp(0.0, double.infinity)
        .toDouble();
    final srcCenterHeight = (frame.height - srcTop - srcBottom)
        .clamp(0.0, double.infinity)
        .toDouble();

    _draw(
      canvas,
      paint,
      Rect.fromLTWH(frame.left, frame.top, srcLeft, srcTop),
      Rect.fromLTWH(0, 0, destLeft, destTop),
    );
    _draw(
      canvas,
      paint,
      Rect.fromLTWH(frame.right - srcRight, frame.top, srcRight, srcTop),
      Rect.fromLTWH(size.width - destRight, 0, destRight, destTop),
    );
    _draw(
      canvas,
      paint,
      Rect.fromLTWH(frame.left, frame.bottom - srcBottom, srcLeft, srcBottom),
      Rect.fromLTWH(0, size.height - destBottom, destLeft, destBottom),
    );
    _draw(
      canvas,
      paint,
      Rect.fromLTWH(
        frame.right - srcRight,
        frame.bottom - srcBottom,
        srcRight,
        srcBottom,
      ),
      Rect.fromLTWH(
        size.width - destRight,
        size.height - destBottom,
        destRight,
        destBottom,
      ),
    );

    _draw(
      canvas,
      paint,
      Rect.fromLTWH(frame.left + srcLeft, frame.top, srcCenterWidth, srcTop),
      Rect.fromLTWH(destLeft, 0, destCenterWidth, destTop),
    );
    _draw(
      canvas,
      paint,
      Rect.fromLTWH(
        frame.left + srcLeft,
        frame.bottom - srcBottom,
        srcCenterWidth,
        srcBottom,
      ),
      Rect.fromLTWH(
        destLeft,
        size.height - destBottom,
        destCenterWidth,
        destBottom,
      ),
    );
    _draw(
      canvas,
      paint,
      Rect.fromLTWH(frame.left, frame.top + srcTop, srcLeft, srcCenterHeight),
      Rect.fromLTWH(0, destTop, destLeft, destCenterHeight),
    );
    _draw(
      canvas,
      paint,
      Rect.fromLTWH(
        frame.right - srcRight,
        frame.top + srcTop,
        srcRight,
        srcCenterHeight,
      ),
      Rect.fromLTWH(
        size.width - destRight,
        destTop,
        destRight,
        destCenterHeight,
      ),
    );
  }

  void _draw(Canvas canvas, Paint paint, Rect source, Rect destination) {
    if (source.width <= 0 ||
        source.height <= 0 ||
        destination.width <= 0 ||
        destination.height <= 0) {
      return;
    }
    canvas.drawImageRect(image, source, destination, paint);
  }

  @override
  bool shouldRepaint(covariant _FamilySpritePanelPainter oldDelegate) {
    return oldDelegate.image != image || oldDelegate.skin != skin;
  }
}

Rect _deflateSafely(Rect rect, double inset) {
  if (inset <= 0) {
    return rect;
  }
  final maxInset = (rect.shortestSide / 2) - 0.5;
  if (maxInset <= 0) {
    return rect;
  }
  return rect.deflate(inset.clamp(0.0, maxInset).toDouble());
}
