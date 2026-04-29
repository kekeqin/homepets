import 'package:flutter/material.dart';

import '../../../models/pet.dart';
import '../models/family_member_view_data.dart';
import 'family_empty_card.dart';
import 'family_member_card.dart';

class FamilyMemberGrid extends StatefulWidget {
  const FamilyMemberGrid({
    super.key,
    required this.members,
    required this.entryAnimation,
    required this.canAddMembers,
    required this.onAddMemberTap,
    this.onPetTap,
    this.canEditAvatar,
    this.onAvatarEditTap,
    this.updatingAvatarMemberId,
    this.canDeleteMember,
    this.onMemberLongPress,
  });

  static const int maxDisplayMembers = 8;

  final List<FamilyMemberViewData> members;
  final Animation<double> entryAnimation;
  final bool canAddMembers;
  final VoidCallback onAddMemberTap;
  final ValueChanged<Pet>? onPetTap;
  final bool Function(FamilyMemberViewData member)? canEditAvatar;
  final ValueChanged<FamilyMemberViewData>? onAvatarEditTap;
  final int? updatingAvatarMemberId;
  final bool Function(FamilyMemberViewData member)? canDeleteMember;
  final ValueChanged<FamilyMemberViewData>? onMemberLongPress;

  @override
  State<FamilyMemberGrid> createState() => _FamilyMemberGridState();
}

class _FamilyMemberGridState extends State<FamilyMemberGrid> {
  static const int _visibleMemberCount = 4;

  int _currentPage = 0;
  double _dragDelta = 0;
  bool _movingForward = true;

  int get _pageCount => (widget.members.length / _visibleMemberCount).ceil();

  @override
  void didUpdateWidget(covariant FamilyMemberGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    final maxPageIndex = _pageCount > 0 ? _pageCount - 1 : 0;
    if (_currentPage > maxPageIndex) {
      setState(() {
        _currentPage = maxPageIndex;
      });
    }
  }

  void _setPage(int page) {
    if (page < 0 || page >= _pageCount || page == _currentPage) {
      return;
    }

    setState(() {
      _movingForward = page > _currentPage;
      _currentPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const crossAxisCount = 2;
        final spacing = constraints.maxWidth >= 760 ? 18.0 : 8.0;

        if (widget.members.isEmpty) {
          return FamilyEmptyCard(
            canAddMembers: widget.canAddMembers,
            onAddTap: widget.onAddMemberTap,
          );
        }

        final pages = <List<FamilyMemberViewData>>[
          for (
            var start = 0;
            start < widget.members.length;
            start += _visibleMemberCount
          )
            widget.members
                .skip(start)
                .take(_visibleMemberCount)
                .toList(growable: false),
        ];
        final pageMembers = pages[_currentPage];
        final dotsHeight = _pageCount > 1 ? 52.0 : 0.0;
        final cardWidth =
            (constraints.maxWidth - spacing * (crossAxisCount - 1)) /
            crossAxisCount;
        final hasBoundedHeight =
            constraints.hasBoundedHeight && constraints.maxHeight.isFinite;
        final availableGridHeight = hasBoundedHeight
            ? (constraints.maxHeight - dotsHeight).clamp(0.0, double.infinity)
            : double.infinity;
        final cardHeight = hasBoundedHeight
            ? ((availableGridHeight - spacing - 4) / 2)
                  .clamp(96.0, double.infinity)
                  .toDouble()
            : cardWidth / 0.78;
        final gridHeight = cardHeight * 2 + spacing;
        final childAspectRatio = cardWidth / cardHeight;

        final grid = SizedBox(
          height: gridHeight,
          child: GridView.builder(
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pageMembers.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: childAspectRatio,
            ),
            itemBuilder: (context, index) {
              final member = pageMembers[index];
              return _AnimatedMemberCard(
                index: index,
                entryAnimation: widget.entryAnimation,
                child: FamilyMemberCard(
                  member: member,
                  displaySlot: index,
                  onPetTap: member.pet != null
                      ? () => widget.onPetTap?.call(member.pet!)
                      : null,
                  onAvatarEditTap:
                      (widget.canEditAvatar?.call(member) ?? false) &&
                          widget.onAvatarEditTap != null
                      ? () => widget.onAvatarEditTap!.call(member)
                      : null,
                  avatarEditBusy: widget.updatingAvatarMemberId == member.id,
                  onLongPress:
                      (widget.canDeleteMember?.call(member) ?? false) &&
                          widget.onMemberLongPress != null
                      ? () => widget.onMemberLongPress!.call(member)
                      : null,
                ),
              );
            },
          ),
        );

        if (_pageCount <= 1) {
          return grid;
        }

        return SizedBox(
          height: hasBoundedHeight ? constraints.maxHeight : gridHeight + 34,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 42),
                child: GestureDetector(
                  key: const Key('family_member_grid_swipe_area'),
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: (_) => _dragDelta = 0,
                  onHorizontalDragUpdate: (details) {
                    _dragDelta += details.delta.dx;
                  },
                  onHorizontalDragEnd: (_) {
                    if (_dragDelta <= -36) {
                      _setPage(_currentPage + 1);
                    } else if (_dragDelta >= 36) {
                      _setPage(_currentPage - 1);
                    }
                    _dragDelta = 0;
                  },
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      final offsetAnimation = Tween<Offset>(
                        begin: Offset(_movingForward ? 0.05 : -0.05, 0),
                        end: Offset.zero,
                      ).animate(animation);

                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: offsetAnimation,
                          child: child,
                        ),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey<int>(_currentPage),
                      child: Align(alignment: Alignment.topCenter, child: grid),
                    ),
                  ),
                ),
              ),
              Positioned(
                key: const Key('family_member_grid_page_dots'),
                left: 0,
                right: 0,
                bottom: 11,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _PageDivider(),
                    const SizedBox(width: 14),
                    _PageDot(
                      active: _currentPage == 0,
                      onTap: () => _setPage(0),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${_currentPage + 1}/$_pageCount',
                      style: const TextStyle(
                        color: Color(0xFF7D5A36),
                        fontSize: 18,
                        height: 1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _PageDot(
                      active: _currentPage == _pageCount - 1,
                      onTap: () => _setPage(_pageCount - 1),
                    ),
                    const SizedBox(width: 14),
                    const _PageDivider(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PageDivider extends StatelessWidget {
  const _PageDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 2,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFE9B66F).withValues(alpha: 0.68),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _PageDot extends StatelessWidget {
  const _PageDot({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        scale: active ? 1 : 0.9,
        child: SizedBox(
          width: 18,
          height: 18,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? const Color(0xFF93A83B) : const Color(0xFFFFDCA6),
              border: Border.all(color: const Color(0xFF8D5B2E), width: 1.1),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8D5B2E).withValues(alpha: 0.12),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedMemberCard extends StatelessWidget {
  const _AnimatedMemberCard({
    required this.index,
    required this.entryAnimation,
    required this.child,
  });

  final int index;
  final Animation<double> entryAnimation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final start = (0.14 + index * 0.08).clamp(0.0, 0.82).toDouble();
    final end = (start + 0.28).clamp(0.0, 1.0).toDouble();
    final moveCurve = CurvedAnimation(
      parent: entryAnimation,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    final fadeCurve = CurvedAnimation(
      parent: entryAnimation,
      curve: Interval(start, end, curve: Curves.easeOut),
    );

    return FadeTransition(
      opacity: fadeCurve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(moveCurve),
        child: child,
      ),
    );
  }
}
