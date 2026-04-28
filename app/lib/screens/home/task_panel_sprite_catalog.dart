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

class TaskListSheetSpriteCatalog {
  const TaskListSheetSpriteCatalog(this.atlas);

  static const SpriteAtlasAsset atlasAsset = SpriteAtlasAsset(
    imageAsset: 'assets/images/ui/sprites/task_list_sheet_clean.png',
    metadataAsset: 'assets/images/ui/sprites/task_list_sheet_clean.json',
  );

  static const String panelBlankFrameName = 'panel_blank.png';
  static const String titleFrameName = 'title_task_list.png';
  static const String closeButtonFrameName = 'close_button.png';
  static const String taskRowBlankFrameName = 'task_row_blank.png';
  static const String addTaskButtonFrameName = 'add_task_button.png';
  static const String checkboxCheckedFrameName = 'checkbox_checked.png';
  static const String checkboxEmptyFrameName = 'checkbox_empty.png';
  static const String arrowLeftFrameName = 'arrow_left.png';
  static const String arrowRightFrameName = 'arrow_right.png';
  static const String plusIconFrameName = 'plus_icon.png';

  final SpriteAtlas atlas;

  String get imageAsset => atlas.imageAsset;
  Size get sheetSize => atlas.sheetSize;

  SpriteAtlasFrame get panelBlank => atlas.frame(panelBlankFrameName);
  SpriteAtlasFrame get title => atlas.frame(titleFrameName);
  SpriteAtlasFrame get closeButton => atlas.frame(closeButtonFrameName);
  SpriteAtlasFrame get taskRowBlank => atlas.frame(taskRowBlankFrameName);
  SpriteAtlasFrame get addTaskButton => atlas.frame(addTaskButtonFrameName);
  SpriteAtlasFrame get checkboxChecked => atlas.frame(checkboxCheckedFrameName);
  SpriteAtlasFrame get checkboxEmpty => atlas.frame(checkboxEmptyFrameName);
  SpriteAtlasFrame get arrowLeft => atlas.frame(arrowLeftFrameName);
  SpriteAtlasFrame get arrowRight => atlas.frame(arrowRightFrameName);
  SpriteAtlasFrame get plusIcon => atlas.frame(plusIconFrameName);
}

class TaskEditorSheetSpriteCatalog {
  const TaskEditorSheetSpriteCatalog(this.atlas);

  static const SpriteAtlasAsset atlasAsset = SpriteAtlasAsset(
    imageAsset: 'assets/images/ui/sprites/edit_task_sheet_clean_alpha.png',
    metadataAsset: 'assets/images/ui/sprites/edit_task_sheet_clean_alpha.json',
  );

  static const String panelBlankFrameName = 'edit_panel_blank.png';
  static const String closeButtonFrameName = 'close_button.png';
  static const String titleEditTaskFrameName = 'title_edit_task.png';
  static const String labelTaskNameFrameName = 'label_task_name.png';
  static const String taskNameFieldFrameName = 'task_name_field.png';
  static const String labelRewardPointsFrameName = 'label_reward_points.png';
  static const String pointsFieldFrameName = 'points_field.png';
  static const String trashIconFrameName = 'trash_icon.png';
  static const String deleteTaskTextFrameName = 'delete_task_text.png';
  static const String cancelButtonBgFrameName = 'cancel_button_bg.png';
  static const String cancelButtonTextFrameName = 'cancel_button_text.png';
  static const String saveButtonBgFrameName = 'save_button_bg.png';
  static const String saveButtonTextFrameName = 'save_button_text.png';
  static const double panelBlankAspectRatio = 627 / 632;

  final SpriteAtlas atlas;

  String get imageAsset => atlas.imageAsset;
  Size get sheetSize => atlas.sheetSize;

  SpriteAtlasFrame get panelBlank => atlas.frame(panelBlankFrameName);
  SpriteAtlasFrame get closeButton => atlas.frame(closeButtonFrameName);
  SpriteAtlasFrame get titleEditTask => atlas.frame(titleEditTaskFrameName);
  SpriteAtlasFrame get labelTaskName => atlas.frame(labelTaskNameFrameName);
  SpriteAtlasFrame get taskNameField => atlas.frame(taskNameFieldFrameName);
  SpriteAtlasFrame get labelRewardPoints =>
      atlas.frame(labelRewardPointsFrameName);
  SpriteAtlasFrame get pointsField => atlas.frame(pointsFieldFrameName);
  SpriteAtlasFrame get trashIcon => atlas.frame(trashIconFrameName);
  SpriteAtlasFrame get deleteTaskText => atlas.frame(deleteTaskTextFrameName);
  SpriteAtlasFrame get cancelButtonBg => atlas.frame(cancelButtonBgFrameName);
  SpriteAtlasFrame get cancelButtonText =>
      atlas.frame(cancelButtonTextFrameName);
  SpriteAtlasFrame get saveButtonBg => atlas.frame(saveButtonBgFrameName);
  SpriteAtlasFrame get saveButtonText => atlas.frame(saveButtonTextFrameName);
}
