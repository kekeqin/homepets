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

    test('loads the clean task list sheet atlas', () async {
      final atlas = await TaskListSheetSpriteCatalog.atlasAsset.load();
      final sprites = TaskListSheetSpriteCatalog(atlas);

      expect(
        sprites.panelBlank.textureRect,
        const Rect.fromLTWH(525, 49, 447, 649),
      );
      expect(
        sprites.title.textureRect,
        const Rect.fromLTWH(1066, 43, 317, 137),
      );
      expect(
        sprites.taskRowBlank.textureRect,
        const Rect.fromLTWH(917, 796, 479, 92),
      );
      expect(
        sprites.addTaskButton.textureRect,
        const Rect.fromLTWH(530, 800, 290, 94),
      );
      expect(
        TaskListSheetSpriteCatalog.atlasAsset.flameImageAsset,
        'images/ui/sprites/task_list_sheet_clean.png',
      );
    });

    test('loads the clean task editor sheet atlas', () async {
      final atlas = await TaskEditorSheetSpriteCatalog.atlasAsset.load();
      final sprites = TaskEditorSheetSpriteCatalog(atlas);

      expect(
        sprites.panelBlank.textureRect,
        const Rect.fromLTWH(31, 54, 627, 632),
      );
      expect(
        sprites.closeButton.textureRect,
        const Rect.fromLTWH(808, 69, 98, 100),
      );
      expect(
        sprites.taskNameField.textureRect,
        const Rect.fromLTWH(997, 283, 412, 71),
      );
      expect(
        sprites.saveButtonBg.textureRect,
        const Rect.fromLTWH(727, 941, 275, 104),
      );
      expect(
        TaskEditorSheetSpriteCatalog.atlasAsset.flameImageAsset,
        'images/ui/sprites/edit_task_sheet_clean_alpha.png',
      );
    });
  });
}
