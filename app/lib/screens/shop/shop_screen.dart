import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_error_helper.dart';
import '../../providers/auth_provider.dart';

class _ShopPalette {
  static const woodDark = Color(0xFF8C643D);
  static const paper = Color(0xFFF7F0DE);
  static const text = Color(0xFF503A23);
  static const muted = Color(0xFF7D664A);
  static const green = Color(0xFF4D8C54);
  static const greenDark = Color(0xFF2E6636);
  static const softGreen = Color(0xFFDCEACF);
}

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key, this.embedded = false, this.onClose});

  final bool embedded;
  final VoidCallback? onClose;

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen>
    with SingleTickerProviderStateMixin {
  static const _backgroundAsset = 'assets/images/ui/green.png';
  static const _storeAsset = 'assets/images/ui/store_foreground.png';
  static const _pageSize = 4;

  final List<Map<String, dynamic>> _items = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> _myItems = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> _members = <Map<String, dynamic>>[];

  bool _loading = true;
  int? _selectedMemberId;
  int _selectedMemberPoints = 0;
  int _pageIndex = 0;

  late final AnimationController _entryController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0, 0.62, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
          CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
        );

    _entryController.forward();
    _loadData();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _toMapList(dynamic data) {
    if (data is! List) {
      return const <Map<String, dynamic>>[];
    }
    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  int? _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  Future<void> _loadData() async {
    final user = ref.read(authProvider).user;

    if (!mounted) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final dio = ref.read(apiClientProvider).dio;
      final userParams = _selectedMemberId != null
          ? <String, dynamic>{'user_id': _selectedMemberId}
          : <String, dynamic>{};

      final responses = await Future.wait<dynamic>([
        dio.get('/api/shop/items', queryParameters: userParams),
        dio.get('/api/shop/my-items', queryParameters: userParams),
        if (user?.familyId != null)
          dio.get('/api/families/${user!.familyId}/members'),
      ]);

      if (!mounted) {
        return;
      }

      final items = _toMapList(responses[0].data);
      final myItems = _toMapList(responses[1].data);
      final members = responses.length > 2
          ? _toMapList(responses[2].data)
          : <Map<String, dynamic>>[];

      int? selectedMemberId = _selectedMemberId;
      var selectedPoints = _selectedMemberPoints;

      if (members.isNotEmpty) {
        selectedMemberId ??=
            members.firstWhere(
                  (member) => member['id'] == user?.id,
                  orElse: () => members.first,
                )['id']
                as int?;

        final selectedMember = members.firstWhere(
          (member) => member['id'] == selectedMemberId,
          orElse: () => <String, dynamic>{'points': 0},
        );
        selectedPoints = selectedMember['points'] as int? ?? 0;
      } else {
        selectedMemberId = null;
        selectedPoints = user?.points ?? 0;
      }

      final totalPages = math.max(
        1,
        (items.length + _pageSize - 1) ~/ _pageSize,
      );
      final clampedPageIndex = _pageIndex.clamp(0, totalPages - 1);

      setState(() {
        _items
          ..clear()
          ..addAll(items);
        _myItems
          ..clear()
          ..addAll(myItems);
        _members
          ..clear()
          ..addAll(members);
        _selectedMemberId = selectedMemberId;
        _selectedMemberPoints = selectedPoints;
        _pageIndex = clampedPageIndex;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      showFriendlyApiErrorSnackBar(
        context,
        error,
        fallbackMessage: '加载商店失败，请稍后重试',
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  int get _totalPages =>
      math.max(1, (_items.length + _pageSize - 1) ~/ _pageSize);

  List<Map<String, dynamic>?> get _currentPageSlots {
    final start = _pageIndex * _pageSize;
    final end = math.min(start + _pageSize, _items.length);
    final pageItems = start < end
        ? _items.sublist(start, end)
        : const <Map<String, dynamic>>[];

    return List<Map<String, dynamic>?>.generate(
      _pageSize,
      (index) => index < pageItems.length ? pageItems[index] : null,
    );
  }

  bool _isOwned(Map<String, dynamic> item) {
    if (item['owned'] == true) {
      return true;
    }

    final itemId = _toInt(item['id']);
    if (itemId == null) {
      return false;
    }

    for (final myItem in _myItems) {
      final ownedId = _toInt(myItem['item_id']) ?? _toInt(myItem['id']);
      if (ownedId == itemId) {
        return true;
      }
    }

    return false;
  }

  Future<void> _buyItem(Map<String, dynamic> item) async {
    final itemId = _toInt(item['id']);
    final name = (item['name'] ?? '未知道具').toString();
    final price = _toInt(item['price']) ?? 0;

    if (itemId == null) {
      return;
    }

    if (_selectedMemberPoints < price) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('积分不足，先去完成任务吧')));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('确认购买'),
          content: Text('使用 $price 积分购买「$name」？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('购买'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      final dio = ref.read(apiClientProvider).dio;
      final data = <String, dynamic>{'item_id': itemId};
      if (_selectedMemberId != null) {
        data['for_user_id'] = _selectedMemberId;
      }

      final response = await dio.post('/api/shop/buy', data: data);
      await ref.read(authProvider.notifier).refreshUser();
      await _loadData();

      if (!mounted) {
        return;
      }

      final remaining = response.data['remaining_points'];
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('购买成功，剩余积分：$remaining')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      showFriendlyApiErrorSnackBar(
        context,
        error,
        fallbackMessage: '购买失败，请稍后重试',
      );
    }
  }

  Future<void> _onSlotTap(Map<String, dynamic>? item) async {
    if (item == null) {
      return;
    }

    if (_isOwned(item)) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已拥有该商品，可在背包中查看')));
      return;
    }

    await _buyItem(item);
  }

  void _prevPage() {
    if (_pageIndex <= 0) {
      return;
    }
    setState(() {
      _pageIndex -= 1;
    });
  }

  void _nextPage() {
    if (_pageIndex >= _totalPages - 1) {
      return;
    }
    setState(() {
      _pageIndex += 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoggedIn = authState.isAuthenticated;
    final content = _buildSceneContent(isLoggedIn: isLoggedIn);

    if (widget.embedded) {
      return _buildEmbeddedShell(content);
    }

    return Scaffold(backgroundColor: _ShopPalette.softGreen, body: content);
  }

  Widget _buildSceneContent({required bool isLoggedIn}) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: Image.asset(
            _backgroundAsset,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.high,
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.12),
                    Colors.white.withValues(alpha: 0.02),
                  ],
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: Column(
                  children: [
                    _buildTopInfo(isLoggedIn: isLoggedIn),
                    const SizedBox(height: 6),
                    Expanded(
                      child: isLoggedIn ? _buildShopBody() : _buildGuestState(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmbeddedShell(Widget child) {
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        minimum: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= 900;
            final borderRadius = BorderRadius.circular(isTablet ? 34 : 28);
            final maxWidth = isTablet ? 900.0 : constraints.maxWidth;
            final maxHeight = isTablet
                ? math.min(constraints.maxHeight, 920.0)
                : constraints.maxHeight;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxWidth,
                  maxHeight: maxHeight,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _ShopPalette.softGreen,
                    borderRadius: borderRadius,
                    border: Border.all(
                      color: _ShopPalette.woodDark.withValues(alpha: 0.35),
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                      BoxShadow(
                        color: const Color(0xFF4B5C3C).withValues(alpha: 0.12),
                        blurRadius: 0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(borderRadius: borderRadius, child: child),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _handleLeadingAction(BuildContext context) {
    if (widget.embedded) {
      final onClose = widget.onClose;
      if (onClose != null) {
        onClose();
        return;
      }
      Navigator.of(context).maybePop();
      return;
    }

    context.go('/home');
  }

  Widget _buildTopInfo({required bool isLoggedIn}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _ShopPalette.woodDark.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _handleLeadingAction(context),
            icon: Icon(
              widget.embedded ? Icons.close_rounded : Icons.arrow_back_rounded,
            ),
            color: _ShopPalette.text,
            tooltip: widget.embedded ? '关闭' : '返回首页',
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 2),
          const Text(
            '商店',
            style: TextStyle(
              color: _ShopPalette.text,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          if (isLoggedIn && _members.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _MemberDropdown(
                members: _members,
                selectedMemberId: _selectedMemberId,
                onChanged: (memberId) {
                  if (memberId == null) {
                    return;
                  }
                  final member = _members.firstWhere(
                    (item) => item['id'] == memberId,
                    orElse: () => const <String, dynamic>{'points': 0},
                  );
                  setState(() {
                    _selectedMemberId = memberId;
                    _selectedMemberPoints = _toInt(member['points']) ?? 0;
                    _pageIndex = 0;
                  });
                  _loadData();
                },
              ),
            ),
          if (isLoggedIn)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _ShopPalette.paper,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: _ShopPalette.woodDark.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.bolt_rounded,
                    size: 15,
                    color: _ShopPalette.text,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _selectedMemberPoints.toString(),
                    style: const TextStyle(
                      color: _ShopPalette.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(width: 6),
          IconButton(
            onPressed: _loading ? null : _loadData,
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
            color: _ShopPalette.text,
            tooltip: '刷新',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildShopBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 760;

        return Column(
          children: [
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isTablet ? 760 : 520),
                  child: AspectRatio(
                    aspectRatio: 1024 / 1536,
                    child: _buildStallScene(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildPagerControls(),
          ],
        );
      },
    );
  }

  Widget _buildStallScene() {
    final slots = _currentPageSlots;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        Widget pos({
          required double left,
          required double top,
          required double w,
          required double h,
          required Widget child,
        }) {
          return Positioned(
            left: width * left,
            top: height * top,
            width: width * w,
            height: height * h,
            child: child,
          );
        }

        return Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                _storeAsset,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
            pos(
              left: 0.194,
              top: 0.246,
              w: 0.284,
              h: 0.150,
              child: _buildStoreSlotCard(slots[0]),
            ),
            pos(
              left: 0.522,
              top: 0.246,
              w: 0.284,
              h: 0.150,
              child: _buildStoreSlotCard(slots[1]),
            ),
            pos(
              left: 0.194,
              top: 0.418,
              w: 0.284,
              h: 0.150,
              child: _buildStoreSlotCard(slots[2]),
            ),
            pos(
              left: 0.522,
              top: 0.418,
              w: 0.284,
              h: 0.150,
              child: _buildStoreSlotCard(slots[3]),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStoreSlotCard(Map<String, dynamic>? item) {
    if (item == null) {
      return const SizedBox.shrink();
    }

    final name = (item['name'] ?? '\u672A\u77E5\u9053\u5177').toString();
    final emoji = (item['emoji'] ?? '\u{1F381}').toString();
    final price = _toInt(item['price']) ?? 0;
    final owned = _isOwned(item);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onSlotTap(item),
        borderRadius: BorderRadius.circular(12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _ShopPalette.paper.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _ShopPalette.woodDark.withValues(alpha: 0.18),
              width: 1.0,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 30)),
                const SizedBox(height: 2),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _ShopPalette.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  owned ? '\u5DF2\u62E5\u6709' : '$price \u79EF\u5206',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: owned ? _ShopPalette.greenDark : _ShopPalette.green,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPagerControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _PagerButton(
          icon: Icons.chevron_left_rounded,
          enabled: _pageIndex > 0,
          onTap: _prevPage,
        ),
        Text(
          '${_pageIndex + 1} / $_totalPages 页',
          style: const TextStyle(
            color: _ShopPalette.text,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            shadows: [Shadow(color: Colors.white, blurRadius: 6)],
          ),
        ),
        _PagerButton(
          icon: Icons.chevron_right_rounded,
          enabled: _pageIndex < _totalPages - 1,
          onTap: _nextPage,
        ),
      ],
    );
  }

  Widget _buildGuestState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.76),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: _ShopPalette.woodDark.withValues(alpha: 0.2),
          ),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.storefront_rounded,
              size: 42,
              color: _ShopPalette.woodDark,
            ),
            SizedBox(height: 10),
            Text(
              '登录后可进入商店',
              style: TextStyle(
                color: _ShopPalette.text,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 6),
            Text(
              '可浏览四宫格商品并按页翻动',
              style: TextStyle(
                color: _ShopPalette.muted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberDropdown extends StatelessWidget {
  const _MemberDropdown({
    required this.members,
    required this.selectedMemberId,
    required this.onChanged,
  });

  final List<Map<String, dynamic>> members;
  final int? selectedMemberId;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _ShopPalette.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _ShopPalette.woodDark.withValues(alpha: 0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectedMemberId,
          borderRadius: BorderRadius.circular(16),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          icon: const Icon(Icons.expand_more, color: _ShopPalette.muted),
          items: members
              .map(
                (member) => DropdownMenuItem<int>(
                  value: member['id'] as int,
                  child: Text(
                    (member['nickname'] ?? '').toString(),
                    style: const TextStyle(
                      color: _ShopPalette.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _PagerButton extends StatelessWidget {
  const _PagerButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: enabled ? 0.96 : 0.60),
          shape: BoxShape.circle,
          border: Border.all(color: _ShopPalette.woodDark, width: 2),
        ),
        child: Icon(
          icon,
          size: 34,
          color: enabled ? _ShopPalette.text : _ShopPalette.muted,
        ),
      ),
    );
  }
}
