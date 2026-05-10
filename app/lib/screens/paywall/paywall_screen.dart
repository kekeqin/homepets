import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../core/ui/sprite_atlas.dart';
import '../../providers/revenue_cat_provider.dart';
import '../../widgets/app_modal_shell.dart';
import '../family/widgets/family_sprite_slice.dart';

Future<void> showPaywallDialog(
  BuildContext context, {
  bool useRootNavigator = true,
}) {
  return showAppModalDialog<void>(
    context: context,
    useRootNavigator: useRootNavigator,
    barrierLabel: '会员权益',
    blurSigma: 7,
    barrierTint: HomePetsDialogTheme.barrierTint,
    transitionDuration: const Duration(milliseconds: 260),
    beginScale: 0.92,
    beginYOffset: 22,
    pageBuilder: (dialogContext) {
      return AppModalShell(
        layout: AppModalLayouts.paywall,
        minimumSafeArea: const EdgeInsets.fromLTRB(10, 12, 10, 12),
        clipChild: false,
        child: _PaywallSpriteContent(
          onClose: () => Navigator.of(dialogContext).pop(),
        ),
      );
    },
  );
}

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F4EE),
      body: SafeArea(
        child: _PaywallSpriteContent(onClose: () => _closePaywall(context)),
      ),
    );
  }

  static void _closePaywall(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/home');
  }
}

class _PaywallSpriteContent extends ConsumerStatefulWidget {
  const _PaywallSpriteContent({required this.onClose});

  final VoidCallback onClose;

  @override
  ConsumerState<_PaywallSpriteContent> createState() =>
      _PaywallSpriteContentState();
}

class _PaywallSpriteContentState extends ConsumerState<_PaywallSpriteContent> {
  var _selectedSlot = 0;
  var _hasManualSelection = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(revenueCatProvider);
    final slotPackages = _packagesBySlot(state.packages);
    final selectedSlot = _hasManualSelection
        ? _selectedSlot
        : _slotForSelectedPackage(slotPackages, state.selectedPackage) ??
              _selectedSlot;
    final statusMessage = _statusMessageFor(state);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : _PaywallSprite.design.width;
        final maxHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : _PaywallSprite.design.height;
        final scale = math.min(
          maxWidth / _PaywallSprite.design.width,
          maxHeight / _PaywallSprite.design.height,
        );

