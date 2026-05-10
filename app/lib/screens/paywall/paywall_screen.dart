import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../providers/revenue_cat_provider.dart';
import '../../widgets/app_modal_shell.dart';

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
        minimumSafeArea: const EdgeInsets.fromLTRB(12, 16, 12, 16),
        backgroundColor: _PaywallPalette.background,
        borderRadius: const BorderRadius.all(Radius.circular(30)),
        border: Border.all(color: HomePetsDialogTheme.panelBorder, width: 1.5),
        boxShadow: HomePetsDialogTheme.shellShadow,
        child: _PaywallContent(
          heroHeightFactor: 0.30,
          heroMaxHeight: 260,
          onClose: () => Navigator.of(dialogContext).pop(),
        ),
      );
    },
  );
}

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  static const _heroAsset = 'assets/images/ui/paywall_screen.png';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: _PaywallPalette.background,
      body: SafeArea(
        child: _PaywallContent(
          heroHeightFactor: 0.42,
          heroMaxHeight: 360,
          onClose: () => _closePaywall(context),
        ),
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

class _PaywallContent extends ConsumerWidget {
  const _PaywallContent({
    required this.heroHeightFactor,
    required this.heroMaxHeight,
    required this.onClose,
  });

  final double heroHeightFactor;
  final double heroMaxHeight;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(revenueCatProvider);
    final packages = state.packages;
    final selectedPackage = state.selectedPackage;

    return Stack(
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _PaywallHero(
                      assetPath: PaywallScreen._heroAsset,
                      heightFactor: heroHeightFactor,
                      maxHeight: heroMaxHeight,
                    ),
                    const SizedBox(height: 14),
                    const _BenefitGrid(),
                    const SizedBox(height: 18),
                    _PackageSection(
                      state: state,
                      packages: packages,
                      selectedPackage: selectedPackage,
                      onSelectPackage: (package) {
                        ref
                            .read(revenueCatProvider.notifier)
                            .selectPackage(package);
                      },
                      onRetry: () {
                        ref
                            .read(revenueCatProvider.notifier)
                            .refreshOfferings();
                      },
                    ),
                    const SizedBox(height: 12),
                    _StatusBanner(state: state),
                    const SizedBox(height: 14),
                    _UnlockButton(
                      state: state,
                      onPressed: () async {
                        final unlocked = await ref
                            .read(revenueCatProvider.notifier)
                            .purchaseSelectedPackage();
                        if (!context.mounted || !unlocked) {
                          return;
                        }
                        onClose();
                      },
                    ),
                    const SizedBox(height: 10),
                    _RestoreRow(
                      state: state,
                      onRestore: () async {
                        final restored = await ref
                            .read(revenueCatProvider.notifier)
                            .restorePurchases();
                        if (!context.mounted || !restored) {
                          return;
                        }
                        onClose();
                      },
                      onClose: onClose,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '可随时取消，实际价格与续订周期以商店确认页为准',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _PaywallPalette.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(top: 10, right: 14, child: _CloseButton(onPressed: onClose)),
      ],
    );
  }
}

class _PaywallHero extends StatelessWidget {
  const _PaywallHero({
    required this.assetPath,
    required this.heightFactor,
    required this.maxHeight,
  });

  final String assetPath;
  final double heightFactor;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final heroHeight = math.min(screenHeight * heightFactor, maxHeight);

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        height: heroHeight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              assetPath,
              alignment: Alignment.topCenter,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00FFF4DD), Color(0xFFFFF4DD)],
                  stops: [0.62, 1],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BenefitGrid extends StatelessWidget {
  const _BenefitGrid();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _BenefitTile(icon: Icons.groups_rounded, label: '更多家庭成员'),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _BenefitTile(icon: Icons.insights_rounded, label: '成长报告'),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _BenefitTile(icon: Icons.favorite_rounded, label: '专属装饰'),
        ),
      ],
    );
  }
}

