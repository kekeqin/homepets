import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_error_helper.dart';
import '../../providers/auth_provider.dart';
import '../member/member_detail_screen.dart';

class FamilyScreen extends ConsumerStatefulWidget {
  const FamilyScreen({super.key});

  @override
  ConsumerState<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends ConsumerState<FamilyScreen>
    with SingleTickerProviderStateMixin {
  static const _backgroundAsset = 'assets/images/ui/family_link.png';
  static const _dogHeadAsset = 'assets/images/ui/dog_head.png';
  static const _cardAssets = <String>[
    'assets/images/ui/member_card_1.png',
    'assets/images/ui/member_card_2.png',
    'assets/images/ui/member_card_3.png',
    'assets/images/ui/member_card_4.png',
  ];
  static const _portraitAssets = <String>[
    'assets/images/ui/person_male.png',
    'assets/images/ui/person_boy.png',
    'assets/images/ui/person_girl.png',
    'assets/images/ui/person_female.png',
  ];
  static const _cardAspectRatio = 385 / 598;
  static const _portraitStyles = <_PortraitStyle>[
    _PortraitStyle(scale: 1.12, dx: -0.01, dy: 0.05),
    _PortraitStyle(scale: 1.14, dx: 0.00, dy: 0.09),
    _PortraitStyle(scale: 1.44, dx: -0.01, dy: 0.13),
    _PortraitStyle(scale: 1.16, dx: 0.00, dy: 0.08),
  ];

  static const _maxDisplayMembers = 8;

  final List<_FamilyMember> _members = <_FamilyMember>[];
  bool _loading = true;
  bool _hasFamily = false;
  bool _addingMember = false;
  String _familyName = '\u5bb6\u5ead';

  late final AnimationController _entryController;
  late final Animation<double> _backgroundOpacity;
  late final Animation<double> _backgroundScale;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1150),
    );
    _backgroundOpacity = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0, 0.42, curve: Curves.easeOut),
    );
    _backgroundScale = Tween<double>(begin: 1.04, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0, 0.54, curve: Curves.easeOutCubic),
      ),
    );
    _loadFamily();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  Future<void> _loadFamily() async {
    final authState = ref.read(authProvider);
    final familyId = authState.user?.familyId;

    if (familyId == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _hasFamily = false;
        _members.clear();
      });
      _playEntryAnimation();
      return;
    }

    setState(() {
      _loading = true;
      _hasFamily = true;
    });

    try {
      final dio = ref.read(apiClientProvider).dio;
      final responses = await Future.wait<dynamic>([
        dio.get('/api/families/$familyId'),
        dio.get('/api/families/$familyId/members'),
      ]);

      if (!mounted) {
        return;
      }

      final familyData = responses[0].data;
      final membersData = responses[1].data;
      final parsedMembers = <_FamilyMember>[];

      if (membersData is List) {
        for (final dynamic item in membersData) {
          if (item is! Map) {
            continue;
          }
          final memberMap = Map<String, dynamic>.from(item);
          final id = _toInt(memberMap['id']);
          if (id == null) {
            continue;
          }
          final nickname = (memberMap['nickname'] ?? '').toString().trim();
          final role = (memberMap['role'] ?? 'member').toString().trim();
          parsedMembers.add(
            _FamilyMember(
              id: id,
              nickname: nickname.isEmpty ? '\u6210\u5458$id' : nickname,
              role: role.isEmpty ? 'member' : role,
            ),
          );
        }
      }

      parsedMembers.sort((a, b) => a.id.compareTo(b.id));

      var familyName = '\u5bb6\u5ead';
      if (familyData is Map && familyData['name'] is String) {
        final value = (familyData['name'] as String).trim();
        if (value.isNotEmpty) {
          familyName = value;
        }
      }

      setState(() {
        _loading = false;
        _hasFamily = true;
        _familyName = familyName;
        _members
          ..clear()
          ..addAll(parsedMembers);
      });
      _playEntryAnimation();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
      });
      showFriendlyApiErrorSnackBar(
        context,
        error,
        fallbackMessage:
            '\u52a0\u8f7d\u5bb6\u5ead\u4fe1\u606f\u5931\u8d25\uff0c\u8bf7\u7a0d\u540e\u91cd\u8bd5',
      );
    }
  }

  int? _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  void _playEntryAnimation() {
    if (!mounted) {
      return;
    }
    _entryController.forward(from: 0);
  }

  Future<void> _openMemberDetail(_FamilyMember member) async {
    await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => MemberDetailScreen(
          memberId: member.id,
          nickname: member.nickname,
          role: member.role,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    await _loadFamily();
  }

  Future<void> _onAddMemberTap(AuthState authState) async {
    if (_loading || _addingMember) {
      return;
    }

    final user = authState.user;
    final familyId = user?.familyId;
    final canManageMembers = user?.isAdmin == true && !authState.viewOnly;

    if (!canManageMembers || familyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '\u53ea\u6709\u5bb6\u957f\u53ef\u4ee5\u6dfb\u52a0\u6210\u5458',
          ),
        ),
      );
      return;
    }

    if (_members.length >= _maxDisplayMembers) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '\u5f53\u524d\u5bb6\u5ead\u6700\u591a\u652f\u6301 8 \u4f4d\u6210\u5458',
          ),
        ),
      );
      return;
    }

    final nickname = await _showAddMemberDialog();
    if (nickname == null) {
      return;
    }

    setState(() {
      _addingMember = true;
    });

    try {
      final dio = ref.read(apiClientProvider).dio;
      await dio.post(
        '/api/families/$familyId/members',
        data: {'nickname': nickname},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('\u5df2\u6dfb\u52a0\u6210\u5458\uff1a$nickname'),
          ),
        );
      }
      await _loadFamily();
    } catch (error) {
      if (!mounted) {
        return;
      }
      showFriendlyApiErrorSnackBar(
        context,
        error,
        fallbackMessage:
            '\u6dfb\u52a0\u6210\u5458\u5931\u8d25\uff0c\u8bf7\u7a0d\u540e\u91cd\u8bd5',
      );
    } finally {
      if (mounted) {
        setState(() {
          _addingMember = false;
        });
      }
    }
  }

  Future<String?> _showAddMemberDialog() async {
    return showDialog<String>(
      context: context,
      builder: (_) => const _AddMemberDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF4E5D2),
      body: Stack(
        children: [
          Positioned.fill(child: _buildBackground()),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _FamilyTopBar(
                  title: _familyName,
                  showRefresh: authState.isAuthenticated && _hasFamily,
                  loading: _loading,
                  onRefresh: _loadFamily,
                ),
                Expanded(child: _buildBody(authState)),
                if (authState.isAuthenticated &&
                    _hasFamily &&
                    authState.user?.isAdmin == true &&
                    !authState.viewOnly)
                  _FamilyAddMemberButton(
                    loading: _addingMember || _loading,
                    onTap: () => _onAddMemberTap(authState),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return AnimatedBuilder(
      animation: _entryController,
      builder: (context, child) {
        return Opacity(
          opacity: _backgroundOpacity.value,
          child: Transform.scale(scale: _backgroundScale.value, child: child),
        );
      },
      child: Image.asset(
        _backgroundAsset,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        filterQuality: FilterQuality.high,
      ),
    );
  }

  Widget _buildBody(AuthState authState) {
    if (!authState.isAuthenticated) {
      return const _FamilyHintCard(
        title: '\u8bf7\u5148\u767b\u5f55',
        message:
            '\u767b\u5f55\u540e\u53ef\u67e5\u770b\u5bb6\u5ead\u6210\u5458\u5e76\u8fdb\u5165\u4eba\u5458\u8be6\u60c5\u9875\u3002',
      );
    }

    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF74512D)),
      );
    }

    if (!_hasFamily) {
      return const _FamilyHintCard(
        title: '\u6682\u672a\u52a0\u5165\u5bb6\u5ead',
        message:
            '\u8bf7\u5148\u521b\u5efa\u5bb6\u5ead\u6216\u901a\u8fc7\u9080\u8bf7\u7801\u52a0\u5165\u5bb6\u5ead\u3002',
      );
    }

    final visibleMembers = List<_FamilyMember?>.generate(
      _maxDisplayMembers,
      (index) => index < _members.length ? _members[index] : null,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 900;
        final sidePadding = isTablet ? 44.0 : 22.0;
        final topPadding = isTablet ? 18.0 : 12.0;
        final spacing = isTablet ? 30.0 : 18.0;

        final contentWidth = constraints.maxWidth - sidePadding * 2;
        final baseCellWidth = (contentWidth - spacing) / 2;
        final cardScale = isTablet ? 0.94 : 0.92;
        final cellWidth = baseCellWidth * cardScale;

        const previewRowCount = 2;
        final contentHeight = constraints.maxHeight - topPadding * 2;
        final maxCellHeight =
            (contentHeight - (spacing * (previewRowCount - 1))) /
            previewRowCount;
        final naturalCellHeight = cellWidth / _cardAspectRatio;
        final cellHeight = naturalCellHeight > maxCellHeight
            ? maxCellHeight
            : naturalCellHeight;

        final rowCount = (visibleMembers.length / 2).ceil();

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: EdgeInsets.fromLTRB(
            sidePadding,
            topPadding,
            sidePadding,
            topPadding,
          ),
          child: Column(
            children: [
              for (var rowIndex = 0; rowIndex < rowCount; rowIndex++) ...[
                _buildCardRow(
                  members: visibleMembers.sublist(
                    rowIndex * 2,
                    (rowIndex * 2) + 2,
                  ),
                  rowOffset: rowIndex * 2,
                  cellWidth: cellWidth,
                  cellHeight: cellHeight,
                  spacing: spacing,
                ),
                if (rowIndex < rowCount - 1) SizedBox(height: spacing),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildCardRow({
    required List<_FamilyMember?> members,
    required int rowOffset,
    required double cellWidth,
    required double cellHeight,
    required double spacing,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < members.length; index++) ...[
          SizedBox(
            width: cellWidth,
            height: cellHeight,
            child: _buildAnimatedSlot(
              index: rowOffset + index,
              member: members[index],
            ),
          ),
          if (index == 0) SizedBox(width: spacing),
        ],
      ],
    );
  }

  Widget _buildAnimatedSlot({
    required int index,
    required _FamilyMember? member,
  }) {
    final start = (0.18 + index * 0.08).clamp(0.0, 0.82).toDouble();
    final end = (start + 0.32).clamp(0.0, 1.0).toDouble();
    final moveCurve = CurvedAnimation(
      parent: _entryController,
      curve: Interval(start, end, curve: Curves.easeOutBack),
    );
    final fadeCurve = CurvedAnimation(
      parent: _entryController,
      curve: Interval(start, end, curve: Curves.easeOut),
    );

    final cardAsset = _cardAssets[index % _cardAssets.length];
    final portraitAsset = _portraitAssets[index % _portraitAssets.length];
    final portraitStyle = _portraitStyles[index % _portraitStyles.length];

    return FadeTransition(
      opacity: fadeCurve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(moveCurve),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.93, end: 1.0).animate(moveCurve),
          child: member == null
              ? _FamilyEmptyCard(cardAsset: cardAsset)
              : _FamilyMemberCard(
                  member: member,
                  cardAsset: cardAsset,
                  portraitAsset: portraitAsset,
                  portraitStyle: portraitStyle,
                  dogHeadAsset: _dogHeadAsset,
                  onDetailTap: () => _openMemberDetail(member),
                ),
        ),
      ),
    );
  }
}

