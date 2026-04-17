import 'dart:math' as math;

import 'dart:ui' as ui;

import 'package:dio/dio.dart';

import 'package:flame_riverpod/flame_riverpod.dart';

import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../core/api_error_helper.dart';
import '../../core/ui/sprite_atlas.dart';

import '../../models/pet.dart';
import '../../models/pet_artwork.dart';

import '../../providers/auth_provider.dart';

import '../pet/widgets/pet_detail_view.dart';
import '../shop/shop_screen.dart';

import 'game/home_scene_game.dart';
import 'task_panel_sprite_catalog.dart';

enum _TaskPanelRowAction { edit, delete, complete }

const String _taskEditorPanelAsset = 'assets/images/ui/task_editor_panel.png';

const String _taskContextMenuBoardAsset =
    'assets/images/ui/task_context_menu_board_compact.png';

const String _taskContextMenuEditButtonAsset =
    'assets/images/ui/task_context_menu_btn_edit.png';

const String _taskContextMenuDeleteButtonAsset =
    'assets/images/ui/task_context_menu_btn_delete.png';

const String _taskContextMenuCompleteButtonAsset =
    'assets/images/ui/task_context_menu_btn_cancel.png';

const double _taskEditorAssetWidth = 399;

const double _taskEditorAssetHeight = 307;

const int _taskTitleMaxLength = 200;

const int _taskPointsMin = 1;

const int _taskPointsMax = 1000;

const String _taskPanelBoardAsset = 'assets/images/ui/task.png';
const String _taskPanelNoteAsset = 'assets/images/ui/task_note.png';
const String _taskPanelStickerAsset = 'assets/images/ui/task_add_sticker.png';
const String _taskPanelRowFieldAsset =
    'assets/images/ui/task_row_field_idle.png';
const String _taskPanelCheckboxEmptyAsset =
    'assets/images/ui/task_checkbox_empty.png';
const String _taskPanelCheckboxCheckedAsset =
    'assets/images/ui/task_checkbox_checked.png';
const Rect _taskPanelBoardCropRect = Rect.fromLTWH(431, 326, 492, 792);
const Size _taskPanelBoardSourceSize = Size(1024, 1536);
const double _taskPanelBoardAspectRatio = 492 / 792;
const double _taskPanelBoardHeightRatio = 792 / 492;
const Duration _taskPanelTransitionDuration = Duration(milliseconds: 320);
const Duration _petDetailOverlayDuration = Duration(milliseconds: 260);
const String _taskPanelAddButtonLabel = '+ \u6dfb\u52a0\u4efb\u52a1';

class HomeSceneFlameView extends ConsumerStatefulWidget {
  const HomeSceneFlameView({
    super.key,
    required this.device,
    this.openTasksPanelOnStart = false,
    this.openShopPanelOnStart = false,
  });

  final HomeSceneDevice device;
  final bool openTasksPanelOnStart;
  final bool openShopPanelOnStart;

  @override
  ConsumerState<HomeSceneFlameView> createState() => _HomeSceneFlameViewState();
}