class _BenefitTile extends StatelessWidget {
  const _BenefitTile({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 94,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: _PaywallPalette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _PaywallPalette.softBorder, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16865A2E),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: _PaywallPalette.sage, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _PaywallPalette.text,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _PackageSection extends StatelessWidget {
  const _PackageSection({
    required this.state,
    required this.packages,
    required this.selectedPackage,
    required this.onSelectPackage,
    required this.onRetry,
  });

  final RevenueCatState state;
  final List<Package> packages;
  final Package? selectedPackage;
  final ValueChanged<Package> onSelectPackage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.isLoadingOfferings && packages.isEmpty) {
      return const _LoadingPackages();
    }

    if (packages.isEmpty) {
      return _EmptyPackages(
        message: state.errorMessage ?? 'RevenueCat 还没有可展示的 current Offering。',
        onRetry: state.isAvailable ? onRetry : null,
      );
    }

    final recommendedIdentifier = packages.length > 1
        ? packages.first.identifier
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < packages.length; index++) ...[
          _PackageCard(
            package: packages[index],
            displayIndex: index,
            selected: selectedPackage?.identifier == packages[index].identifier,
            recommended: packages[index].identifier == recommendedIdentifier,
            onTap: () => onSelectPackage(packages[index]),
          ),
          if (index != packages.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.package,
    required this.displayIndex,
    required this.selected,
    required this.recommended,
    required this.onTap,
  });

  final Package package;
  final int displayIndex;
  final bool selected;
  final bool recommended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final product = package.storeProduct;
    final priceLabel = '${product.priceString}${_periodSuffix(package)}';

    return Semantics(
      button: true,
      selected: selected,
      label: '${_packageTitle(package, displayIndex)}，$priceLabel',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
          decoration: BoxDecoration(
            color: selected
                ? _PaywallPalette.selectedSurface
                : _PaywallPalette.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected
                  ? _PaywallPalette.sage
                  : _PaywallPalette.packageBorder,
              width: selected ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: selected
                    ? const Color(0x338BA652)
                    : const Color(0x12865A2E),
                blurRadius: selected ? 18 : 12,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _packageTitle(package, displayIndex),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _PaywallPalette.text,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ),
                        ),
                        if (recommended) ...[
                          const SizedBox(width: 8),
                          const _RecommendedPill(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 9),
                    Text(
                      _packageSubtitle(package),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _PaywallPalette.secondaryText,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    priceLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _PaywallPalette.sageDark,
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: selected
                          ? _PaywallPalette.sage
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? _PaywallPalette.sage
                            : _PaywallPalette.packageBorder,
                        width: 2,
                      ),
                    ),
                    child: selected
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 20,
                          )
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecommendedPill extends StatelessWidget {
  const _RecommendedPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _PaywallPalette.pink,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        '推荐',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class _LoadingPackages extends StatelessWidget {
  const _LoadingPackages();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      decoration: BoxDecoration(
        color: _PaywallPalette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _PaywallPalette.softBorder),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
          SizedBox(width: 12),
          Text(
            '正在读取会员套餐...',
            style: TextStyle(
              color: _PaywallPalette.secondaryText,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPackages extends StatelessWidget {
  const _EmptyPackages({required this.message, required this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _PaywallPalette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _PaywallPalette.softBorder),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _PaywallPalette.secondaryText,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: _PaywallPalette.sageDark,
                side: const BorderSide(color: _PaywallPalette.sage, width: 1.5),
              ),
              child: const Text('重新加载套餐'),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.state});

  final RevenueCatState state;

  @override
  Widget build(BuildContext context) {
    final message = _messageForState(state);
    if (message == null) {
      return const SizedBox.shrink();
    }

    final isError =
        state.errorMessage != null ||
        state.purchaseError != null ||
        state.restoreError != null;
    final isSuccess = state.isPremiumActive;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: isSuccess
            ? const Color(0xFFEFF5DD)
            : isError
            ? const Color(0xFFFFECE7)
            : const Color(0xFFFFF7E8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSuccess
              ? const Color(0xFFC8DB98)
              : isError
              ? const Color(0xFFF0B1A2)
              : const Color(0xFFE9D5AD),
        ),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isSuccess
              ? _PaywallPalette.sageDark
              : isError
              ? const Color(0xFFB2604E)
              : _PaywallPalette.secondaryText,
          fontSize: 14,
          fontWeight: FontWeight.w800,
          height: 1.3,
        ),
      ),
    );
  }

  String? _messageForState(RevenueCatState state) {
    if (state.isPremiumActive) {
      return '家庭高级版已开通。';
    }
    if (state.isPurchasing) {
      return '正在连接商店，请稍候...';
    }
    if (state.isRestoring) {
      return '正在恢复购买，请稍候...';
    }
    return state.purchaseError ?? state.restoreError ?? state.errorMessage;
  }
}