class _FamilyMember {
  const _FamilyMember({
    required this.id,
    required this.nickname,
    required this.role,
  });

  final int id;
  final String nickname;
  final String role;
}

class _PortraitStyle {
  const _PortraitStyle({
    required this.scale,
    required this.dx,
    required this.dy,
  });

  final double scale;
  final double dx;
  final double dy;
}

class _FamilyTopBar extends StatelessWidget {
  const _FamilyTopBar({
    required this.title,
    required this.showRefresh,
    required this.loading,
    required this.onRefresh,
  });

  final String title;
  final bool showRefresh;
  final bool loading;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF2E5CF).withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF7A5733).withValues(alpha: 0.45),
          ),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () => context.go('/home'),
              tooltip: '\u8fd4\u56de\u4e3b\u9875',
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Color(0xFF694426),
              ),
              visualDensity: VisualDensity.compact,
            ),
            const Icon(Icons.family_restroom_rounded, color: Color(0xFF694426)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$title\u00b7\u5bb6\u5ead',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF57351B),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (showRefresh)
              IconButton(
                onPressed: loading ? null : onRefresh,
                tooltip: '\u5237\u65b0',
                icon: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.1,
                          color: Color(0xFF57351B),
                        ),
                      )
                    : const Icon(Icons.refresh_rounded),
              ),
          ],
        ),
      ),
    );
  }
}

