import 'dart:ui';

import '../../core/ui/sprite_atlas.dart';

class TaskBoardReferenceAsset {
  const TaskBoardReferenceAsset._();

  static const String board = 'assets/images/ui/task/1.webp';
  static const String clip = 'assets/images/ui/task/2.webp';
  static const String dialogPanel = 'assets/images/ui/task/33.webp';
  static const String rowWarm = 'assets/images/ui/task/3.webp';
  static const String rowGreen = 'assets/images/ui/task/4.webp';
  static const String rowPink = 'assets/images/ui/task/5.webp';
  static const String rowYellow = 'assets/images/ui/task/6.webp';
  static const String paginationDotActive = 'assets/images/ui/task/7.webp';
  static const String paginationDotInactive = 'assets/images/ui/task/8.webp';
  static const String checkboxEmpty = 'assets/images/ui/task/9.webp';
  static const String addTaskButton = 'assets/images/ui/task/10.webp';
  static const String pawLeft = 'assets/images/ui/task/11.webp';
  static const String pawRight = 'assets/images/ui/task/12.webp';
  static const String rewardStar = 'assets/images/ui/task/13.webp';
  static const double boardWidth = 575;
  static const double boardHeight = 685;
  static const double boardVisibleLeftInset = 8;
  static const double boardVisibleRightInset = 6;
  static const double dialogPanelWidth = 1149;
  static const double dialogPanelHeight = 1369;
  static const double dialogPanelVisibleLeftInset = 48;
  static const double dialogPanelVisibleRightInset = 51;
  static const double clipWidth = 166;
  static const double clipHeight = 116;
  static const double rowWarmWidth = 493;
  static const double rowWarmHeight = 111;
  static const double rowGreenWidth = 496;
  static const double rowGreenHeight = 113;
  static const double rowPinkWidth = 493;
  static const double rowPinkHeight = 109;
  static const double rowYellowWidth = 500;
  static const double rowYellowHeight = 114;
  static const double addTaskButtonWidth = 408;
  static const double addTaskButtonHeight = 124;
  static const Size boardSize = Size(boardWidth, boardHeight);
  static const Size dialogPanelSize = Size(dialogPanelWidth, dialogPanelHeight);
  static const Size clipSize = Size(clipWidth, clipHeight);
  static const Size rowWarmSize = Size(rowWarmWidth, rowWarmHeight);
  static const Size rowGreenSize = Size(rowGreenWidth, rowGreenHeight);
  static const Size rowPinkSize = Size(rowPinkWidth, rowPinkHeight);
  static const Size rowYellowSize = Size(rowYellowWidth, rowYellowHeight);
  static const Size addTaskButtonSize = Size(
    addTaskButtonWidth,
    addTaskButtonHeight,
  );
  static const double boardTopOffset = 42;
  static const double panelWidth = boardWidth;
  static const double panelHeight = boardTopOffset + boardHeight;
  static const double panelAspectRatio = panelWidth / panelHeight;
  static const double panelHeightRatio = panelHeight / panelWidth;
  static const double dialogPanelAspectRatio =
      dialogPanelWidth / dialogPanelHeight;
  static const double addTaskButtonAspectRatio =
      addTaskButtonWidth / addTaskButtonHeight;
  static const List<String> runtimeAssets = <String>[
    board,
    clip,
    dialogPanel,
    rowWarm,
    rowGreen,
    rowPink,
    rowYellow,
    paginationDotActive,
    paginationDotInactive,
    checkboxEmpty,
    addTaskButton,
    pawLeft,
    pawRight,
    rewardStar,
  ];
}

class TaskPanelSpriteCatalog {
  const TaskPanelSpriteCatalog(this.atlas);

  static const SpriteAtlasAsset atlasAsset = SpriteAtlasAsset(
    imageAsset: 'assets/images/ui/sprites/task.webp',
    metadataAsset: 'assets/images/ui/sprites/task.json',
  );

  static const String boardFrameName = 'image2.webp';
  static const String titleBannerFrameName = 'image0.webp';
  static const String pushPinFrameName = 'image1.webp';
  static const String headerTapeFrameName = 'image10.webp';
  static const String primaryButtonFrameName = 'image5.webp';
  static const String rowFieldFrameName = 'image6.webp';
  static const String dividerFrameName = 'image7.webp';
  static const String emptyStateFrameName = 'image14.webp';
  static const String checkboxCheckedFrameName = 'image3.webp';
  static const String checkboxEmptyFrameName = 'image13.webp';
  static const String checkboxFilledFrameName = 'image4.webp';
  static const String deleteIconFrameName = 'image15.webp';

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
    imageAsset: 'assets/images/ui/sprites/task_list_sheet_clean.webp',
    metadataAsset: 'assets/images/ui/sprites/task_list_sheet_clean.json',
  );

  static const String panelBlankFrameName = 'panel_blank.webp';
  static const String titleFrameName = 'title_task_list.webp';
  static const String closeButtonFrameName = 'close_button.webp';
  static const String taskRowBlankFrameName = 'task_row_blank.webp';
  static const String addTaskButtonFrameName = 'add_task_button.webp';
  static const String checkboxCheckedFrameName = 'checkbox_checked.webp';
  static const String checkboxEmptyFrameName = 'checkbox_empty.webp';
  static const String arrowLeftFrameName = 'arrow_left.webp';
  static const String arrowRightFrameName = 'arrow_right.webp';
  static const String plusIconFrameName = 'plus_icon.webp';

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
    imageAsset: 'assets/images/ui/sprites/edit_task_sheet_clean_alpha.webp',
    metadataAsset: 'assets/images/ui/sprites/edit_task_sheet_clean_alpha.json',
  );

  static const String panelBlankFrameName = 'edit_panel_blank.webp';
  static const String closeButtonFrameName = 'close_button.webp';
  static const String titleEditTaskFrameName = 'title_edit_task.webp';
  static const String labelTaskNameFrameName = 'label_task_name.webp';
  static const String taskNameFieldFrameName = 'task_name_field.webp';
  static const String labelRewardPointsFrameName = 'label_reward_points.webp';
  static const String pointsFieldFrameName = 'points_field.webp';
  static const String trashIconFrameName = 'trash_icon.webp';
  static const String deleteTaskTextFrameName = 'delete_task_text.webp';
  static const String cancelButtonBgFrameName = 'cancel_button_bg.webp';
  static const String cancelButtonTextFrameName = 'cancel_button_text.webp';
  static const String saveButtonBgFrameName = 'save_button_bg.webp';
  static const String saveButtonTextFrameName = 'save_button_text.webp';
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