class _UnlockButton extends StatelessWidget {
  const _UnlockButton({required this.state, required this.onPressed});

  final RevenueCatState state;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final busy = state.isPurchasing || state.isRestoring;
    final label = state.isPremiumActive
        ? '已开通'
        : state.isPurchasing
        ? '开通中...'
        : '立即开通';

    return FilledButton(
      onPressed: state.canPurchase ? onPressed : null,
      style: FilledButton.styleFrom(
        backgroundColor: _PaywallPalette.sage,
        disabledBackgroundColor: _PaywallPalette.sage.withValues(alpha: 0.42),
        foregroundColor: _PaywallPalette.text,
        disabledForegroundColor: _PaywallPalette.text.withValues(alpha: 0.48),
        padding: const EdgeInsets.symmetric(vertical: 17),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
      ),
      child: busy
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.8,
                color: _PaywallPalette.text,
              ),
            )
          : Text(label),
    );
  }
}

class _RestoreRow extends StatelessWidget {
  const _RestoreRow({
    required this.state,
    required this.onRestore,
    required this.onClose,
  });

  final RevenueCatState state;
  final VoidCallback onRestore;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final disabled =
        state.isPurchasing || state.isRestoring || state.isPremiumActive;

    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: disabled ? null : onRestore,
            style: TextButton.styleFrom(
              foregroundColor: _PaywallPalette.text,
              disabledForegroundColor: _PaywallPalette.muted,
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            child: const Text('恢复购买'),
          ),
        ),
        Container(width: 1, height: 22, color: _PaywallPalette.softBorder),
        Expanded(
          child: TextButton(
            onPressed: onClose,
            style: TextButton.styleFrom(
              foregroundColor: _PaywallPalette.text,
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            child: const Text('稍后再说'),
          ),
        ),
      ],
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onPressed});

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
          HomePetsDialogTheme.closeIconAsset,
          width: 48,
          height: 48,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}

String _packageTitle(Package package, int displayIndex) {
  return switch (package.packageType) {
    PackageType.weekly => '周度会员',
    PackageType.monthly => '月度会员',
    PackageType.twoMonth => '双月会员',
    PackageType.threeMonth => '季度会员',
    PackageType.sixMonth => '半年会员',
    PackageType.annual => '年度会员',
    PackageType.lifetime => '永久会员',
    PackageType.custom || PackageType.unknown => '会员套餐 ${displayIndex + 1}',
  };
}

String _periodSuffix(Package package) {
  final period = package.storeProduct.subscriptionPeriod;
  if (period != null) {
    return switch (period) {
      'P1W' => '/周',
      'P1M' => '/月',
      'P2M' => '/2个月',
      'P3M' => '/季',
      'P6M' => '/半年',
      'P1Y' => '/年',
      _ => '',
    };
  }

  return switch (package.packageType) {
    PackageType.weekly => '/周',
    PackageType.monthly => '/月',
    PackageType.twoMonth => '/2个月',
    PackageType.threeMonth => '/季',
    PackageType.sixMonth => '/半年',
    PackageType.annual => '/年',
    PackageType.lifetime || PackageType.custom || PackageType.unknown => '',
  };
}

String _packageSubtitle(Package package) {
  final product = package.storeProduct;
  if (package.packageType == PackageType.annual &&
      product.pricePerMonthString != null) {
    return '折合 ${product.pricePerMonthString}/月';
  }
  if (package.packageType == PackageType.sixMonth &&
      product.pricePerMonthString != null) {
    return '折合 ${product.pricePerMonthString}/月';
  }
  if (package.packageType == PackageType.lifetime) {
    return '一次购买，长期使用高级权益';
  }
  return '自动续订，可在商店账号中管理';
}

class _PaywallPalette {
  const _PaywallPalette._();

  static const background = Color(0xFFFFF4DD);
  static const surface = Color(0xFFFFFBF0);
  static const selectedSurface = Color(0xFFF9F4D9);
  static const softBorder = Color(0xFFE7CFA8);
  static const packageBorder = Color(0xFFD7B88D);
  static const text = Color(0xFF4F3521);
  static const secondaryText = Color(0xFF8A6B4F);
  static const muted = Color(0xFFA88A6B);
  static const sage = Color(0xFFAFCB62);
  static const sageDark = Color(0xFF789345);
  static const pink = Color(0xFFECA29A);
}
