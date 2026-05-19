import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FamilySpriteSheet {
  const FamilySpriteSheet._();

  static const assetPath = 'assets/images/ui/sprites/family_home.png';
  static const sheetSize = Size(842, 1264);

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

  static const Rect outerPanel = Rect.fromLTWH(33, 33, 293, 256);
  static const Rect contentPanel = Rect.fromLTWH(29, 306, 384, 468);
  static const Rect heroIllustration = Rect.fromLTWH(596, 85, 233, 199);
  static const Rect addMemberButton = Rect.fromLTWH(342, 211, 177, 60);
  static const Rect editIcon = Rect.fromLTWH(556, 55, 35, 34);

  static const Rect statMemberIcon = Rect.fromLTWH(352, 142, 34, 25);
  static const Rect statPetIcon = Rect.fromLTWH(441, 141, 28, 27);
  static const Rect starIcon = Rect.fromLTWH(522, 142, 29, 27);

  static const Rect avatarMom = Rect.fromLTWH(42, 786, 71, 75);
  static const Rect avatarChild = Rect.fromLTWH(131, 786, 69, 74);
  static const Rect avatarDad = Rect.fromLTWH(217, 786, 69, 74);
  static const Rect avatarGrandma = Rect.fromLTWH(301, 786, 66, 74);

  static const Rect emptyPetPaw = Rect.fromLTWH(390, 892, 111, 150);
  static const Rect petShadow = Rect.fromLTWH(502, 1082, 133, 21);
  static const Rect petNameLabel = Rect.fromLTWH(527, 891, 102, 36);
  static const Rect progressTrack = Rect.fromLTWH(666, 894, 144, 18);
  static const Rect progressFill = Rect.fromLTWH(666, 927, 144, 18);
  static const Rect pageDotActive = Rect.fromLTWH(360, 1078, 20, 21);
  static const Rect pageDotInactive = Rect.fromLTWH(442, 1078, 21, 21);
}

class FamilyHomePartAssets {
  const FamilyHomePartAssets._();

  static const String _base = 'assets/images/ui/sprites/family_home_parts';
  static const String petIcon = '$_base/1.png';
  static const String starIcon = '$_base/2.png';
  static const String memberIcon = '$_base/3.png';
  static const String petNameLabel = '$_base/6.png';
  static const String statBadgeFrame = '$_base/7.png';
  static const String familyIllustration = '$_base/8.png';
  static const String petCircleFrame = '$_base/9.png';
  static const String closeButton = '$_base/5.png';
}

class FamilyPopupAssets {
  const FamilyPopupAssets._();

  static const String _base = 'assets/images/ui/family';
  static const String mainPanel = 'assets/images/ui/task/33.png';
  static const String mainPanelOutline =
      '$_base/family_popup_panel_outline.png';
  static const String cardPanel = '$_base/3.png';
  static const String title = '$_base/8 (3).png';
  static const String closeButton = '$_base/12 (2).png';
  static const String addButton = '$_base/2.png';
  static const String pageArrow = '$_base/9 (2).png';
  static const String namePlate = '$_base/4 (4).png';
  static const String boyPortrait = '$_base/5-(2).png';
  static const String girlPortrait = '$_base/6 (1).png';
  static const String childPortrait = '$_base/7 (1).png';
  static const String adultFemalePortrait =
      '$_base/avatar_adult_male_reference_style.png';
}

class FamilySpriteSkins {
  const FamilySpriteSkins._();

  static const outerPanel = FamilySpritePanelSkin(
    frame: FamilySpriteRegions.outerPanel,
    fill: Rect.fromLTWH(94, 92, 38, 38),
    insets: EdgeInsets.fromLTRB(36, 36, 36, 36),
  );

  static const contentPanel = FamilySpritePanelSkin(
    frame: FamilySpriteRegions.contentPanel,
    fill: Rect.fromLTWH(80, 360, 36, 36),
    insets: EdgeInsets.fromLTRB(28, 28, 28, 28),
  );

  static const statPill = FamilySpritePanelSkin(
    frame: Rect.fromLTWH(337, 130, 78, 47),
    fill: Rect.fromLTWH(386, 147, 10, 10),
    insets: EdgeInsets.fromLTRB(18, 13, 18, 13),
  );

  static const scoreBadge = FamilySpritePanelSkin(
    frame: Rect.fromLTWH(391, 812, 76, 41),
    fill: Rect.fromLTWH(433, 826, 10, 10),
    insets: EdgeInsets.fromLTRB(18, 12, 18, 12),
  );

  static const petNameLabel = FamilySpritePanelSkin(
    frame: FamilySpriteRegions.petNameLabel,
    fill: Rect.fromLTWH(570, 903, 10, 10),
    insets: EdgeInsets.fromLTRB(18, 10, 18, 10),
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
    this.sampleInset = 1.5,
    this.filterQuality = FilterQuality.medium,
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
    final innerPadding = (height * 0.16).clamp(1.0, 2.0).toDouble();

    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0D1),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: const Color(0xFF775131).withValues(alpha: 0.78),
            width: 1,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(innerPadding),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: clampedValue,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFA5BB46), Color(0xFF708D24)],
                    ),
                  ),
                  child: SizedBox.expand(),
                ),
              ),
            ),
          ),
        ),
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
      ..filterQuality = FilterQuality.medium
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
