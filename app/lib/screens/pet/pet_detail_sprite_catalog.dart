import 'dart:ui';

import '../../core/ui/sprite_atlas.dart';

class PetDetailSheetSpriteCatalog {
  const PetDetailSheetSpriteCatalog._();

  static const SpriteAtlasAsset atlasAsset = SpriteAtlasAsset(
    imageAsset: imageAsset,
    metadataAsset: 'assets/images/ui/sprites/pet_detail_sheet_clean_alpha.json',
  );

  static const String imageAsset =
      'assets/images/ui/sprites/pet_detail_sheet_clean_alpha.png';
  static const Size sheetSize = Size(1130, 1392);

  static const String panelBlankFrameName = 'panel_blank.png';
  static const String nameBannerFrameName = 'name_banner.png';
  static const String closeButtonFrameName = 'close_button.png';
  static const String portraitFrameBlankFrameName = 'portrait_frame_blank.png';
  static const String stageCardFrameName = 'stage_card.png';
  static const String growthCardFrameName = 'growth_card.png';
  static const String feedCardFrameName = 'feed_card.png';
  static const String recentPanelFrameName = 'recent_panel.png';
  static const String achievementTagFrameName = 'achievement_tag.png';
  static const String bookIconFrameName = 'book_icon.png';
  static const String fishIconFrameName = 'fish_icon.png';
  static const String wandIconFrameName = 'wand_icon.png';

  static const SpriteAtlasFrame panelBlank = SpriteAtlasFrame(
    name: panelBlankFrameName,
    textureRect: Rect.fromLTWH(20, 48, 499, 793),
    sourceRect: Rect.fromLTWH(0, 0, 499, 793),
    sourceSize: Size(499, 793),
    rotated: false,
    trimmed: false,
  );

  static const SpriteAtlasFrame nameBanner = SpriteAtlasFrame(
    name: nameBannerFrameName,
    textureRect: Rect.fromLTWH(548, 50, 401, 130),
    sourceRect: Rect.fromLTWH(0, 0, 401, 130),
    sourceSize: Size(401, 130),
    rotated: false,
    trimmed: false,
  );

  static const SpriteAtlasFrame closeButton = SpriteAtlasFrame(
    name: closeButtonFrameName,
    textureRect: Rect.fromLTWH(980, 63, 110, 111),
    sourceRect: Rect.fromLTWH(0, 0, 110, 111),
    sourceSize: Size(110, 111),
    rotated: false,
    trimmed: false,
  );

  static const SpriteAtlasFrame portraitFrameBlank = SpriteAtlasFrame(
    name: portraitFrameBlankFrameName,
    textureRect: Rect.fromLTWH(531, 216, 262, 379),
    sourceRect: Rect.fromLTWH(0, 0, 262, 379),
    sourceSize: Size(262, 379),
    rotated: false,
    trimmed: false,
  );

  static const SpriteAtlasFrame stageCard = SpriteAtlasFrame(
    name: stageCardFrameName,
    textureRect: Rect.fromLTWH(807, 211, 294, 174),
    sourceRect: Rect.fromLTWH(0, 0, 294, 174),
    sourceSize: Size(294, 174),
    rotated: false,
    trimmed: false,
  );

  static const SpriteAtlasFrame growthCard = SpriteAtlasFrame(
    name: growthCardFrameName,
    textureRect: Rect.fromLTWH(798, 502, 296, 145),
    sourceRect: Rect.fromLTWH(0, 0, 296, 145),
    sourceSize: Size(296, 145),
    rotated: false,
    trimmed: false,
  );

  static const SpriteAtlasFrame feedCard = SpriteAtlasFrame(
    name: feedCardFrameName,
    textureRect: Rect.fromLTWH(791, 716, 276, 142),
    sourceRect: Rect.fromLTWH(0, 0, 276, 142),
    sourceSize: Size(276, 142),
    rotated: false,
    trimmed: false,
  );

  static const SpriteAtlasFrame recentPanel = SpriteAtlasFrame(
    name: recentPanelFrameName,
    textureRect: Rect.fromLTWH(41, 875, 533, 396),
    sourceRect: Rect.fromLTWH(0, 0, 533, 396),
    sourceSize: Size(533, 396),
    rotated: false,
    trimmed: false,
  );

  static const SpriteAtlasFrame achievementTag = SpriteAtlasFrame(
    name: achievementTagFrameName,
    textureRect: Rect.fromLTWH(824, 886, 245, 358),
    sourceRect: Rect.fromLTWH(0, 0, 245, 358),
    sourceSize: Size(245, 358),
    rotated: false,
    trimmed: false,
  );

  static const SpriteAtlasFrame bookIcon = SpriteAtlasFrame(
    name: bookIconFrameName,
    textureRect: Rect.fromLTWH(640, 920, 102, 88),
    sourceRect: Rect.fromLTWH(0, 0, 102, 88),
    sourceSize: Size(102, 88),
    rotated: false,
    trimmed: false,
  );

  static const SpriteAtlasFrame fishIcon = SpriteAtlasFrame(
    name: fishIconFrameName,
    textureRect: Rect.fromLTWH(631, 1040, 101, 89),
    sourceRect: Rect.fromLTWH(0, 0, 101, 89),
    sourceSize: Size(101, 89),
    rotated: false,
    trimmed: false,
  );

  static const SpriteAtlasFrame wandIcon = SpriteAtlasFrame(
    name: wandIconFrameName,
    textureRect: Rect.fromLTWH(635, 1150, 105, 96),
    sourceRect: Rect.fromLTWH(0, 0, 105, 96),
    sourceSize: Size(105, 96),
    rotated: false,
    trimmed: false,
  );
}
