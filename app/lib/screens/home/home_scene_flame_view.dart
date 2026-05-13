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
import '../../providers/family_provider.dart';
import '../../widgets/app_modal_shell.dart';
import '../../widgets/homepets_button.dart';
import '../../widgets/homepets_dialog.dart';
import '../../widgets/homepets_select_field.dart';

import '../family/family_screen.dart';
import '../family/widgets/family_sprite_slice.dart';
import '../paywall/paywall_screen.dart';
import '../pet/pet_detail_screen.dart';
import 'game/home_scene_game.dart';
import 'settings_dialog.dart';
import 'task_panel_sprite_catalog.dart';

enum _TaskPanelRowAction { edit, delete, complete }

class _ProfileEditResult {
  const _ProfileEditResult({required this.nickname, required this.familyName});

  final String nickname;
  final String? familyName;
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
const String _taskDeleteTrashAsset = 'assets/images/ui/task_delete/trash.png';
const String _taskDeleteTitleAsset =
    'assets/images/ui/task_delete/title_text.png';
const String _taskDeleteWarningAsset =
    'assets/images/ui/task_delete/restore_warning_text.png';
const String _taskDeleteNoteAsset = 'assets/images/ui/task_delete/note.png';
const String _taskDeleteCatAsset = 'assets/images/ui/task_delete/cat_head.png';
const String _taskDeleteCancelButtonAsset =
    'assets/images/ui/task_delete/cancel_button.png';
const String _taskDeleteCancelButtonPressedAsset =
    'assets/images/ui/task_delete/cancel_button_pressed.png';
const String _taskDeleteButtonAsset =
    'assets/images/ui/task_delete/delete_button.png';
const String _taskDeleteButtonPressedAsset =
    'assets/images/ui/task_delete/delete_button_pressed.png';
const String _taskDialogPanelBackgroundAsset = 'assets/images/ui/task/33.png';
const String _completeMemberDialogAssetRoot =
    'assets/images/ui/sprites/complete_member_dialog_parts';
const Size _completeMemberDialogDesignSize = Size(436, 502);
const String _completeMemberDialogPanelAsset =
    '$_completeMemberDialogAssetRoot/complete_member_dialog_panel_blank_large.png';
const String _completeMemberDialogShadowAsset =
    '$_completeMemberDialogAssetRoot/complete_member_dialog_shadow_large.png';
const String _completeMemberHeaderIconAsset =
    '$_completeMemberDialogAssetRoot/complete_member_header_icon_clipboard_star_left.png';
const String _completeMemberDropdownArrowAsset =
    '$_completeMemberDialogAssetRoot/complete_member_chevron_down_standalone.png';
const String _completeMemberCheckmarkAsset =
    '$_completeMemberDialogAssetRoot/complete_member_checkmark_white_right.png';
const String _completeMemberConfirmButtonAsset =
    '$_completeMemberDialogAssetRoot/complete_member_confirm_complete_button_bottom.png';
const Color _completeMemberFieldFillColor = Color(0xFFFFFCF4);
const Color _completeMemberFieldBorderColor = Color(0xFF76563E);
const Color _completeMemberMenuFillColor = Color(0xFFFFF4E5);
const Color _completeMemberOptionFillColor = Color(0xFFFBE3BD);
const Color _completeMemberOptionSelectedColor = Color(0xFFD7E09A);
const double _taskMutationDialogWidthFactor = 0.86;
const double _taskMutationDialogMaxWidth = 390;
const double _taskMutationDialogHeightFactor = 0.76;
const double _taskPanelBoardHeightRatio =
    TaskBoardReferenceAsset.panelHeightRatio;
const Duration _taskPanelTransitionDuration = Duration(milliseconds: 320);

Size _taskMutationDialogSize(Size screenSize) {
  final maxPanelWidth = math.min(
    screenSize.width * _taskMutationDialogWidthFactor,
    _taskMutationDialogMaxWidth,
  );
  final maxPanelHeight = screenSize.height * _taskMutationDialogHeightFactor;
  final panelAspectRatio = TaskEditorSheetSpriteCatalog.panelBlankAspectRatio;
  final panelWidth = math.min(maxPanelWidth, maxPanelHeight * panelAspectRatio);

  return Size(panelWidth, panelWidth / panelAspectRatio);
}

class HomeSceneFlameView extends ConsumerStatefulWidget {
  const HomeSceneFlameView({
    super.key,
    required this.device,
    this.openTasksPanelOnStart = false,
    this.openFamilyPanelOnStart = false,
    this.openShopPanelOnStart = false,
    this.openPaywallOnStart = false,
  });

