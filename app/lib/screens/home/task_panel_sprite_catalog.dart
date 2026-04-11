import 'dart:ui';

import '../../core/ui/sprite_atlas.dart';

class TaskPanelSpriteCatalog {
  const TaskPanelSpriteCatalog(this.atlas);

  static const SpriteAtlasAsset atlasAsset = SpriteAtlasAsset(
    imageAsset: 'assets/images/ui/sprites/task.png',
    metadataAsset: 'assets/images/ui/sprites/task.json',
  );

  static const String boardFrameName = 'image2.png';
  static const String titleBannerFrameName = 'image0.png';
  static const String pushPinFrameName = 'image1.png';
  static const String headerTapeFrameName = 'image10.png';
  static const String primaryButtonFrameName = 'image5.png';
  static const String rowFieldFrameName = 'image6.png';
  static const String dividerFrameName = 'image7.png';
  static const String emptyStateFrameName = 'image14.png';
  static const String checkboxCheckedFrameName = 'image3.png';
  static const String checkboxEmptyFrameName = 'image13.png';
  static const String checkboxFilledFrameName = 'image4.png';
  static const String deleteIconFrameName = 'image15.png';

  final SpriteAtlas atlas;

  String get imageAsset => atlas.imageAsset;
  Size get sheetSize => atlas.sheetSize;

  SpriteAtlasFrame get board => atlas.frame(boardFrameName);
  SpriteAtlasFrame get titleBanner => atlas.frame(titleBannerFrameName);
  SpriteAtlasFrame get pushPin => atlas.frame(pushPinFrameName);
  SpriteAtlasFrame get headerTape => atlas.frame(headerTapeFrameName);
  SpriteAtlasFrame get primaryButton => atlas.frame(primaryButtonFrameName);
  SpriteAtlasFrame get rowField => atlas.frame(rowFieldFrameName);
  SpriteAtlasFrame get divider => atlas.frame(dividerFrameName);
  SpriteAtlasFrame get emptyState => atlas.frame(emptyStateFrameName);
  SpriteAtlasFrame get checkboxChecked => atlas.frame(checkboxCheckedFrameName);
  SpriteAtlasFrame get checkboxEmpty => atlas.frame(checkboxEmptyFrameName);
  SpriteAtlasFrame get checkboxFilled => atlas.frame(checkboxFilledFrameName);
  SpriteAtlasFrame get deleteIcon => atlas.frame(deleteIconFrameName);
}