class _HomeSceneFlameViewState extends ConsumerState<HomeSceneFlameView>
    with TickerProviderStateMixin {
  late HomeSceneGame _game;

  late GlobalKey<RiverpodAwareGameWidgetState<HomeSceneGame>> _gameKey;
  late final AnimationController _taskPanelController;
  late final AnimationController _petDetailOverlayController;

  SpriteAtlas? _taskPanelSpriteAtlas;
  List<Pet> _pets = const <Pet>[];

  List<Map<String, dynamic>> _homeTasks = const <Map<String, dynamic>>[];
  bool _didRequestInitialTaskPanel = false;
  bool _didRequestInitialShopPanel = false;
  bool _shopPanelVisible = false;
  bool _taskPanelVisible = false;
  bool _taskPanelExpanded = false;
  bool _taskPanelClosing = false;
  bool _taskPanelBackdropInteractive = false;
  bool _clearTaskRouteAfterClose = false;
  int _taskPanelPageIndex = 0;
  Rect? _taskPanelOriginRect;
  bool _didPrecacheTaskPanelAssets = false;
  String? _taskPanelPressedInteractionKey;
  bool _petDetailVisible = false;
  bool _petDetailClosing = false;
  bool _petDetailBackdropInteractive = false;
  Pet? _activePetDetail;

  static const int _taskPanelPageSize = 4;

  bool get _isAdmin {
    final user = ref.read(authProvider).user;

    return user?.isAdmin == true;
  }

  @override
  void initState() {
    super.initState();

    _game = _createGame();

    _gameKey = GlobalKey<RiverpodAwareGameWidgetState<HomeSceneGame>>();
    _taskPanelController = AnimationController(
      vsync: this,
      duration: _taskPanelTransitionDuration,
      reverseDuration: _taskPanelTransitionDuration,
    );
    _petDetailOverlayController = AnimationController(
      vsync: this,
      duration: _petDetailOverlayDuration,
      reverseDuration: _petDetailOverlayDuration,
    );

    _preloadTaskPanelSpriteAtlas();
    _loadFamilyPets();

    _loadHomeTasks();
    _maybeOpenInitialTaskPanel();
    _maybeOpenInitialShopPanel();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheTaskPanelAssets();
  }

  void _precacheTaskPanelAssets() {
    if (_didPrecacheTaskPanelAssets) {
      return;
    }

    _didPrecacheTaskPanelAssets = true;
    for (final assetPath in <String>[
      _taskPanelNoteAsset,
      _taskPanelBoardAsset,
      _taskPanelStickerAsset,
      _taskPanelRowFieldAsset,
      _taskPanelCheckboxEmptyAsset,
      _taskPanelCheckboxCheckedAsset,
      TaskPanelSpriteCatalog.atlasAsset.imageAsset,
    ]) {
      precacheImage(AssetImage(assetPath), context);
    }
  }

  void _preloadTaskPanelSpriteAtlas() {
    TaskPanelSpriteCatalog.atlasAsset.load().then((atlas) {
      if (!mounted) {
        _taskPanelSpriteAtlas = atlas;
        return;
      }

      setState(() => _taskPanelSpriteAtlas = atlas);
    });
  }

  @override
  void reassemble() {
    super.reassemble();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _syncGameTasksFromServer();
      _syncGamePetsFromServer();
    });
  }

  @override
  void didUpdateWidget(covariant HomeSceneFlameView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.device != widget.device) {
      _game.startExitAnimation();

      _game = _createGame();

      _gameKey = GlobalKey<RiverpodAwareGameWidgetState<HomeSceneGame>>();

      _syncGameTasksFromServer();
      _syncGamePetsFromServer();
      _didRequestInitialTaskPanel = false;
      _didRequestInitialShopPanel = false;
    }

    if (!oldWidget.openTasksPanelOnStart && widget.openTasksPanelOnStart) {
      _didRequestInitialTaskPanel = false;
    }

    if (!oldWidget.openShopPanelOnStart && widget.openShopPanelOnStart) {
      _didRequestInitialShopPanel = false;
    }

    _maybeOpenInitialTaskPanel();
    _maybeOpenInitialShopPanel();
  }

  HomeSceneGame _createGame() {
    return HomeSceneGame(
      device: widget.device,
      onTaskTap: () => _handleTaskStickerTap(),

      onOpenFamily: _openFamily,

      onOpenShop: _openShop,

      onTaskItemLongPress: _showTaskPanelRowActions,

      onTaskAddTap: _handleTaskAddTap,

      onOpenPetDetail: _openPetDetail,
    );
  }

  void _maybeOpenInitialTaskPanel() {
    if (!widget.openTasksPanelOnStart || _didRequestInitialTaskPanel) {
      return;
    }

    _didRequestInitialTaskPanel = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _handleTaskStickerTap(clearRouteAfterClose: true);
    });
  }

  void _openFamily() {
    if (!mounted) {
      return;
    }

    context.go('/family');
  }

  void _openShop() {
    if (!mounted) {
      return;
    }

    _showShopPanel(clearRouteAfterClose: false);
  }

  void _maybeOpenInitialShopPanel() {
    if (!widget.openShopPanelOnStart || _didRequestInitialShopPanel) {
      return;
    }

    _didRequestInitialShopPanel = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _showShopPanel(clearRouteAfterClose: true);
    });
  }

  Future<void> _showShopPanel({required bool clearRouteAfterClose}) async {
    if (_shopPanelVisible) {
      return;
    }

    _shopPanelVisible = true;
    await showGeneralDialog<void>(
      context: context,
      barrierLabel: 'shop_overlay',
      barrierDismissible: true,
      barrierColor: const Color(0x660F0A05),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return ShopScreen(
          embedded: true,
          onClose: () => Navigator.of(dialogContext).pop(),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
    _shopPanelVisible = false;

    if (!mounted || !clearRouteAfterClose) {
      return;
    }

    final routerState = GoRouterState.of(context);
    if (routerState.matchedLocation == '/home' &&
        routerState.uri.queryParameters['panel'] == 'shop') {
      context.go('/home');
    }
  }

  List<Map<String, dynamic>> get _activeHomeTasks =>
      _homeTasks.where((item) => item['is_active'] != false).toList();

  int get _taskPanelPageCount => math.max(
    1,
    (_activeHomeTasks.length + _taskPanelPageSize - 1) ~/ _taskPanelPageSize,
  );

  int get _taskPanelCurrentPageIndex => _taskPanelPageIndex
      .clamp(0, math.max(0, _taskPanelPageCount - 1))
      .toInt();

  int get _taskPanelCurrentPageNumber => _taskPanelCurrentPageIndex + 1;

  bool get _canGoToPreviousTaskPage =>
      _taskPanelPageCount > 1 && _taskPanelCurrentPageIndex > 0;

  bool get _canGoToNextTaskPage =>
      _taskPanelPageCount > 1 &&
      _taskPanelCurrentPageIndex < _taskPanelPageCount - 1;

  String get _taskPanelPageIndicatorLabel =>
      '$_taskPanelCurrentPageNumber/$_taskPanelPageCount';

  List<Map<String, dynamic>> get _visibleTaskPanelTasks {
    final tasks = _activeHomeTasks;
    final start = _taskPanelCurrentPageIndex * _taskPanelPageSize;
    if (start >= tasks.length) {
      return const <Map<String, dynamic>>[];
    }
    final end = math.min(start + _taskPanelPageSize, tasks.length);
    return tasks.sublist(start, end);
  }

  Rect _defaultTaskPanelOriginRect(Size size) {
    final width = math.min(size.width * 0.18, 118.0);
    final height = width * 1.16;
    return Rect.fromLTWH(size.width * 0.06, size.height * 0.10, width, height);
  }

  Rect _clampPanelRect(Rect rect, Size size) {
    final maxLeft = math.max(0.0, size.width - rect.width);
    final maxTop = math.max(0.0, size.height - rect.height);
    return Rect.fromLTWH(
      rect.left.clamp(0.0, maxLeft).toDouble(),
      rect.top.clamp(0.0, maxTop).toDouble(),
      rect.width,
      rect.height,
    );
  }

  Rect _expandedTaskPanelRect(Size size) {
    final maxWidth = math.min(size.width * 0.76, 388.0);
    final maxHeight = size.height * 0.72;
    final height = math.min(maxHeight, maxWidth * _taskPanelBoardHeightRatio);
    final width = height / _taskPanelBoardHeightRatio;
    return Rect.fromCenter(
      center: Offset(size.width * 0.5, size.height * 0.52),
      width: width,
      height: height,
    );
  }

  Future<void> _handleTaskStickerTap({
    bool clearRouteAfterClose = false,
  }) async {
    if (!mounted || _taskPanelVisible) {
      return;
    }

    final gameBox = _gameKey.currentContext?.findRenderObject() as RenderBox?;
    final gameSize = gameBox?.size ?? MediaQuery.sizeOf(context);
    final originRect = _clampPanelRect(
      _game.taskPanelOriginRect() ?? _defaultTaskPanelOriginRect(gameSize),
      gameSize,
    );

    setState(() {
      _taskPanelOriginRect = originRect;
      _taskPanelVisible = true;
      _taskPanelExpanded = true;
      _taskPanelClosing = false;
      _taskPanelBackdropInteractive = false;
      _clearTaskRouteAfterClose = clearRouteAfterClose;
      _taskPanelPressedInteractionKey = null;
      _taskPanelPageIndex = _taskPanelPageIndex.clamp(
        0,
        math.max(0, _taskPanelPageCount - 1),
      );
    });

    await _taskPanelController.forward(from: 0);
    if (!mounted || !_taskPanelVisible || !_taskPanelExpanded) {
      return;
    }

    setState(() => _taskPanelBackdropInteractive = true);
  }

  Future<void> _hideTaskPanel() async {
    if (!_taskPanelVisible || _taskPanelClosing) {
      return;
    }

    final shouldClearRoute = _clearTaskRouteAfterClose;
    setState(() {
      _taskPanelClosing = true;
      _taskPanelExpanded = false;
      _taskPanelBackdropInteractive = false;
    });

    await _taskPanelController.reverse(
      from: _taskPanelController.value == 0 ? 1 : _taskPanelController.value,
    );
    if (!mounted) {
      return;
    }

    setState(() {
      _taskPanelVisible = false;
      _taskPanelClosing = false;
      _taskPanelBackdropInteractive = false;
      _clearTaskRouteAfterClose = false;
      _taskPanelOriginRect = null;
      _taskPanelPressedInteractionKey = null;
    });

    if (!shouldClearRoute) {
      return;
    }

    final routerState = GoRouterState.of(context);
    if (routerState.matchedLocation == '/home' &&
        routerState.uri.queryParameters['panel'] == 'tasks') {
      context.go('/home');
    }
  }

  void _goToPreviousTaskPage() {
    if (!_canGoToPreviousTaskPage) {
      return;
    }

    setState(() => _taskPanelPageIndex = _taskPanelCurrentPageIndex - 1);
  }

  void _goToNextTaskPage() {
    if (!_canGoToNextTaskPage) {
      return;
    }

    setState(() => _taskPanelPageIndex = _taskPanelCurrentPageIndex + 1);
  }

  Future<void> _showTaskPanelRowActionsFromGlobalPosition(
    String taskLabel,
    Offset globalPosition,
  ) async {
    if (!mounted) {
      return;
    }

    if (!_isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '\u4ec5\u7ba1\u7406\u5458\u53ef\u65b0\u589e\u4efb\u52a1',
          ),
        ),
      );
      return;
    }

    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlayBox == null) {
      return;
    }

    final anchorInOverlay = overlayBox.globalToLocal(globalPosition);
    final action = await _showSpriteTaskContextMenu(anchorInOverlay);

    if (!mounted) {
      return;
    }

    switch (action) {
      case _TaskPanelRowAction.edit:
        await _editTaskByLabel(taskLabel);
        break;
      case _TaskPanelRowAction.delete:
        await _deleteTaskByLabel(taskLabel);
        break;
      case _TaskPanelRowAction.complete:
        await _completeTaskByLabel(taskLabel);
        break;
      case null:
        break;
    }
  }

  double _taskPanelIntervalValue(
    double value, {
    required double begin,
    required double end,
    Curve curve = Curves.linear,
  }) {
    if (value <= begin) {
      return 0;
    }
    if (value >= end) {
      return 1;
    }

    final normalized = ((value - begin) / (end - begin)).clamp(0.0, 1.0);
    return curve.transform(normalized.toDouble());
  }

  Widget _buildTaskPanelBoardLayer() {
    return Center(
      child: AspectRatio(
        aspectRatio: _taskPanelBoardAspectRatio,
        child: FittedBox(
          fit: BoxFit.fill,
          child: SizedBox(
            width: _taskPanelBoardCropRect.width,
            height: _taskPanelBoardCropRect.height,
            child: Stack(
              children: [
                Positioned(
                  left: -_taskPanelBoardCropRect.left,
                  top: -_taskPanelBoardCropRect.top,
                  child: Image.asset(
                    _taskPanelBoardAsset,
                    width: _taskPanelBoardSourceSize.width,
                    height: _taskPanelBoardSourceSize.height,
                    fit: BoxFit.fill,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _taskPanelTaskTitle(Map<String, dynamic> task) {
    return (task['title'] ?? '\u672a\u547d\u540d\u4efb\u52a1').toString();
  }

  String _taskPanelTaskPointsLabel(Map<String, dynamic> task) {
    final points = _asInt(task['points'], fallback: 10);
    return '$points\u5206';
  }

  bool _taskPanelTaskCompleted(Map<String, dynamic> task) {
    return task['is_completed'] == true ||
        task['completed'] == true ||
        task['done'] == true;
  }

  String _taskPanelInteractionKey(
    Map<String, dynamic> task,
    int index, {
    required String area,
  }) {
    final taskId = _asInt(task['id'], fallback: -1);
    final taskToken = taskId > 0
        ? 'task_$taskId'
        : 'page_${_taskPanelCurrentPageIndex}_${index}_${_taskPanelTaskTitle(task)}';
    return '$area:$taskToken';
  }

  bool _isTaskPanelInteractionPressed(String key) =>
      _taskPanelPressedInteractionKey == key;

  void _setTaskPanelInteractionPressed(String key) {
    if (!mounted || _taskPanelPressedInteractionKey == key) {
      return;
    }
    setState(() => _taskPanelPressedInteractionKey = key);
  }

  void _clearTaskPanelInteractionPressed(String key, {bool delayed = false}) {
    if (delayed) {
      Future<void>.delayed(const Duration(milliseconds: 85), () {
        if (!mounted || _taskPanelPressedInteractionKey != key) {
          return;
        }
        setState(() => _taskPanelPressedInteractionKey = null);
      });
      return;
    }

    if (!mounted || _taskPanelPressedInteractionKey != key) {
      return;
    }
    setState(() => _taskPanelPressedInteractionKey = null);
  }

  Widget _buildTaskPanelPointsText({
    required String label,
    required double width,
    required double fontSize,
    required bool completed,
  }) {
    final textColor = const Color(
      0xFF846F59,
    ).withValues(alpha: completed ? 0.56 : 0.82);
    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: width,
        child: Padding(
          padding: EdgeInsets.only(right: width * 0.04),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: textColor,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskPanelExpandedContent(
    TaskPanelSpriteCatalog? taskPanelSprites,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final panelSize = constraints.biggest;
        final rowHeight = panelSize.height * 0.106;
        final rowFieldInset = rowHeight * 0.05;
        final rowTextSize = panelSize.width * 0.045;
        final pointsLabelWidth = math.max(
          54.0,
          math.min(panelSize.width * 0.16, 68.0),
        );
        final pointsLabelTextSize = panelSize.width * 0.033;
        final titleWidth =
            panelSize.width * (taskPanelSprites == null ? 0.42 : 0.46);
        final titleAspectRatio =
            taskPanelSprites?.titleBanner.aspectRatio ?? (648 / 262);
        final actionButtonAspectRatio =
            taskPanelSprites?.primaryButton.aspectRatio ?? (648 / 262);
        return Padding(
          padding: EdgeInsets.fromLTRB(
            panelSize.width * 0.12,
            panelSize.height * 0.07,
            panelSize.width * 0.12,
            panelSize.height * 0.08,
          ),
          child: Column(
            children: [
              SizedBox(
                width: titleWidth,
                child: AspectRatio(
                  aspectRatio: titleAspectRatio,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: taskPanelSprites == null
                            ? Image.asset(
                                _taskPanelStickerAsset,
                                fit: BoxFit.fill,
                              )
                            : SpriteFrameImage(
                                imageAsset: taskPanelSprites.imageAsset,
                                sheetSize: taskPanelSprites.sheetSize,
                                frame: taskPanelSprites.titleBanner,
                                fit: BoxFit.fill,
                              ),
                      ),
                      Positioned(
                        top: -panelSize.height * 0.022,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: taskPanelSprites == null
                              ? Container(
                                  width: panelSize.height * 0.038,
                                  height: panelSize.height * 0.038,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFFF3C97D),
                                        Color(0xFFC78E49),
                                      ],
                                    ),
                                    border: Border.all(
                                      color: const Color(0xB87A5330),
                                      width: 1.1,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x22000000),
                                        blurRadius: 4,
                                        offset: Offset(0, 1.5),
                                      ),
                                    ],
                                  ),
                                )
                              : SizedBox(
                                  width: panelSize.height * 0.065,
                                  height: panelSize.height * 0.078,
                                  child: SpriteFrameImage(
                                    imageAsset: taskPanelSprites.imageAsset,
                                    sheetSize: taskPanelSprites.sheetSize,
                                    frame: taskPanelSprites.pushPin,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                        ),
                      ),
                      if (taskPanelSprites == null)
                        Center(
                          child: Text(
                            '\u4efb\u52a1\u6e05\u5355',
                            style: TextStyle(
                              color: const Color(0xFF5B4327),
                              fontSize: panelSize.width * 0.062,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: panelSize.height * 0.026),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(bottom: panelSize.height * 0.018),
                  child: Column(
                    children: [
                      for (
                        var index = 0;
                        index < _visibleTaskPanelTasks.length;
                        index++
                      )
                        Builder(
                          builder: (context) {
                            final task = _visibleTaskPanelTasks[index];
                            final taskTitle = _taskPanelTaskTitle(task);
                            final taskPointsLabel = _taskPanelTaskPointsLabel(
                              task,
                            );
                            final completed = _taskPanelTaskCompleted(task);
                            final checkboxPressKey = _taskPanelInteractionKey(
                              task,
                              index,
                              area: 'checkbox',
                            );
                            final bodyPressKey = _taskPanelInteractionKey(
                              task,
                              index,
                              area: 'body',
                            );
                            final isCheckboxPressed =
                                _isTaskPanelInteractionPressed(
                                  checkboxPressKey,
                                );
                            final isBodyPressed =
                                _isTaskPanelInteractionPressed(bodyPressKey);
                            final titleColor = const Color(
                              0xFF5A4228,
                            ).withValues(alpha: completed ? 0.66 : 1);
                            final rowFieldOpacity =
                                (index.isEven ? 0.96 : 0.88) *
                                (completed ? 0.76 : 1);
                            final checkboxOpacity = completed
                                ? 0.70
                                : (isCheckboxPressed ? 0.82 : 1.0);
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: panelSize.height * 0.012,
                              ),
                              child: SizedBox(
                                height: rowHeight,
                                child: Stack(
                                  children: [
                                    Positioned(
                                      left: 0,
                                      top: rowHeight * 0.18,
                                      child: AnimatedSlide(
                                        duration: const Duration(
                                          milliseconds: 90,
                                        ),
                                        curve: Curves.easeOutCubic,
                                        offset: isCheckboxPressed
                                            ? const Offset(0, 0.05)
                                            : Offset.zero,
                                        child: AnimatedScale(
                                          duration: const Duration(
                                            milliseconds: 90,
                                          ),
                                          curve: Curves.easeOutCubic,
                                          scale: isCheckboxPressed ? 0.92 : 1,
                                          child: SizedBox(
                                            width: rowHeight * 0.58,
                                            height: rowHeight * 0.58,
                                            child: taskPanelSprites == null
                                                ? Opacity(
                                                    opacity: checkboxOpacity,
                                                    child: Image.asset(
                                                      completed
                                                          ? _taskPanelCheckboxCheckedAsset
                                                          : _taskPanelCheckboxEmptyAsset,
                                                    ),
                                                  )
                                                : Opacity(
                                                    opacity: checkboxOpacity,
                                                    child: SpriteFrameImage(
                                                      imageAsset:
                                                          taskPanelSprites
                                                              .imageAsset,
                                                      sheetSize:
                                                          taskPanelSprites
                                                              .sheetSize,
                                                      frame: completed
                                                          ? taskPanelSprites
                                                                .checkboxChecked
                                                          : taskPanelSprites
                                                                .checkboxEmpty,
                                                      fit: BoxFit.contain,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: rowHeight * 0.78,
                                      right: 0,
                                      top: rowFieldInset,
                                      bottom: rowFieldInset,
                                      child: AnimatedSlide(
                                        duration: const Duration(
                                          milliseconds: 90,
                                        ),
                                        curve: Curves.easeOutCubic,
                                        offset: isBodyPressed
                                            ? const Offset(0, 0.02)
                                            : Offset.zero,
                                        child: AnimatedScale(
                                          duration: const Duration(
                                            milliseconds: 90,
                                          ),
                                          curve: Curves.easeOutCubic,
                                          alignment: Alignment.centerLeft,
                                          scale: isBodyPressed ? 0.992 : 1,
                                          child: Stack(
                                            children: [
                                              Positioned.fill(
                                                child: taskPanelSprites == null
                                                    ? Opacity(
                                                        opacity: completed
                                                            ? 0.76
                                                            : 1,
                                                        child: Image.asset(
                                                          _taskPanelRowFieldAsset,
                                                          fit: BoxFit.fill,
                                                        ),
                                                      )
                                                    : Opacity(
                                                        opacity:
                                                            rowFieldOpacity,
                                                        child: SpriteFrameImage(
                                                          imageAsset:
                                                              taskPanelSprites
                                                                  .imageAsset,
                                                          sheetSize:
                                                              taskPanelSprites
                                                                  .sheetSize,
                                                          frame:
                                                              taskPanelSprites
                                                                  .rowField,
                                                          fit: BoxFit.fill,
                                                        ),
                                                      ),
                                              ),
                                              Positioned(
                                                left: rowHeight * 0.28,
                                                right:
                                                    pointsLabelWidth +
                                                    rowHeight * 0.30,
                                                top: 0,
                                                bottom: 0,
                                                child: Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                    taskTitle,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color: titleColor,
                                                      fontSize: rowTextSize,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                right: rowHeight * 0.16,
                                                top: 0,
                                                bottom: 0,
                                                child:
                                                    _buildTaskPanelPointsText(
                                                      label: taskPointsLabel,
                                                      width: pointsLabelWidth,
                                                      fontSize:
                                                          pointsLabelTextSize,
                                                      completed: completed,
                                                    ),
                                              ),
                                              Positioned.fill(
                                                child: IgnorePointer(
                                                  child: AnimatedOpacity(
                                                    duration: const Duration(
                                                      milliseconds: 90,
                                                    ),
                                                    curve: Curves.easeOutCubic,
                                                    opacity: isBodyPressed
                                                        ? 1
                                                        : 0,
                                                    child: DecoratedBox(
                                                      decoration: BoxDecoration(
                                                        color:
                                                            const Color(
                                                              0xFF765A3C,
                                                            ).withValues(
                                                              alpha: 0.05,
                                                            ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              rowHeight * 0.20,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 0,
                                      top: rowHeight * 0.08,
                                      width: rowHeight * 0.74,
                                      height: rowHeight * 0.84,
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTapDown: (_) =>
                                            _setTaskPanelInteractionPressed(
                                              checkboxPressKey,
                                            ),
                                        onTapCancel: () =>
                                            _clearTaskPanelInteractionPressed(
                                              checkboxPressKey,
                                            ),
                                        onTapUp: (_) =>
                                            _clearTaskPanelInteractionPressed(
                                              checkboxPressKey,
                                              delayed: true,
                                            ),
                                        onTap: () =>
                                            _completeTaskByLabel(taskTitle),
                                        child: const SizedBox.expand(),
                                      ),
                                    ),
                                    Positioned(
                                      left: rowHeight * 0.78,
                                      right: 0,
                                      top: rowFieldInset,
                                      bottom: rowFieldInset,
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTapDown: (_) =>
                                            _setTaskPanelInteractionPressed(
                                              bodyPressKey,
                                            ),
                                        onTapCancel: () =>
                                            _clearTaskPanelInteractionPressed(
                                              bodyPressKey,
                                            ),
                                        onTapUp: (_) =>
                                            _clearTaskPanelInteractionPressed(
                                              bodyPressKey,
                                              delayed: true,
                                            ),
                                        onTap: () =>
                                            _editTaskByLabel(taskTitle),
                                        child: const SizedBox.expand(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      if (_visibleTaskPanelTasks.isEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: panelSize.height * 0.04,
                          ),
                          child: taskPanelSprites == null
                              ? Text(
                                  '\u4eca\u5929\u8fd8\u6ca1\u6709\u4efb\u52a1',
                                  style: TextStyle(
                                    color: const Color(0xFF7A624A),
                                    fontSize: panelSize.width * 0.05,
                                    fontWeight: FontWeight.w700,
                                  ),
                                )
                              : SizedBox(
                                  width: panelSize.width * 0.58,
                                  child: AspectRatio(
                                    aspectRatio:
                                        taskPanelSprites.emptyState.aspectRatio,
                                    child: Stack(
                                      children: [
                                        Positioned.fill(
                                          child: Opacity(
                                            opacity: 0.84,
                                            child: SpriteFrameImage(
                                              imageAsset:
                                                  taskPanelSprites.imageAsset,
                                              sheetSize:
                                                  taskPanelSprites.sheetSize,
                                              frame:
                                                  taskPanelSprites.emptyState,
                                              fit: BoxFit.fill,
                                            ),
                                          ),
                                        ),
                                        Center(
                                          child: Text(
                                            '\u4eca\u5929\u8fd8\u6ca1\u6709\u4efb\u52a1',
                                            style: TextStyle(
                                              color: const Color(0xFF7A624A),
                                              fontSize: panelSize.width * 0.048,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: panelSize.height * 0.010),
              if (_taskPanelPageCount > 1)
                Padding(
                  padding: EdgeInsets.only(bottom: panelSize.height * 0.010),
                  child: Text(
                    _taskPanelPageIndicatorLabel,
                    style: TextStyle(
                      color: const Color(0xFF6A5237),
                      fontSize: panelSize.width * 0.040,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              SizedBox(
                width: panelSize.width * 0.86,
                height: panelSize.width * 0.16,
                child: Row(
                  children: [
                    _buildTaskPanelArrowButton(
                      icon: Icons.chevron_left_rounded,
                      size: panelSize.width * 0.095,
                      visible: _taskPanelPageCount > 1,
                      enabled: _canGoToPreviousTaskPage,
                      onTap: _goToPreviousTaskPage,
                    ),
                    const Spacer(),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _handleTaskAddTap,
                      child: SizedBox(
                        width: panelSize.width * 0.56,
                        child: AspectRatio(
                          aspectRatio: actionButtonAspectRatio,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: taskPanelSprites == null
                                    ? Image.asset(
                                        _taskPanelStickerAsset,
                                        fit: BoxFit.fill,
                                      )
                                    : SpriteFrameImage(
                                        imageAsset: taskPanelSprites.imageAsset,
                                        sheetSize: taskPanelSprites.sheetSize,
                                        frame: taskPanelSprites.primaryButton,
                                        fit: BoxFit.fill,
                                      ),
                              ),
                              Center(
                                child: Text(
                                  _taskPanelAddButtonLabel,
                                  style: TextStyle(
                                    color: const Color(0xFF5A4228),
                                    fontSize: panelSize.width * 0.045,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    _buildTaskPanelArrowButton(
                      icon: Icons.chevron_right_rounded,
                      size: panelSize.width * 0.095,
                      visible: _taskPanelPageCount > 1,
                      enabled: _canGoToNextTaskPage,
                      onTap: _goToNextTaskPage,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnimatedTaskPanelOverlay(Size size) {
    final collapsedRect = _clampPanelRect(
      _taskPanelOriginRect ?? _defaultTaskPanelOriginRect(size),
      size,
    );
    final expandedRect = _expandedTaskPanelRect(size);
    final taskPanelSprites = _taskPanelSpriteAtlas == null
        ? null
        : TaskPanelSpriteCatalog(_taskPanelSpriteAtlas!);

    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _taskPanelController,
        child: RepaintBoundary(
          child: _buildTaskPanelExpandedContent(taskPanelSprites),
        ),
        builder: (context, panelContent) {
          final animationValue = _taskPanelController.value;
          final panelProgress = Curves.easeInOutCubicEmphasized.transform(
            animationValue,
          );
          final backdropOpacity = _taskPanelIntervalValue(
            animationValue,
            begin: 0.04,
            end: 1,
            curve: Curves.easeOutCubic,
          );
          final stickerOpacity =
              1 -
              _taskPanelIntervalValue(
                animationValue,
                begin: 0,
                end: 0.56,
                curve: Curves.easeOutCubic,
              );
          final boardOpacity = _taskPanelIntervalValue(
            animationValue,
            begin: 0.12,
            end: 0.72,
            curve: Curves.easeOutCubic,
          );
          final contentOpacity = _taskPanelIntervalValue(
            animationValue,
            begin: 0.40,
            end: 1,
            curve: Curves.easeOutCubic,
          );
          final panelRect = Rect.lerp(
            collapsedRect,
            expandedRect,
            panelProgress,
          )!;
          final panelShadowOpacity = ui.lerpDouble(0.10, 0.22, panelProgress)!;
          final panelShadowBlur = ui.lerpDouble(10, 24, panelProgress)!;
          final panelShadowOffset = ui.lerpDouble(4, 10, panelProgress)!;
          final panelScale = ui.lerpDouble(0.985, 1.0, panelProgress)!;
          final panelRotation = ui.lerpDouble(-0.035, 0, panelProgress)!;
          final boardSlide = ui.lerpDouble(12, 0, boardOpacity)!;
          final contentSlide = ui.lerpDouble(18, 0, contentOpacity)!;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _taskPanelBackdropInteractive ? _hideTaskPanel : null,
                  child: ColoredBox(
                    color: Colors.black.withValues(
                      alpha: 0.42 * backdropOpacity,
                    ),
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(
                          sigmaX: 5.5 * backdropOpacity,
                          sigmaY: 5.5 * backdropOpacity,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: panelRect.left,
                top: panelRect.top,
                width: panelRect.width,
                height: panelRect.height,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {},
                  child: RepaintBoundary(
                    child: Transform.rotate(
                      angle: panelRotation,
                      child: Transform.scale(
                        scale: panelScale,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              ui.lerpDouble(18, 28, panelProgress)!,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF3A2514,
                                ).withValues(alpha: panelShadowOpacity),
                                blurRadius: panelShadowBlur,
                                offset: Offset(0, panelShadowOffset),
                              ),
                            ],
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            clipBehavior: Clip.none,
                            children: [
                              Opacity(
                                opacity: stickerOpacity,
                                child: Image.asset(
                                  _taskPanelNoteAsset,
                                  fit: BoxFit.fill,
                                ),
                              ),
                              Transform.translate(
                                offset: Offset(0, boardSlide),
                                child: Opacity(
                                  opacity: boardOpacity,
                                  child: _buildTaskPanelBoardLayer(),
                                ),
                              ),
                              IgnorePointer(
                                ignoring: !_taskPanelBackdropInteractive,
                                child: Transform.translate(
                                  offset: Offset(0, contentSlide),
                                  child: Opacity(
                                    opacity: contentOpacity,
                                    child: panelContent!,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTaskPanelArrowButton({
    required IconData icon,
    required double size,
    required bool visible,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    if (!visible) {
      return SizedBox.square(dimension: size);
    }

    final radius = BorderRadius.circular(size * 0.28);
    return SizedBox.square(
      dimension: size,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: enabled ? 1 : 0.34,
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              color: const Color(0xFFF7EAD2),
              borderRadius: radius,
              border: Border.all(color: const Color(0xFFB59A7C), width: 1.2),
              boxShadow: enabled
                  ? const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 4,
                        offset: Offset(0, 1.5),
                      ),
                    ]
                  : null,
            ),
            child: InkWell(
              borderRadius: radius,
              onTap: enabled ? onTap : null,
              child: Center(
                child: Icon(
                  icon,
                  size: size * 0.62,
                  color: const Color(0xFF6A5237),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showTaskPanelRowActions(
    String taskLabel,
    Offset localPosition,
  ) async {
    final gameBox = _gameKey.currentContext?.findRenderObject() as RenderBox?;
    if (gameBox == null) {
      return;
    }

    final globalPosition = gameBox.localToGlobal(localPosition);
    await _showTaskPanelRowActionsFromGlobalPosition(taskLabel, globalPosition);
  }

  Future<_TaskPanelRowAction?> _showSpriteTaskContextMenu(
    Offset anchorInOverlay,
  ) {
    return showGeneralDialog<_TaskPanelRowAction>(
      context: context,

      barrierLabel: 'task_context_menu',

      barrierDismissible: true,

      barrierColor: Colors.transparent,

      transitionDuration: const Duration(milliseconds: 120),

      pageBuilder: (context, animation, secondaryAnimation) {
        return _TaskContextSpriteMenu(anchorInOverlay: anchorInOverlay);
      },

      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  Future<void> _editTaskByLabel(String taskLabel) async {
    if (!_isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '\u4ec5\u7ba1\u7406\u5458\u53ef\u7f16\u8f91\u4efb\u52a1',
          ),
        ),
      );
      return;
    }

    var targetTask = _findHomeTaskByLabel(taskLabel);

    if (targetTask == null) {
      await _loadHomeTasks();
      if (!mounted) {
        return;
      }

      targetTask = _findHomeTaskByLabel(taskLabel);
    }

    if (targetTask == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '\u672a\u627e\u5230\u8be5\u4efb\u52a1\uff0c\u8bf7\u91cd\u8bd5',
          ),
        ),
      );

      return;
    }

    final editedTask = await _showTaskEditorDialog(
      initialTaskLabel: (targetTask['title'] ?? taskLabel).toString(),
      initialTaskPoints: _asInt(targetTask['points'], fallback: 10),
      isEditing: true,
    );

    if (!mounted || editedTask == null) {
      return;
    }

    if (editedTask.deleteRequested) {
      await _deleteTaskByLabel(taskLabel);
      return;
    }

    final taskId = _asInt(targetTask['id'], fallback: -1);

    if (taskId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '\u4efb\u52a1\u6570\u636e\u5f02\u5e38\uff0c\u8bf7\u5237\u65b0\u540e\u91cd\u8bd5',
          ),
        ),
      );

      return;
    }

    try {
      final dio = ref.read(apiClientProvider).dio;

      final oldTaskLabel = (targetTask['title'] ?? taskLabel).toString().trim();

      await dio.put(
        '/api/tasks/$taskId',
        data: {'title': editedTask.taskLabel, 'points': editedTask.points},
      );

      _game.updateTaskItem(
        oldTaskLabel: oldTaskLabel,
        newTaskLabel: editedTask.taskLabel,
        points: editedTask.points,
      );

      await _loadHomeTasks();
    } catch (error) {
      if (mounted) {
        showFriendlyApiErrorSnackBar(
          context,
          error,
          fallbackMessage:
              '\u4fdd\u5b58\u4efb\u52a1\u5931\u8d25\uff0c\u8bf7\u7a0d\u540e\u91cd\u8bd5',
        );
      }
    }
  }

  Future<void> _deleteTaskByLabel(String taskLabel) async {
    if (!_isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '\u4ec5\u7ba1\u7406\u5458\u53ef\u5220\u9664\u4efb\u52a1',
          ),
        ),
      );
      return;
    }

    final shouldDelete = await _confirmDeleteTask(taskLabel);

    if (!mounted || !shouldDelete) {
      return;
    }

    var targetTask = _findHomeTaskByLabel(taskLabel);

    if (targetTask == null) {
      await _loadHomeTasks();
      if (!mounted) {
        return;
      }

      targetTask = _findHomeTaskByLabel(taskLabel);
    }

    if (targetTask == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '\u672a\u627e\u5230\u8be5\u4efb\u52a1\uff0c\u8bf7\u91cd\u8bd5',
          ),
        ),
      );

      return;
    }

    final taskId = _asInt(targetTask['id'], fallback: -1);

    if (taskId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '\u4efb\u52a1\u6570\u636e\u5f02\u5e38\uff0c\u8bf7\u5237\u65b0\u540e\u91cd\u8bd5',
          ),
        ),
      );

      return;
    }

    try {
      final dio = ref.read(apiClientProvider).dio;

      await dio.delete('/api/tasks/$taskId');

      _game.removeTaskItem((targetTask['title'] ?? taskLabel).toString());

      await _loadHomeTasks();
    } catch (error) {
      if (mounted) {
        showFriendlyApiErrorSnackBar(
          context,
          error,
          fallbackMessage:
              '\u5220\u9664\u4efb\u52a1\u5931\u8d25\uff0c\u8bf7\u7a0d\u540e\u91cd\u8bd5',
        );
      }
    }
  }

  Future<void> _completeTaskByLabel(String taskLabel) async {
    var targetTask = _findHomeTaskByLabel(taskLabel);

    if (targetTask == null) {
      await _loadHomeTasks();
      if (!mounted) {
        return;
      }

      targetTask = _findHomeTaskByLabel(taskLabel);
    }

    if (targetTask == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '\u672a\u627e\u5230\u8be5\u4efb\u52a1\uff0c\u8bf7\u91cd\u8bd5',
          ),
        ),
      );

      return;
    }

    final taskId = _asInt(targetTask['id'], fallback: -1);

    if (taskId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '\u4efb\u52a1\u6570\u636e\u5f02\u5e38\uff0c\u8bf7\u5237\u65b0\u540e\u91cd\u8bd5',
          ),
        ),
      );

      return;
    }

    final memberId = await _pickCompletionMemberId();

    if (!mounted || memberId == null) {
      return;
    }

    try {
      final dio = ref.read(apiClientProvider).dio;

      await dio.post(
        '/api/tasks/$taskId/completions',
        data: {'member_id': memberId},
      );

      await _loadHomeTasks();

      await _loadFamilyPets();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('\u4efb\u52a1\u5b8c\u6210\u6210\u529f')),
      );
    } catch (error) {
      if (mounted) {
        showFriendlyApiErrorSnackBar(
          context,

          error,

          fallbackMessage:
              '\u63d0\u4ea4\u5b8c\u6210\u5931\u8d25\uff0c\u8bf7\u7a0d\u540e\u91cd\u8bd5',
        );
      }
    }
  }

  Future<int?> _pickCompletionMemberId() async {
    final familyId = ref.read(authProvider).user?.familyId;

    if (familyId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '\u5f53\u524d\u8d26\u53f7\u8fd8\u672a\u52a0\u5165\u5bb6\u5ead',
            ),
          ),
        );
      }

      return null;
    }

    try {
      final dio = ref.read(apiClientProvider).dio;

      final response = await dio.get('/api/families/$familyId/members');

      final payload = response.data;

      if (payload is! List) {
        return null;
      }

      final members = payload
          .map((item) => Map<String, dynamic>.from(item as Map))
          .where((member) => _asInt(member['id'], fallback: -1) > 0)
          .toList();

      if (members.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('\u5f53\u524d\u5bb6\u5ead\u6682\u65e0\u6210\u5458'),
            ),
          );
        }

        return null;
      }

      if (!mounted) {
        return null;
      }

      return _showCompletionMemberDialog(members);
    } catch (error) {
      if (mounted) {
        showFriendlyApiErrorSnackBar(
          context,

          error,

          fallbackMessage:
              '\u52a0\u8f7d\u5bb6\u5ead\u6210\u5458\u5931\u8d25\uff0c\u8bf7\u7a0d\u540e\u91cd\u8bd5',
        );
      }

      return null;
    }
  }

  Future<int?> _showCompletionMemberDialog(List<Map<String, dynamic>> members) {
    final initialMemberId = _asInt(members.first['id'], fallback: -1);

    return showDialog<int>(
      context: context,

      builder: (dialogContext) {
        var selectedMemberId = initialMemberId > 0 ? initialMemberId : null;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('\u9009\u62e9\u5b8c\u6210\u4eba\u5458'),

              content: DropdownButtonFormField<int>(
                isExpanded: true,

                initialValue: selectedMemberId,

                decoration: const InputDecoration(
                  labelText: '\u5b8c\u6210\u6210\u5458',
                ),

                items: members
                    .map(
                      (member) => DropdownMenuItem<int>(
                        value: _asInt(member['id'], fallback: -1),

                        child: Text(_memberDisplayName(member)),
                      ),
                    )
                    .toList(),

                onChanged: (value) =>
                    setDialogState(() => selectedMemberId = value),
              ),

              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),

                  child: const Text('\u53d6\u6d88'),
                ),

                FilledButton(
                  onPressed: selectedMemberId == null
                      ? null
                      : () => Navigator.of(dialogContext).pop(selectedMemberId),

                  child: const Text('\u786e\u8ba4\u5b8c\u6210'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _memberDisplayName(Map<String, dynamic> member) {
    final nickname = (member['nickname'] ?? '').toString().trim();

    if (nickname.isNotEmpty) {
      return nickname;
    }

    final username = (member['username'] ?? '').toString().trim();

    if (username.isNotEmpty) {
      return username;
    }

    final memberId = _asInt(member['id'], fallback: 0);

    return '\u6210\u5458#$memberId';
  }

  Future<void> _handleTaskAddTap() async {
    if (!mounted) {
      return;
    }

    if (!_isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '\u4ec5\u7ba1\u7406\u5458\u53ef\u65b0\u589e\u4efb\u52a1',
          ),
        ),
      );

      return;
    }

    if (_homeTasks.length >= HomeSceneGame.maxTaskCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '\u4efb\u52a1\u6570\u91cf\u5df2\u8fbe\u4e0a\u9650\uff0c\u6700\u591a\u53ea\u80fd\u6dfb\u52a0 12 \u4e2a',
          ),
        ),
      );

      return;
    }

    final newTask = await _showTaskEditorDialog(isEditing: false);

    if (!mounted || newTask == null) {
      return;
    }

    try {
      await _createTaskWithCompatibility(newTask);

      _game.addTaskItem(newTask.taskLabel, points: newTask.points);

      await _loadHomeTasks();
    } catch (error) {
      if (mounted) {
        showFriendlyApiErrorSnackBar(
          context,

          error,

          fallbackMessage:
              '\u521b\u5efa\u4efb\u52a1\u5931\u8d25\uff0c\u8bf7\u7a0d\u540e\u91cd\u8bd5',
        );
      }
    }
  }

  Future<void> _createTaskWithCompatibility(_TaskEditorResult task) async {
    final dio = ref.read(apiClientProvider).dio;

    final user = ref.read(authProvider).user;

    try {
      await dio.post('/api/tasks', data: _taskMutationPayload(task));
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;

      if (statusCode != 400 && statusCode != 422) {
        rethrow;
      }

      await dio.post(
        '/api/tasks',

        data: _taskMutationPayload(
          task,

          includeCompatibilityFields: true,

          familyId: user?.familyId,
        ),
      );
    }
  }

  Map<String, dynamic> _taskMutationPayload(
    _TaskEditorResult task, {

    bool includeCompatibilityFields = false,

    int? familyId,
  }) {
    final payload = <String, dynamic>{
      'title': task.taskLabel,

      'points': task.points,
    };

    if (includeCompatibilityFields) {
      payload['task_type'] = 'daily';

      payload['is_active'] = true;

      if (familyId != null) {
        payload['family_id'] = familyId;
      }
    }

    return payload;
  }

  Future<_TaskEditorResult?> _showTaskEditorDialog({
    required bool isEditing,

    String? initialTaskLabel,

    int? initialTaskPoints,
  }) {
    return showGeneralDialog<_TaskEditorResult>(
      context: context,

      barrierLabel: 'task_editor_dialog',

      barrierDismissible: true,

      barrierColor: Colors.black.withValues(alpha: 0.14),

      transitionDuration: const Duration(milliseconds: 160),

      pageBuilder: (context, animation, secondaryAnimation) {
        return _TaskEditorSpriteDialog(
          isEditing: isEditing,

          initialTaskLabel: initialTaskLabel,

          initialTaskPoints: initialTaskPoints,
        );
      },

      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,

          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(animation),

            child: child,
          ),
        );
      },
    );
  }

  Future<bool> _confirmDeleteTask(String taskLabel) async {
    final result = await showDialog<bool>(
      context: context,

      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('\u5220\u9664\u4efb\u52a1'),

          content: Text(
            '\u786e\u8ba4\u5220\u9664\u4efb\u52a1\u300c$taskLabel\u300d\u5417\uff1f',
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),

              child: const Text('\u53d6\u6d88'),
            ),

            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),

              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB86A57),

                foregroundColor: Colors.white,
              ),

              child: const Text('\u5220\u9664'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> _loadHomeTasks() async {
    final familyId = ref.read(authProvider).user?.familyId;

    if (familyId == null) {
      if (mounted) {
        setState(() {
          _homeTasks = const <Map<String, dynamic>>[];
          _taskPanelPageIndex = 0;
        });
      } else {
        _homeTasks = const <Map<String, dynamic>>[];
      }

      _syncGameTasksFromServer();
      return;
    }

    try {
      final dio = ref.read(apiClientProvider).dio;
      final response = await dio.get('/api/families/$familyId/tasks');
      final payload = response.data;

      if (payload is! List) {
        return;
      }

      final tasks = payload
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      if (!mounted) {
        _homeTasks = tasks;
        _syncGameTasksFromServer();
        return;
      }

      final nextPageCount = math.max(
        1,
        (tasks.length + _taskPanelPageSize - 1) ~/ _taskPanelPageSize,
      );

      setState(() {
        _homeTasks = tasks;
        _taskPanelPageIndex = _taskPanelPageIndex.clamp(
          0,
          math.max(0, nextPageCount - 1),
        );
      });

      _syncGameTasksFromServer();
    } catch (error) {
      if (mounted) {
        showFriendlyApiErrorSnackBar(
          context,
          error,
          fallbackMessage:
              '\u52a0\u8f7d\u4efb\u52a1\u5931\u8d25\uff0c\u8bf7\u7a0d\u540e\u91cd\u8bd5',
        );
      }
    }
  }

  void _syncGameTasksFromServer() {
    final seeds = _homeTasks
        .where((item) => item['is_active'] != false)
        .map(
          (item) => HomeSceneTaskSeed(
            title: (item['title'] ?? '').toString(),

            points: _asInt(item['points'], fallback: 10),
          ),
        )
        .toList();

    _game.replaceTaskEntries(seeds);
  }

  void _syncGamePetsFromServer() {
    final sortedPets = List<Pet>.from(_pets)
      ..sort((left, right) => left.ownerId.compareTo(right.ownerId));

    final renderedOwnerIds = <int>{};
    final seeds = <HomeScenePetSeed>[];

    for (var index = 0; index < sortedPets.length; index++) {
      final pet = sortedPets[index];
      if (!renderedOwnerIds.add(pet.ownerId)) {
        continue;
      }
      seeds.add(
        HomeScenePetSeed(
          petId: pet.id,
          petType: normalizePetType(
            pet.petType,
            fallback:
                selectablePetTypes[seeds.length % selectablePetTypes.length],
          ),
        ),
      );
    }

    _game.replacePetEntries(seeds);
  }

  Map<String, dynamic>? _findHomeTaskByLabel(String taskLabel) {
    final normalized = taskLabel.trim();

    if (normalized.isEmpty) {
      return null;
    }

    for (final task in _homeTasks) {
      if ((task['title'] ?? '').toString().trim() == normalized) {
        return task;
      }
    }

    return null;
  }

  int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse('$value') ?? fallback;
  }

  Future<void> _loadFamilyPets() async {
    final familyId = ref.read(authProvider).user?.familyId;

    if (familyId == null) {
      _pets = const <Pet>[];
      _syncGamePetsFromServer();
      return;
    }

    try {
      final dio = ref.read(apiClientProvider).dio;

      final response = await dio.get('/api/families/$familyId/pets');

      final payload = response.data;

      if (payload is! List) {
        return;
      }

      final pets = payload
          .map(
            (item) => Pet.fromJson(
              Map<String, dynamic>.from(item as Map<dynamic, dynamic>),
            ),
          )
          .toList();

      if (!mounted) {
        return;
      }

      setState(() => _pets = pets);
      _syncGamePetsFromServer();
    } catch (_) {}
  }

  Pet? _findPetById(int petId) {
    for (final pet in _pets) {
      if (pet.id == petId) {
        return pet;
      }
    }

    return null;
  }

  void _openPetDetail(int petId) {
    final selectedPet = _findPetById(petId);

    if (selectedPet != null) {
      _showPetDetailOverlay(selectedPet);
      return;
    }

    _loadFamilyPets().then((_) {
      if (!mounted) {
        return;
      }

      final refreshedPet = _findPetById(petId);
      if (refreshedPet == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('当前家庭还没有宠物，先去创建一个吧')));
        return;
      }

      _showPetDetailOverlay(refreshedPet);
    });
  }

  Future<void> _showPetDetailOverlay(Pet pet) async {
    if (!mounted) {
      return;
    }

    if (_petDetailVisible) {
      setState(() => _activePetDetail = pet);
      return;
    }

    setState(() {
      _activePetDetail = pet;
      _petDetailVisible = true;
      _petDetailClosing = false;
      _petDetailBackdropInteractive = false;
    });

    await _petDetailOverlayController.forward(from: 0);
    if (!mounted || !_petDetailVisible) {
      return;
    }

    setState(() => _petDetailBackdropInteractive = true);
  }

  Future<void> _hidePetDetailOverlay() async {
    if (!_petDetailVisible || _petDetailClosing) {
      return;
    }

    setState(() {
      _petDetailClosing = true;
      _petDetailBackdropInteractive = false;
    });

    await _petDetailOverlayController.reverse(
      from: _petDetailOverlayController.value == 0
          ? 1
          : _petDetailOverlayController.value,
    );
    if (!mounted) {
      return;
    }

    setState(() {
      _petDetailVisible = false;
      _petDetailClosing = false;
      _petDetailBackdropInteractive = false;
      _activePetDetail = null;
    });
  }

  Widget _buildPetDetailOverlay(Size size) {
    final pet = _activePetDetail!;
    final panelWidth = math.min(
      size.width * (widget.device == HomeSceneDevice.tablet ? 0.58 : 0.92),
      620.0,
    );
    final panelHeight = math.min(
      size.height * 0.82,
      widget.device == HomeSceneDevice.tablet ? 760.0 : 680.0,
    );
    final panelLeft = (size.width - panelWidth) / 2;
    final panelTop = math.max(24.0, (size.height - panelHeight) / 2);

    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _petDetailOverlayController,
        child: RepaintBoundary(
          child: PetDetailView(
            pet: pet,
            embedded: true,
            onClose: _hidePetDetailOverlay,
          ),
        ),
        builder: (context, child) {
          final progress = Curves.easeInOutCubicEmphasized.transform(
            _petDetailOverlayController.value,
          );
          final backdropOpacity = Curves.easeOutCubic.transform(
            _petDetailOverlayController.value,
          );
          final panelOpacity = _taskPanelIntervalValue(
            _petDetailOverlayController.value,
            begin: 0.12,
            end: 1,
            curve: Curves.easeOutCubic,
          );
          final panelScale = ui.lerpDouble(0.92, 1.0, progress)!;
          final panelTranslateY = ui.lerpDouble(22, 0, progress)!;

          return Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _petDetailBackdropInteractive
                      ? _hidePetDetailOverlay
                      : null,
                  child: ColoredBox(
                    color: Colors.black.withValues(
                      alpha: 0.36 * backdropOpacity,
                    ),
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(
                          sigmaX: 5.0 * backdropOpacity,
                          sigmaY: 5.0 * backdropOpacity,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: panelLeft,
                top: panelTop + panelTranslateY,
                width: panelWidth,
                height: panelHeight,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {},
                  child: Opacity(
                    opacity: panelOpacity,
                    child: Transform.scale(
                      scale: panelScale,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF3A2514,
                              ).withValues(alpha: 0.22),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: IgnorePointer(
                          ignoring: !_petDetailBackdropInteractive,
                          child: child,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _taskPanelController.dispose();
    _petDetailOverlayController.dispose();
    _game.startExitAnimation();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        return ColoredBox(
          color: const Color(0xFFF6E8CB),
          child: Stack(
            fit: StackFit.expand,
            children: [
              RiverpodAwareGameWidget<HomeSceneGame>(
                key: _gameKey,
                game: _game,
                loadingBuilder: (BuildContext context) {
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (BuildContext context, Object error) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        '\u9996\u9875\u573a\u666f\u52a0\u8f7d\u5931\u8d25\uff1a$error',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF6F4D35),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                },
              ),
              if (_taskPanelVisible) _buildAnimatedTaskPanelOverlay(size),
              if (_petDetailVisible && _activePetDetail != null)
                _buildPetDetailOverlay(size),
            ],
          ),
        );
      },
    );
  }
}

class _TaskContextSpriteMenu extends StatelessWidget {
  const _TaskContextSpriteMenu({required this.anchorInOverlay});

  final Offset anchorInOverlay;

  static const double _menuWidth = 190;

  static const double _menuHeight = _menuWidth * (169 / 135);

  static const double _screenPadding = 8;

  Offset _resolveMenuOffset(Size screenSize) {
    var left = anchorInOverlay.dx + 8;

    var top = anchorInOverlay.dy + 8;

    if (left + _menuWidth > screenSize.width - _screenPadding) {
      left = screenSize.width - _menuWidth - _screenPadding;
    }

    if (left < _screenPadding) {
      left = _screenPadding;
    }

    if (top + _menuHeight > screenSize.height - _screenPadding) {
      top = anchorInOverlay.dy - _menuHeight - 8;
    }

    if (top < _screenPadding) {
      top = _screenPadding;
    }

    return Offset(left, top);
  }

  @override
  Widget build(BuildContext context) {
    final offset = _resolveMenuOffset(MediaQuery.sizeOf(context));

    return Material(
      color: Colors.transparent,

      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,

              onTap: () => Navigator.of(context).pop(),
            ),
          ),

          Positioned(
            left: offset.dx,

            top: offset.dy,

            child: SizedBox(
              width: _menuWidth,

              height: _menuHeight,

              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      _taskContextMenuBoardAsset,

                      fit: BoxFit.fill,
                    ),
                  ),

                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(26, 18, 26, 16),

                      child: Column(
                        children: [
                          _TaskContextSpriteButton(
                            assetPath: _taskContextMenuEditButtonAsset,

                            label: '\u7f16\u8f91',

                            onTap: () => Navigator.of(
                              context,
                            ).pop(_TaskPanelRowAction.edit),
                          ),

                          const SizedBox(height: 7),

                          _TaskContextSpriteButton(
                            assetPath: _taskContextMenuDeleteButtonAsset,

                            label: '\u5220\u9664',

                            textColor: const Color(0xFF6A3A2D),

                            onTap: () => Navigator.of(
                              context,
                            ).pop(_TaskPanelRowAction.delete),
                          ),

                          const SizedBox(height: 7),

                          _TaskContextSpriteButton(
                            assetPath: _taskContextMenuCompleteButtonAsset,

                            label: '\u5b8c\u6210',

                            textColor: const Color(0xFF4F6B3A),

                            useSpriteBackground: false,

                            plainBackgroundColor: const Color(0xFFE7E8DD),

                            onTap: () => Navigator.of(
                              context,
                            ).pop(_TaskPanelRowAction.complete),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskContextSpriteButton extends StatefulWidget {
  const _TaskContextSpriteButton({
    required this.assetPath,

    required this.label,

    required this.onTap,

    this.textColor = const Color(0xFF4D3623),

    this.useSpriteBackground = true,

    this.plainBackgroundColor = const Color(0xFFE8DDD0),
  });

  final String assetPath;

  final String label;

  final VoidCallback onTap;

  final Color textColor;

  final bool useSpriteBackground;

  final Color plainBackgroundColor;

  @override
  State<_TaskContextSpriteButton> createState() =>
      _TaskContextSpriteButtonState();
}

class _TaskContextSpriteButtonState extends State<_TaskContextSpriteButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 120 / 54,

      child: GestureDetector(
        behavior: HitTestBehavior.opaque,

        onTapDown: (_) => setState(() => _pressed = true),

        onTapCancel: () => setState(() => _pressed = false),

        onTapUp: (_) => setState(() => _pressed = false),

        onTap: widget.onTap,

        child: AnimatedScale(
          scale: _pressed ? 0.975 : 1,

          duration: const Duration(milliseconds: 80),

          curve: Curves.easeOut,

          child: Stack(
            fit: StackFit.expand,

            children: [
              if (widget.useSpriteBackground)
                Image.asset(widget.assetPath, fit: BoxFit.fill)
              else
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: widget.plainBackgroundColor,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: const Color(0xFF9F876E),
                      width: 1.4,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22000000),
                        offset: Offset(0, 1.2),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),

              Center(
                child: Text(
                  widget.label,

                  style: TextStyle(
                    color: widget.textColor,

                    fontWeight: FontWeight.w800,

                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskEditorResult {
  const _TaskEditorResult({required this.taskLabel, required this.points})
    : deleteRequested = false;

  const _TaskEditorResult.delete()
    : taskLabel = '',
      points = 0,
      deleteRequested = true;

  final String taskLabel;

  final int points;

  final bool deleteRequested;
}

class _TaskEditorSpriteDialog extends StatefulWidget {
  const _TaskEditorSpriteDialog({
    required this.isEditing,

    this.initialTaskLabel,

    this.initialTaskPoints,
  });

  final bool isEditing;

  final String? initialTaskLabel;

  final int? initialTaskPoints;

  @override
  State<_TaskEditorSpriteDialog> createState() =>
      _TaskEditorSpriteDialogState();
}

class _TaskEditorSpriteDialogState extends State<_TaskEditorSpriteDialog> {
  late final TextEditingController _taskNameController;
  late final TextEditingController _taskPointsController;
  String? _validationMessage;

  @override
  void initState() {
    super.initState();
    _taskNameController = TextEditingController(
      text: widget.initialTaskLabel ?? '',
    );
    final initialPoints = (widget.initialTaskPoints ?? 10).clamp(
      _taskPointsMin,
      _taskPointsMax,
    );
    _taskPointsController = TextEditingController(text: '$initialPoints');
  }

  @override
  void dispose() {
    _taskNameController.dispose();
    _taskPointsController.dispose();
    super.dispose();
  }

  void _save() {
    final trimmedName = _taskNameController.text.trim();
    final points = int.tryParse(_taskPointsController.text.trim());

    final validationMessage = _validateTaskInput(
      taskName: trimmedName,
      points: points,
    );
    if (validationMessage != null) {
      setState(() => _validationMessage = validationMessage);
      return;
    }

    if (_validationMessage != null) {
      setState(() => _validationMessage = null);
    }

    Navigator.of(
      context,
    ).pop(_TaskEditorResult(taskLabel: trimmedName, points: points!));
  }

  void _requestDelete() {
    Navigator.of(context).pop(const _TaskEditorResult.delete());
  }

  String? _validateTaskInput({required String taskName, required int? points}) {
    if (taskName.isEmpty) {
      return '\u8bf7\u8f93\u5165\u4efb\u52a1\u540d';
    }
    if (taskName.length > _taskTitleMaxLength) {
      return '\u4efb\u52a1\u540d\u6700\u591a $_taskTitleMaxLength \u5b57';
    }
    if (points == null) {
      return '\u8bf7\u8f93\u5165\u79ef\u5206';
    }
    if (points < _taskPointsMin || points > _taskPointsMax) {
      return '\u79ef\u5206\u9700\u5728 $_taskPointsMin-$_taskPointsMax \u4e4b\u95f4';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final panelAspectRatio = _taskEditorAssetWidth / _taskEditorAssetHeight;
    final panelWidth = math.min(screenSize.width * 0.995, 560.0);
    final basePanelHeight = panelWidth / panelAspectRatio;
    final heightBoostFactor = basePanelHeight < 320 ? 1.12 : 1.06;
    final panelHeight = math.min(
      screenSize.height * 0.9,
      basePanelHeight * heightBoostFactor,
    );

    final horizontalInset = math.max(34.0, panelWidth * 0.10);
    final verticalInset = math.max(34.0, panelHeight * 0.10);
    final contentPadding = EdgeInsets.fromLTRB(
      horizontalInset,
      verticalInset,
      horizontalInset,
      verticalInset,
    );
    final frameScale = basePanelHeight < 320 ? 1.10 : 1.06;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: ColoredBox(
                  color: const Color(0xB3261A10).withValues(alpha: 0.46),
                ),
              ),
            ),
          ),
          SafeArea(
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.only(bottom: viewInsets.bottom * 0.85),
              child: Center(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: SizedBox(
                    width: panelWidth,
                    height: panelHeight,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Transform.scale(
                              scale: frameScale,
                              child: Image.asset(
                                _taskEditorPanelAsset,
                                width: _taskEditorAssetWidth,
                                height: _taskEditorAssetHeight,
                                fit: BoxFit.fill,
                                alignment: Alignment.center,
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Padding(
                            padding: contentPadding,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return SingleChildScrollView(
                                  padding: EdgeInsets.only(
                                    bottom: viewInsets.bottom > 0 ? 8 : 0,
                                  ),
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minHeight: constraints.maxHeight,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0x1AF8F1E6),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: const Color(0xFF2F2218),
                                              width: 1.2,
                                            ),
                                          ),
                                          child: Text(
                                            widget.isEditing
                                                ? '\u7f16\u8f91\u4efb\u52a1'
                                                : '\u6dfb\u52a0\u4efb\u52a1',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: Color(0xFF4D3623),
                                              fontWeight: FontWeight.w900,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.fromLTRB(
                                            12,
                                            8,
                                            10,
                                            8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0x1AF8F1E6),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            border: Border.all(
                                              color: const Color(0xFF2F2218),
                                              width: 1.1,
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              _TaskEditorField(
                                                label: '\u4efb\u52a1\u540d',
                                                controller: _taskNameController,
                                                hintText:
                                                    '\u4f8b\u5982\uff1a\u6574\u7406\u73a9\u5177',
                                                maxLength: _taskTitleMaxLength,
                                                textInputAction:
                                                    TextInputAction.next,
                                              ),
                                              const SizedBox(height: 6),
                                              const Divider(
                                                height: 1,
                                                thickness: 1,
                                                color: Color(0xFF3E2E21),
                                              ),
                                              const SizedBox(height: 6),
                                              _TaskEditorField(
                                                label: '\u79ef\u5206',
                                                controller:
                                                    _taskPointsController,
                                                hintText:
                                                    '\u4f8b\u5982\uff1a10',
                                                keyboardType:
                                                    TextInputType.number,
                                                maxLength: 4,
                                                inputFormatters: [
                                                  FilteringTextInputFormatter
                                                      .digitsOnly,
                                                  LengthLimitingTextInputFormatter(
                                                    4,
                                                  ),
                                                ],
                                                textInputAction:
                                                    TextInputAction.done,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        if (_validationMessage != null)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 6,
                                            ),
                                            child: Text(
                                              _validationMessage!,
                                              style: const TextStyle(
                                                color: Color(0xFF8A3228),
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        if (widget.isEditing)
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: TextButton.icon(
                                              onPressed: _requestDelete,
                                              style: TextButton.styleFrom(
                                                foregroundColor: const Color(
                                                  0xFF9C5F4F,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                      vertical: 2,
                                                    ),
                                                tapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                              ),
                                              icon: const Icon(
                                                Icons.delete_outline_rounded,
                                                size: 18,
                                              ),
                                              label: const Text(
                                                '\u5220\u9664\u4efb\u52a1',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ),
                                        if (widget.isEditing)
                                          const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton(
                                                onPressed: () =>
                                                    Navigator.of(context).pop(),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: const Color(
                                                    0xFF5C4A38,
                                                  ),
                                                  side: const BorderSide(
                                                    color: Color(0xFF8E6C4D),
                                                    width: 1.3,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  backgroundColor: const Color(
                                                    0xFFF0E6D3,
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 9,
                                                      ),
                                                ),
                                                child: const Text(
                                                  '\u53d6\u6d88',
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: FilledButton(
                                                onPressed: _save,
                                                style: FilledButton.styleFrom(
                                                  backgroundColor: const Color(
                                                    0xFFB67B56,
                                                  ),
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 9,
                                                      ),
                                                ),
                                                child: Text(
                                                  widget.isEditing
                                                      ? '\u4fdd\u5b58\u4fee\u6539'
                                                      : '\u6dfb\u52a0\u4efb\u52a1',
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskEditorField extends StatelessWidget {
  const _TaskEditorField({
    required this.label,

    required this.controller,

    required this.hintText,

    this.keyboardType,

    this.inputFormatters,

    this.maxLength,

    this.textInputAction,
  });

  final String label;

  final TextEditingController controller;

  final String hintText;

  final TextInputType? keyboardType;

  final List<TextInputFormatter>? inputFormatters;

  final int? maxLength;

  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text(
          label,

          style: const TextStyle(
            color: Color(0xFF4D3623),

            fontWeight: FontWeight.w800,

            fontSize: 13,
          ),
        ),

        const SizedBox(height: 4),

        SizedBox(
          height: 44,
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/ui/task_row_field_idle.png',
                  fit: BoxFit.fill,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 4),
                child: TextField(
                  controller: controller,

                  keyboardType: keyboardType,

                  inputFormatters: inputFormatters,

                  maxLength: maxLength,

                  textInputAction: textInputAction,

                  cursorColor: const Color(0xFF2F2218),

                  style: const TextStyle(
                    color: Color(0xFF4E3A27),

                    fontWeight: FontWeight.w700,

                    fontSize: 14,
                  ),

                  decoration: InputDecoration(
                    hintText: hintText,

                    hintStyle: const TextStyle(
                      color: Color(0xA36F563D),
                      fontSize: 13,
                    ),

                    counterText: '',

                    border: InputBorder.none,

                    isCollapsed: true,

                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