  final HomeSceneDevice device;
  final bool openTasksPanelOnStart;
  final bool openFamilyPanelOnStart;
  final bool openShopPanelOnStart;
  final bool openPaywallOnStart;

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
  bool _didRequestInitialPaywall = false;
  bool _familyPanelVisible = false;
  bool _shopPanelVisible = false;
  bool _paywallVisible = false;
  bool _settingsPanelVisible = false;
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
  OverlayEntry? _topSnackBarEntry;

  static const int _taskPanelPageSize = 4;

  static const Duration _topSnackBarDuration = Duration(milliseconds: 1800);

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

    _loadFamilyPets();

    _loadHomeTasks();
    _maybeOpenInitialTaskPanel();
    _maybeOpenInitialFamilyPanel();
    _maybeOpenInitialShopPanel();
    _maybeOpenInitialPaywall();
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
      FamilyHomePartAssets.closeButton,
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
          FamilyHomePartAssets.closeButton,
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
      _didRequestInitialPaywall = false;
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

    if (!oldWidget.openPaywallOnStart && widget.openPaywallOnStart) {
      _didRequestInitialPaywall = false;
    }

    _maybeOpenInitialTaskPanel();
    _maybeOpenInitialFamilyPanel();
    _maybeOpenInitialShopPanel();
    _maybeOpenInitialPaywall();
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

    if (!mounted || !clearRouteAfterClose) {
      return;
    }

    final routerState = GoRouterState.of(context);
    if (routerState.matchedLocation == '/home' &&
        routerState.uri.queryParameters['panel'] == 'family') {
      context.go('/home');
    }
  }

  void _openShop() {
    if (!mounted) {
      return;
    }

    _showShopComingSoonDialog(clearRouteAfterClose: false);
  }

  void _openPaywall() {
    if (!mounted) {
      return;
    }

    _showPaywallPanel(clearRouteAfterClose: false);
  }

