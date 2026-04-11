import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homepets/core/ui/sprite_atlas.dart';
import 'package:homepets/screens/home/task_panel_sprite_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SpriteAtlas', () {
    test('parses task sprite atlas frame positions', () async {
      final rawJson = await rootBundle.loadString(
        TaskPanelSpriteCatalog.atlasAsset.metadataAsset,
      );
      final atlas = SpriteAtlas.fromJsonString(
        rawJson,
        imageAsset: TaskPanelSpriteCatalog.atlasAsset.imageAsset,
        metadataAsset: TaskPanelSpriteCatalog.atlasAsset.metadataAsset,
      );

      expect(
        atlas.frame(TaskPanelSpriteCatalog.boardFrameName).textureRect,
        const Rect.fromLTWH(1, 1, 510, 812),
      );
      expect(
        atlas.frame(TaskPanelSpriteCatalog.titleBannerFrameName).textureRect,
        const Rect.fromLTWH(511, 71, 390, 172),
      );
      expect(
        atlas.frame(TaskPanelSpriteCatalog.pushPinFrameName).textureRect,
        const Rect.fromLTWH(901, 71, 104, 124),
      );
      expect(
        atlas.frame(TaskPanelSpriteCatalog.checkboxEmptyFrameName).textureRect,
        const Rect.fromLTWH(511, 478, 88, 82),
      );
      expect(
        atlas.frame(TaskPanelSpriteCatalog.primaryButtonFrameName).textureRect,
        const Rect.fromLTWH(776, 243, 248, 59),
      );
    });

    test('loads the task sprite atlas via the shared asset helper', () async {
      final atlas = await TaskPanelSpriteCatalog.atlasAsset.load();
      final sprites = TaskPanelSpriteCatalog(atlas);

      expect(atlas.frameNames, contains(TaskPanelSpriteCatalog.boardFrameName));
      expect(sprites.titleBanner.aspectRatio, closeTo(390 / 172, 0.0001));
      expect(
        sprites.rowField.textureRect,
        const Rect.fromLTWH(776, 302, 245, 60),
      );
      expect(
        TaskPanelSpriteCatalog.atlasAsset.flameImageAsset,
        'images/ui/sprites/task.png',
      );
    });
  });
}
