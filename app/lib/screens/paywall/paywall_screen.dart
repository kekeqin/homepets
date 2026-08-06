import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../core/constants.dart';
import '../../core/support_links.dart';
import '../../core/ui/adaptive_design_layout.dart';
import '../../core/ui/sprite_atlas.dart';
import '../../models/subscription_status.dart';
import '../../providers/auth_provider.dart';
import '../../providers/revenue_cat_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/app_modal_shell.dart';
import '../../widgets/membership_top_notice.dart';

enum PaywallMode { optional, blocking }

Future<void> showPaywallDialog(
  BuildContext context, {
  bool useRootNavigator = true,
  PaywallMode mode = PaywallMode.optional,
}) {
  return showAppModalDialog<void>(
    context: context,
    useRootNavigator: useRootNavigator,
    barrierLabel: '会员权益',
    barrierDismissible: mode == PaywallMode.optional,
    blurSigma: 7,
    barrierTint: PickStarPetDialogTheme.barrierTint,
    transitionDuration: const Duration(milliseconds: 260),
    beginScale: 0.92,
    beginYOffset: 22,
    pageBuilder: (dialogContext) {
      return _PaywallShell(
        mode: mode,
        onClose: () => Navigator.of(dialogContext).pop(),
      );
    },
  );
}

class _PaywallShell extends ConsumerWidget {
  const _PaywallShell({
    required this.mode,
    required this.onClose,
    this.reason,
  });