  void _openSettings() {
    if (!mounted) {
      return;
    }

    _showSettingsPanel();
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
        action = await showSettingsDialog(settingsContext);
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
          await _showEditProfileDialog();
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

  Future<void> _waitForDismissedSettingsRoute() async {
    await Future<void>.delayed(const Duration(milliseconds: 260));
    await WidgetsBinding.instance.endOfFrame;
  }

  Future<void> _showEditProfileDialog() async {
    final authState = ref.read(authProvider);
    final user = authState.user;

    if (user == null) {
      _showTopSnackBar(
        '\u8bf7\u5148\u767b\u5f55\u540e\u518d\u7f16\u8f91\u8d44\u6599',
      );
      return;
    }

    final canManageFamilyName =
        user.isAdmin && !authState.viewOnly && user.familyId != null;

    if (canManageFamilyName) {
      try {
        await ref.read(familyProvider.notifier).loadFamily();
      } catch (error) {
        if (!mounted) {
          return;
        }
        showFriendlyApiErrorSnackBar(
          context,
          error,
          fallbackMessage:
              '\u52a0\u8f7d\u5bb6\u5ead\u8d44\u6599\u5931\u8d25\uff0c\u8bf7\u7a0d\u540e\u91cd\u8bd5',
        );
        return;
      }
    }

    final familyState = ref.read(familyProvider);
    final canEditFamilyName = canManageFamilyName && familyState.hasFamily;
    final nicknameController = TextEditingController(text: user.nickname);
    final familyNameController = TextEditingController(
      text: canEditFamilyName ? familyState.familyName : '',
    );

    try {
      if (!mounted) {
        return;
      }

      final result = await showHomePetsDialog<_ProfileEditResult>(
        context: context,
        barrierLabel: 'edit_profile_dialog',
        title: '\u7f16\u8f91\u8d44\u6599',
        layout: const AppModalLayout(
          mobileWidthFactor: 0.88,
          mobileMaxWidth: 390,
          mobileHeightFactor: 0.78,
          mobileMaxHeight: 520,
          tabletWidthFactor: 0.38,
          tabletMaxWidth: 430,
          tabletHeightFactor: 0.62,
          tabletMaxHeight: 560,
        ),
        contentBuilder: (dialogContext) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
            HomePetsButton(
              label: '\u53d6\u6d88',
              variant: HomePetsButtonVariant.secondary,
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            HomePetsButton(
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
        return;
      }

      final nextNickname = result.nickname.trim();
      final nextFamilyName = result.familyName?.trim();
      final nicknameChanged = nextNickname != user.nickname.trim();
      final familyNameChanged =
          canEditFamilyName &&
          nextFamilyName != null &&
          nextFamilyName != familyState.familyName.trim();

      if (!nicknameChanged && !familyNameChanged) {
        return;
      }

      if (nicknameChanged) {
        final dio = ref.read(apiClientProvider).dio;
        await dio.put(
          '/api/users/${user.id}',
          data: {'nickname': nextNickname},
        );
        await ref.read(authProvider.notifier).refreshUser();
      }

      if (familyNameChanged) {
        await ref
            .read(familyProvider.notifier)
            .updateFamilyName(nextFamilyName);
      }

      if (mounted) {
        _showTopSnackBar('\u8d44\u6599\u5df2\u66f4\u65b0');
      }
    } catch (error) {
      if (mounted) {
        showFriendlyApiErrorSnackBar(
          context,
          error,
          fallbackMessage:
              '\u66f4\u65b0\u8d44\u6599\u5931\u8d25\uff0c\u8bf7\u7a0d\u540e\u91cd\u8bd5',
        );
      }
    } finally {
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
    final result = await showHomePetsDialog<bool>(
      context: context,
      barrierLabel: 'logout_confirm_dialog',
      title: '\u9000\u51fa\u767b\u5f55',
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
          HomePetsButton(
            label: '\u53d6\u6d88',
            variant: HomePetsButtonVariant.secondary,
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          HomePetsButton(
            label: '\u786e\u8ba4\u9000\u51fa',
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ];
      },
    );

    return result == true;
  }

  Future<void> _showAboutDialog() {
    return showHomePetsDialog<void>(
      context: context,
      barrierLabel: 'about_homepets_dialog',
      title: '关于',
      contentBuilder: (dialogContext) {
        return const Text(
          'HomePets 家庭宠物\n\n'
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
          HomePetsButton(
            label: '知道了',
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
        ];
      },
    );
  }

  void _maybeOpenInitialPaywall() {
    if (!widget.openPaywallOnStart || _didRequestInitialPaywall) {
      return;
    }

    _didRequestInitialPaywall = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _showPaywallPanel(clearRouteAfterClose: true);
    });
  }

  Future<void> _showPaywallPanel({required bool clearRouteAfterClose}) async {
    if (_paywallVisible) {
      return;
    }

    _paywallVisible = true;
    await showPaywallDialog(context);
    _paywallVisible = false;

    if (!mounted || !clearRouteAfterClose) {
      return;
    }

    final routerState = GoRouterState.of(context);
    if (routerState.matchedLocation == '/home' &&
        routerState.uri.queryParameters['panel'] == 'paywall') {
      context.go('/home');
    }
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
    await showHomePetsDialog<void>(
      context: context,
      barrierLabel: 'shop_coming_soon',
      title: '商店完善中',
      contentBuilder: (dialogContext) {
        return const Text(
          '商店页面还在完善中，我们会尽快上线。',
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
          HomePetsButton(
            label: '知道了',
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
        ];
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
    final maxWidth = math.min(size.width * 0.88, 452.0);
    final maxHeight = size.height * 0.80;
    final height = math.min(maxHeight, maxWidth * _taskPanelBoardHeightRatio);
    final width = height / _taskPanelBoardHeightRatio;
    return Rect.fromCenter(
      center: Offset(size.width * 0.5, size.height * 0.51),
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
        final closeButtonHitSize = panelSize.width * 0.102;
        final closeButtonVisualSize = panelSize.width * 0.093;
        final addButtonWidth = panelSize.width * 0.460;
        final addButtonHeight =
            addButtonWidth / TaskBoardReferenceAsset.addTaskButtonAspectRatio;
        final addButtonBottom = panelSize.height * 0.060;

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
              top: panelSize.height * 0.082,
              right: panelSize.width * 0.032,
              width: closeButtonHitSize,
              height: closeButtonHitSize,
              child: _buildTaskPanelCloseButton(
                visualSize: closeButtonVisualSize,
                onTap: _hideTaskPanel,
              ),
            ),
            for (var index = 0; index < _visibleTaskPanelTasks.length; index++)
              Positioned(
                left: rowLeft,
                top: rowsTop + (index * (rowHeight + rowGap)),
                width: rowWidth,
                height: rowHeight,
                child: _buildTaskPanelTaskRow(
                  task: _visibleTaskPanelTasks[index],
                  index: index,
                ),
              ),
            if (_visibleTaskPanelTasks.isEmpty)
              Positioned(
                left: rowLeft,
                top: rowsTop + rowHeight + rowGap,
                width: rowWidth,
                height: rowHeight,
                child: _buildTaskPanelEmptyRow(),
              ),
            Positioned(
              left:
                  panelSize.width * 0.5 -
                  pageControlGap * 0.5 -
                  pageControlHitSize,
              top: pageControlsCenterY - (pageControlHitSize * 0.5),
              width: pageControlHitSize,
              height: pageControlHitSize,
              child: _buildTaskPanelPageControl(
                active: _taskPanelCurrentPageIndex == 0,
                enabled: _canGoToPreviousTaskPage,
                visualSize: pageControlVisualSize,
                semanticsLabel: '上一页',
                onTap: _goToPreviousTaskPage,
              ),
            ),
            if (_taskPanelPageCount > 1)
              Positioned(
                left: panelSize.width * 0.5 - (pageIndicatorWidth * 0.5),
                top: pageControlsCenterY - (pageIndicatorHeight * 0.5),
                width: pageIndicatorWidth,
                height: pageIndicatorHeight,
                child: Center(
                  child: Text(
                    _taskPanelPageIndicatorLabel,
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
            Positioned(
              left: panelSize.width * 0.5 + pageControlGap * 0.5,
              top: pageControlsCenterY - (pageControlHitSize * 0.5),
              width: pageControlHitSize,
              height: pageControlHitSize,
              child: _buildTaskPanelPageControl(
                active: _taskPanelCurrentPageIndex == _taskPanelPageCount - 1,
                enabled: _canGoToNextTaskPage,
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
            child: Image.asset(
              FamilyHomePartAssets.closeButton,
              width: visualSize,
              height: visualSize,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
              isAntiAlias: false,
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
    final completed = _taskPanelTaskCompleted(task);
    final checkboxPressKey = _taskPanelInteractionKey(
      task,
      index,
      area: 'checkbox',
    );
    final bodyPressKey = _taskPanelInteractionKey(task, index, area: 'body');
    final isCheckboxPressed = _isTaskPanelInteractionPressed(checkboxPressKey);
    final isBodyPressed = _isTaskPanelInteractionPressed(bodyPressKey);

    return LayoutBuilder(
      builder: (context, constraints) {
        final rowSize = constraints.biggest;
        final starSize = rowSize.height * 0.40;
        final checkboxSize = rowSize.height * 0.62;
        final titleFontSize = rowSize.height * 0.30;
        final titleColor = const Color(
          0xFF4D3721,
        ).withValues(alpha: completed ? 0.56 : 1);
        final rowOpacity =
            (completed ? 0.86 : 1.0) * (isBodyPressed ? 0.94 : 1.0);
        final checkboxOpacity = completed
            ? 0.92
            : (isCheckboxPressed ? 0.82 : 1.0);
        final pointsLabelWidth = math.max(
          42.0,
          math.min(rowSize.width * 0.13, 62.0),
        );
        final rowAsset = _taskPanelRowAssetForIndex(index);

        return Stack(
          children: [
            Positioned.fill(
              child: AnimatedScale(
                duration: const Duration(milliseconds: 90),
                curve: Curves.easeOutCubic,
                alignment: Alignment.center,
                scale: isBodyPressed ? 0.992 : 1,
                child: Opacity(
                  opacity: rowOpacity,
                  child: Image.asset(rowAsset, fit: BoxFit.fill),
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
                offset: isCheckboxPressed ? const Offset(0, 0.05) : Offset.zero,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 90),
                  curve: Curves.easeOutCubic,
                  scale: isCheckboxPressed ? 0.92 : 1,
                  child: Opacity(
                    opacity: checkboxOpacity,
                    child: Image.asset(
                      TaskBoardReferenceAsset.checkboxEmpty,
                      fit: BoxFit.contain,
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
              right: rowSize.width * 0.135 + pointsLabelWidth,
              top: (rowSize.height - starSize) * 0.5,
              width: starSize,
              height: starSize,
              child: Opacity(
                opacity: completed ? 0.58 : 1,
                child: Image.asset(
                  TaskBoardReferenceAsset.rewardStar,
                  fit: BoxFit.contain,
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
                onTap: () => _completeTaskByLabel(taskTitle),
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
                onTapDown: (_) => _setTaskPanelInteractionPressed(bodyPressKey),
                onTapCancel: () =>
                    _clearTaskPanelInteractionPressed(bodyPressKey),
                onTapUp: (_) => _clearTaskPanelInteractionPressed(
                  bodyPressKey,
                  delayed: true,
                ),
                onTap: () => _editTaskByLabel(taskTitle),
                child: const SizedBox.expand(),
              ),
            ),
          ],
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
    return Semantics(
      button: true,
      label: '\u6dfb\u52a0\u4efb\u52a1',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Image.asset(
          TaskBoardReferenceAsset.addTaskButton,
          fit: BoxFit.fill,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
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
                          HomePetsDialogTheme.barrierTint,
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
                                HomePetsDialogTheme.borderRadius.topLeft.x,
                                panelProgress,
                              )!,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: HomePetsDialogTheme.shadow.withValues(
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

      _showTopSnackBar('任务完成成功');
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
    final options = members
        .map(
          (member) => HomePetsSelectOption<int>(
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
      barrierTint: HomePetsDialogTheme.barrierTint,
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
  }

  void _syncGamePetsFromServer() {
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

      if (_sameHomePets(_pets, pets)) {
        return;
      }

      setState(() => _pets = pets);
      _syncGamePetsFromServer();
    } catch (error, stackTrace) {
      debugPrint('Failed to load home scene pets: $error');
      debugPrint('$stackTrace');
    }
  }

  bool _sameHomePets(List<Pet> left, List<Pet> right) {
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
  }

  void _showTopSnackBar(String message) {
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
            child: Material(
              color: Colors.transparent,
              child: IgnorePointer(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: DecoratedBox(
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
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
                  ),
                ),
              ),
            ),
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
    ref.listen<int?>(authProvider.select((state) => state.user?.familyId), (
      previous,
      next,
    ) {
      if (previous == next) {
        return;
      }

      _loadFamilyPets();
      _loadHomeTasks();
    });

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
    final panelSize = _taskMutationDialogSize(screenSize);

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        child: Center(
          child: Transform.translate(
            offset: Offset(0, screenSize.height * 0.025),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
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
                child: SizedBox(
                  width: width * 0.43,
                  child: AspectRatio(
                    aspectRatio: 226 / 30,
                    child: Image.asset(
                      _taskDeleteWarningAsset,
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: height * 0.565,
              left: width * 0.31,
              width: width * 0.38,
              height: height * 0.19,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    width: width * 0.16,
                    height: height * 0.17,
                    child: Image.asset(
                      _taskDeleteNoteAsset,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                  Positioned(
                    right: width * 0.005,
                    top: height * 0.012,
                    width: width * 0.215,
                    height: height * 0.170,
                    child: Image.asset(
                      _taskDeleteCatAsset,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: width * 0.095,
              bottom: height * 0.074,
              width: width * 0.39,
              height: height * 0.166,
              child: _TaskDeleteActionButton(
                label: '取消',
                assetPath: _taskDeleteCancelButtonAsset,
                pressedAssetPath: _taskDeleteCancelButtonPressedAsset,
                onPressed: onCancel,
              ),
            ),
            Positioned(
              right: width * 0.095,
              bottom: height * 0.074,
              width: width * 0.39,
              height: height * 0.166,
              child: _TaskDeleteActionButton(
                label: '删除',
                assetPath: _taskDeleteButtonAsset,
                pressedAssetPath: _taskDeleteButtonPressedAsset,
                onPressed: onDelete,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TaskDeleteActionButton extends StatefulWidget {
  const _TaskDeleteActionButton({
    required this.label,
    required this.assetPath,
    required this.pressedAssetPath,
    required this.onPressed,
  });

  final String label;
  final String assetPath;
  final String pressedAssetPath;
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
          child: Image.asset(
            _pressed ? widget.pressedAssetPath : widget.assetPath,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.high,
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
  final List<HomePetsSelectOption<int>> options;

  @override
  State<_CompletionMemberSelectContent> createState() =>
      _CompletionMemberSelectContentState();
}

class _CompletionMemberSelectContentState
    extends State<_CompletionMemberSelectContent> {
  late int? _selectedMemberId;

  @override
  void initState() {
    super.initState();
    _selectedMemberId =
        widget.options.any((option) => option.value == widget.initialMemberId)
        ? widget.initialMemberId
        : widget.options.isEmpty
        ? null
        : widget.options.first.value;
  }

  HomePetsSelectOption<int>? get _selectedOption {
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
    final aspect =
        _completeMemberDialogDesignSize.width /
        _completeMemberDialogDesignSize.height;
    final maxWidth = math.min(screenSize.width * 0.92, 436.0);
    final maxHeight = screenSize.height * 0.74;
    final panelWidth = math.min(maxWidth, maxHeight * aspect);
    final panelHeight = panelWidth / aspect;

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Center(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {},
          child: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: panelWidth,
              height: panelHeight,
              child: FittedBox(
                fit: BoxFit.fill,
                child: SizedBox(
                  width: _completeMemberDialogDesignSize.width,
                  height: _completeMemberDialogDesignSize.height,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Positioned(
                        left: 82,
                        bottom: -9,
                        width: 272,
                        height: 42,
                        child: _CompleteMemberAssetImage(
                          assetPath: _completeMemberDialogShadowAsset,
                          fit: BoxFit.fill,
                        ),
                      ),
                      const Positioned.fill(
                        child: _CompleteMemberAssetImage(
                          assetPath: _completeMemberDialogPanelAsset,
                          fit: BoxFit.fill,
                        ),
                      ),
                      const Positioned(
                        left: 43,
                        top: 28,
                        width: 64,
                        height: 69,
                        child: _CompleteMemberAssetImage(
                          assetPath: _completeMemberHeaderIconAsset,
                        ),
                      ),
                      const Positioned(
                        left: 128,
                        top: 41,
                        width: 268,
                        height: 47,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '选择完成人员',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xFF4D3623),
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              height: 1,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ),
                      const Positioned(
                        left: 42,
                        top: 116,
                        width: 132,
                        height: 30,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '完成成员',
                            maxLines: 1,
                            style: TextStyle(
                              color: Color(0xFF4D3623),
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              height: 1,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 35,
                        top: 145,
                        width: 367,
                        height: 65,
                        child: _CompleteMemberClosedField(
                          label: _selectedOption?.label ?? '',
                        ),
                      ),
                      Positioned(
                        left: 35,
                        top: 201,
                        width: 367,
                        height: 193,
                        child: _CompleteMemberOptionsList(
                          options: widget.options,
                          selectedMemberId: _selectedMemberId,
                          onSelected: _selectMember,
                        ),
                      ),
                      Positioned(
                        left: 106,
                        top: 419,
                        width: 86,
                        height: 48,
                        child: _CompleteMemberTextButton(
                          label: '取消',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      Positioned(
                        left: 220,
                        top: 404,
                        width: 188,
                        height: 76,
                        child: _CompleteMemberImageButton(
                          onPressed: _selectedMemberId == null
                              ? null
                              : _confirm,
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
    );
  }
}

class _CompleteMemberAssetImage extends StatelessWidget {
  const _CompleteMemberAssetImage({
    required this.assetPath,
    this.fit = BoxFit.contain,
  });

  final String assetPath;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.asset(assetPath, fit: fit, filterQuality: FilterQuality.high);
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
                  fontSize: 28,
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

  final List<HomePetsSelectOption<int>> options;
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
            itemExtent: 55,
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

  final HomePetsSelectOption<int> option;
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
                    fontSize: 28,
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

class _CompleteMemberTextButton extends StatelessWidget {
  const _CompleteMemberTextButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: Center(
        child: Text(
          label,
          maxLines: 1,
          style: const TextStyle(
            color: Color(0xFF4D3623),
            fontSize: 27,
            fontWeight: FontWeight.w900,
            height: 1,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _CompleteMemberImageButton extends StatelessWidget {
  const _CompleteMemberImageButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? 0.55 : 1,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: const _CompleteMemberAssetImage(
          assetPath: _completeMemberConfirmButtonAsset,
          fit: BoxFit.fill,
        ),
      ),
    );
  }
}

class _TaskDialogPanelBackground extends StatelessWidget {
  const _TaskDialogPanelBackground();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _taskDialogPanelBackgroundAsset,
      fit: BoxFit.fill,
      filterQuality: FilterQuality.high,
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

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.only(bottom: viewInsets.bottom * 0.72),
          child: Center(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => FocusScope.of(context).unfocus(),
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
                          top: -panelSize.height * 0.036,
                          right: -panelSize.width * 0.002,
                          width: panelSize.width * 0.138,
                          height: panelSize.width * 0.138,
                          child: _TaskEditorCloseButton(
                            sprites: sprites,
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
    );
  }
}

class _TaskEditorCloseButton extends StatelessWidget {
  const _TaskEditorCloseButton({
    required this.sprites,
    required this.onPressed,
  });

  final TaskEditorSheetSpriteCatalog sprites;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '关闭',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Center(
          child: FractionallySizedBox(
            widthFactor: 0.78,
            heightFactor: 0.78,
            child: SpriteFrameImage(
              imageAsset: sprites.imageAsset,
              sheetSize: sprites.sheetSize,
              frame: sprites.closeButton,
              fit: BoxFit.contain,
            ),
          ),
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
        final fieldWidth = panelSize.width * 0.66;
        final fieldHeight = panelSize.height * 0.112;
        final fieldLeft = panelSize.width * 0.17;
        final buttonBottom =
            panelSize.height * (bottomInset > 0 ? 0.052 : 0.075);
        final buttonHeight = panelSize.height * 0.112;
        final buttonSideInset = panelSize.width * 0.17;
        final cancelButtonWidth =
            buttonHeight * sprites.cancelButtonBg.aspectRatio;
        final saveButtonWidth = buttonHeight * sprites.saveButtonBg.aspectRatio;

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
              left: panelSize.width * 0.17,
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
                sprites: sprites,
                frame: sprites.taskNameField,
                controller: taskNameController,
                hintText: '\u6574\u7406\u73a9\u5177',
                maxLength: _taskTitleMaxLength,
                textInputAction: TextInputAction.next,
              ),
            ),
            Positioned(
              top: panelSize.height * 0.457,
              left: panelSize.width * 0.17,
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
                sprites: sprites,
                frame: sprites.pointsField,
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
                child: _TaskEditorDeleteSpriteButton(
                  sprites: sprites,
                  onTap: onDelete,
                ),
              ),
            Positioned(
              bottom: buttonBottom,
              left: buttonSideInset,
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
              right: buttonSideInset,
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
    required this.sprites,
    required this.frame,
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.inputFormatters,
    this.maxLength,
    this.textInputAction,
  });

  final TaskEditorSheetSpriteCatalog sprites;
  final SpriteAtlasFrame frame;
  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        SpriteFrameImage(
          imageAsset: sprites.imageAsset,
          sheetSize: sprites.sheetSize,
          frame: frame,
          fit: BoxFit.fill,
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                constraints.maxWidth * 0.070,
                0,
                constraints.maxWidth * 0.060,
                0,
              ),
              child: Center(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  inputFormatters: inputFormatters,
                  maxLength: maxLength,
                  textInputAction: textInputAction,
                  cursorColor: const Color(0xFF2F2218),
                  maxLines: 1,
                  style: TextStyle(
                    color: const Color(0xFF4E3A27),
                    fontWeight: FontWeight.w900,
                    fontSize: constraints.maxHeight * 0.44,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: TextStyle(
                      color: const Color(0xA36F563D),
                      fontSize: constraints.maxHeight * 0.38,
                      fontWeight: FontWeight.w800,
                    ),
                    counterText: '',
                    border: InputBorder.none,
                    isCollapsed: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            );
          },
        ),
      ],
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
  const _TaskEditorDeleteSpriteButton({
    required this.sprites,
    required this.onTap,
  });

  final TaskEditorSheetSpriteCatalog sprites;
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
              child: AspectRatio(
                aspectRatio: sprites.trashIcon.aspectRatio,
                child: SpriteFrameImage(
                  imageAsset: sprites.imageAsset,
                  sheetSize: sprites.sheetSize,
                  frame: sprites.trashIcon,
                  fit: BoxFit.contain,
                ),
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