class _FamilyAddMemberButton extends StatelessWidget {
  const _FamilyAddMemberButton({required this.loading, required this.onTap});

  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE9D5AC), Color(0xFFE1C591)],
          ),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: const Color(0xFF6E4B2D).withValues(alpha: 0.6),
            width: 1.2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x4A6E4B2D),
              offset: Offset(0, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: loading ? null : onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (loading)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        color: Color(0xFF5A3A21),
                      ),
                    )
                  else
                    const Icon(
                      Icons.person_add_alt_1_rounded,
                      size: 20,
                      color: Color(0xFF5A3A21),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    loading
                        ? '\u6dfb\u52a0\u4e2d...'
                        : '\u6dfb\u52a0\u6210\u5458',
                    style: const TextStyle(
                      color: Color(0xFF5A3A21),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FamilyMemberCard extends StatelessWidget {
  const _FamilyMemberCard({
    required this.member,
    required this.cardAsset,
    required this.portraitAsset,
    required this.portraitStyle,
    required this.dogHeadAsset,
    required this.onDetailTap,
  });

  final _FamilyMember member;
  final String cardAsset;
  final String portraitAsset;
  final _PortraitStyle portraitStyle;
  final String dogHeadAsset;
  final VoidCallback onDetailTap;

  String get _roleText {
    if (member.role == 'admin') {
      return '\u5bb6\u957f';
    }
    return '\u6210\u5458';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onDetailTap,
        borderRadius: BorderRadius.circular(24),
        child: AspectRatio(
          aspectRatio: 385 / 598,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned.fill(
                child: Image.asset(
                  cardAsset,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
              Positioned(
                top: 16,
                left: 14,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: const Color(0xFF694426).withValues(alpha: 0.35),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    child: Text(
                      '${member.nickname} \u00b7 $_roleText',
                      style: const TextStyle(
                        color: Color(0xFF57351B),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 12,
                top: 44,
                width: 74,
                height: 74,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.98,
                    child: Image.asset(
                      dogHeadAsset,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 30,
                right: 30,
                top: 90,
                bottom: 86,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Transform.translate(
                      offset: Offset(
                        constraints.maxWidth * portraitStyle.dx,
                        constraints.maxHeight * portraitStyle.dy,
                      ),
                      child: Transform.scale(
                        scale: portraitStyle.scale,
                        alignment: Alignment.bottomCenter,
                        child: Image.asset(
                          portraitAsset,
                          fit: BoxFit.contain,
                          alignment: Alignment.bottomCenter,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                left: 72,
                right: 72,
                bottom: 24,
                height: 46,
                child: _DetailTapOverlay(onTap: onDetailTap),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FamilyEmptyCard extends StatelessWidget {
  const _FamilyEmptyCard({required this.cardAsset});

  final String cardAsset;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 385 / 598,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned.fill(
            child: Image.asset(
              cardAsset,
              fit: BoxFit.contain,
              color: Colors.white.withValues(alpha: 0.25),
              colorBlendMode: BlendMode.srcATop,
              filterQuality: FilterQuality.high,
            ),
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                '\u5f85\u52a0\u5165\u6210\u5458',
                style: TextStyle(
                  color: Color(0xFF644124),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailTapOverlay extends StatelessWidget {
  const _DetailTapOverlay({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFE7D19A).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFF6C482B).withValues(alpha: 0.55),
          width: 1.2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          splashColor: const Color(0xFF7A5733).withValues(alpha: 0.18),
          highlightColor: const Color(0xFF7A5733).withValues(alpha: 0.08),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '\u4eba\u5458\u8be6\u60c5',
                  style: TextStyle(
                    color: Color(0xFF57351B),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.person, size: 13, color: Color(0xFF57351B)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddMemberDialog extends StatefulWidget {
  const _AddMemberDialog();

  @override
  State<_AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<_AddMemberDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _validationMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFF8EED8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        '\u6dfb\u52a0\u6210\u5458',
        style: TextStyle(
          color: Color(0xFF5A3A21),
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
      content: TextField(
        controller: _controller,
        maxLength: 20,
        autofocus: true,
        onChanged: (_) {
          if (_validationMessage != null) {
            setState(() => _validationMessage = null);
          }
        },
        decoration: InputDecoration(
          labelText: '\u6210\u5458\u6635\u79f0',
          hintText: '\u4f8b\u5982\uff1a\u5c0f\u5b9d',
          errorText: _validationMessage,
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.72),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: const Color(0xFF7A5733).withValues(alpha: 0.4),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: const Color(0xFF7A5733).withValues(alpha: 0.4),
            ),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide(color: Color(0xFF7A5733), width: 1.3),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('\u53d6\u6d88'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF7A5733),
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            final nickname = _controller.text.trim();
            if (nickname.isEmpty) {
              setState(() {
                _validationMessage =
                    '\u6210\u5458\u6635\u79f0\u4e0d\u80fd\u4e3a\u7a7a';
              });
              return;
            }
            Navigator.of(context).pop(nickname);
          },
          child: const Text('\u6dfb\u52a0'),
        ),
      ],
    );
  }
}

class _FamilyHintCard extends StatelessWidget {
  const _FamilyHintCard({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFF7EDD9).withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFF7A5733).withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: Color(0xFF5C3C22),
                size: 30,
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF5C3C22),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF6A4A31),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
