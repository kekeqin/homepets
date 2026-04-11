import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'sprite_atlas.dart';

extension SpriteAtlasFrameFlameX on SpriteAtlasFrame {
  Sprite toFlameSprite(ui.Image image) {
    return Sprite(
      image,
      srcPosition: Vector2(textureRect.left, textureRect.top),
      srcSize: Vector2(textureRect.width, textureRect.height),
    );
  }
}
