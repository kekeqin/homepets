import 'dart:async';

import 'dart:math' as math;

import 'dart:ui' as ui;

import 'package:flame_riverpod/flame_riverpod.dart';

import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api_error_helper.dart';
import '../../core/constants.dart';
import '../../core/ui/sprite_atlas.dart';

import '../../models/pet.dart';
import '../../models/pet_artwork.dart';
import '../../models/user.dart';

import '../../providers/auth_provider.dart';
import '../../providers/family_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/app_modal_shell.dart';
import '../../widgets/pickstarpet_button.dart';
import '../../widgets/pickstarpet_dialog.dart';
import '../../widgets/pickstarpet_select_field.dart';
import '../../widgets/membership_top_notice.dart';
import '../../widgets/public_id_row.dart';
import '../../widgets/source_scaled_rrect_border.dart';

import '../family/family_screen.dart';
import '../family/models/family_member_view_data.dart';
import '../family/models/family_screen_state.dart';
import '../family/widgets/family_sprite_slice.dart';
import '../paywall/paywall_screen.dart';
import '../pet/pet_detail_screen.dart';
import 'game/home_scene_game.dart';
import 'guide/home_guide_controller.dart';
import 'guide/home_guide_overlay.dart';
import 'settings_dialog.dart';
import 'task_panel_sprite_catalog.dart';

enum _TaskPanelRowAction { edit, delete, complete }

class _ProfileEditResult {
  const _ProfileEditResult({required this.nickname, required this.familyName});

  final String nickname;
  final String? familyName;
}

String _homePetBindingSignature(FamilyScreenState state) {
  final memberSignatures = List<String>.from(
    state.members.map(
      (member) =>
          '${member.id}:${member.petId ?? ''}:${member.petType ?? ''}:${member.pet?.level ?? ''}:${member.needsPetSelection}',
    ),
  )..sort();
  return '${state.hasFamily}|${memberSignatures.join('|')}';
}

String _homeGuideAuthScopeSignature(AuthState state) {
  final user = state.user;
  return '${user?.id ?? 'anonymous'}:${user?.familyId ?? 'no_family'}';
}

const String _taskContextMenuBoardAsset =
    'assets/images/ui/task_context_menu_board_compact.png';

const String _taskContextMenuEditButtonAsset =
    'assets/images/ui/task_context_menu_btn_edit.png';

const String _taskContextMenuDeleteButtonAsset =
    'assets/images/ui/task_context_menu_btn_delete.png';

const String _taskContextMenuCompleteButtonAsset =
    'assets/images/ui/task_context_menu_btn_cancel.png';

const int _taskTitleMaxLength = 200;

const int _taskPointsMin = 1;

const int _taskPointsMax = 1000;

const String _taskPanelNoteAsset = 'assets/images/ui/task_note.png';
const String _membershipRequiredMessage = membershipRequiredMessage;
const String _sharedCloseButtonAsset = 'assets/images/ui/sprites/close.png';
const String _taskPanelCloseButtonAsset = FamilyPopupAssets.closeButton;
const String _taskDeleteTrashAsset = 'assets/images/ui/task_delete/trash.png';
const String _taskDeleteTitleAsset =
    'assets/images/ui/task_delete/title_text.png';
const String _taskDeleteMemberButtonSpriteAsset =
    'assets/images/ui/sprites/delete_member_dialog_sprites.png';
const Size _taskDeleteMemberButtonSpriteSheetSize = Size(1536, 1024);
const Rect _taskDeleteMemberIllustrationRegion = Rect.fromLTWH(
  284,
  818,
  211,
  134,
);
const Rect _taskDeleteMemberCancelButtonRegion = Rect.fromLTWH(
  639,
  856,
  257,
  102,
);
const Rect _taskDeleteMemberConfirmButtonRegion = Rect.fromLTWH(
  1005,
  856,
  258,
  102,
);
const String _taskDialogPanelBackgroundAsset =
    TaskBoardReferenceAsset.dialogPanel;
const String _completeMemberDialogAssetRoot =
    'assets/images/ui/sprites/complete_member_dialog_parts';
const double _completeMemberDialogDesignWidth = 436;
const double _completeMemberFieldHeight = 65;
const double _completeMemberOptionExtent = 55;
const double _completeMemberTitleFontSize =
    _completeMemberDialogDesignWidth * 0.075;
const double _completeMemberLabelFontSize =
    _completeMemberDialogDesignWidth * 0.048;
const double _completeMemberFieldFontSize = _completeMemberFieldHeight * 0.44;
const double _completeMemberOptionFontSize = _completeMemberOptionExtent * 0.44;
const Size _completeMemberDialogDesignSize = Size(
  _completeMemberDialogDesignWidth,
  _completeMemberDialogDesignWidth /
      TaskBoardReferenceAsset.dialogPanelAspectRatio,
);
const String _completeMemberDropdownArrowAsset =
    '$_completeMemberDialogAssetRoot/complete_member_chevron_down_standalone.png';
const String _completeMemberCheckmarkAsset =
    '$_completeMemberDialogAssetRoot/complete_member_checkmark_white_right.png';
const Color _completeMemberFieldFillColor = Color(0xFFFFFCF4);
const Color _completeMemberFieldBorderColor = Color(0xFF76563E);
const Color _completeMemberMenuFillColor = Color(0xFFFFF4E5);
const Color _completeMemberOptionFillColor = Color(0xFFFBE3BD);
const Color _completeMemberOptionSelectedColor = Color(0xFFD7E09A);
const Color _taskEditorFieldFillColor = Color(0x6BFFFFFF);
const Color _taskEditorFieldLineColor = Color(0xFF2F2218);
const Color _taskEditorFieldInkColor = Color(0xFF5A3A21);
const Color _taskEditorFieldHintColor = Color(0x615A3A21);
const Color _taskDialogOuterBorderColor = Color(0xFF6A3D20);
const Duration _taskCompletionFeedbackDuration = Duration(milliseconds: 650);
const double _taskMutationDialogMaxWidth = 430;
const double _taskMutationDialogHeightFactor = 0.76;
const double _taskPanelBoardHeightRatio =
    TaskBoardReferenceAsset.panelHeightRatio;
const Duration _taskPanelTransitionDuration = Duration(milliseconds: 320);

Size _taskMutationDialogSize(
  Size screenSize, {
  double horizontalGutter = PickStarPetDialogGutter.medium,
}) {
  const visibleWidthRatio =
      (TaskBoardReferenceAsset.dialogPanelWidth -
          TaskBoardReferenceAsset.dialogPanelVisibleLeftInset -
          TaskBoardReferenceAsset.dialogPanelVisibleRightInset) /
      TaskBoardReferenceAsset.dialogPanelWidth;
  final visibleWidthLimit = math.max(
    0.0,
    screenSize.width - horizontalGutter * 2,
  );
  final maxPanelWidth = math.min(
    visibleWidthLimit / visibleWidthRatio,
    _taskMutationDialogMaxWidth,
  );
  final maxPanelHeight = screenSize.height * _taskMutationDialogHeightFactor;
  final panelAspectRatio = TaskBoardReferenceAsset.dialogPanelAspectRatio;
  final panelWidth = math.min(maxPanelWidth, maxPanelHeight * panelAspectRatio);

  return Size(panelWidth, panelWidth / panelAspectRatio);
}

double _taskDialogVisibleCenterOffset(double panelWidth) {
  final scaledLeftInset =
      panelWidth *
      TaskBoardReferenceAsset.dialogPanelVisibleLeftInset /
      TaskBoardReferenceAsset.dialogPanelWidth;
  final scaledRightInset =
      panelWidth *
      TaskBoardReferenceAsset.dialogPanelVisibleRightInset /
      TaskBoardReferenceAsset.dialogPanelWidth;
  return (scaledRightInset - scaledLeftInset) / 2;
}

class HomeSceneFlameView extends ConsumerStatefulWidget {
  const HomeSceneFlameView({
    super.key,
    required this.device,
    this.openTasksPanelOnStart = false,
    this.openFamilyPanelOnStart = false,
    this.openShopPanelOnStart = false,
  });

  final HomeSceneDevice device;
  final bool openTasksPanelOnStart;
  final bool openFamilyPanelOnStart;
  final bool openShopPanelOnStart;

  @override
  ConsumerState<HomeSceneFlameView> createState() => _HomeSceneFlameViewState();
}