  final PaywallMode mode;
  final VoidCallback onClose;
  final String? reason;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPermanent =
        ref.watch(subscriptionProvider).status?.isPermanentPremium == true;
    return AppModalShell(
      layout: isPermanent
          ? AppModalLayouts.paywallPermanent
          : AppModalLayouts.paywall,
      minimumSafeArea: PickStarPetDialogGutter.largeInsets,
      clipChild: false,
      child: PaywallContent(mode: mode, reason: reason, onClose: onClose),
    );
  }
}

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({
    super.key,
    this.mode = PaywallMode.optional,
    this.reason,
    this.returnRoute,
  });

  final PaywallMode mode;
  final String? reason;
  final String? returnRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<SubscriptionState>(subscriptionProvider, (previous, next) {
      if (mode != PaywallMode.blocking || !next.accessAllowed) {
        return;
      }
      final target =
          returnRoute == null ||
              returnRoute!.isEmpty ||
              returnRoute == '/paywall'
          ? '/home'
          : returnRoute!;
      context.go(target);
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PopScope(
        canPop: mode == PaywallMode.optional,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && mode == PaywallMode.blocking) {
            MembershipTopNotice.show(context, message: '试用期已结束，请开通会员后继续使用');
          }
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _closePaywall(context, ref),
                child: const _PaywallRouteBackdrop(),
              ),
            ),
            SafeArea(
              child: _PaywallShell(
                mode: mode,
                reason: reason,
                onClose: () => _closePaywall(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _closePaywall(BuildContext context, WidgetRef ref) {
    if (mode == PaywallMode.blocking) {
      final subscriptionState = ref.read(subscriptionProvider);
      final target =
          returnRoute == null ||
              returnRoute!.isEmpty ||
              returnRoute == '/paywall'
          ? '/home'
          : returnRoute!;
      if (subscriptionState.accessAllowed) {
        ref.read(authProvider.notifier).setViewOnly(false);
        context.go(target);
      } else {
        ref.read(authProvider.notifier).setViewOnly(true);
        context.go('/home');
      }
      return;
    }
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/home');
  }
}

class _PaywallRouteBackdrop extends StatelessWidget {
  const _PaywallRouteBackdrop();

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 7, sigmaY: 7),
        child: ColoredBox(
          color: PickStarPetDialogTheme.barrierTint,
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class PaywallContent extends ConsumerStatefulWidget {
  const PaywallContent({
    super.key,
    required this.mode,
    required this.onClose,
    this.reason,
  });

  final PaywallMode mode;
  final VoidCallback onClose;
  final String? reason;

  @override
  ConsumerState<PaywallContent> createState() => _PaywallContentState();
}

class _PaywallContentState extends ConsumerState<PaywallContent> {
  var _selectedSlot = 0;
  var _hasManualSelection = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(revenueCatProvider);
    final authState = ref.watch(authProvider);
    final slotPackages = _packagesBySlot(state.purchasablePackages);
    final selectedSlot = _hasManualSelection
        ? _selectedSlot
        : _slotForSelectedPackage(slotPackages, state.selectedPackage) ??
              _selectedSlot;
    final subscriptionState = ref.watch(subscriptionProvider);
    final isPermanent =
        subscriptionState.status?.isPermanentPremium == true;
    final designSize = isPermanent
        ? _PaywallSprite.permanentDesign
        : _PaywallSprite.design;
    final statusMessage = isPermanent
        ? null
        : _inlineStatusMessageFor(state, subscriptionState);

    return AdaptiveDesignLayout(
      designSize: designSize,
      useViewPadding: false,
      builder: (context, geometry) {
        return Center(
          child: SizedBox(
            width: geometry.scaledDesignSize.width,
            height: geometry.scaledDesignSize.height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Positioned.fill(child: _PaywallPanelBackground()),
                Positioned.fill(
                  child: FittedBox(
                    fit: BoxFit.fill,
                    child: SizedBox(
                      width: designSize.width,
                      height: designSize.height,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _sprite(_PaywallSprite.cat, _PaywallSprite.catTarget),
                          _sprite(
                            _PaywallSprite.gift,
                            _PaywallSprite.giftTarget,
                          ),
                          _sprite(
                            _PaywallSprite.calendar,
                            _PaywallSprite.calendarTarget,
                          ),
                          _sprite(
                            _PaywallSprite.star,
                            _PaywallSprite.starTarget,
                          ),
                          _PaywallHeaderCopy(
                            mode: widget.mode,
                            revenueCatState: state,
                            subscriptionState: subscriptionState,
                          ),
                          const _PaywallBenefitRow(),
                          _PaywallTrialChip(
                            revenueCatState: state,
                            subscriptionState: subscriptionState,
                          ),
                          if (!isPermanent) ...[
                            _PaywallPlanCard(
                              target: _PaywallSprite.monthlyCardTarget,
                              fallbackTitle: '月度订阅',
                              fallbackPrice: '¥9.99',
                              fallbackPeriod: '每月 · 自动续订',
                              accentColor: const Color(0xFFD15F52),
                              selected: selectedSlot == 0,
                              package: slotPackages[0],
                              onTap: () => _selectPlan(0, slotPackages[0]),
                            ),
                            _PaywallPlanCard(
                              target: _PaywallSprite.annualCardTarget,
                              fallbackTitle: '年度订阅',
                              fallbackPrice: '¥79.98',
                              fallbackPeriod: '每年 · 自动续订',
                              accentColor: const Color(0xFF6F9A4A),
                              selected: selectedSlot == 1,
                              package: slotPackages[1],
                              onTap: () => _selectPlan(1, slotPackages[1]),
                            ),
                          ],
                          if (statusMessage != null)
                            _PaywallStatusMessage(
                              message: statusMessage,
                              isError: _hasError(state),
                            ),
                          _PaywallUnlockHitTarget(
                            state: state,
                            isPermanentPremium: isPermanent,
                            canStartPurchase:
                                !isPermanent &&
                                authState.user?.isAdmin == true,
                            unlockButtonTarget: isPermanent
                                ? _PaywallSprite.permanentUnlockButtonTarget
                                : _PaywallSprite.unlockButtonTarget,
                            onPressed: () async {
                              final unlocked = await ref
                                  .read(revenueCatProvider.notifier)
                                  .purchaseSelectedPackage();
                              if (!context.mounted) {
                                return;
                              }
                              if (unlocked) {
                                final user = ref.read(authProvider).user;
                                final entitlement = ref
                                    .read(revenueCatProvider.notifier)
                                    .currentClientEntitlement();
                                final backendUnlocked = await ref
                                    .read(subscriptionProvider.notifier)
                                    .syncAfterStorePurchase(
                                      revenueCatAppUserId: user == null
                                          ? null
                                          : revenueCatAppUserIdFor(user),
                                      entitlement: entitlement,
                                    );
                                if (!context.mounted || !backendUnlocked) {
                                  return;
                                }
                                widget.onClose();
                                return;
                              }
                            },
                          ),
                          if (!isPermanent)
                            _PaywallRestoreHitTarget(
                              state: state,
                              onRestore: () async {
                                final restored = await ref
                                    .read(revenueCatProvider.notifier)
                                    .restorePurchases();
                                if (!context.mounted) {
                                  return;
                                }
                                if (restored) {
                                  final user = ref.read(authProvider).user;
                                  final entitlement = ref
                                      .read(revenueCatProvider.notifier)
                                      .currentClientEntitlement();
                                  final backendUnlocked = await ref
                                      .read(subscriptionProvider.notifier)
                                      .syncAfterStorePurchase(
                                        revenueCatAppUserId: user == null
                                            ? null
                                            : revenueCatAppUserIdFor(user),
                                        entitlement: entitlement,
                                      );
                                  if (!context.mounted || !backendUnlocked) {
                                    return;
                                  }
                                  widget.onClose();
                                  return;
                                }
                              },
                            ),
                          _PaywallComplianceLinks(
                            showManageSubscription: !isPermanent,
                            complianceTarget: isPermanent
                                ? _PaywallSprite.permanentComplianceTarget
                                : _PaywallSprite.complianceTarget,
                          ),
                          _CloseButton(onPressed: widget.onClose),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
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
    required this.fallbackTitle,
    required this.fallbackPrice,
    required this.fallbackPeriod,
    required this.accentColor,
    required this.selected,
    required this.package,
    required this.onTap,
  });

  final Rect target;
  final String fallbackTitle;
  final String fallbackPrice;
  final String fallbackPeriod;
  final Color accentColor;
  final bool selected;
  final Package? package;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final package = this.package;
    final title = package == null ? fallbackTitle : _packageTitle(package);
    final price = _rmbPriceLabel(
      package?.storeProduct.priceString,
      fallbackPrice,
    );
    final period = package == null
        ? fallbackPeriod
        : _packagePeriodLabel(package);
    final borderColor = selected ? const Color(0xFFD15F52) : accentColor;
    return Positioned.fromRect(
      rect: target,
      child: Semantics(
        button: true,
        selected: selected,
        label: '$title，$price，$period',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: package == null ? null : onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                width: target.width,
                height: target.height,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7E7),
                  borderRadius: BorderRadius.circular(18),
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
                        fontSize: title.length > 5 ? 19 : 22,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        price,
                        style: TextStyle(
                          color: const Color(0xFF2A1B11),
                          fontSize: price.length > 7 ? 34 : 40,
                          fontWeight: FontWeight.w900,
                          height: 0.95,
                        ),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      period,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF7B5A37),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        height: 1,
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

class _PaywallHeaderCopy extends StatelessWidget {
  const _PaywallHeaderCopy({
    required this.mode,
    required this.revenueCatState,
    required this.subscriptionState,
  });

  final PaywallMode mode;
  final RevenueCatState revenueCatState;
  final SubscriptionState subscriptionState;

  @override
  Widget build(BuildContext context) {
    final isBlocking = mode == PaywallMode.blocking;
    final entitlement = revenueCatState
        .customerInfo
        ?.entitlements
        .active[RevenueCatConstants.entitlementId];
    final status = subscriptionState.status;
    final isPermanent = status?.isPermanentPremium == true;
    final title = isPermanent
        ? '永久会员'
        : isBlocking
        ? '试用期已结束'
        : '拾星小宠家庭会员';
    final subtitle = isPermanent
        ? '永久会员权益已生效，可长期使用全部家庭功能。'
        : entitlement?.isActive == true
        ? '会员权益已生效，可继续体验全部家庭功能。'
        : status?.status == 'trial_expiring'
        ? '试用期即将结束。订阅后可继续管理家庭任务和宠物成长。'
        : isBlocking
        ? '订阅拾星小宠后，可以继续使用家庭任务、宠物成长和成长记录功能。'
        : '试用期内可完整体验家庭任务、宠物成长和任务记录，试用结束后需要订阅继续使用。';
    return Positioned.fromRect(
      rect: Rect.fromLTWH(
        _PaywallSprite.titleTarget.left,
        _PaywallSprite.titleTarget.top - 6,
        _PaywallSprite.titleTarget.width,
        _PaywallSprite.subtitleTarget.bottom -
            _PaywallSprite.titleTarget.top +
            4,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF5B371E),
              fontSize: 46,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF7A5636),
              fontSize: 19,
              fontWeight: FontWeight.w800,
              height: 1.22,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaywallBenefitRow extends StatelessWidget {
  const _PaywallBenefitRow();

  @override
  Widget build(BuildContext context) {
    return Positioned.fromRect(
      rect: Rect.fromLTWH(
        _PaywallSprite.benefitFamilyTarget.left,
        _PaywallSprite.benefitFamilyTarget.top,
        _PaywallSprite.benefitTasksTarget.right -
            _PaywallSprite.benefitFamilyTarget.left,
        _PaywallSprite.benefitFamilyTarget.height,
      ),
      child: const Row(
        children: [
          Expanded(
            child: _BenefitItem(icon: Icons.family_restroom, label: '家庭共享'),
          ),
          SizedBox(width: 14),
          Expanded(
            child: _BenefitItem(icon: Icons.task_alt, label: '亲子任务'),
          ),
          SizedBox(width: 14),
          Expanded(
            child: _BenefitItem(icon: Icons.auto_graph, label: '宠物成长'),
          ),
        ],
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  const _BenefitItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9CDA3), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF8D6A3E), size: 68),
            const SizedBox(height: 12),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF5F4126),
                fontSize: 26,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaywallTrialChip extends StatelessWidget {
  const _PaywallTrialChip({
    required this.revenueCatState,
    required this.subscriptionState,
  });

  final RevenueCatState revenueCatState;
  final SubscriptionState subscriptionState;

  @override
  Widget build(BuildContext context) {
    final entitlement = revenueCatState
        .customerInfo
        ?.entitlements
        .active[RevenueCatConstants.entitlementId];
    final status = subscriptionState.status;
    final text =
        _membershipChipText(entitlement, status) ??
        (status == null
            ? '正在确认试用状态'
            : status.isTrialActive
            ? '7 天免费体验已开启，还剩 ${status.trialDaysRemaining} 天'
            : _statusChipText(status.status));
    return Positioned.fromRect(
      rect: _PaywallSprite.trialChipTarget,
      child: Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFEAF4D5),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFF9BAE66), width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF59692A),
                  fontSize: 17,
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
  const _PaywallUnlockHitTarget({
    required this.state,
    required this.canStartPurchase,
    required this.onPressed,
    this.isPermanentPremium = false,
    this.unlockButtonTarget = _PaywallSprite.unlockButtonTarget,
  });

  final RevenueCatState state;
  final bool canStartPurchase;
  final bool isPermanentPremium;
  final Rect unlockButtonTarget;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final busy = state.isPurchasing || state.isRestoring;
    final isActive = isPermanentPremium || state.isPremiumActive;
    final enabled =
        !isActive && state.canPurchase && canStartPurchase;
    final label = isPermanentPremium
        ? '永久会员已开通'
        : isActive
        ? '家庭会员已开通'
        : canStartPurchase
        ? '订阅'
        : '请家长订阅后继续使用';
    return Positioned.fromRect(
      rect: unlockButtonTarget,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? onPressed : null,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 120),
            opacity: enabled || isActive ? 1 : 0.52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: isPermanentPremium
                    ? const Color(0xFFBFD98A)
                    : const Color(0xFFFFB65A),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isPermanentPremium
                      ? const Color(0xFF6F8A3E)
                      : const Color(0xFFA8642E),
                  width: 3,
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
                child: busy
                    ? const SizedBox(
                        width: 34,
                        height: 34,
                        child: CircularProgressIndicator(
                          strokeWidth: 4,
                          color: Color(0xFF7B4D22),
                        ),
                      )
                    : Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isPermanentPremium
                              ? const Color(0xFF3F4F1C)
                              : const Color(0xFF4D3623),
                          fontSize: isPermanentPremium ? 23 : 25,
                          fontWeight: FontWeight.w900,
                          height: 1,
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

class _PaywallComplianceLinks extends StatelessWidget {
  const _PaywallComplianceLinks({
    this.showManageSubscription = true,
    this.complianceTarget = _PaywallSprite.complianceTarget,
  });

  final bool showManageSubscription;
  final Rect complianceTarget;

  @override
  Widget build(BuildContext context) {
    return Positioned.fromRect(
      rect: complianceTarget,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 14,
        runSpacing: 8,
        children: [
          if (showManageSubscription)
            _ComplianceLink(
              label: '管理订阅',
              onTap: () => _showInfo(
                context,
                '管理订阅',
                '请在 App Store 的订阅管理页面查看、变更或取消订阅。',
              ),
            ),
          _ComplianceLink(
            label: '联系客服',
            onTap: () => SupportLinks.openSupportPage(context),
          ),
          _ComplianceLink(
            label: '隐私政策',
            onTap: () => SupportLinks.openPrivacy(context),
          ),
          _ComplianceLink(
            label: '用户协议',
            onTap: () => SupportLinks.openTerms(context),
          ),
        ],
      ),
    );
  }

  static void _showInfo(BuildContext context, String title, String message) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: PickStarPetDialogGutter.small,
            vertical: 24,
          ),
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('知道了'),
            ),
          ],
        );
      },
    );
  }
}

class _ComplianceLink extends StatelessWidget {
  const _ComplianceLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF6B543B),
            fontSize: 17,
            fontWeight: FontWeight.w900,
            decoration: TextDecoration.underline,
            decorationColor: Color(0xFF6B543B),
            height: 1,
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
      child: Center(
        child: TextButton(
          onPressed: disabled ? null : onRestore,
          child: const Text(
            '恢复购买',
            style: TextStyle(
              color: Color(0xFF6B543B),
              fontSize: 18,
              fontWeight: FontWeight.w900,
              decoration: TextDecoration.underline,
              height: 1,
            ),
          ),
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

  static const _assetPath = 'assets/images/ui/sprites/close.webp';
  static const _visualSize = 90.0;

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
          child: Center(
            child: SizedBox.square(
              dimension: _visualSize,
              child: Image.asset(
                _assetPath,
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
}

class _PaywallPanelBackground extends StatelessWidget {
  const _PaywallPanelBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: PickStarPetDialogTheme.borderRadius,
        border: Border.all(
          color: PickStarPetDialogTheme.outerBorderColor,
          width: PickStarPetDialogTheme.outerBorderWidth,
        ),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFCE8C1), Color(0xFFFEEDC9)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x28604429),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
    );
  }
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
  final slots = List<Package?>.filled(2, null);
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

  // Paywall only offers recurring subscriptions (monthly / annual).
  assignType(PackageType.monthly, 0);
  assignType(PackageType.annual, 1);

  for (final package in packages) {
    if (usedIdentifiers.contains(package.identifier)) {
      continue;
    }
    // Never surface lifetime / one-time purchases on the paywall.
    if (package.packageType == PackageType.lifetime ||
        _isLifetimePackage(package)) {
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

bool _isLifetimePackage(Package package) {
  if (package.packageType == PackageType.lifetime) {
    return true;
  }
  final signature =
      '${package.identifier} ${package.storeProduct.identifier} ${package.storeProduct.title}'
          .toLowerCase();
  return signature.contains('lifetime') ||
      signature.contains('forever') ||
      signature.contains('permanent') ||
      signature.contains('永久');
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

String? _inlineStatusMessageFor(
  RevenueCatState state,
  SubscriptionState subscriptionState,
) {
  if (state.isPremiumActive) {
    return null;
  }
  if (_hasError(state) ||
      (state.isLoadingOfferings && !state.hasPackages) ||
      (!state.hasPackages && state.isInitialized)) {
    return null;
  }
  return _statusMessageFor(state, subscriptionState);
}

String? _statusMessageFor(
  RevenueCatState state,
  SubscriptionState subscriptionState,
) {
  if (subscriptionState.isLoading) {
    return '正在同步后端会员状态...';
  }
  if (subscriptionState.error != null) {
    return subscriptionState.error;
  }
  final entitlementStatus = subscriptionState.status?.status;
  if (entitlementStatus == 'subscription_grace_period') {
    return '账单处于宽限期，请及时更新付款方式';
  }
  if (entitlementStatus == 'subscription_expired') {
    return '订阅已过期，请重新订阅后继续使用';
  }
  if (entitlementStatus == 'offline_unverified_or_expired') {
    return '离线状态无法确认会员资格，请联网重试';
  }
  if (state.isPremiumActive) {
    return '家庭会员已开通';
  }
  if (state.isPurchasing) {
    return '正在连接商店...';
  }
  if (state.isRestoring) {
    return '正在恢复购买...';
  }
  return null;
}

String _rmbPriceLabel(String? storePrice, String fallbackPrice) {
  final price = storePrice?.trim();
  if (price == null || price.isEmpty) {
    return fallbackPrice;
  }
  return price.replaceFirst(RegExp(r'^(?:US\$\s*|USD\s*|\$\s*)'), '¥');
}

String _packageTitle(Package package) {
  final packageTypeTitle = _packageTypeTitle(package.packageType);
  if (packageTypeTitle != null) {
    return packageTypeTitle;
  }

  final inferredTitle = _packageSignatureTitle(
    '${package.identifier} ${package.storeProduct.identifier} ${package.storeProduct.title}',
  );
  if (inferredTitle != null) {
    return inferredTitle;
  }

  final storeTitle = package.storeProduct.title.trim();
  if (storeTitle.isNotEmpty) {
    return storeTitle;
  }
  return '会员套餐';
}

String? _packageTypeTitle(PackageType packageType) {
  return switch (packageType) {
    PackageType.weekly => '周度',
    PackageType.monthly => '月度',
    PackageType.twoMonth => '双月',
    PackageType.threeMonth => '季度',
    PackageType.sixMonth => '半年',
    PackageType.annual => '年度',
    PackageType.lifetime => '永久会员',
    PackageType.custom || PackageType.unknown => null,
  };
}

String? _packageSignatureTitle(String value) {
  final normalized = value.toLowerCase();
  if (normalized.contains('lifetime') ||
      normalized.contains('forever') ||
      normalized.contains('permanent') ||
      normalized.contains('永久')) {
    return '永久会员';
  }
  if (normalized.contains('annual') ||
      normalized.contains('yearly') ||
      normalized.contains('year') ||
      normalized.contains('年度') ||
      normalized.contains('年卡')) {
    return '年度';
  }
  if (normalized.contains('six_month') ||
      normalized.contains('six-month') ||
      normalized.contains('6month') ||
      normalized.contains('6_month') ||
      normalized.contains('half') ||
      normalized.contains('半年')) {
    return '半年';
  }
  if (normalized.contains('three_month') ||
      normalized.contains('three-month') ||
      normalized.contains('3month') ||
      normalized.contains('3_month') ||
      normalized.contains('quarter') ||
      normalized.contains('季度')) {
    return '季度';
  }
  if (normalized.contains('two_month') ||
      normalized.contains('two-month') ||
      normalized.contains('2month') ||
      normalized.contains('2_month') ||
      normalized.contains('双月')) {
    return '双月';
  }
  if (normalized.contains('monthly') ||
      normalized.contains('month') ||
      normalized.contains('月度') ||
      normalized.contains('月卡')) {
    return '月度';
  }
  if (normalized.contains('weekly') ||
      normalized.contains('week') ||
      normalized.contains('周度') ||
      normalized.contains('周卡')) {
    return '周度';
  }
  return null;
}

String _packagePeriodLabel(Package package) {
  final period = package.storeProduct.subscriptionPeriod;
  if (period == null || period.isEmpty) {
    return package.packageType == PackageType.lifetime ? '一次购买' : '自动续订';
  }
  return '${_readableSubscriptionPeriod(period)} · 自动续订';
}

String _readableSubscriptionPeriod(String period) {
  return switch (period) {
    'P1W' => '每周',
    'P1M' => '每月',
    'P2M' => '每 2 个月',
    'P3M' => '每季度',
    'P6M' => '每半年',
    'P1Y' => '每年',
    _ => '订阅周期 $period',
  };
}

String? _membershipChipText(
  EntitlementInfo? entitlement,
  SubscriptionStatus? status,
) {
  if (status?.isPermanentPremium == true) {
    return '永久会员已开通';
  }
  if (status?.isPremiumActive == true) {
    final expirationDate = status?.subscriptionExpiresAt?.toLocal();
    if (expirationDate == null) {
      return '永久会员已开通';
    }
    return '会员有效期至：${_formatChineseDate(expirationDate)}';
  }
  if (entitlement == null || !entitlement.isActive) {
    return null;
  }
  return '家庭会员已开通';
}

String _formatChineseDate(DateTime date) {
  return '${date.year}年${date.month}月${date.day}日';
}

String _statusChipText(String status) {
  return switch (status) {
    'trial_expired_unsubscribed' => '试用期已结束',
    'subscribed_active' => '家庭会员已开通',
    'subscription_grace_period' => '账单宽限期内',
    'subscription_expired' => '订阅已过期',
    'offline_cached_active' => '离线模式，稍后会重新确认',
    'offline_unverified_or_expired' => '需要联网确认会员状态',
    'blocked' => '账号访问受限，请联系客服',
    _ => '正在确认订阅状态',
  };
}

class _PaywallSprite {
  const _PaywallSprite._();

  static const asset = 'assets/images/ui/paywall/paywall_cutouts.webp';
  static const sheetSize = Size(1122, 1402);
  static const design = Size(760, 1320);
  /// Compact canvas when permanent membership hides plan cards + restore.
  static const permanentDesign = Size(760, 1080);

  static const cat = Rect.fromLTWH(608, 48, 235, 273);
  static const gift = Rect.fromLTWH(876, 92, 150, 169);
  static const calendar = Rect.fromLTWH(819, 290, 220, 277);
  static const star = Rect.fromLTWH(618, 370, 151, 149);

  static const catTarget = Rect.fromLTWH(82, 58, 238, 276);
  static const giftTarget = Rect.fromLTWH(304, 217, 142, 160);
  static const calendarTarget = Rect.fromLTWH(476, 78, 218, 274);
  static const starTarget = Rect.fromLTWH(416, 321, 126, 124);
  static const titleTarget = Rect.fromLTWH(96, 433, 568, 101);
  static const subtitleTarget = Rect.fromLTWH(142, 526, 476, 66);
  static const benefitFamilyTarget = Rect.fromLTWH(54, 624, 205, 168);
  static const benefitTasksTarget = Rect.fromLTWH(502, 624, 204, 168);
  // Two plan cards centered in the 760-wide design canvas.
  static const monthlyCardTarget = Rect.fromLTWH(118, 880, 248, 130);
  static const annualCardTarget = Rect.fromLTWH(394, 880, 248, 130);
  static const unlockButtonTarget = Rect.fromLTWH(151, 1074, 458, 96);
  static const closeTarget = Rect.fromLTWH(662, 0, 96, 96);
  static const statusTarget = Rect.fromLTWH(120, 1024, 520, 46);
  static const trialChipTarget = Rect.fromLTWH(118, 805, 524, 46);
  static const restoreTarget = Rect.fromLTWH(282, 1180, 196, 48);
  static const complianceTarget = Rect.fromLTWH(82, 1236, 596, 72);

  // Permanent-membership layout: button sits where plan cards were.
  static const permanentUnlockButtonTarget = Rect.fromLTWH(151, 880, 458, 96);
  static const permanentComplianceTarget = Rect.fromLTWH(82, 1000, 596, 60);
}
