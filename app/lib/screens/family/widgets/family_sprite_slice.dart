import 'package:flutter/material.dart';

class FamilySpriteSlice extends StatelessWidget {
  const FamilySpriteSlice({
    super.key,
    required this.assetPath,
    required this.region,
  });

  final String assetPath;
  final Rect region;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scaledWidth = constraints.maxWidth / region.width;
        final scaledHeight = constraints.maxHeight / region.height;

        return ClipRect(
          child: Stack(
            children: [
              Positioned(
                left: -(region.left * scaledWidth),
                top: -(region.top * scaledHeight),
                width: scaledWidth,
                height: scaledHeight,
                child: SizedBox(
                  width: scaledWidth,
                  height: scaledHeight,
                  child: Image.asset(
                    assetPath,
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class FamilySpriteRegions {
  static const Rect heroIllustration = Rect.fromLTWH(
    0.657,
    0.045,
    0.316,
    0.184,
  );

  static const Rect footerCat = Rect.fromLTWH(0.565, 0.735, 0.088, 0.105);
}