        return Center(
          child: SizedBox(
            width: _PaywallSprite.design.width * scale,
            height: _PaywallSprite.design.height * scale,
            child: FittedBox(
              fit: BoxFit.fill,
              child: SizedBox(
                width: _PaywallSprite.design.width,
                height: _PaywallSprite.design.height,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Positioned.fill(child: _PaywallPanelBackground()),
                    _sprite(_PaywallSprite.cat, _PaywallSprite.catTarget),
                    _sprite(_PaywallSprite.gift, _PaywallSprite.giftTarget),
                    _sprite(
                      _PaywallSprite.calendar,
                      _PaywallSprite.calendarTarget,
                    ),
                    _sprite(_PaywallSprite.star, _PaywallSprite.starTarget),
                    _sprite(_PaywallSprite.title, _PaywallSprite.titleTarget),
                    _sprite(
                      _PaywallSprite.subtitle,
                      _PaywallSprite.subtitleTarget,
                    ),
                    _sprite(
                      _PaywallSprite.benefitFamily,
                      _PaywallSprite.benefitFamilyTarget,
                    ),
                    _sprite(
                      _PaywallSprite.benefitGrowth,
                      _PaywallSprite.benefitGrowthTarget,
                    ),
                    _sprite(
                      _PaywallSprite.benefitTasks,
                      _PaywallSprite.benefitTasksTarget,
                    ),
                    _sprite(
                      _PaywallSprite.divider,
                      _PaywallSprite.dividerTarget,
                    ),
                    _PaywallPlanCard(
                      target: _PaywallSprite.monthlyCardTarget,
                      title: '月卡',
                      price: '9.99',
                      accentColor: const Color(0xFFD15F52),
                      selected: selectedSlot == 0,
                      package: slotPackages[0],
                      fallbackLabel: '月卡，9.99 元',
                      onTap: () => _selectPlan(0, slotPackages[0]),
                    ),
                    _PaywallPlanCard(
                      target: _PaywallSprite.annualCardTarget,
                      title: '年卡',
                      price: '79.98',
                      accentColor: const Color(0xFF6F9A4A),
                      selected: selectedSlot == 1,
                      package: slotPackages[1],
                      fallbackLabel: '年卡，79.98 元',
                      onTap: () => _selectPlan(1, slotPackages[1]),
                    ),
                    _PaywallPlanCard(
                      target: _PaywallSprite.lifetimeCardTarget,
                      title: '永久会员',
                      price: '198',
                      accentColor: const Color(0xFFE09A28),
                      selected: selectedSlot == 2,
                      package: slotPackages[2],
                      fallbackLabel: '永久会员，198 元',
                      onTap: () => _selectPlan(2, slotPackages[2]),
                    ),
                    _sprite(
                      _PaywallSprite.unlockButton,
                      _PaywallSprite.unlockButtonTarget,
                    ),
                    _sprite(
                      _PaywallSprite.parentConfirm,
                      _PaywallSprite.parentConfirmTarget,
                    ),
                    if (statusMessage != null)
                      _PaywallStatusMessage(
                        message: statusMessage,
                        isError: _hasError(state),
                      ),
                    _PaywallUnlockHitTarget(
                      state: state,
                      onPressed: () async {
                        final unlocked = await ref
                            .read(revenueCatProvider.notifier)
                            .purchaseSelectedPackage();
                        if (!context.mounted || !unlocked) {
                          return;
                        }
                        widget.onClose();
                      },
                    ),
                    _PaywallRestoreHitTarget(
                      state: state,
                      onRestore: () async {
                        final restored = await ref
                            .read(revenueCatProvider.notifier)
                            .restorePurchases();
                        if (!context.mounted || !restored) {
                          return;
                        }
                        widget.onClose();
                      },
                    ),
                    _CloseButton(onPressed: widget.onClose),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _selectPlan(int slot, Package? package) {
    setState(() {
      _selectedSlot = slot;
      _hasManualSelection = true;
    });
    if (package != null) {
      ref.read(revenueCatProvider.notifier).selectPackage(package);
    }
  }
}

class _PaywallPlanCard extends StatelessWidget {
  const _PaywallPlanCard({
    required this.target,
    required this.title,
    required this.price,
    required this.accentColor,
    required this.selected,
    required this.package,
    required this.fallbackLabel,
    required this.onTap,
  });

  final Rect target;
  final String title;
  final String price;
  final Color accentColor;
  final bool selected;
  final Package? package;
  final String fallbackLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final package = this.package;
    final borderColor = selected ? const Color(0xFFD15F52) : accentColor;
    return Positioned.fromRect(
      rect: target,
      child: Semantics(
        button: true,
        selected: selected,
        label: package == null
            ? fallbackLabel
            : _packageAccessibilityLabel(package),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                width: target.width,
                height: target.height,
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 11),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7E7),
                  borderRadius: BorderRadius.circular(23),
                  border: Border.all(
                    color: borderColor,
                    width: selected ? 4 : 2.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (selected ? borderColor : const Color(0xFF8C5B30))
                          .withValues(alpha: selected ? 0.18 : 0.09),
                      blurRadius: selected ? 13 : 8,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: accentColor,
                        fontSize: title.length > 2 ? 24 : 27,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Text(
                              '¥',
                              style: TextStyle(
                                color: Color(0xFF2F2015),
                                fontSize: 29,
                                fontWeight: FontWeight.w900,
                                height: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            price,
                            style: const TextStyle(
                              color: Color(0xFF2A1B11),
                              fontSize: 52,
                              fontWeight: FontWeight.w900,
                              height: 0.9,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Positioned(
                  left: -17,
                  top: -17,
                  child: const _PaywallSelectedBadge(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaywallSelectedBadge extends StatelessWidget {
  const _PaywallSelectedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFE77B70),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF9A4D3C), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x308E4B38),
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.check_rounded, color: Colors.white, size: 34),
      ),
    );
  }
}

class _PaywallUnlockHitTarget extends StatelessWidget {
  const _PaywallUnlockHitTarget({required this.state, required this.onPressed});

  final RevenueCatState state;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final busy = state.isPurchasing || state.isRestoring;
    return Positioned.fromRect(
      rect: _PaywallSprite.unlockButtonTarget,
      child: Semantics(
        button: true,
        enabled: state.canPurchase,
        label: state.isPremiumActive ? '已开通家庭会员' : '立即开通家庭会员',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: state.canPurchase ? onPressed : null,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const SizedBox.expand(),
              if (busy)
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Color(0xCCF7D4BB),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(13),
                  child: const CircularProgressIndicator(
                    strokeWidth: 4,
                    color: Color(0xFF7B4D22),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaywallRestoreHitTarget extends StatelessWidget {
  const _PaywallRestoreHitTarget({
    required this.state,
    required this.onRestore,
  });

  final RevenueCatState state;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final disabled =
        state.isPurchasing || state.isRestoring || state.isPremiumActive;
    return Positioned.fromRect(
      rect: _PaywallSprite.restoreTarget,
      child: Semantics(
        button: true,
        enabled: !disabled,
        label: '恢复购买',
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: disabled ? null : onRestore,
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _PaywallStatusMessage extends StatelessWidget {
  const _PaywallStatusMessage({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Positioned.fromRect(
      rect: _PaywallSprite.statusTarget,
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isError ? const Color(0xFFF9DDD3) : const Color(0xFFF7EBD2),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isError
                  ? const Color(0xFFE4A393)
                  : const Color(0xFFE5CFA3),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            child: Text(
              message,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isError
                    ? const Color(0xFFAC5A48)
                    : const Color(0xFF7F5A30),
                fontSize: 18,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Positioned.fromRect(
      rect: _PaywallSprite.closeTarget,
      child: Semantics(
        button: true,
        label: '关闭',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onPressed,
          child: Image.asset(
            FamilyHomePartAssets.closeButton,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}

class _PaywallPanelBackground extends StatelessWidget {
  const _PaywallPanelBackground();

  @override
  Widget build(BuildContext context) {
    return const _NineSliceSprite(
      source: _PaywallSprite.panel,
      left: 92,
      top: 92,
      right: 92,
      bottom: 92,
      targetLeft: 92,
      targetTop: 92,
      targetRight: 92,
      targetBottom: 92,
    );
  }
}

class _NineSliceSprite extends StatelessWidget {
  const _NineSliceSprite({
    required this.source,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    required this.targetLeft,
    required this.targetTop,
    required this.targetRight,
    required this.targetBottom,
  });

  final Rect source;
  final double left;
  final double top;
  final double right;
  final double bottom;
  final double targetLeft;
  final double targetTop;
  final double targetRight;
  final double targetBottom;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final dstLeft = math.min(targetLeft, size.width / 2);
        final dstRight = math.min(targetRight, size.width - dstLeft);
        final dstTop = math.min(targetTop, size.height / 2);
        final dstBottom = math.min(targetBottom, size.height - dstTop);
        final dstCenterWidth = math.max(0.0, size.width - dstLeft - dstRight);
        final dstCenterHeight = math.max(0.0, size.height - dstTop - dstBottom);
        final srcCenterWidth = math.max(0.0, source.width - left - right);
        final srcCenterHeight = math.max(0.0, source.height - top - bottom);

        final srcColumns = <_SliceAxis>[
          _SliceAxis(source.left, left, 0, dstLeft),
          _SliceAxis(
            source.left + left,
            srcCenterWidth,
            dstLeft,
            dstCenterWidth,
          ),
          _SliceAxis(
            source.right - right,
            right,
            dstLeft + dstCenterWidth,
            dstRight,
          ),
        ];
        final srcRows = <_SliceAxis>[
          _SliceAxis(source.top, top, 0, dstTop),
          _SliceAxis(
            source.top + top,
            srcCenterHeight,
            dstTop,
            dstCenterHeight,
          ),
          _SliceAxis(
            source.bottom - bottom,
            bottom,
            dstTop + dstCenterHeight,
            dstBottom,
          ),
        ];

        return Stack(
          fit: StackFit.expand,
          children: [
            for (final row in srcRows)
              for (final column in srcColumns)
                if (row.sourceSize > 0 &&
                    column.sourceSize > 0 &&
                    row.targetSize > 0 &&
                    column.targetSize > 0)
                  Positioned.fromRect(
                    rect: Rect.fromLTWH(
                      column.targetOffset,
                      row.targetOffset,
                      column.targetSize,
                      row.targetSize,
                    ),
                    child: _PaywallSpritePiece(
                      source: Rect.fromLTWH(
                        column.sourceOffset,
                        row.sourceOffset,
                        column.sourceSize,
                        row.sourceSize,
                      ),
                      fit: BoxFit.fill,
                    ),
                  ),
          ],
        );
      },
    );
  }
}

class _SliceAxis {
  const _SliceAxis(
    this.sourceOffset,
    this.sourceSize,
    this.targetOffset,
    this.targetSize,
  );

  final double sourceOffset;
  final double sourceSize;
  final double targetOffset;
  final double targetSize;
}

class _PaywallSpritePiece extends StatelessWidget {
  const _PaywallSpritePiece({required this.source, this.fit = BoxFit.contain});

  final Rect source;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return SpriteFrameImage(
      imageAsset: _PaywallSprite.asset,
      sheetSize: _PaywallSprite.sheetSize,
      frame: SpriteAtlasFrame(
        name:
            'paywall_${source.left}_${source.top}_${source.width}_${source.height}',
        textureRect: source,
        sourceRect: Offset.zero & source.size,
        sourceSize: source.size,
        rotated: false,
        trimmed: false,
      ),
      fit: fit,
      filterQuality: FilterQuality.high,
    );
  }
}

Widget _sprite(Rect source, Rect target, {BoxFit fit = BoxFit.contain}) {
  return Positioned.fromRect(
    rect: target,
    child: _PaywallSpritePiece(source: source, fit: fit),
  );
}

List<Package?> _packagesBySlot(List<Package> packages) {
  final slots = List<Package?>.filled(3, null);
  final usedIdentifiers = <String>{};

  void assignType(PackageType type, int slot) {
    for (final package in packages) {
      if (package.packageType == type &&
          usedIdentifiers.add(package.identifier)) {
        slots[slot] = package;
        return;
      }
    }
  }

  assignType(PackageType.monthly, 0);
  assignType(PackageType.annual, 1);
  assignType(PackageType.lifetime, 2);

  for (final package in packages) {
    if (usedIdentifiers.contains(package.identifier)) {
      continue;
    }
    final slot = slots.indexWhere((value) => value == null);
    if (slot == -1) {
      break;
    }
    slots[slot] = package;
    usedIdentifiers.add(package.identifier);
  }

  return slots;
}

int? _slotForSelectedPackage(List<Package?> slotPackages, Package? selected) {
  if (selected == null) {
    return null;
  }
  for (var index = 0; index < slotPackages.length; index++) {
    if (slotPackages[index]?.identifier == selected.identifier) {
      return index;
    }
  }
  return null;
}

bool _hasError(RevenueCatState state) {
  return state.errorMessage != null ||
      state.purchaseError != null ||
      state.restoreError != null;
}

String? _statusMessageFor(RevenueCatState state) {
  if (state.isPremiumActive) {
    return '家庭会员已开通';
  }
  if (state.isPurchasing) {
    return '正在连接商店...';
  }
  if (state.isRestoring) {
    return '正在恢复购买...';
  }
  if (_hasError(state)) {
    return '商店暂时不可用，请稍后再试';
  }
  if (state.isLoadingOfferings && !state.hasPackages) {
    return '正在读取会员套餐...';
  }
  if (!state.hasPackages && state.isInitialized) {
    return '暂无可购买套餐';
  }
  return null;
}

String _packageAccessibilityLabel(Package package) {
  final title = switch (package.packageType) {
    PackageType.weekly => '周卡',
    PackageType.monthly => '月卡',
    PackageType.twoMonth => '双月卡',
    PackageType.threeMonth => '季卡',
    PackageType.sixMonth => '半年卡',
    PackageType.annual => '年卡',
    PackageType.lifetime => '永久会员',
    PackageType.custom || PackageType.unknown => '会员套餐',
  };
  return '$title，${package.storeProduct.priceString}';
}

class _PaywallSprite {
  const _PaywallSprite._();

  static const asset = 'assets/images/ui/paywall/paywall_cutouts.png';
  static const sheetSize = Size(1122, 1402);
  static const design = Size(760, 1320);

  static const panel = Rect.fromLTWH(21, 17, 529, 532);
  static const cat = Rect.fromLTWH(608, 48, 235, 273);
  static const gift = Rect.fromLTWH(876, 92, 150, 169);
  static const calendar = Rect.fromLTWH(819, 290, 220, 277);
  static const star = Rect.fromLTWH(618, 370, 151, 149);
  static const title = Rect.fromLTWH(60, 640, 665, 118);
  static const subtitle = Rect.fromLTWH(118, 748, 580, 80);
  static const benefitFamily = Rect.fromLTWH(57, 818, 221, 181);
  static const benefitGrowth = Rect.fromLTWH(303, 818, 218, 181);
  static const benefitTasks = Rect.fromLTWH(546, 818, 210, 181);
  static const divider = Rect.fromLTWH(48, 1008, 720, 12);
  static const unlockButton = Rect.fromLTWH(128, 1290, 465, 97);
  static const parentConfirm = Rect.fromLTWH(655, 1318, 250, 55);

  static const catTarget = Rect.fromLTWH(82, 58, 238, 276);
  static const giftTarget = Rect.fromLTWH(304, 217, 142, 160);
  static const calendarTarget = Rect.fromLTWH(476, 78, 218, 274);
  static const starTarget = Rect.fromLTWH(416, 321, 126, 124);
  static const titleTarget = Rect.fromLTWH(96, 433, 568, 101);
  static const subtitleTarget = Rect.fromLTWH(142, 526, 476, 66);
  static const benefitFamilyTarget = Rect.fromLTWH(54, 624, 205, 168);
  static const benefitGrowthTarget = Rect.fromLTWH(278, 624, 204, 168);
  static const benefitTasksTarget = Rect.fromLTWH(502, 624, 204, 168);
  static const dividerTarget = Rect.fromLTWH(64, 831, 632, 12);
  static const monthlyCardTarget = Rect.fromLTWH(43, 880, 216, 130);
  static const annualCardTarget = Rect.fromLTWH(274, 880, 216, 130);
  static const lifetimeCardTarget = Rect.fromLTWH(505, 880, 216, 130);
  static const unlockButtonTarget = Rect.fromLTWH(151, 1074, 458, 96);
  static const parentConfirmTarget = Rect.fromLTWH(251, 1170, 258, 57);
  static const closeTarget = Rect.fromLTWH(667, -18, 96, 96);
  static const statusTarget = Rect.fromLTWH(120, 1024, 520, 46);
  static const restoreTarget = Rect.fromLTWH(305, 1266, 150, 38);
}