class _HomeSceneFlameViewState extends ConsumerState<HomeSceneFlameView>
    with TickerProviderStateMixin {
  late HomeSceneGame _game;

  late GlobalKey<RiverpodAwareGameWidgetState<HomeSceneGame>> _gameKey;
  late final AnimationController _taskPanelController;

  List<Pet> _pets = const <Pet>[];

  List<Map<String, dynamic>> _homeTasks = const <Map<String, dynamic>>[];
  bool _didRequestInitialTaskPanel = false;
  bool _didRequestInitialFamilyPanel = false;
  bool _didRequestInitialShopPanel = false;
  bool _familyPanelVisible = false;
  bool _shopPanelVisible = false;
  bool _settingsPanelVisible = false;
  /// When true, the next settings dialog open will also show paywall on top so
  /// settings stays behind the membership sheet (e.g. save profile while blocked).
  bool _pendingPaywallOverSettings = false;
  bool _taskPanelVisible = false;
  bool _taskPanelExpanded = false;
  bool _taskPanelClosing = false;
  bool _taskPanelBackdropInteractive = false;
  bool _clearTaskRouteAfterClose = false;
  int _taskPanelPageIndex = 0;
  double _taskPanelHorizontalDragOffset = 0;
  Rect? _taskPanelOriginRect;
  bool _didPrecacheTaskPanelAssets = false;
  String? _taskPanelPressedInteractionKey;
  int? _taskPanelCompletingTaskId;
  HomeGuideController? _homeGuideController;
  HomeGuideProgress? _homeGuideProgress;
  bool _homeGuideLoading = true;
  bool _advanceHomeGuideAfterTaskPanelClose = false;
  bool _homeGuideCompletionPaywallQueued = false;
  OverlayEntry? _topSnackBarEntry;
  bool _paywallDialogVisible = false;
  final math.Random _taskCompletionMessageRandom = math.Random();

  static const int _taskPanelPageSize = 4;

  static const Duration _topSnackBarDuration = Duration(milliseconds: 1800);

  bool get _isAdmin {
    final user = ref.read(authProvider).user;

    return user?.isAdmin == true;
  }

  bool get _isReadOnlyAfterTrial {
    return ref.read(coreMutationBlockedProvider);
  }

  bool get _canCompleteTasks => !_isReadOnlyAfterTrial;

  void _showReadOnlyPaywall() {
    if (!mounted) {
      return;
    }
    _openPaywall();
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

    _loadHomeTasks();
    _initHomeGuide();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _loadFamilyForHomeGuide();
      _loadFamilyPets();
    });
    _maybeOpenInitialTaskPanel();
    _maybeOpenInitialFamilyPanel();
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
      _taskDialogPanelBackgroundAsset,
      _taskPanelCloseButtonAsset,
      _sharedCloseButtonAsset,
      ...TaskBoardReferenceAsset.runtimeAssets,
    ]) {
      _safePrecacheImage(assetPath);
    }
  }

  void _safePrecacheImage(String assetPath) {
    precacheImage(AssetImage(assetPath), context).catchError((
      Object error,
      StackTrace stackTrace,
    ) {
      debugPrint('Home scene image asset failed to precache: $assetPath');
      debugPrint('$error');
    });
  }

  Future<bool> _ensureTaskPanelSpritesReady() async {
    try {
      await Future.wait(
        <String>[
          _taskPanelNoteAsset,
          _taskDialogPanelBackgroundAsset,
          _taskPanelCloseButtonAsset,
          _sharedCloseButtonAsset,
          ...TaskBoardReferenceAsset.runtimeAssets,
        ].map((assetPath) => precacheImage(AssetImage(assetPath), context)),
      );
      return mounted;
    } catch (error) {
      debugPrint(
        'Task panel reference sprite assets are not available: $error',
      );
      return false;
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(_game.reloadSceneLayoutForHotReload());
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
      _didRequestInitialFamilyPanel = false;
      _didRequestInitialShopPanel = false;
    }

    if (!oldWidget.openTasksPanelOnStart && widget.openTasksPanelOnStart) {
      _didRequestInitialTaskPanel = false;
    }

    if (!oldWidget.openFamilyPanelOnStart && widget.openFamilyPanelOnStart) {
      _didRequestInitialFamilyPanel = false;
    }

    if (!oldWidget.openShopPanelOnStart && widget.openShopPanelOnStart) {
      _didRequestInitialShopPanel = false;
    }

    _maybeOpenInitialTaskPanel();
    _maybeOpenInitialFamilyPanel();
    _maybeOpenInitialShopPanel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _syncGamePetsFromServer();
      }
    });
  }

  HomeSceneGame _createGame() {
    return HomeSceneGame(
      device: widget.device,
      onTaskTap: () => _handleTaskStickerTap(),

      onOpenFamily: _openFamily,

      onOpenShop: _openShop,

      onOpenPaywall: _openPaywall,

      onOpenSettings: _openSettings,

      onTaskItemLongPress: _showTaskPanelRowActions,

      onTaskAddTap: _handleTaskAddTap,

      onOpenPetDetail: (petId, avatarAssetPath) {
        _openPetDetail(petId, avatarAssetPath);
      },
      onGuideAnchorLayoutChanged: _handleGuideAnchorLayoutChanged,
    );
  }

  void _handleGuideAnchorLayoutChanged() {
    if (!_shouldShowHomeGuideOverlay) {
      return;
    }
    if (mounted) {
      setState(() {});
    }
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

    _showFamilyPanel(clearRouteAfterClose: false);
  }

  void _maybeOpenInitialFamilyPanel() {
    if (!widget.openFamilyPanelOnStart || _didRequestInitialFamilyPanel) {
      return;
    }

    _didRequestInitialFamilyPanel = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _showFamilyPanel(clearRouteAfterClose: true);
    });
  }

  Future<void> _showFamilyPanel({required bool clearRouteAfterClose}) async {
    if (_familyPanelVisible) {
      return;
    }

    _familyPanelVisible = true;
    await showFamilyDialog(
      context,
      petAvatarAssetPathsById: _game.debugPetDetailAvatarAssetPaths(),
    );
    _familyPanelVisible = false;

    if (!mounted) {
      return;
    }

    await _loadFamilyPets();

    if (mounted) {
      _game.shufflePetLayout();
    }

    if (!mounted || !clearRouteAfterClose) {
      return;
    }

    final routerState = GoRouterState.of(context);
    if (routerState.matchedLocation == '/home' &&
        routerState.uri.queryParameters['panel'] == 'family') {
      context.go('/home');
    }
  }

  HomeGuideSnapshot get _homeGuideSnapshot {
    final familyState = ref.read(familyProvider);
    final authState = ref.read(authProvider);
    return HomeGuideSnapshot(
      hasFamilyMembers: familyState.members.isNotEmpty,
      hasActiveTasks: _activeHomeTasks.isNotEmpty,
      hasCurrentUserPet: _currentUserHasPet(authState, familyState),
      hasMembersMissingPets: familyState.members.any(_memberNeedsPet),
    );
  }

  bool _currentUserHasPet(AuthState authState, FamilyScreenState familyState) {
    final user = authState.user;
    if (user == null) {
      return false;
    }

    for (final member in familyState.members) {
      if (member.id == user.id) {
        return !_memberNeedsPet(member);
      }
    }

    return false;
  }

  bool _memberNeedsPet(FamilyMemberViewData member) {
    return member.needsPetSelection ||
        (member.pet == null && member.petId == null);
  }

  String get _homeGuideScopeId {
    final user = ref.read(authProvider).user;
    if (user == null) {
      return 'anonymous';
    }

    final familyId = user.familyId == null
        ? 'no_family'
        : 'family_${user.familyId}';
    return 'user_${user.id}_$familyId';
  }

  Future<void> _initHomeGuide() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }
    final controller = HomeGuideController(
      preferences: preferences,
      scopeId: _homeGuideScopeId,
    );
    setState(() {
      _homeGuideController = controller;
      _homeGuideProgress = controller.readProgress(_homeGuideSnapshot);
      _homeGuideLoading = false;
    });
    _maybeShowHomeGuideCompletionPaywall();
  }

  Future<void> _loadFamilyForHomeGuide() async {
    try {
      await ref.read(familyProvider.notifier).loadFamily();
      _refreshHomeGuideProgress();
    } catch (error) {
      debugPrint('Home guide failed to load family state: $error');
    }
  }

  void _refreshHomeGuideProgress() {
    final controller = _homeGuideController;
    if (controller == null || _homeGuideLoading) {
      return;
    }
    final nextProgress = controller.readProgress(_homeGuideSnapshot);
    final currentProgress = _homeGuideProgress;
    if (currentProgress?.currentStep == nextProgress.currentStep &&
        currentProgress?.completed == nextProgress.completed &&
        currentProgress?.skipped == nextProgress.skipped) {
      return;
    }
    if (mounted) {
      setState(() => _homeGuideProgress = nextProgress);
    } else {
      _homeGuideProgress = nextProgress;
    }
    _maybeShowHomeGuideCompletionPaywall();
  }

  Rect? _homeGuideAnchorRect(Size size) {
    final progress = _homeGuideProgress;
    if (progress == null || !progress.shouldShow) {
      return null;
    }
    final rawRect = switch (progress.currentStep) {
      HomeGuideStep.taskSticker => _game.taskPanelOriginRect(),
      HomeGuideStep.familyFrame => _game.familyPhotoRect(),
      HomeGuideStep.petArea => _game.primaryPetRect(),
      HomeGuideStep.done => null,
    };
    if (rawRect == null) {
      return null;
    }
    return _clampPanelRect(rawRect, size);
  }

  bool get _shouldShowHomeGuideOverlay {
    final progress = _homeGuideProgress;
    final authState = ref.read(authProvider);
    return !_isReadOnlyAfterTrial &&
        !homeGuideBlockedByEntitlement(authState) &&
        !_homeGuideLoading &&
        progress != null &&
        progress.shouldShow &&
        !_taskPanelVisible &&
        !_familyPanelVisible &&
        !_shopPanelVisible &&
        !_settingsPanelVisible;
  }

  Future<void> _skipHomeGuide() async {
    final controller = _homeGuideController;
    if (controller == null) {
      return;
    }
    final nextProgress = await controller.skip();
    if (!mounted) {
      return;
    }
    setState(() => _homeGuideProgress = nextProgress);
    _maybeShowHomeGuideCompletionPaywall();
  }

  Future<void> _advanceHomeGuide(HomeGuideStep step) async {
    final controller = _homeGuideController;
    if (controller == null) {
      return;
    }
    final nextProgress = await controller.advance(step, _homeGuideSnapshot);
    if (!mounted) {
      return;
    }
    setState(() => _homeGuideProgress = nextProgress);
    _maybeShowHomeGuideCompletionPaywall();
  }

  void _maybeShowHomeGuideCompletionPaywall() {
    final controller = _homeGuideController;
    if (controller == null ||
        _homeGuideCompletionPaywallQueued ||
        !controller.shouldShowCompletionPaywall()) {
      return;
    }

    _homeGuideCompletionPaywallQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _homeGuideCompletionPaywallQueued = false;
      if (!mounted) {
        return;
      }

      final latestController = _homeGuideController;
      if (latestController == null ||
          !latestController.shouldShowCompletionPaywall() ||
          _paywallDialogVisible ||
          _isReadOnlyAfterTrial ||
          ref.read(authProvider).viewOnly) {
        return;
      }

      await latestController.markCompletionPaywallShown();
      if (!mounted) {
        return;
      }
      _showTopSnackBar('引导已完成，开始体验吧');
      await Future<void>.delayed(_topSnackBarDuration);
      if (!mounted) {
        return;
      }
      _openPaywall();
    });
  }

  Future<void> _handleHomeGuideHotspotTap(HomeGuideStep step) async {
    switch (step) {
      case HomeGuideStep.taskSticker:
        await _handleTaskStickerTap(advanceHomeGuideAfterClose: true);
        break;
      case HomeGuideStep.familyFrame:
        await _showFamilyPanel(clearRouteAfterClose: false);
        await _advanceHomeGuide(step);
        break;
      case HomeGuideStep.petArea:
        final petId = _game.primaryPetId();
        final avatarAssetPath = _game.primaryPetDetailAvatarAssetPath();
        if (petId != null && avatarAssetPath != null) {
          await _openPetDetail(petId, avatarAssetPath);
        } else {
          _game.playPetCompletionReaction(message: '完成任务后，我会陪你一起成长', points: 0);
        }
        await _advanceHomeGuide(step);
        break;
      case HomeGuideStep.done:
        break;
    }
  }

  void _openShop() {
    if (!mounted) {
      return;
    }

    _showShopComingSoonDialog(clearRouteAfterClose: false);
  }

  void _openPaywall() {
    if (!mounted || _paywallDialogVisible) {
      return;
    }

    _topSnackBarEntry?.remove();
    _topSnackBarEntry = null;
    unawaited(_openPaywallDialog());
  }

  Future<void> _openPaywallDialog() async {
    _paywallDialogVisible = true;
    try {
      await showPaywallDialog(context);
    } finally {
      _paywallDialogVisible = false;
    }
    await _refreshHomeAfterPaywallDismiss();
  }

  Future<void> _refreshHomeAfterPaywallDismiss() async {
    if (!mounted) {
      return;
    }

    try {
      await ref.read(familyProvider.notifier).loadFamily();
    } catch (error, stackTrace) {
      debugPrint('Failed to refresh family after paywall dismissed: $error');
      debugPrint('$stackTrace');
    }

    if (!mounted) {
      return;
    }

    await _loadFamilyPets(forceSync: true);
    _refreshHomeGuideProgress();
  }

  Future<void> _openSettings() async {
    if (!mounted) {
      return;
    }

    await _showSettingsPanel();
    if (mounted) {
      _game.shufflePetLayout();
    }
  }

  Future<void> _showSettingsPanel() async {
    if (_settingsPanelVisible) {
      return;
    }

    final settingsContext = context;
    var keepSettingsOpen = true;

    while (mounted && keepSettingsOpen) {
      if (!settingsContext.mounted) {
        return;
      }

      _settingsPanelVisible = true;
      HomeSettingsAction? action;
      try {
        final settingsFuture = showSettingsDialog(settingsContext);
        // Re-open settings first, then stack paywall on top so settings stays
        // behind (instead of racing unawaited paywall under a new settings sheet).
        if (_pendingPaywallOverSettings) {
          _pendingPaywallOverSettings = false;
          await _waitForSettingsRoutePresented();
          if (mounted && !_paywallDialogVisible) {
            await _openPaywallDialog();
          }
        }
        action = await settingsFuture;
      } finally {
        _settingsPanelVisible = false;
      }

      if (!mounted || action == null) {
        return;
      }

      await _waitForDismissedSettingsRoute();
      if (!mounted) {
        return;
      }

      switch (action) {
        case HomeSettingsAction.editProfile:
          // Always allow opening edit profile so expired-trial users can still
          // view/copy their public_id. Paywall is enforced only when saving.
          final showPaywallAfter = await _showEditProfileDialog();
          if (showPaywallAfter) {
            _pendingPaywallOverSettings = true;
          }
          break;
        case HomeSettingsAction.about:
          await _showAboutDialog();
          break;
        case HomeSettingsAction.logout:
          final confirmed = await _showLogoutConfirmDialog();
          if (!mounted) {
            return;
          }

          if (!confirmed) {
            break;
          }

          keepSettingsOpen = false;
          await ref.read(authProvider.notifier).logout();
          if (!mounted) {
            return;
          }
          context.go('/login');
          return;
      }
    }
  }

  Future<void> _waitForSettingsRoutePresented() async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame;
  }

  Future<void> _waitForDismissedSettingsRoute() async {
    await Future<void>.delayed(const Duration(milliseconds: 260));
    await WidgetsBinding.instance.endOfFrame;
  }

  /// Returns true when membership paywall should be shown after returning to
  /// settings (so paywall can stack on top of the reopened settings sheet).
  Future<bool> _showEditProfileDialog() async {
    User? loadedUser = ref.read(authProvider).user;

    if (loadedUser == null) {
      _showTopSnackBar(
        '\u8bf7\u5148\u767b\u5f55\u540e\u518d\u7f16\u8f91\u8d44\u6599',
      );
      return false;
    }

    // Refresh so public_id is available after backend upgrades.
    try {
      await ref.read(authProvider.notifier).refreshUser();
      if (!mounted) {
        return false;
      }
      loadedUser = ref.read(authProvider).user ?? loadedUser;
    } catch (_) {
      // Keep the existing in-memory user if refresh fails.
    }

    final user = loadedUser;
    if (user == null) {
      return false;
    }

    // Admins can still view family name after trial expiry; mutating it is gated
    // at save time so public_id remains visible in read-only mode.
    final canManageFamilyName = user.isAdmin && user.familyId != null;

    if (canManageFamilyName) {
      try {
        await ref.read(familyProvider.notifier).loadFamily();
      } catch (error) {
        if (!mounted) {
          return false;
        }
        showFriendlyApiErrorSnackBar(
          context,
          error,
          fallbackMessage:
              '\u52a0\u8f7d\u5bb6\u5ead\u8d44\u6599\u5931\u8d25\uff0c\u8bf7\u7a0d\u540e\u91cd\u8bd5',
        );
        return false;
      }
    }

    final familyState = ref.read(familyProvider);
    final canEditFamilyName = canManageFamilyName && familyState.hasFamily;
    final nicknameController = TextEditingController(text: user.nickname);
    final familyNameController = TextEditingController(
      text: canEditFamilyName ? familyState.familyName : '',
    );
    final publicId = user.publicId;

    try {
      if (!mounted) {
        return false;
      }

      final result = await showPickStarPetDialog<_ProfileEditResult>(
        context: context,
        barrierLabel: 'edit_profile_dialog',
        title: '\u7f16\u8f91\u8d44\u6599',
        layout: const AppModalLayout(
          mobileWidthFactor: 1.0,
          mobileMaxWidth: 390,
          mobileHeightFactor: 0.78,
          mobileMaxHeight: 520,
          tabletWidthFactor: 0.38,
          tabletMaxWidth: 430,
          tabletHeightFactor: 0.62,
          tabletMaxHeight: 560,
        ),
        showInnerBorder: false,
        contentBuilder: (dialogContext) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PublicIdRow(
                publicId: publicId,
                labelColor: const Color(0xFF7C634C),
                valueColor: const Color(0xFF4D3623),
                onCopied: () {
                  if (!mounted) {
                    return;
                  }
                  _showTopSnackBar('\u4e13\u5c5e ID \u5df2\u590d\u5236');
                },
              ),
              const SizedBox(height: 16),
              _buildEditProfileField(
                controller: nicknameController,
                labelText: '\u6635\u79f0',
                maxLength: 20,
                textInputAction: canEditFamilyName
                    ? TextInputAction.next
                    : TextInputAction.done,
                onSubmitted: canEditFamilyName
                    ? () => FocusScope.of(dialogContext).nextFocus()
                    : () => _submitEditProfileDialog(
                        dialogContext,
                        nickname: nicknameController.text,
                        familyName: null,
                      ),
              ),
              if (canEditFamilyName) ...[
                const SizedBox(height: 16),
                _buildEditProfileField(
                  controller: familyNameController,
                  labelText: '\u5bb6\u5ead\u540d\u79f0',
                  maxLength: 30,
                  textInputAction: TextInputAction.done,
                  onSubmitted: () => _submitEditProfileDialog(
                    dialogContext,
                    nickname: nicknameController.text,
                    familyName: familyNameController.text,
                  ),
                ),
              ],
            ],
          );
        },
        actionsBuilder: (dialogContext) {
          return <Widget>[
            PickStarPetButton(
              label: '\u53d6\u6d88',
              variant: PickStarPetButtonVariant.secondary,
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            PickStarPetButton(
              label: '\u4fdd\u5b58',
              onPressed: () => _submitEditProfileDialog(
                dialogContext,
                nickname: nicknameController.text,
                familyName: canEditFamilyName
                    ? familyNameController.text
                    : null,
              ),
            ),
          ];
        },
      );

      if (!mounted || result == null) {
        return false;
      }

      final nextNickname = result.nickname.trim();
      final nextFamilyName = result.familyName?.trim();
      final nicknameChanged = nextNickname != user.nickname.trim();
      final familyNameChanged =
          canEditFamilyName &&
          nextFamilyName != null &&
          nextFamilyName != familyState.familyName.trim();

      if (!nicknameChanged && !familyNameChanged) {
        return false;
      }

      // Trial expired / subscription blocked: allow viewing public_id above,
      // but require paywall before mutating nickname or family name.
      // Defer paywall until settings is reopened so it stacks on top.
      if (_isReadOnlyAfterTrial) {
        return true;
      }

      var shouldReloadFamilyAfterNicknameChange = false;

      if (nicknameChanged) {
        final dio = ref.read(apiClientProvider).dio;
        await dio.put(
          '/api/users/${user.id}',
          data: {'nickname': nextNickname},
        );
        await ref.read(authProvider.notifier).refreshUser();
        shouldReloadFamilyAfterNicknameChange = user.familyId != null;
      }

      if (familyNameChanged) {
        await ref
            .read(familyProvider.notifier)
            .updateFamilyName(nextFamilyName);
        shouldReloadFamilyAfterNicknameChange = false;
      }

      if (shouldReloadFamilyAfterNicknameChange) {
        await ref.read(familyProvider.notifier).loadFamily();
      }

      if (mounted) {
        _showTopSnackBar('\u8d44\u6599\u5df2\u66f4\u65b0');
      }
      return false;
    } catch (error) {
      if (mounted) {
        showFriendlyApiErrorSnackBar(
          context,
          error,
          fallbackMessage:
              '\u66f4\u65b0\u8d44\u6599\u5931\u8d25\uff0c\u8bf7\u7a0d\u540e\u91cd\u8bd5',
        );
      }
      return false;
    } finally {
      // Wait for dialog exit animation so fields no longer hold controllers.
      await Future<void>.delayed(const Duration(milliseconds: 300));
      nicknameController.dispose();
      familyNameController.dispose();
    }
  }

  Widget _buildEditProfileField({
    required TextEditingController controller,
    required String labelText,
    required int maxLength,
    required TextInputAction textInputAction,
    VoidCallback? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      maxLength: maxLength,
      textInputAction: textInputAction,
      decoration: InputDecoration(labelText: labelText, counterText: ''),
      style: const TextStyle(
        color: Color(0xFF4D3623),
        fontSize: 17,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
      onSubmitted: onSubmitted == null ? null : (_) => onSubmitted(),
    );
  }

  void _submitEditProfileDialog(
    BuildContext dialogContext, {
    required String nickname,
    required String? familyName,
  }) {
    final trimmedNickname = nickname.trim();
    final trimmedFamilyName = familyName?.trim();

    if (trimmedNickname.isEmpty) {
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        const SnackBar(content: Text('\u8bf7\u8f93\u5165\u6635\u79f0')),
      );
      return;
    }

    if (familyName != null &&
        (trimmedFamilyName == null || trimmedFamilyName.isEmpty)) {
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        const SnackBar(
          content: Text('\u8bf7\u8f93\u5165\u5bb6\u5ead\u540d\u79f0'),
        ),
      );
      return;
    }

    Navigator.of(dialogContext).pop(
      _ProfileEditResult(
        nickname: trimmedNickname,
        familyName: familyName == null ? null : trimmedFamilyName,
      ),
    );
  }

  Future<bool> _showLogoutConfirmDialog() async {
    final result = await showPickStarPetDialog<bool>(
      context: context,
      barrierLabel: 'logout_confirm_dialog',
      minimumSafeArea: PickStarPetDialogGutter.smallInsets,
      title: '\u9000\u51fa\u767b\u5f55',
      showInnerBorder: false,
      contentBuilder: (dialogContext) {
        return const Text(
          '\u786e\u5b9a\u8981\u9000\u51fa\u5f53\u524d\u8d26\u53f7\u5417\uff1f',
          style: TextStyle(
            color: Color(0xFF6F563D),
            fontSize: 16,
            fontWeight: FontWeight.w700,
            height: 1.4,
            letterSpacing: 0,
          ),
        );
      },
      actionsBuilder: (dialogContext) {
        return <Widget>[
          PickStarPetButton(
            label: '\u53d6\u6d88',
            variant: PickStarPetButtonVariant.secondary,
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          PickStarPetButton(
            label: '\u786e\u8ba4\u9000\u51fa',
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ];
      },
    );

    return result == true;
  }

  Future<void> _showAboutDialog() {
    return showPickStarPetDialog<void>(
      context: context,
      barrierLabel: 'about_pickstarpet_dialog',
      minimumSafeArea: PickStarPetDialogGutter.smallInsets,
      showInnerBorder: false,
      title: '关于',
      contentBuilder: (dialogContext) {
        return const Text(
          '拾星小宠家庭宠物\n\n'
          '通过任务喂养和宠物升级，把家庭日常任务变成亲子互动。\n\n'
          '版本：1.0.0',
          style: TextStyle(
            color: Color(0xFF6F563D),
            fontSize: 16,
            fontWeight: FontWeight.w700,
            height: 1.45,
            letterSpacing: 0,
          ),
        );
      },
      actionsBuilder: (dialogContext) {
        return <Widget>[
          // Smooth long pill like the paywall subscribe button — avoid the
          // sprite-atlas primary button, which shows jagged edges when scaled.
          _ShopConfirmActionButton(
            label: '知道了',
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
        ];
      },
    );
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
      _showShopComingSoonDialog(clearRouteAfterClose: true);
    });
  }

  Future<void> _showShopComingSoonDialog({
    required bool clearRouteAfterClose,
  }) async {
    if (_shopPanelVisible) {
      return;
    }

    _shopPanelVisible = true;
    await showPickStarPetDialog<void>(
      context: context,
      barrierLabel: 'shop_coming_soon',
      minimumSafeArea: PickStarPetDialogGutter.smallInsets,
      showInnerBorder: false,
      title: '星愿屋完善中',
      contentBuilder: (dialogContext) {
        return const Text(
          '星愿屋还在完善中，我们会尽快上线。',
          style: TextStyle(
            color: Color(0xFF6F563D),
            fontSize: 16,
            fontWeight: FontWeight.w700,
            height: 1.4,
            letterSpacing: 0,
          ),
        );
      },
      actionsBuilder: (dialogContext) {
        return <Widget>[
          _ShopConfirmActionButton(
            label: '知道了',
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
        ];
      },
    );
    _shopPanelVisible = false;

    if (mounted) {
      _game.shufflePetLayout();
    }

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

  bool get _canGoToPreviousTaskPage =>
      _taskPanelPageCount > 1 && _taskPanelCurrentPageIndex > 0;

  bool get _canGoToNextTaskPage =>
      _taskPanelPageCount > 1 &&
      _taskPanelCurrentPageIndex < _taskPanelPageCount - 1;

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
    const visibleWidthRatio =
        (TaskBoardReferenceAsset.panelWidth -
            TaskBoardReferenceAsset.boardVisibleLeftInset -
            TaskBoardReferenceAsset.boardVisibleRightInset) /
        TaskBoardReferenceAsset.panelWidth;
    final visibleWidthLimit = math.max(
      0.0,
      size.width - PickStarPetDialogGutter.large * 2,
    );
    final maxWidth = math.min(visibleWidthLimit / visibleWidthRatio, 452.0);
    final maxHeight = size.height * 0.80;
    final height = math.min(maxHeight, maxWidth * _taskPanelBoardHeightRatio);
    final width = height / _taskPanelBoardHeightRatio;
    final scaledLeftInset =
        width *
        TaskBoardReferenceAsset.boardVisibleLeftInset /
        TaskBoardReferenceAsset.panelWidth;
    final scaledRightInset =
        width *
        TaskBoardReferenceAsset.boardVisibleRightInset /
        TaskBoardReferenceAsset.panelWidth;
    return Rect.fromCenter(
      center: Offset(
        size.width * 0.5 + (scaledRightInset - scaledLeftInset) / 2,
        size.height * 0.51,
      ),
      width: width,
      height: height,
    );
  }

  Future<void> _handleTaskStickerTap({
    bool clearRouteAfterClose = false,
    bool advanceHomeGuideAfterClose = false,
  }) async {
    if (!mounted || _taskPanelVisible) {
      return;
    }

    final spritesReady = await _ensureTaskPanelSpritesReady();
    if (!mounted || _taskPanelVisible) {
      return;
    }
    if (!spritesReady) {
      _showTopSnackBar('任务面板资源未加载，请完全重启应用后再试');
      return;
    }

    final gameBox = _gameKey.currentContext?.findRenderObject() as RenderBox?;
    final gameSize = gameBox?.size ?? MediaQuery.sizeOf(context);
    final originRect = _clampPanelRect(
      _game.taskPanelOriginRect() ?? _defaultTaskPanelOriginRect(gameSize),
      gameSize,
    );

    if (advanceHomeGuideAfterClose) {
      _advanceHomeGuideAfterTaskPanelClose = true;
    }

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
    final shouldAdvanceHomeGuide = _advanceHomeGuideAfterTaskPanelClose;
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
      _advanceHomeGuideAfterTaskPanelClose = false;
      _taskPanelOriginRect = null;
      _taskPanelPressedInteractionKey = null;
    });

    if (shouldAdvanceHomeGuide) {
      await _advanceHomeGuide(HomeGuideStep.taskSticker);
      if (!mounted) {
        return;
      }
    }

    if (!shouldClearRoute) {
      return;
    }

    final routerState = GoRouterState.of(context);
    if (routerState.matchedLocation == '/home' &&
        routerState.uri.queryParameters['panel'] == 'tasks') {
      context.go('/home');
    }
  }

  void _setTaskPanelPageIndex(int pageIndex) {
    final clampedPageIndex = pageIndex
        .clamp(0, math.max(0, _taskPanelPageCount - 1))
        .toInt();
    if (clampedPageIndex == _taskPanelCurrentPageIndex) {
      return;
    }

    setState(() {
      _taskPanelPageIndex = clampedPageIndex;
      _taskPanelPressedInteractionKey = null;
    });
  }

  void _goToPreviousTaskPage() {
    if (!_canGoToPreviousTaskPage) {
      return;
    }

    _setTaskPanelPageIndex(_taskPanelCurrentPageIndex - 1);
  }

  void _goToNextTaskPage() {
    if (!_canGoToNextTaskPage) {
      return;
    }

    _setTaskPanelPageIndex(_taskPanelCurrentPageIndex + 1);
  }

  void _handleTaskPanelHorizontalDragStart(DragStartDetails details) {
    _taskPanelHorizontalDragOffset = 0;
  }

  void _handleTaskPanelHorizontalDragUpdate(DragUpdateDetails details) {
    _taskPanelHorizontalDragOffset += details.primaryDelta ?? 0;
  }

  void _handleTaskPanelHorizontalDragEnd(
    DragEndDetails details,
    double panelWidth,
  ) {
    if (!_taskPanelBackdropInteractive || _taskPanelPageCount <= 1) {
      _taskPanelHorizontalDragOffset = 0;
      return;
    }

    final dragOffset = _taskPanelHorizontalDragOffset;
    final velocity = details.primaryVelocity ?? 0;
    _taskPanelHorizontalDragOffset = 0;

    final distanceThreshold = math.min(96.0, math.max(44.0, panelWidth * 0.16));
    const velocityThreshold = 420.0;

    if (dragOffset <= -distanceThreshold || velocity <= -velocityThreshold) {
      _goToNextTaskPage();
      return;
    }

    if (dragOffset >= distanceThreshold || velocity >= velocityThreshold) {
      _goToPreviousTaskPage();
    }
  }

  void _handleTaskPanelHorizontalDragCancel() {
    _taskPanelHorizontalDragOffset = 0;
  }

  Future<void> _showTaskPanelRowActionsFromGlobalPosition(
    String taskLabel,
    Offset globalPosition,
  ) async {
    if (!mounted) {
      return;
    }

    if (_isReadOnlyAfterTrial) {
      _showReadOnlyPaywall();
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final panelSize = constraints.biggest;
        final boardTop =
            panelSize.height *
            (TaskBoardReferenceAsset.boardTopOffset /
                TaskBoardReferenceAsset.panelHeight);
        final boardHeight =
            panelSize.height *
            (TaskBoardReferenceAsset.boardSize.height /
                TaskBoardReferenceAsset.panelHeight);
        final boardWidth =
            boardHeight *
            (TaskBoardReferenceAsset.boardSize.width /
                TaskBoardReferenceAsset.boardSize.height);
        final clipWidth =
            panelSize.width *
            (TaskBoardReferenceAsset.clipSize.width /
                TaskBoardReferenceAsset.panelWidth) *
            0.76;
        final clipHeight =
            clipWidth *
            (TaskBoardReferenceAsset.clipSize.height /
                TaskBoardReferenceAsset.clipSize.width);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: (panelSize.width - boardWidth) * 0.5,
              top: boardTop,
              width: boardWidth,
              height: boardHeight,
              child: const _InsetSampledAssetImage(
                assetPath: TaskBoardReferenceAsset.board,
                sampleInset: 1,
              ),
            ),
            Positioned(
              left: (panelSize.width - clipWidth) * 0.5,
              top: 0,
              width: clipWidth,
              height: clipHeight,
              child: Image.asset(
                TaskBoardReferenceAsset.clip,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ],
        );
      },
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
        task['done'] == true ||
        task['completed_today'] == true ||
        task['status'] == 'completed';
  }

  bool _taskPanelTaskCompleting(Map<String, dynamic> task) {
    final taskId = _asInt(task['id'], fallback: -1);
    return taskId > 0 && taskId == _taskPanelCompletingTaskId;
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

  String _taskPanelRowAssetForIndex(int index) {
    return switch (index % 4) {
      0 => TaskBoardReferenceAsset.rowWarm,
      1 => TaskBoardReferenceAsset.rowGreen,
      2 => TaskBoardReferenceAsset.rowPink,
      _ => TaskBoardReferenceAsset.rowYellow,
    };
  }

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
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: width,
        child: Padding(
          padding: EdgeInsets.only(left: width * 0.04),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.left,
            style: TextStyle(
              color: textColor,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              height: 1,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskPanelExpandedContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final panelSize = constraints.biggest;
        final titleTop = panelSize.height * 0.119;
        final titleHeight = panelSize.height * 0.080;
        final titleIconBoxWidth = panelSize.width * 0.170;
        final titleIconVisualHeight = panelSize.height * 0.058;
        final titleIconGap = panelSize.width * 0.010;
        final rowWidth = panelSize.width * 0.858;
        final rowHeight = panelSize.height * 0.094;
        final rowLeft = (panelSize.width - rowWidth) * 0.5;
        final rowsTop = panelSize.height * 0.260;
        final rowGap = panelSize.height * 0.025;
        final pageControlVisualSize = panelSize.width * 0.027;
        final pageControlHitSize = panelSize.width * 0.064;
        final pageControlsCenterY = panelSize.height * 0.765;
        final pageControlGap = panelSize.width * 0.168;
        final pageIndicatorWidth = panelSize.width * 0.120;
        final pageIndicatorHeight = panelSize.height * 0.034;
        final closeButtonVisualSize = panelSize.width * 0.116;
        final closeButtonHitSize = closeButtonVisualSize * 1.12;
        final boardTop =
            panelSize.height *
            (TaskBoardReferenceAsset.boardTopOffset /
                TaskBoardReferenceAsset.panelHeight);
        final addButtonWidth = panelSize.width * 0.460;
        final addButtonHeight =
            addButtonWidth / TaskBoardReferenceAsset.addTaskButtonAspectRatio;
        final addButtonBottom = panelSize.height * 0.060;
        final activeTasks = _activeHomeTasks;
        final pageCount = math.max(
          1,
          (activeTasks.length + _taskPanelPageSize - 1) ~/ _taskPanelPageSize,
        );
        final currentPageIndex = _taskPanelPageIndex
            .clamp(0, math.max(0, pageCount - 1))
            .toInt();
        final visibleStart = currentPageIndex * _taskPanelPageSize;
        final visibleTasks = visibleStart >= activeTasks.length
            ? const <Map<String, dynamic>>[]
            : activeTasks.sublist(
                visibleStart,
                math.min(visibleStart + _taskPanelPageSize, activeTasks.length),
              );
        final canGoToPreviousPage = pageCount > 1 && currentPageIndex > 0;
        final canGoToNextPage =
            pageCount > 1 && currentPageIndex < pageCount - 1;
        final pageIndicatorLabel = '${currentPageIndex + 1}/$pageCount';

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: panelSize.width * 0.08,
              right: panelSize.width * 0.08,
              top: titleTop,
              height: titleHeight,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: titleIconBoxWidth,
                      height: titleHeight,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Image.asset(
                          TaskBoardReferenceAsset.pawLeft,
                          height: titleIconVisualHeight,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
                    SizedBox(width: titleIconGap),
                    Text(
                      '任务清单',
                      maxLines: 1,
                      style: TextStyle(
                        color: const Color(0xFF4A2014),
                        fontSize: panelSize.width * 0.071,
                        fontWeight: FontWeight.w900,
                        height: 1,
                        letterSpacing: 0,
                      ),
                    ),
                    SizedBox(width: titleIconGap),
                    SizedBox(
                      width: titleIconBoxWidth,
                      height: titleHeight,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Transform.flip(
                          flipX: true,
                          child: Image.asset(
                            TaskBoardReferenceAsset.pawLeft,
                            height: titleIconVisualHeight,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top:
                  boardTop - (closeButtonHitSize - closeButtonVisualSize) * 0.5,
              right: panelSize.width * 0.004,
              width: closeButtonHitSize,
              height: closeButtonHitSize,
              child: _buildTaskPanelCloseButton(
                visualSize: closeButtonVisualSize,
                onTap: _hideTaskPanel,
              ),
            ),
            for (var index = 0; index < visibleTasks.length; index++)
              Positioned(
                left: rowLeft,
                top: rowsTop + (index * (rowHeight + rowGap)),
                width: rowWidth,
                height: rowHeight,
                child: _buildTaskPanelTaskRow(
                  task: visibleTasks[index],
                  index: index,
                ),
              ),
            if (visibleTasks.isEmpty)
              Positioned(
                left: rowLeft,
                top: rowsTop + rowHeight + rowGap,
                width: rowWidth,
                height: rowHeight,
                child: _buildTaskPanelEmptyRow(),
              ),
            if (pageCount > 1)
              Positioned(
                left:
                    panelSize.width * 0.5 -
                    pageControlGap * 0.5 -
                    pageControlHitSize,
                top: pageControlsCenterY - (pageControlHitSize * 0.5),
                width: pageControlHitSize,
                height: pageControlHitSize,
                child: _buildTaskPanelPageControl(
                  active: currentPageIndex == 0,
                  enabled: canGoToPreviousPage,
                  visualSize: pageControlVisualSize,
                  semanticsLabel: '上一页',
                  onTap: _goToPreviousTaskPage,
                ),
              ),
            if (pageCount > 1)
              Positioned(
                left: panelSize.width * 0.5 - (pageIndicatorWidth * 0.5),
                top: pageControlsCenterY - (pageIndicatorHeight * 0.5),
                width: pageIndicatorWidth,
                height: pageIndicatorHeight,
                child: Center(
                  child: Text(
                    pageIndicatorLabel,
                    style: TextStyle(
                      color: const Color(0xFF5A4228),
                      fontSize: panelSize.width * 0.033,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            if (pageCount > 1)
              Positioned(
                left: panelSize.width * 0.5 + pageControlGap * 0.5,
                top: pageControlsCenterY - (pageControlHitSize * 0.5),
                width: pageControlHitSize,
                height: pageControlHitSize,
                child: _buildTaskPanelPageControl(
                  active: currentPageIndex == pageCount - 1,
                  enabled: canGoToNextPage,
                  visualSize: pageControlVisualSize,
                  semanticsLabel: '下一页',
                  onTap: _goToNextTaskPage,
                ),
              ),
            Positioned(
              bottom: addButtonBottom,
              left: (panelSize.width - addButtonWidth) * 0.5,
              width: addButtonWidth,
              height: addButtonHeight,
              child: _buildTaskPanelAddButton(onTap: _handleTaskAddTap),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTaskPanelCloseButton({
    required double visualSize,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: '\u5173\u95ed',
      child: Semantics(
        button: true,
        label: '\u5173\u95ed',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Center(
            child: SizedBox(
              width: visualSize,
              height: visualSize,
              child: Image.asset(
                _taskPanelCloseButtonAsset,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                isAntiAlias: true,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskPanelTaskRow({
    required Map<String, dynamic> task,
    required int index,
  }) {
    final taskTitle = _taskPanelTaskTitle(task);
    final completing = _taskPanelTaskCompleting(task);
    final completed = _taskPanelTaskCompleted(task) || completing;
    final checkboxPressKey = _taskPanelInteractionKey(
      task,
      index,
      area: 'checkbox',
    );
    final bodyPressKey = _taskPanelInteractionKey(task, index, area: 'body');
    final isCheckboxPressed = _isTaskPanelInteractionPressed(checkboxPressKey);
    final isBodyPressed = _isTaskPanelInteractionPressed(bodyPressKey);

    return TweenAnimationBuilder<double>(
      key: ValueKey<String>(
        'task-complete-${_asInt(task['id'], fallback: index)}-$completing',
      ),
      tween: Tween<double>(begin: 0, end: completing ? 1 : 0),
      duration: completing
          ? _taskCompletionFeedbackDuration
          : const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      builder: (context, completionProgress, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final rowSize = constraints.biggest;
            final starSize = rowSize.height * 0.40;
            final checkboxSize = rowSize.height * 0.62;
            final titleFontSize = rowSize.height * 0.30;
            final titleColor = const Color(
              0xFF4D3721,
            ).withValues(alpha: completed ? 0.56 : 1);
            final completionFade = Curves.easeOut.transform(
              completionProgress.clamp(0, 1).toDouble(),
            );
            final checkboxPop =
                1 + (math.sin(completionProgress * math.pi * 2.0) * 0.18);
            final flyProgress = Curves.easeInOutCubic.transform(
              completionProgress.clamp(0, 1).toDouble(),
            );
            final floatProgress = Curves.easeOutCubic.transform(
              completionProgress.clamp(0, 1).toDouble(),
            );
            final rowOpacity =
                (completed ? 0.86 : 1.0) *
                (1 - completionFade * 0.18) *
                (isBodyPressed ? 0.94 : 1.0);
            final checkboxOpacity = completed
                ? 0.92
                : (isCheckboxPressed ? 0.82 : 1.0);
            final pointsLabelWidth = math.max(
              42.0,
              math.min(rowSize.width * 0.13, 62.0),
            );
            final rowAsset = _taskPanelRowAssetForIndex(index);
            final starBaseRight = rowSize.width * 0.135 + pointsLabelWidth;
            final starTop = (rowSize.height - starSize) * 0.5;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 90),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.center,
                    scale: isBodyPressed ? 0.992 : 1,
                    child: Opacity(
                      opacity: rowOpacity,
                      child: Image.asset(
                        rowAsset,
                        fit: BoxFit.fill,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: rowSize.width * 0.050,
                  top: (rowSize.height - checkboxSize) * 0.5,
                  width: checkboxSize,
                  height: checkboxSize,
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 90),
                    curve: Curves.easeOutCubic,
                    offset: isCheckboxPressed
                        ? const Offset(0, 0.05)
                        : Offset.zero,
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 90),
                      curve: Curves.easeOutCubic,
                      scale: completing
                          ? checkboxPop
                          : (isCheckboxPressed ? 0.92 : 1),
                      child: Opacity(
                        opacity: checkboxOpacity,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              TaskBoardReferenceAsset.checkboxEmpty,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                            ),
                            if (completed)
                              Icon(
                                Icons.check_rounded,
                                color: const Color(
                                  0xFF6D8B35,
                                ).withValues(alpha: 0.92),
                                size: checkboxSize * 0.72,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: rowSize.width * 0.075,
                  right: rowSize.width * 0.170 + starSize + pointsLabelWidth,
                  top: 0,
                  bottom: 0,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      taskTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w900,
                        height: 1,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: starBaseRight,
                  top: starTop,
                  width: starSize,
                  height: starSize,
                  child: Opacity(
                    opacity: completed ? 0.58 : 1,
                    child: Image.asset(
                      TaskBoardReferenceAsset.rewardStar,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
                Positioned(
                  right: rowSize.width * 0.125,
                  top: 0,
                  bottom: 0,
                  child: _buildTaskPanelPointsText(
                    label: _taskPanelTaskPointsLabel(task),
                    width: pointsLabelWidth,
                    fontSize: rowSize.height * 0.30,
                    completed: completed,
                  ),
                ),
                if (completing) ...[
                  Positioned(
                    right:
                        starBaseRight +
                        (rowSize.width * 0.52 * flyProgress) -
                        (starSize * 0.20),
                    top:
                        starTop -
                        (rowSize.height * 1.05 * flyProgress) +
                        (math.sin(flyProgress * math.pi) *
                            rowSize.height *
                            0.20),
                    width: starSize * (1 + 0.20 * (1 - flyProgress)),
                    height: starSize * (1 + 0.20 * (1 - flyProgress)),
                    child: Opacity(
                      opacity: (1 - flyProgress).clamp(0, 1).toDouble(),
                      child: Image.asset(
                        TaskBoardReferenceAsset.rewardStar,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                  Positioned(
                    right: rowSize.width * 0.16,
                    top: rowSize.height * (0.08 - 0.62 * floatProgress),
                    child: Opacity(
                      opacity: (1 - floatProgress).clamp(0, 1).toDouble(),
                      child: Text(
                        '+${_asInt(task['points'], fallback: 10)}',
                        style: TextStyle(
                          color: const Color(0xFFFF8E32),
                          fontSize: rowSize.height * 0.36,
                          fontWeight: FontWeight.w900,
                          height: 1,
                          letterSpacing: 0,
                          shadows: const [
                            Shadow(
                              color: Color(0xAAFFFFFF),
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                Positioned(
                  right: 0,
                  top: 0,
                  width: rowSize.width * 0.14,
                  bottom: 0,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (_) =>
                        _setTaskPanelInteractionPressed(checkboxPressKey),
                    onTapCancel: () =>
                        _clearTaskPanelInteractionPressed(checkboxPressKey),
                    onTapUp: (_) => _clearTaskPanelInteractionPressed(
                      checkboxPressKey,
                      delayed: true,
                    ),
                    onTap: completing
                        ? null
                        : () => _completeTaskByLabel(taskTitle),
                    child: const SizedBox.expand(),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: rowSize.width * 0.13,
                  top: 0,
                  bottom: 0,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (_) =>
                        _setTaskPanelInteractionPressed(bodyPressKey),
                    onTapCancel: () =>
                        _clearTaskPanelInteractionPressed(bodyPressKey),
                    onTapUp: (_) => _clearTaskPanelInteractionPressed(
                      bodyPressKey,
                      delayed: true,
                    ),
                    onTap: completing
                        ? null
                        : () => _editTaskByLabel(taskTitle),
                    child: const SizedBox.expand(),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTaskPanelEmptyRow() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Opacity(
          opacity: 0.82,
          child: Image.asset(
            TaskBoardReferenceAsset.rowGreen,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.high,
          ),
        ),
        const Center(
          child: Text(
            '\u4eca\u5929\u8fd8\u6ca1\u6709\u4efb\u52a1',
            style: TextStyle(
              color: Color(0xFF7A624A),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskPanelPageControl({
    required bool active,
    required bool enabled,
    required double visualSize,
    required String semanticsLabel,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: Center(
          child: SizedBox.square(
            dimension: visualSize,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 120),
              opacity: active || enabled ? 1 : 0.48,
              child: Image.asset(
                active
                    ? TaskBoardReferenceAsset.paginationDotActive
                    : TaskBoardReferenceAsset.paginationDotInactive,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskPanelAddButton({required VoidCallback onTap}) {
    return _TaskPanelAddButton(onTap: onTap);
  }

  Widget _buildAnimatedTaskPanelOverlay(Size size) {
    final collapsedRect = _clampPanelRect(
      _taskPanelOriginRect ?? _defaultTaskPanelOriginRect(size),
      size,
    );
    final expandedRect = _expandedTaskPanelRect(size);
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _taskPanelController,
        child: RepaintBoundary(child: _buildTaskPanelExpandedContent()),
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
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(
                        sigmaX: 7 * backdropOpacity,
                        sigmaY: 7 * backdropOpacity,
                      ),
                      child: ColoredBox(
                        color: Color.lerp(
                          Colors.transparent,
                          PickStarPetDialogTheme.barrierTint,
                          backdropOpacity,
                        )!,
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
                  onHorizontalDragStart: _handleTaskPanelHorizontalDragStart,
                  onHorizontalDragUpdate: _handleTaskPanelHorizontalDragUpdate,
                  onHorizontalDragCancel: _handleTaskPanelHorizontalDragCancel,
                  onHorizontalDragEnd: (details) =>
                      _handleTaskPanelHorizontalDragEnd(
                        details,
                        panelRect.width,
                      ),
                  child: RepaintBoundary(
                    child: Transform.rotate(
                      angle: panelRotation,
                      child: Transform.scale(
                        scale: panelScale,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              ui.lerpDouble(
                                18,
                                PickStarPetDialogTheme.borderRadius.topLeft.x,
                                panelProgress,
                              )!,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: PickStarPetDialogTheme.shadow.withValues(
                                  alpha: panelShadowOpacity,
                                ),
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
                                  filterQuality: FilterQuality.high,
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
    if (_isReadOnlyAfterTrial) {
      _showReadOnlyPaywall();
      return;
    }

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
    if (_isReadOnlyAfterTrial) {
      _showReadOnlyPaywall();
      return;
    }

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
    if (!_canCompleteTasks) {
      _showReadOnlyPaywall();
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
    final taskPoints = _asInt(targetTask['points'], fallback: 10);

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

    final previousPets = List<Pet>.from(_pets);
    final reactionPetBefore = _petForOwner(previousPets, memberId);

    try {
      final dio = ref.read(apiClientProvider).dio;

      await dio.post(
        '/api/tasks/$taskId/completions',
        data: {'member_id': memberId},
      );

      if (mounted) {
        setState(() => _taskPanelCompletingTaskId = taskId);
      }

      await Future<void>.delayed(_taskCompletionFeedbackDuration);
      await _loadFamilyPets();

      if (!mounted) {
        return;
      }

      final reactionPetAfter = _petForOwner(_pets, memberId);
      final leveledUp =
          reactionPetBefore != null &&
          reactionPetAfter != null &&
          reactionPetAfter.level > reactionPetBefore.level;
      final fallbackPetId = reactionPetBefore?.id ?? reactionPetAfter?.id;
      final reactionMessage = leveledUp
          ? '升级啦！Lv.${reactionPetAfter.level}'
          : _taskCompletionMessageFor(taskPoints);

      await _loadHomeTasks();

      if (!mounted) {
        return;
      }

      setState(() => _taskPanelCompletingTaskId = null);
      if (_taskPanelVisible) {
        await _hideTaskPanel();
        if (!mounted) {
          return;
        }
      }

      _game.playPetCompletionReaction(
        petId: fallbackPetId,
        message: reactionMessage,
        points: taskPoints,
        leveledUp: leveledUp,
        level: reactionPetAfter?.level,
      );
      _showTopSnackBar('任务完成成功');
    } catch (error) {
      if (mounted && _taskPanelCompletingTaskId == taskId) {
        setState(() => _taskPanelCompletingTaskId = null);
      }
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

  Pet? _petForOwner(List<Pet> pets, int ownerId) {
    for (final pet in pets) {
      if (pet.ownerId == ownerId) {
        return pet;
      }
    }
    return null;
  }

  String _taskCompletionMessageFor(int points) {
    final messages = points >= 20
        ? const <String>['我长大一点啦', '今天又进步啦', '能量满满！', '谢谢你陪我成长', '我变强一点啦']
        : const <String>['谢谢你！', '好开心呀', '收到奖励啦', '任务完成啦', '今天也很棒', '我会继续加油'];

    return messages[_taskCompletionMessageRandom.nextInt(messages.length)];
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
    final options = members
        .map(
          (member) => PickStarPetSelectOption<int>(
            value: _asInt(member['id'], fallback: -1),
            label: _memberDisplayName(member),
          ),
        )
        .where((option) => option.value > 0)
        .toList();

    return showAppModalDialog<int>(
      context: context,
      barrierLabel: 'completion_member_dialog',
      blurSigma: 6,
      barrierTint: PickStarPetDialogTheme.barrierTint,
      beginScale: 0.95,
      beginYOffset: 16,
      pageBuilder: (dialogContext) {
        return _CompletionMemberSelectContent(
          initialMemberId: initialMemberId > 0 ? initialMemberId : null,
          options: options,
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

    final authState = ref.read(authProvider);
    final user = authState.user;

    if (_isReadOnlyAfterTrial) {
      _showReadOnlyPaywall();
      return;
    }

    if (user?.isAdmin != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '\u4ec5\u7ba1\u7406\u5458\u53ef\u65b0\u589e\u4efb\u52a1',
          ),
        ),
      );

      return;
    }

    if (user?.familyId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先创建家庭后再添加任务')));
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
      await _createTask(newTask);
    } catch (error) {
      if (mounted) {
        showFriendlyApiErrorSnackBar(
          context,

          error,

          fallbackMessage:
              '\u521b\u5efa\u4efb\u52a1\u5931\u8d25\uff0c\u8bf7\u7a0d\u540e\u91cd\u8bd5',
        );
      }
      return;
    }

    _game.addTaskItem(newTask.taskLabel, points: newTask.points);

    try {
      await _loadHomeTasks();
    } catch (error) {
      if (mounted) {
        showFriendlyApiErrorSnackBar(
          context,
          error,
          fallbackMessage:
              '\u4efb\u52a1\u5df2\u521b\u5efa\uff0c\u4f46\u5237\u65b0\u4efb\u52a1\u5217\u8868\u5931\u8d25',
        );
      }
    }
  }

  Future<void> _createTask(_TaskEditorResult task) async {
    if (_isReadOnlyAfterTrial) {
      throw StateError(_membershipRequiredMessage);
    }

    final dio = ref.read(apiClientProvider).dio;
    final familyId = ref.read(authProvider).user?.familyId;

    if (familyId == null) {
      throw StateError('请先创建家庭后再添加任务');
    }

    await dio.post(
      '/api/families/$familyId/tasks',
      data: _taskMutationPayload(task),
    );
  }

  Map<String, dynamic> _taskMutationPayload(_TaskEditorResult task) {
    return <String, dynamic>{'title': task.taskLabel, 'points': task.points};
  }

  Future<_TaskEditorResult?> _showTaskEditorDialog({
    required bool isEditing,

    String? initialTaskLabel,

    int? initialTaskPoints,
  }) {
    if (_isReadOnlyAfterTrial) {
      _showReadOnlyPaywall();
      return Future<_TaskEditorResult?>.value();
    }

    return showAppModalDialog<_TaskEditorResult>(
      context: context,
      barrierLabel: 'task_editor_dialog',
      blurSigma: 7,
      barrierTint: const Color(0x32674A30),
      transitionDuration: const Duration(milliseconds: 220),
      beginScale: 0.96,
      beginYOffset: 16,
      pageBuilder: (dialogContext) {
        return _TaskEditorSpriteDialog(
          isEditing: isEditing,
          initialTaskLabel: initialTaskLabel,
          initialTaskPoints: initialTaskPoints,
        );
      },
    );
  }

  Future<bool> _confirmDeleteTask(String taskLabel) async {
    if (_isReadOnlyAfterTrial) {
      _showReadOnlyPaywall();
      return false;
    }

    final result = await showAppModalDialog<bool>(
      context: context,
      barrierLabel: 'task_delete_confirm_dialog',
      blurSigma: 6,
      barrierTint: const Color(0x663C2A1D),
      transitionDuration: const Duration(milliseconds: 220),
      beginScale: 0.94,
      beginYOffset: 18,
      pageBuilder: (dialogContext) {
        return _TaskDeleteConfirmDialog(
          taskLabel: taskLabel,
          onCancel: () => Navigator.of(dialogContext).pop(false),
          onDelete: () => Navigator.of(dialogContext).pop(true),
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
    _refreshHomeGuideProgress();
  }

  void _syncGamePetsFromServer({bool forceGameRebuild = false}) {
    final sortedPets = List<Pet>.from(_pets)
      ..sort((left, right) {
        final ownerCompare = left.ownerId.compareTo(right.ownerId);
        if (ownerCompare != 0) {
          return ownerCompare;
        }
        final leftCreatedAt = left.createdAt;
        final rightCreatedAt = right.createdAt;
        if (leftCreatedAt != null && rightCreatedAt != null) {
          final createdAtCompare = rightCreatedAt.compareTo(leftCreatedAt);
          if (createdAtCompare != 0) {
            return createdAtCompare;
          }
        } else if (leftCreatedAt != null) {
          return -1;
        } else if (rightCreatedAt != null) {
          return 1;
        }
        return right.id.compareTo(left.id);
      });

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
          petType: _homePetTypeFor(pet),
          level: pet.level,
        ),
      );
    }

    _game.replacePetEntries(seeds, forceRebuild: forceGameRebuild);
    _refreshHomeGuideProgress();
  }

  String _homePetTypeFor(Pet pet) {
    final normalized = normalizePetType(pet.petType, fallback: '');
    if (normalized.isNotEmpty) {
      return normalized;
    }
    return switch (pet.petType.trim().toLowerCase()) {
      'panda' => 'cat',
      'bird' => 'rabbit',
      'fish' => 'turtle',
      _ => selectablePetTypes[pet.id % selectablePetTypes.length],
    };
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

  Future<void> _loadFamilyPets({bool forceSync = false}) async {
    final familyId = ref.read(authProvider).user?.familyId;

    if (familyId == null) {
      _pets = const <Pet>[];
      _syncGamePetsFromServer(forceGameRebuild: forceSync);
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

      final samePets = _samePickStarPet(_pets, pets);
      if (samePets && !forceSync) {
        return;
      }

      if (!samePets) {
        setState(() => _pets = pets);
      }
      _syncGamePetsFromServer(forceGameRebuild: forceSync);
    } catch (error, stackTrace) {
      debugPrint('Failed to load home scene pets: $error');
      debugPrint('$stackTrace');
    }
  }

  bool _samePickStarPet(List<Pet> left, List<Pet> right) {
    if (left.length != right.length) {
      return false;
    }

    final leftSorted = List<Pet>.from(left)
      ..sort((leftPet, rightPet) => leftPet.id.compareTo(rightPet.id));
    final rightSorted = List<Pet>.from(right)
      ..sort((leftPet, rightPet) => leftPet.id.compareTo(rightPet.id));

    for (var index = 0; index < leftSorted.length; index++) {
      final leftPet = leftSorted[index];
      final rightPet = rightSorted[index];
      if (leftPet.id != rightPet.id ||
          leftPet.name != rightPet.name ||
          leftPet.petType != rightPet.petType ||
          leftPet.ownerId != rightPet.ownerId ||
          leftPet.level != rightPet.level ||
          leftPet.experience != rightPet.experience ||
          leftPet.levelThreshold != rightPet.levelThreshold) {
        return false;
      }
    }

    return true;
  }

  Pet? _findPetById(int petId) {
    for (final pet in _pets) {
      if (pet.id == petId) {
        return pet;
      }
    }

    return null;
  }

  Future<void> _openPetDetail(int petId, String avatarAssetPath) async {
    final selectedPet = _findPetById(petId);

    if (selectedPet != null) {
      await _showPetDetailDialog(selectedPet, avatarAssetPath: avatarAssetPath);
      return;
    }

    await _loadFamilyPets();
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

    await _showPetDetailDialog(refreshedPet, avatarAssetPath: avatarAssetPath);
  }

  Future<void> _showPetDetailDialog(
    Pet pet, {
    required String avatarAssetPath,
  }) async {
    if (!mounted) {
      return;
    }

    await showPetDetailDialog(
      context,
      pet: pet,
      avatarAssetPath: avatarAssetPath,
    );
    if (mounted) {
      await _loadFamilyPets();
    }
  }

  void _showTopSnackBar(String message, {VoidCallback? onTap}) {
    _topSnackBarEntry?.remove();

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    final topPadding = MediaQuery.paddingOf(context).top;
    final entry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: topPadding + 14,
          left: 16,
          right: 16,
          child: SafeArea(
            bottom: false,
            child: _HomeTopNoticeCard(message: message, onTap: onTap),
          ),
        );
      },
    );

    _topSnackBarEntry = entry;
    overlay.insert(entry);
    Future<void>.delayed(_topSnackBarDuration, () {
      if (_topSnackBarEntry != entry) {
        return;
      }
      entry.remove();
      _topSnackBarEntry = null;
    });
  }

  @override
  void dispose() {
    _topSnackBarEntry?.remove();
    _topSnackBarEntry = null;
    _taskPanelController.dispose();
    _game.startExitAnimation();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(coreMutationBlockedProvider);

    ref.listen<String>(authProvider.select(_homeGuideAuthScopeSignature), (
      previous,
      next,
    ) {
      if (previous == next) {
        return;
      }

      if (mounted) {
        setState(() {
          _homeGuideLoading = true;
          _homeGuideProgress = null;
          _homeGuideCompletionPaywallQueued = false;
        });
      } else {
        _homeGuideLoading = true;
        _homeGuideProgress = null;
        _homeGuideCompletionPaywallQueued = false;
      }
      _initHomeGuide();
      _loadFamilyForHomeGuide();
      _loadFamilyPets();
      _loadHomeTasks();
    });

    ref.listen<String>(familyProvider.select(_homePetBindingSignature), (
      previous,
      next,
    ) {
      if (previous == next) {
        return;
      }

      _loadFamilyForHomeGuide();
      _loadFamilyPets(forceSync: true);
      _refreshHomeGuideProgress();
    });

    ref.listen<SubscriptionState>(subscriptionProvider, (previous, next) {
      if (previous?.isInitialized == next.isInitialized &&
          previous?.accessAllowed == next.accessAllowed &&
          previous?.paywallRequired == next.paywallRequired) {
        return;
      }
      _maybeShowHomeGuideCompletionPaywall();
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final guideStep = _homeGuideProgress?.currentStep;
        final shouldShowGuideOverlay = _shouldShowHomeGuideOverlay;
        _game.setHomeGuideStep(shouldShowGuideOverlay ? guideStep : null);
        _game.setHomeGuidePetFrozen(shouldShowGuideOverlay);
        _game.setHomeGuidePetsHidden(
          shouldShowGuideOverlay && guideStep == HomeGuideStep.familyFrame,
        );
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
              const _TrialStatusBanner(),
              if (_taskPanelVisible) _buildAnimatedTaskPanelOverlay(size),
              if (shouldShowGuideOverlay)
                Builder(
                  builder: (context) {
                    final anchorRect = _homeGuideAnchorRect(size);
                    final step = guideStep;
                    if (anchorRect == null ||
                        step == null ||
                        step == HomeGuideStep.done) {
                      return const SizedBox.shrink();
                    }
                    return HomeGuideOverlay(
                      step: step,
                      anchorRect: anchorRect,
                      screenSize: size,
                      targetAssetPath: _game.guideTargetAssetPath(step),
                      targetAssetCropRect: _game.guideTargetAssetCropRect(step),
                      onHotspotTap: () => _handleHomeGuideHotspotTap(step),
                      onSkip: _skipHomeGuide,
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TrialStatusBanner extends ConsumerWidget {
  const _TrialStatusBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionState = ref.watch(subscriptionProvider);
    final status = subscriptionState.status;
    final showExpired = ref.watch(coreMutationBlockedProvider);
    if (showExpired) {
      return Positioned(
        left: 16,
        right: 16,
        top: MediaQuery.paddingOf(context).top + 12,
        child: MembershipStatusBanner(onTap: () => showPaywallDialog(context)),
      );
    }

    // 推广阶段不展示「7 天免费体验」提示。
    if (ApiConstants.hideHomeFreeTrialBanner ||
        status == null ||
        !status.isTrialActive) {
      return const SizedBox.shrink();
    }
    final text = status.isTrialExpiring
        ? '试用期即将结束。订阅后可继续管理家庭任务和宠物成长。'
        : '7 天免费体验已开启，还剩 ${status.trialDaysRemaining} 天';

    return Positioned(
      left: 16,
      right: 16,
      top: MediaQuery.paddingOf(context).top + 12,
      child: IgnorePointer(
        child: Align(
          alignment: Alignment.topCenter,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xEEFFF7E7),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE5CFA3), width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1F604429),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF6B543B),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeTopNoticeCard extends StatelessWidget {
  const _HomeTopNoticeCard({required this.message, this.onTap});

  final String message;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (message == _membershipRequiredMessage) {
      return MembershipStatusBanner(onTap: onTap);
    }

    final content = DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF3A2B22).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );

    return Material(
      color: Colors.transparent,
      child: IgnorePointer(
        ignoring: onTap == null,
        child: Align(
          alignment: Alignment.topCenter,
          child: onTap == null
              ? content
              : InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: onTap,
                  child: content,
                ),
        ),
      ),
    );
  }
}

class _TaskPanelAddButton extends StatefulWidget {
  const _TaskPanelAddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_TaskPanelAddButton> createState() => _TaskPanelAddButtonState();
}

class _TaskPanelAddButtonState extends State<_TaskPanelAddButton> {
  static const Duration _feedbackHoldDuration = Duration(milliseconds: 110);

  bool _pressed = false;
  bool _tapPending = false;

  void _setPressed(bool pressed) {
    if (_pressed == pressed) {
      return;
    }
    setState(() => _pressed = pressed);
  }

  void _handleTap() {
    if (_tapPending) {
      return;
    }
    Feedback.forTap(context);
    setState(() {
      _pressed = true;
      _tapPending = true;
    });
    Future<void>.delayed(_feedbackHoldDuration, () {
      if (!mounted) {
        return;
      }
      setState(() {
        _pressed = false;
        _tapPending = false;
      });
      widget.onTap();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '\u6dfb\u52a0\u4efb\u52a1',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleTap,
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () {
          if (!_tapPending) {
            _setPressed(false);
          }
        },
        child: AnimatedScale(
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOutCubic,
          scale: _pressed ? 0.88 : 1,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 90),
            opacity: _pressed ? 0.76 : 1,
            child: Image.asset(
              TaskBoardReferenceAsset.addTaskButton,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskContextSpriteMenu extends StatelessWidget {
  const _TaskContextSpriteMenu({required this.anchorInOverlay});

  final Offset anchorInOverlay;

  static const double _menuWidth = 190;

  static const double _menuHeight = _menuWidth * (169 / 135);

  static const double _screenPadding = PickStarPetDialogGutter.small;

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
                      filterQuality: FilterQuality.high,
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
                Image.asset(
                  widget.assetPath,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.high,
                )
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

class _TaskDeleteConfirmDialog extends StatelessWidget {
  const _TaskDeleteConfirmDialog({
    required this.taskLabel,
    required this.onCancel,
    required this.onDelete,
  });

  final String taskLabel;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final panelSize = _taskMutationDialogSize(
      screenSize,
      horizontalGutter: PickStarPetDialogGutter.small,
    );

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(
        PickStarPetDialogGutter.small,
        24,
        PickStarPetDialogGutter.small,
        24,
      ),
      child: Center(
        child: Transform.translate(
          offset: Offset(
            _taskDialogVisibleCenterOffset(panelSize.width),
            screenSize.height * 0.025,
          ),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            child: Material(
              color: Colors.transparent,
              child: SizedBox(
                width: panelSize.width,
                height: panelSize.height,
                child: _TaskDeleteConfirmPanel(
                  taskLabel: taskLabel,
                  onCancel: onCancel,
                  onDelete: onDelete,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskDeleteConfirmPanel extends StatelessWidget {
  const _TaskDeleteConfirmPanel({
    required this.taskLabel,
    required this.onCancel,
    required this.onDelete,
  });

  final String taskLabel;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final panelSize = constraints.biggest;
        final width = panelSize.width;
        final height = panelSize.height;
        final messageFontSize = taskLabel.runes.length > 10
            ? width * 0.034
            : width * 0.039;
        final cancelButtonAspectRatio =
            _taskDeleteMemberCancelButtonRegion.width /
            _taskDeleteMemberCancelButtonRegion.height;
        final deleteButtonAspectRatio =
            _taskDeleteMemberConfirmButtonRegion.width /
            _taskDeleteMemberConfirmButtonRegion.height;
        final buttonGap = width * 0.035;
        final buttonMaxGroupWidth = width * 0.70;
        final buttonHeight = math.min(
          height * 0.112,
          (buttonMaxGroupWidth - buttonGap) /
              (cancelButtonAspectRatio + deleteButtonAspectRatio),
        );
        final cancelButtonWidth = buttonHeight * cancelButtonAspectRatio;
        final deleteButtonWidth = buttonHeight * deleteButtonAspectRatio;
        final buttonGroupWidth =
            cancelButtonWidth + buttonGap + deleteButtonWidth;
        final buttonLeft = (width - buttonGroupWidth) * 0.5;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: const _TaskDialogPanelBackground()),
            Positioned(
              top: height * 0.052,
              left: width * 0.5 - width * 0.086,
              width: width * 0.172,
              height: height * 0.185,
              child: Image.asset(
                _taskDeleteTrashAsset,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
            Positioned(
              top: height * 0.255,
              left: width * 0.5 - width * 0.205,
              width: width * 0.41,
              height: height * 0.116,
              child: Image.asset(
                _taskDeleteTitleAsset,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
            Positioned(
              top: height * 0.383,
              left: width * 0.06,
              right: width * 0.06,
              height: height * 0.105,
              child: Center(
                child: Text(
                  '确认删除任务「$taskLabel」吗？',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF4D3322),
                    fontSize: messageFontSize,
                    fontWeight: FontWeight.w800,
                    height: 1.14,
                  ),
                ),
              ),
            ),
            Positioned(
              top: height * 0.492,
              left: 0,
              right: 0,
              height: height * 0.065,
              child: Center(
                child: Text(
                  '删除后无法恢复',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF4D3322).withValues(alpha: 0.38),
                    fontFamily: 'PickStarPetFont',
                    fontSize: width * 0.038,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
            ),
            Positioned(
              top: height * 0.565,
              left: width * 0.31,
              width: width * 0.38,
              height: height * 0.19,
              child: FamilySpriteSlice(
                assetPath: _taskDeleteMemberButtonSpriteAsset,
                sheetSize: _taskDeleteMemberButtonSpriteSheetSize,
                region: _taskDeleteMemberIllustrationRegion,
                fit: BoxFit.contain,
                sampleInset: 0,
              ),
            ),
            Positioned(
              left: buttonLeft,
              bottom: height * 0.074,
              width: cancelButtonWidth,
              height: buttonHeight,
              child: _TaskDeleteActionButton(
                semanticLabel: '取消',
                region: _taskDeleteMemberCancelButtonRegion,
                onPressed: onCancel,
              ),
            ),
            Positioned(
              left: buttonLeft + cancelButtonWidth + buttonGap,
              bottom: height * 0.074,
              width: deleteButtonWidth,
              height: buttonHeight,
              child: _TaskDeleteActionButton(
                semanticLabel: '删除',
                region: _taskDeleteMemberConfirmButtonRegion,
                onPressed: onDelete,
              ),
            ),
            Positioned(
              top: 0,
              right: width * 0.005,
              width: width * 0.124,
              height: width * 0.124,
              child: _TaskDialogCloseButton(onPressed: onCancel),
            ),
          ],
        );
      },
    );
  }
}

class _TaskDeleteActionButton extends StatefulWidget {
  const _TaskDeleteActionButton({
    required this.semanticLabel,
    required this.region,
    required this.onPressed,
  });

  final String semanticLabel;
  final Rect region;
  final VoidCallback onPressed;

  @override
  State<_TaskDeleteActionButton> createState() =>
      _TaskDeleteActionButtonState();
}

class _TaskDeleteActionButtonState extends State<_TaskDeleteActionButton> {
  bool _pressed = false;

  void _setPressed(bool pressed) {
    if (_pressed == pressed) {
      return;
    }
    setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onPressed,
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOutCubic,
          scale: _pressed ? 0.97 : 1,
          child: FamilySpriteSlice(
            assetPath: _taskDeleteMemberButtonSpriteAsset,
            sheetSize: _taskDeleteMemberButtonSpriteSheetSize,
            region: widget.region,
            fit: BoxFit.contain,
            sampleInset: 0,
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

class _CompletionMemberSelectContent extends StatefulWidget {
  const _CompletionMemberSelectContent({
    required this.initialMemberId,
    required this.options,
  });

  final int? initialMemberId;
  final List<PickStarPetSelectOption<int>> options;

  @override
  State<_CompletionMemberSelectContent> createState() =>
      _CompletionMemberSelectContentState();
}

class _CompletionMemberSelectContentState
    extends State<_CompletionMemberSelectContent> {
  late int? _selectedMemberId;
  late final Future<SpriteAtlas> _spriteAtlasFuture;

  @override
  void initState() {
    super.initState();
    _spriteAtlasFuture = TaskEditorSheetSpriteCatalog.atlasAsset.load();
    _selectedMemberId =
        widget.options.any((option) => option.value == widget.initialMemberId)
        ? widget.initialMemberId
        : widget.options.isEmpty
        ? null
        : widget.options.first.value;
  }

  PickStarPetSelectOption<int>? get _selectedOption {
    for (final option in widget.options) {
      if (option.value == _selectedMemberId) {
        return option;
      }
    }
    return widget.options.isEmpty ? null : widget.options.first;
  }

  void _selectMember(int value) {
    if (_selectedMemberId == value) {
      return;
    }
    setState(() => _selectedMemberId = value);
  }

  void _confirm() {
    final selectedMemberId = _selectedMemberId;
    if (selectedMemberId == null) {
      return;
    }
    Navigator.of(context).pop(selectedMemberId);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final panelSize = _taskMutationDialogSize(screenSize);
    final buttonGap = _completeMemberDialogDesignSize.width * 0.035;
    final buttonMaxGroupWidth = _completeMemberDialogDesignSize.width * 0.70;

    return SafeArea(
      minimum: PickStarPetDialogGutter.mediumInsets,
      child: Center(
        child: Transform.translate(
          offset: Offset(_taskDialogVisibleCenterOffset(panelSize.width), 0),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            child: Material(
              color: Colors.transparent,
              child: SizedBox(
                width: panelSize.width,
                height: panelSize.height,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Positioned.fill(child: _TaskDialogPanelBackground()),
                    Positioned.fill(
                      child: FittedBox(
                        fit: BoxFit.fill,
                        child: FutureBuilder<SpriteAtlas>(
                          future: _spriteAtlasFuture,
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return SizedBox(
                                width: _completeMemberDialogDesignSize.width,
                                height: _completeMemberDialogDesignSize.height,
                              );
                            }

                            final sprites = TaskEditorSheetSpriteCatalog(
                              snapshot.requireData,
                            );
                            final cancelButtonAspectRatio =
                                sprites.cancelButtonBg.aspectRatio;
                            final confirmButtonAspectRatio =
                                sprites.saveButtonBg.aspectRatio;
                            final buttonHeight = math.min(
                              _completeMemberDialogDesignSize.height * 0.112,
                              (buttonMaxGroupWidth - buttonGap) /
                                  (cancelButtonAspectRatio +
                                      confirmButtonAspectRatio),
                            );
                            final cancelButtonWidth =
                                buttonHeight * cancelButtonAspectRatio;
                            final confirmButtonWidth =
                                buttonHeight * confirmButtonAspectRatio;
                            final buttonGroupWidth =
                                cancelButtonWidth +
                                buttonGap +
                                confirmButtonWidth;
                            final buttonGroupLeft =
                                (_completeMemberDialogDesignSize.width -
                                    buttonGroupWidth) *
                                0.5;

                            return SizedBox(
                              width: _completeMemberDialogDesignSize.width,
                              height: _completeMemberDialogDesignSize.height,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  const Positioned(
                                    left: 42,
                                    top: 52,
                                    width: 352,
                                    height: 47,
                                    child: Align(
                                      alignment: Alignment.center,
                                      child: Text(
                                        '选择完成人员',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Color(0xFF4D3623),
                                          fontSize:
                                              _completeMemberTitleFontSize,
                                          fontWeight: FontWeight.w900,
                                          height: 1,
                                          letterSpacing: 0,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Positioned(
                                    left: 74,
                                    top: 126,
                                    width: 132,
                                    height: 30,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        '完成成员',
                                        maxLines: 1,
                                        style: TextStyle(
                                          color: Color(0xFF4D3623),
                                          fontSize:
                                              _completeMemberLabelFontSize,
                                          fontWeight: FontWeight.w900,
                                          height: 1,
                                          letterSpacing: 0,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: 74,
                                    top: 158,
                                    width: 288,
                                    height: _completeMemberFieldHeight,
                                    child: _CompleteMemberClosedField(
                                      label: _selectedOption?.label ?? '',
                                    ),
                                  ),
                                  Positioned(
                                    left: 74,
                                    top: 214,
                                    width: 288,
                                    height: 193,
                                    child: _CompleteMemberOptionsList(
                                      options: widget.options,
                                      selectedMemberId: _selectedMemberId,
                                      onSelected: _selectMember,
                                    ),
                                  ),
                                  Positioned(
                                    left: buttonGroupLeft,
                                    bottom:
                                        _completeMemberDialogDesignSize.height *
                                        0.075,
                                    width: cancelButtonWidth,
                                    height: buttonHeight,
                                    child: _TaskEditorSpriteImageButton(
                                      sprites: sprites,
                                      backgroundFrame: sprites.cancelButtonBg,
                                      fallbackText: '取消',
                                      semanticsLabel: '取消',
                                      onTap: () => Navigator.of(context).pop(),
                                    ),
                                  ),
                                  Positioned(
                                    left:
                                        buttonGroupLeft +
                                        cancelButtonWidth +
                                        buttonGap,
                                    bottom:
                                        _completeMemberDialogDesignSize.height *
                                        0.075,
                                    width: confirmButtonWidth,
                                    height: buttonHeight,
                                    child: Opacity(
                                      opacity: _selectedMemberId == null
                                          ? 0.55
                                          : 1,
                                      child: _TaskEditorSpriteImageButton(
                                        sprites: sprites,
                                        backgroundFrame: sprites.saveButtonBg,
                                        fallbackText: '确认完成',
                                        semanticsLabel: '确认完成',
                                        onTap: _selectedMemberId == null
                                            ? () {}
                                            : _confirm,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right:
                                        _completeMemberDialogDesignSize.width *
                                        0.005,
                                    width:
                                        _completeMemberDialogDesignSize.width *
                                        0.124,
                                    height:
                                        _completeMemberDialogDesignSize.width *
                                        0.124,
                                    child: _TaskDialogCloseButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                    ),
                                  ),
                                ],
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
    );
  }
}

class _CompleteMemberAssetImage extends StatelessWidget {
  const _CompleteMemberAssetImage({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}

class _CompleteMemberClosedField extends StatelessWidget {
  const _CompleteMemberClosedField({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _completeMemberFieldFillColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x295E3A20),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _completeMemberFieldBorderColor, width: 3),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            left: 30,
            top: 5,
            right: 74,
            bottom: 5,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF4D3623),
                  fontSize: _completeMemberFieldFontSize,
                  fontWeight: FontWeight.w900,
                  height: 1,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
          const Positioned(
            right: 27,
            top: 22,
            width: 34,
            height: 22,
            child: _CompleteMemberAssetImage(
              assetPath: _completeMemberDropdownArrowAsset,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompleteMemberOptionsList extends StatelessWidget {
  const _CompleteMemberOptionsList({
    required this.options,
    required this.selectedMemberId,
    required this.onSelected,
  });

  final List<PickStarPetSelectOption<int>> options;
  final int? selectedMemberId;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _completeMemberMenuFillColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F5E3A20),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _completeMemberFieldBorderColor, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Scrollbar(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            physics: const ClampingScrollPhysics(),
            itemExtent: _completeMemberOptionExtent,
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options[index];
              return _CompleteMemberOptionRow(
                option: option,
                selected: option.value == selectedMemberId,
                onSelected: onSelected,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CompleteMemberOptionRow extends StatelessWidget {
  const _CompleteMemberOptionRow({
    required this.option,
    required this.selected,
    required this.onSelected,
  });

  final PickStarPetSelectOption<int> option;
  final bool selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 55,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onSelected(option.value),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: selected
                        ? _completeMemberOptionSelectedColor
                        : _completeMemberOptionFillColor,
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 22,
              top: 5,
              right: selected ? 62 : 22,
              bottom: 5,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  option.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF4D3623),
                    fontSize: _completeMemberOptionFontSize,
                    fontWeight: FontWeight.w900,
                    height: 1,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),
            if (selected)
              const Positioned(
                right: 17,
                top: 13,
                width: 34,
                height: 32,
                child: _CompleteMemberAssetImage(
                  assetPath: _completeMemberCheckmarkAsset,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TaskDialogPanelBackground extends StatelessWidget {
  const _TaskDialogPanelBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          _taskDialogPanelBackgroundAsset,
          fit: BoxFit.fill,
          filterQuality: FilterQuality.high,
        ),
        const Positioned.fill(
          child: IgnorePointer(
            child: SourceScaledRRectBorder(
              sourceSize: Size(1149, 1369),
              sourceRect: Rect.fromLTRB(48, 43, 1098, 1315),
              sourceRadius: Radius.elliptical(58, 64),
              color: _taskDialogOuterBorderColor,
              strokeWidth: 2.4,
            ),
          ),
        ),
      ],
    );
  }
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
  late final Future<SpriteAtlas> _spriteAtlasFuture;
  String? _validationMessage;

  @override
  void initState() {
    super.initState();
    _spriteAtlasFuture = TaskEditorSheetSpriteCatalog.atlasAsset.load();
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
    final panelSize = _taskMutationDialogSize(screenSize);

    return SafeArea(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(bottom: viewInsets.bottom * 0.72),
        child: Center(
          child: Transform.translate(
            offset: Offset(_taskDialogVisibleCenterOffset(panelSize.width), 0),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => FocusScope.of(context).unfocus(),
              child: Material(
                color: Colors.transparent,
                child: SizedBox(
                  width: panelSize.width,
                  height: panelSize.height,
                  child: FutureBuilder<SpriteAtlas>(
                    future: _spriteAtlasFuture,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const SizedBox.shrink();
                      }

                      final sprites = TaskEditorSheetSpriteCatalog(
                        snapshot.requireData,
                      );
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: _TaskEditorSpriteCard(
                              sprites: sprites,
                              isEditing: widget.isEditing,
                              validationMessage: _validationMessage,
                              taskNameController: _taskNameController,
                              taskPointsController: _taskPointsController,
                              onSave: _save,
                              onDelete: _requestDelete,
                              onCancel: () => Navigator.of(context).pop(),
                              bottomInset: viewInsets.bottom > 0 ? 8 : 0,
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: panelSize.width * 0.005,
                            width: panelSize.width * 0.124,
                            height: panelSize.width * 0.124,
                            child: _TaskDialogCloseButton(
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskDialogCloseButton extends StatelessWidget {
  const _TaskDialogCloseButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '关闭',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Image.asset(
          _sharedCloseButtonAsset,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}

class _InsetSampledAssetImage extends StatelessWidget {
  const _InsetSampledAssetImage({
    required this.assetPath,
    required this.sampleInset,
  });

  final String assetPath;
  final double sampleInset;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        if (width <= 0 || height <= 0 || sampleInset <= 0) {
          return Image.asset(
            assetPath,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.high,
          );
        }

        final sampleWidth = width - (sampleInset * 2);
        final sampleHeight = height - (sampleInset * 2);
        if (sampleWidth <= 0 || sampleHeight <= 0) {
          return Image.asset(
            assetPath,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.high,
          );
        }

        final scaleX = width / sampleWidth;
        final scaleY = height / sampleHeight;

        return ClipRect(
          child: Transform.scale(
            scaleX: scaleX,
            scaleY: scaleY,
            child: Image.asset(
              assetPath,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.high,
            ),
          ),
        );
      },
    );
  }
}

class _TaskEditorSpriteCard extends StatelessWidget {
  const _TaskEditorSpriteCard({
    required this.sprites,
    required this.isEditing,
    required this.validationMessage,
    required this.taskNameController,
    required this.taskPointsController,
    required this.onSave,
    required this.onDelete,
    required this.onCancel,
    required this.bottomInset,
  });

  final TaskEditorSheetSpriteCatalog sprites;
  final bool isEditing;
  final String? validationMessage;
  final TextEditingController taskNameController;
  final TextEditingController taskPointsController;
  final VoidCallback onSave;
  final VoidCallback onDelete;
  final VoidCallback onCancel;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final panelSize = constraints.biggest;
        final titleWidth = panelSize.width * 0.40;
        final fieldWidth = panelSize.width * 0.80;
        final fieldHeight = panelSize.height * 0.128;
        final fieldLeft = (panelSize.width - fieldWidth) * 0.5;
        final buttonBottom =
            panelSize.height * (bottomInset > 0 ? 0.052 : 0.075);
        final buttonGap = panelSize.width * 0.035;
        final buttonMaxGroupWidth = panelSize.width * 0.70;
        final cancelButtonAspectRatio = sprites.cancelButtonBg.aspectRatio;
        final saveButtonAspectRatio = sprites.saveButtonBg.aspectRatio;
        final buttonHeight = math.min(
          panelSize.height * 0.112,
          (buttonMaxGroupWidth - buttonGap) /
              (cancelButtonAspectRatio + saveButtonAspectRatio),
        );
        final cancelButtonWidth = buttonHeight * cancelButtonAspectRatio;
        final saveButtonWidth = buttonHeight * saveButtonAspectRatio;
        final buttonGroupWidth =
            cancelButtonWidth + buttonGap + saveButtonWidth;
        final buttonGroupLeft = (panelSize.width - buttonGroupWidth) * 0.5;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: const _TaskDialogPanelBackground()),
            Positioned(
              top: panelSize.height * 0.095,
              left: (panelSize.width - titleWidth) * 0.5,
              width: titleWidth,
              height: titleWidth / sprites.titleEditTask.aspectRatio,
              child: Center(
                child: Text(
                  isEditing
                      ? '\u7f16\u8f91\u4efb\u52a1'
                      : '\u6dfb\u52a0\u4efb\u52a1',
                  style: TextStyle(
                    color: const Color(0xFF4D3623),
                    fontSize: panelSize.width * 0.075,
                    fontWeight: FontWeight.w900,
                    height: 1,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),
            Positioned(
              top: panelSize.height * 0.238,
              left: fieldLeft,
              width: panelSize.width * 0.168,
              height:
                  panelSize.width * 0.18 / sprites.labelTaskName.aspectRatio,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '\u4efb\u52a1\u540d',
                  style: TextStyle(
                    color: const Color(0xFF4D3623),
                    fontSize: panelSize.width * 0.048,
                    fontWeight: FontWeight.w900,
                    height: 1,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),
            Positioned(
              top: panelSize.height * 0.313,
              left: fieldLeft,
              width: fieldWidth,
              height: fieldHeight,
              child: _TaskEditorSpriteField(
                controller: taskNameController,
                hintText: '\u6574\u7406\u73a9\u5177',
                maxLength: _taskTitleMaxLength,
                textInputAction: TextInputAction.next,
              ),
            ),
            Positioned(
              top: panelSize.height * 0.457,
              left: fieldLeft,
              width: panelSize.width * 0.373,
              height:
                  panelSize.width *
                  0.38 /
                  sprites.labelRewardPoints.aspectRatio,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '\u5b8c\u6210\u53ef\u83b7\u5f97\u79ef\u5206',
                  style: TextStyle(
                    color: const Color(0xFF4D3623),
                    fontSize: panelSize.width * 0.046,
                    fontWeight: FontWeight.w900,
                    height: 1,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),
            Positioned(
              top: panelSize.height * 0.545,
              left: fieldLeft,
              width: fieldWidth,
              height: fieldHeight,
              child: _TaskEditorSpriteField(
                controller: taskPointsController,
                hintText: '10',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.done,
              ),
            ),
            if (validationMessage != null)
              Positioned(
                top: panelSize.height * 0.675,
                left: panelSize.width * 0.10,
                right: panelSize.width * 0.10,
                child: Text(
                  validationMessage!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFFB85F54),
                    fontSize: panelSize.width * 0.035,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            if (isEditing)
              Positioned(
                top: panelSize.height * 0.690,
                left: panelSize.width * 0.28,
                width: panelSize.width * 0.44,
                height: panelSize.height * 0.085,
                child: _TaskEditorDeleteSpriteButton(onTap: onDelete),
              ),
            Positioned(
              bottom: buttonBottom,
              left: buttonGroupLeft,
              width: cancelButtonWidth,
              height: buttonHeight,
              child: _TaskEditorSpriteImageButton(
                sprites: sprites,
                backgroundFrame: sprites.cancelButtonBg,
                fallbackText: '\u53d6\u6d88',
                semanticsLabel: '\u53d6\u6d88',
                onTap: onCancel,
              ),
            ),
            Positioned(
              bottom: buttonBottom,
              left: buttonGroupLeft + cancelButtonWidth + buttonGap,
              width: saveButtonWidth,
              height: buttonHeight,
              child: _TaskEditorSpriteImageButton(
                sprites: sprites,
                backgroundFrame: sprites.saveButtonBg,
                fallbackText: isEditing
                    ? '\u4fdd\u5b58\u4fee\u6539'
                    : '\u521b\u5efa\u4efb\u52a1',
                semanticsLabel: isEditing
                    ? '\u4fdd\u5b58\u4fee\u6539'
                    : '\u521b\u5efa\u4efb\u52a1',
                onTap: onSave,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TaskEditorSpriteField extends StatelessWidget {
  const _TaskEditorSpriteField({
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.inputFormatters,
    this.maxLength,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fieldHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 48.0;
        final dense = fieldHeight < 54;
        final borderRadius = BorderRadius.circular(18);
        final horizontalPadding = dense ? 15.0 : 17.0;
        final verticalPadding = dense ? 10.0 : 14.0;
        final border = OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: const BorderSide(
            color: _taskEditorFieldLineColor,
            width: 1.6,
          ),
        );

        return TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLength: maxLength,
          textInputAction: textInputAction,
          cursorColor: const Color(0xFF2F2218),
          maxLines: 1,
          style: const TextStyle(
            color: _taskEditorFieldInkColor,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: _taskEditorFieldHintColor,
              fontSize: dense ? 15 : 16,
              fontWeight: FontWeight.w900,
            ),
            counterText: '',
            isDense: true,
            filled: true,
            fillColor: _taskEditorFieldFillColor,
            contentPadding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            border: border,
            enabledBorder: border,
            focusedBorder: border.copyWith(
              borderSide: const BorderSide(
                color: _taskEditorFieldInkColor,
                width: 1.8,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TaskEditorSpriteImageButton extends StatefulWidget {
  const _TaskEditorSpriteImageButton({
    required this.sprites,
    required this.backgroundFrame,
    required this.semanticsLabel,
    required this.onTap,
    this.fallbackText,
  });

  final TaskEditorSheetSpriteCatalog sprites;
  final SpriteAtlasFrame backgroundFrame;
  final String? fallbackText;
  final String semanticsLabel;
  final VoidCallback onTap;

  @override
  State<_TaskEditorSpriteImageButton> createState() =>
      _TaskEditorSpriteImageButtonState();
}

class _TaskEditorSpriteImageButtonState
    extends State<_TaskEditorSpriteImageButton> {
  bool _pressed = false;

  void _setPressed(bool pressed) {
    if (_pressed == pressed) {
      return;
    }
    setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticsLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOutCubic,
          scale: _pressed ? 0.985 : 1,
          child: Stack(
            fit: StackFit.expand,
            children: [
              SpriteFrameImage(
                imageAsset: widget.sprites.imageAsset,
                sheetSize: widget.sprites.sheetSize,
                frame: widget.backgroundFrame,
                fit: BoxFit.fill,
              ),
              if (widget.fallbackText != null)
                Center(
                  child: Text(
                    widget.fallbackText!,
                    style: const TextStyle(
                      color: Color(0xFF4D3623),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      height: 1,
                      letterSpacing: 0,
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

class _TaskEditorDeleteSpriteButton extends StatelessWidget {
  const _TaskEditorDeleteSpriteButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '\u5220\u9664\u4efb\u52a1',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 34,
              height: 40,
              child: Image.asset(
                _taskDeleteTrashAsset,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              '\u5220\u9664\u4efb\u52a1',
              style: TextStyle(
                color: Color(0xFFC85445),
                fontSize: 22,
                fontWeight: FontWeight.w900,
                height: 1,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _TaskEditorCard extends StatelessWidget {
  const _TaskEditorCard({
    required this.isEditing,
    required this.validationMessage,
    required this.taskNameController,
    required this.taskPointsController,
    required this.onSave,
    required this.onDelete,
    required this.onCancel,
    required this.bottomInset,
  });

  final bool isEditing;
  final String? validationMessage;
  final TextEditingController taskNameController;
  final TextEditingController taskPointsController;
  final VoidCallback onSave;
  final VoidCallback onDelete;
  final VoidCallback onCancel;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _SoftPanelBorderPainter(),
      child: ClipPath(
        clipper: _SoftPanelClipper(),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF7E9CF), Color(0xFFEBD6B2)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3A2514).withValues(alpha: 0.18),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(22, 32, 22, 22 + bottomInset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _TaskEditorTitle(isEditing: isEditing),
                const SizedBox(height: 18),
                _TaskEditorField(
                  label: '任务名',
                  controller: taskNameController,
                  hintText: '整理玩具',
                  maxLength: _taskTitleMaxLength,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                _TaskEditorField(
                  label: '完成可获得积分',
                  controller: taskPointsController,
                  hintText: '10',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textInputAction: TextInputAction.done,
                ),
                if (validationMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    validationMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFB85F54),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
                if (isEditing) ...[
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: onDelete,
                    label: const Text('删除任务'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFB85F54),
                      textStyle: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ] else
                  const SizedBox(height: 14),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onCancel,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF5A3A21),
                          side: const BorderSide(
                            color: Color(0xFF6B4B32),
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        child: const Text('取消'),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: FilledButton(
                        onPressed: onSave,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFE39B55),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          textStyle: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        child: Text(isEditing ? '保存修改' : '创建任务'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShopConfirmActionButton extends StatefulWidget {
  const _ShopConfirmActionButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  State<_ShopConfirmActionButton> createState() =>
      _ShopConfirmActionButtonState();
}

class _ShopConfirmActionButtonState extends State<_ShopConfirmActionButton> {
  static const double _buttonHeight = 58;
  static const double _buttonWidth = 196;

  bool _pressed = false;

  void _setPressed(bool pressed) {
    if (_pressed == pressed) {
      return;
    }
    setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : _buttonWidth;
        final buttonWidth = math.min(_buttonWidth, availableWidth);

        return SizedBox(
          width: availableWidth,
          child: Center(
            child: SizedBox(
              width: buttonWidth,
              height: _buttonHeight,
              child: Semantics(
                button: true,
                label: widget.label,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onPressed,
                  onTapDown: (_) => _setPressed(true),
                  onTapCancel: () => _setPressed(false),
                  onTapUp: (_) => _setPressed(false),
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 90),
                    curve: Curves.easeOutCubic,
                    scale: _pressed ? 0.985 : 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB65A),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: const Color(0xFFA8642E),
                          width: 2.2,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33604429),
                            blurRadius: 13,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          widget.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF4D3623),
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                            height: 1,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SoftPanelBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = _SoftPanelClipper().getClip(size);
    final shadowPaint = Paint()
      ..color = const Color(0x333A2514)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    final borderPaint = Paint()
      ..color = const Color(0xFF6B4B32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path.shift(const Offset(0, 2)), shadowPaint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TaskEditorTitle extends StatelessWidget {
  const _TaskEditorTitle({required this.isEditing});

  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          isEditing ? '编辑任务' : '添加任务',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF4D3623),
            fontSize: 25,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _SoftPanelClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(size.width * 0.08, size.height * 0.02)
      ..cubicTo(
        size.width * 0.22,
        0,
        size.width * 0.72,
        0.03,
        size.width * 0.92,
        size.height * 0.02,
      )
      ..cubicTo(
        size.width,
        size.height * 0.04,
        size.width * 0.98,
        size.height * 0.24,
        size.width * 0.99,
        size.height * 0.50,
      )
      ..cubicTo(
        size.width,
        size.height * 0.78,
        size.width,
        size.height * 0.96,
        size.width * 0.92,
        size.height * 0.98,
      )
      ..cubicTo(
        size.width * 0.70,
        size.height,
        size.width * 0.24,
        size.height * 0.97,
        size.width * 0.08,
        size.height * 0.98,
      )
      ..cubicTo(
        0,
        size.height * 0.94,
        size.width * 0.01,
        size.height * 0.72,
        size.width * 0.02,
        size.height * 0.48,
      )
      ..cubicTo(
        size.width * 0.01,
        size.height * 0.22,
        0,
        size.height * 0.05,
        size.width * 0.08,
        size.height * 0.02,
      )
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
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
    return Container(
      height: 82,
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF2E1C2).withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF7A5A3D), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFA37A4F),
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          TextField(
            controller: controller,

            keyboardType: keyboardType,

            inputFormatters: inputFormatters,

            maxLength: maxLength,

            textInputAction: textInputAction,

            cursorColor: const Color(0xFF2F2218),

            style: const TextStyle(
              color: Color(0xFF4E3A27),

              fontWeight: FontWeight.w900,

              fontSize: 18,
            ),

            decoration: InputDecoration(
              hintText: hintText,

              hintStyle: const TextStyle(
                color: Color(0xA36F563D),
                fontSize: 15,
              ),

              counterText: '',

              border: InputBorder.none,

              isCollapsed: true,

              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}
