import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_error_helper.dart';
import '../../providers/auth_provider.dart';
import '../../providers/family_provider.dart';
import '../member/member_detail_screen.dart';
import 'dialogs/add_member_dialog.dart';
import 'dialogs/pet_name_dialog.dart';
import 'dialogs/pet_selection_dialog.dart';
import 'models/family_member_view_data.dart';
import 'models/family_screen_state.dart';
import 'widgets/family_hint_card.dart';
import 'widgets/family_member_grid.dart';

class _FamilyPalette {
  static const pageTop = Color(0xFFFFF2E4);
  static const pageBottom = Color(0xFFFFFBF6);
  static const shell = Color(0xFFFFF8F1);
  static const shellBorder = Color(0xFFF0D9C2);
  static const shellShadow = Color(0x2A7B4E20);
  static const text = Color(0xFF6B3608);
  static const muted = Color(0xFFA8774B);
  static const accent = Color(0xFFE7A45D);
  static const accentDark = Color(0xFFC17322);
}

class FamilyScreen extends ConsumerStatefulWidget {
  const FamilyScreen({super.key, this.embedded = false, this.onClose});

  final bool embedded;
  final VoidCallback? onClose;

  @override
  ConsumerState<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends ConsumerState<FamilyScreen>
    with SingleTickerProviderStateMixin {
  static const _heroAsset = 'assets/images/ui/family_man_trim.png';
  static const _maxMembers = FamilyMemberGrid.maxDisplayMembers;

  bool _addingMember = false;

  late final AnimationController _entryController;
  late final Animation<double> _contentOpacity;
  late final Animation<Offset> _contentOffset;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
    _contentOpacity = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );
    _contentOffset =
        Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero).animate(
          CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
        );

    Future<void>.microtask(_loadFamily);
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  Future<void> _loadFamily() async {
    try {
      await ref.read(familyProvider.notifier).loadFamily();
      if (mounted) {
        _entryController.forward(from: 0);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      showFriendlyApiErrorSnackBar(
        context,
        error,
        fallbackMessage:
            '\u52a0\u8f7d\u5bb6\u5ead\u4fe1\u606f\u5931\u8d25\uff0c\u8bf7\u7a0d\u540e\u91cd\u8bd5',
      );
    }
  }

  Future<void> _openMemberDetail(FamilyMemberViewData member) async {
    await showMemberDetailDialog(
      context,
      memberId: member.id,
      nickname: member.nickname,
      role: member.role,
    );

    if (!mounted) {
      return;
    }
    await _loadFamily();
  }

  Future<String?> _showAddMemberDialog() async {
    return showAddMemberDialog(context);
  }

  Future<String?> _showPetSelectionDialog(String nickname) async {
    return showPetSelectionDialog(context, nickname: nickname);
  }

  Future<String?> _showPetNameDialog({
    required String memberNickname,
    required String petType,
  }) async {
    return showPetNameDialog(
      context,
      memberNickname: memberNickname,
      petType: petType,
    );
  }

  void _handleLeadingAction() {
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

  String _familyTitle(String familyName) {
    final trimmed = familyName.trim();
    if (trimmed.isEmpty || trimmed == '\u5bb6\u5ead') {
      return '\u5bb6\u5ead';
    }
    return trimmed.endsWith('\u5bb6\u5ead') ? trimmed : '$trimmed\u5bb6\u5ead';
  }

  int _petCount(List<FamilyMemberViewData> members) {
    return members.where((member) => member.petType != null).length;
  }

  int _familyPoints(List<FamilyMemberViewData> members) {
    return members.fold(0, (sum, member) => sum + member.points);
  }

  Future<void> _onAddMemberTap(
    AuthState authState,
    FamilyScreenState familyState,
  ) async {
    if (familyState.loading || _addingMember) {
      return;
    }

    final user = authState.user;
    final canManageMembers = user?.isAdmin == true && !authState.viewOnly;
    if (!canManageMembers || user?.familyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '\u53ea\u6709\u5bb6\u957f\u53ef\u4ee5\u6dfb\u52a0\u6210\u5458',
          ),
        ),
      );
      return;
    }

    if (familyState.members.length >= _maxMembers) {
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
      final notifier = ref.read(familyProvider.notifier);
      final member = await notifier.addMember(nickname);
      if (!mounted) {
        return;
      }

      while (true) {
        final selectedPetType = await _showPetSelectionDialog(member.nickname);
        if (selectedPetType == null) {
          await _loadFamily();
          return;
        }

        final petName = await _showPetNameDialog(
          memberNickname: member.nickname,
          petType: selectedPetType,
        );
        if (petName == null) {
          await _loadFamily();
          return;
        }

        try {
          await notifier.assignMemberPet(
            memberId: member.id,
            petType: selectedPetType,
            petName: petName,
          );
          if (!mounted) {
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '\u5df2\u6dfb\u52a0${member.nickname}\uff0c\u5e76\u9886\u517b\u4e86$petName',
              ),
            ),
          );
          await _loadFamily();
          return;
        } catch (error) {
          if (!mounted) {
            return;
          }
          showFriendlyApiErrorSnackBar(
            context,
            error,
            fallbackMessage:
                '\u9009\u62e9\u5ba0\u7269\u5931\u8d25\uff0c\u8bf7\u91cd\u8bd5',
          );
        }
      }
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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final familyState = ref.watch(familyProvider);
    final content = DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_FamilyPalette.pageTop, _FamilyPalette.pageBottom],
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            top: -120,
            left: -70,
            child: _BackdropOrb(size: 260, color: Color(0x33FFD9B2)),
          ),
          const Positioned(
            right: -90,
            top: 160,
            child: _BackdropOrb(size: 220, color: Color(0x26F8C68C)),
          ),
          const Positioned(
            left: -50,
            bottom: 100,
            child: _BackdropOrb(size: 170, color: Color(0x1FEBC39A)),
          ),
          SafeArea(bottom: false, child: _buildBody(authState, familyState)),
        ],
      ),
    );

    if (widget.embedded) {
      return _buildEmbeddedShell(content);
    }

    return Scaffold(backgroundColor: _FamilyPalette.pageBottom, body: content);
  }

  Widget _buildEmbeddedShell(Widget child) {
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        minimum: const EdgeInsets.fromLTRB(8, 16, 8, 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= 900;
            final borderRadius = BorderRadius.circular(isTablet ? 36 : 28);
            final maxWidth = isTablet
                ? math.min(constraints.maxWidth * 0.78, 920.0)
                : math.min(constraints.maxWidth * 0.985, 520.0);
            final maxHeight = isTablet
                ? math.min(constraints.maxHeight * 0.95, 1020.0)
                : math.min(constraints.maxHeight * 0.94, 900.0);

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxWidth,
                  maxHeight: maxHeight,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _FamilyPalette.shell,
                    borderRadius: borderRadius,
                    border: Border.all(color: _FamilyPalette.shellBorder),
                    boxShadow: [
                      BoxShadow(
                        color: _FamilyPalette.shellShadow,
                        blurRadius: 34,
                        offset: const Offset(0, 16),
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

  Widget _buildBody(AuthState authState, FamilyScreenState familyState) {
    if (!authState.isAuthenticated) {
      return const FamilyHintCard(
        title: '\u8bf7\u5148\u767b\u5f55',
        message:
            '\u767b\u5f55\u540e\u53ef\u67e5\u770b\u5bb6\u5ead\u6210\u5458\u3002',
      );
    }

    if (familyState.loading) {
      return const Center(
        child: CircularProgressIndicator(color: _FamilyPalette.accentDark),
      );
    }

    if (!familyState.hasFamily) {
      return const FamilyHintCard(
        title: '\u6682\u672a\u52a0\u5165\u5bb6\u5ead',
        message:
            '\u5148\u521b\u5efa\u5bb6\u5ead\u6216\u901a\u8fc7\u9080\u8bf7\u7801\u52a0\u5165\u3002',
      );
    }

    final members = familyState.members;
    final petCount = _petCount(members);
    final familyPoints = _familyPoints(members);
    final familyTitle = _familyTitle(familyState.familyName);
    final canManageMembers =
        authState.user?.isAdmin == true && !authState.viewOnly;

    void onAddMemberTap() {
      _onAddMemberTap(authState, familyState);
    }

    return RefreshIndicator(
      color: _FamilyPalette.accentDark,
      onRefresh: _loadFamily,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(
          widget.embedded ? 18 : 22,
          widget.embedded ? 14 : 18,
          widget.embedded ? 18 : 22,
          widget.embedded ? 22 : 26,
        ),
        child: FadeTransition(
          opacity: _contentOpacity,
          child: SlideTransition(
            position: _contentOffset,
            child: Column(
              children: [
                _FamilyHeaderBar(
                  leadingIcon: widget.embedded
                      ? Icons.close_rounded
                      : Icons.arrow_back_rounded,
                  leadingTooltip: widget.embedded
                      ? '\u5173\u95ed'
                      : '\u8fd4\u56de\u9996\u9875',
                  onBack: _handleLeadingAction,
                  showText: !widget.embedded,
                  title: familyTitle,
                  subtitle:
                      '$familyPoints \u79ef\u5206 \u00b7 $petCount \u53ea\u5ba0\u7269',
                ),
                const SizedBox(height: 8),
                _FamilyHeroShowcase(
                  embedded: widget.embedded,
                  canManageMembers: canManageMembers,
                  addingMember: _addingMember,
                  onAddMemberTap: onAddMemberTap,
                ),
                Transform.translate(
                  offset: const Offset(0, -42),
                  child: _FamilyMembersPanel(
                    compact: widget.embedded,
                    members: members,
                    entryAnimation: _entryController,
                    onMemberTap: _openMemberDetail,
                    canManageMembers: canManageMembers,
                    onAddMemberTap: onAddMemberTap,
                    onRefresh: _loadFamily,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BackdropOrb extends StatelessWidget {
  const _BackdropOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

class _FamilyHeaderBar extends StatelessWidget {
  const _FamilyHeaderBar({
    required this.leadingIcon,
    required this.leadingTooltip,
    required this.onBack,
    required this.showText,
    required this.title,
    required this.subtitle,
  });

  final IconData leadingIcon;
  final String leadingTooltip;
  final VoidCallback onBack;
  final bool showText;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    if (!showText) {
      return Align(
        alignment: Alignment.centerLeft,
        child: _CircleIconButton(
          icon: leadingIcon,
          tooltip: leadingTooltip,
          onTap: onBack,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0DCC9)),
      ),
      child: Row(
        children: [
          _CircleIconButton(
            icon: leadingIcon,
            tooltip: leadingTooltip,
            onTap: onBack,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _FamilyPalette.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _FamilyPalette.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 38),
        ],
      ),
    );
  }
}

class _FamilyHeroShowcase extends StatelessWidget {
  const _FamilyHeroShowcase({
    required this.embedded,
    required this.canManageMembers,
    required this.addingMember,
    required this.onAddMemberTap,
  });

  final bool embedded;
  final bool canManageMembers;
  final bool addingMember;
  final VoidCallback onAddMemberTap;

  @override
  Widget build(BuildContext context) {
    final titleFontSize = embedded ? 36.0 : 56.0;
    final heroImageHeight = embedded ? 226.0 : 382.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        embedded ? 18 : 24,
        embedded ? 2 : 8,
        embedded ? 18 : 24,
        0,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (canManageMembers)
            Positioned(
              top: embedded ? 8 : 10,
              right: embedded ? 4 : 6,
              child: _HeroAddButton(
                busy: addingMember,
                onTap: addingMember ? null : onAddMemberTap,
              ),
            ),
          Column(
            children: [
              Transform.translate(
                offset: Offset(0, embedded ? -4 : -6),
                child: Text(
                  '\u6211\u4eec\u7684\u5bb6',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _FamilyPalette.text,
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
              ),
              SizedBox(height: embedded ? 0 : 4),
              Transform.translate(
                offset: Offset(0, embedded ? -26 : -30),
                child: Align(
                  alignment: Alignment.center,
                  child: Image.asset(
                    _FamilyScreenState._heroAsset,
                    height: heroImageHeight,
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomCenter,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroAddButton extends StatelessWidget {
  const _HeroAddButton({required this.busy, required this.onTap});

  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const buttonSize = 54.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            color: _FamilyPalette.accent,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _FamilyPalette.accent.withValues(alpha: 0.34),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.add_rounded, color: Colors.white, size: 30),
          ),
        ),
      ),
    );
  }
}

class _FamilyMembersPanel extends StatelessWidget {
  const _FamilyMembersPanel({
    required this.compact,
    required this.members,
    required this.entryAnimation,
    required this.onMemberTap,
    required this.canManageMembers,
    required this.onAddMemberTap,
    required this.onRefresh,
  });

  final bool compact;
  final List<FamilyMemberViewData> members;
  final Animation<double> entryAnimation;
  final ValueChanged<FamilyMemberViewData> onMemberTap;
  final bool canManageMembers;
  final VoidCallback onAddMemberTap;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 8 : 10,
        compact ? 0 : 0,
        compact ? 8 : 10,
        compact ? 6 : 6,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FamilyMemberGrid(
            members: members,
            entryAnimation: entryAnimation,
            onMemberTap: onMemberTap,
            canAddMembers: canManageMembers,
            onAddMemberTap: onAddMemberTap,
          ),
          if (!compact) ...[
            const SizedBox(height: 16),
            _FamilyActionBar(
              canManageMembers: canManageMembers,
              onAddMemberTap: onAddMemberTap,
              onRefresh: onRefresh,
            ),
            const SizedBox(height: 14),
            const _FamilyWarmthNote(),
          ],
        ],
      ),
    );
  }
}

class _FamilyActionBar extends StatelessWidget {
  const _FamilyActionBar({
    required this.canManageMembers,
    required this.onAddMemberTap,
    required this.onRefresh,
  });

  final bool canManageMembers;
  final VoidCallback onAddMemberTap;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final buttonStyle = FilledButton.styleFrom(
      backgroundColor: const Color(0xFFF8E6D1),
      foregroundColor: _FamilyPalette.text,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      elevation: 0,
      padding: const EdgeInsets.symmetric(vertical: 16),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
    );

    if (!canManageMembers) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () => onRefresh(),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('\u5237\u65b0\u5bb6\u5ead'),
          style: buttonStyle,
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: onAddMemberTap,
            icon: const Icon(Icons.add_rounded),
            label: const Text('\u6dfb\u52a0\u6210\u5458'),
            style: buttonStyle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: () => onRefresh(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('\u5237\u65b0'),
            style: buttonStyle,
          ),
        ),
      ],
    );
  }
}

class _FamilyWarmthNote extends StatelessWidget {
  const _FamilyWarmthNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFAF5), Color(0xFFFFF2E7)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1DECE)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.favorite_border_rounded,
              color: _FamilyPalette.accent,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              '\u5bb6\u4eba\u548c\u5ba0\u7269\u7684\u6bcf\u4e00\u6b21\u4e92\u52a8\uff0c'
              '\u90fd\u4f1a\u7559\u4e0b\u6e29\u6696\u7684\u6210\u957f\u8bb0\u5f55\u3002',
              style: TextStyle(
                color: _FamilyPalette.muted,
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFF0DCC9)),
          ),
          child: Icon(icon, color: _FamilyPalette.muted, size: 20),
        ),
      ),
    );
  }
}
