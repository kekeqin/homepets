import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../models/pet.dart';
import '../models/family_member_view_data.dart';
import 'family_empty_card.dart';
import 'family_member_card.dart';
import 'family_sprite_slice.dart';

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
        final compact = constraints.maxWidth < 430;
        final spacing = constraints.maxWidth >= 760 ? 14.0 : 10.0;

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
        const pageGap = 4.0;
        const pageDotsRowHeight = 22.0;
        final dotsHeight = _pageCount > 1 ? pageGap + pageDotsRowHeight : 0.0;
        final gridWidthFactor = compact
            ? 0.96
            : constraints.maxWidth >= 760
            ? 0.90
            : 0.94;
        final gridWidth = (constraints.maxWidth * gridWidthFactor)
            .clamp(0.0, constraints.maxWidth)
            .toDouble();
        final cardWidth =
            (gridWidth - spacing * (crossAxisCount - 1)) / crossAxisCount;
        final hasBoundedHeight =
            constraints.hasBoundedHeight && constraints.maxHeight.isFinite;
        final availableGridHeight = hasBoundedHeight
            ? (constraints.maxHeight - dotsHeight).clamp(0.0, double.infinity)
            : double.infinity;
        final slotHeight = hasBoundedHeight
            ? ((availableGridHeight - spacing) / 2)
                  .clamp(118.0, double.infinity)
                  .toDouble()
            : double.infinity;
        final targetCardHeight = cardWidth / (compact ? 0.82 : 0.80);
        final cardHeight = hasBoundedHeight
            ? math.min(slotHeight, targetCardHeight)
            : targetCardHeight;
        final gridHeight = cardHeight * 2 + spacing;
        final childAspectRatio = cardWidth / cardHeight;

        final grid = SizedBox(
          width: gridWidth,
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
          return SizedBox(
            width: double.infinity,
            height: hasBoundedHeight ? constraints.maxHeight : gridHeight,
            child: Align(alignment: Alignment.center, child: grid),
          );
        }

        return SizedBox(
          height: hasBoundedHeight
              ? constraints.maxHeight
              : gridHeight + dotsHeight,
          child: Column(
            children: [
              SizedBox(
                height: gridHeight,
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
              const SizedBox(height: pageGap),
              SizedBox(
                key: const Key('family_member_grid_page_dots'),
                height: pageDotsRowHeight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _PageDivider(),
                    const SizedBox(width: 10),
                    _PageDot(
                      active: _currentPage == 0,
                      onTap: () => _setPage(0),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      '${_currentPage + 1}/$_pageCount',
                      style: const TextStyle(
                        color: Color(0xFF7D5A36),
                        fontSize: 14,
                        height: 1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 7),
                    _PageDot(
                      active: _currentPage == _pageCount - 1,
                      onTap: () => _setPage(_pageCount - 1),
                    ),
                    const SizedBox(width: 10),
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
      width: 36,
      height: 1.5,
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
          width: 12,
          height: 12,
          child: FamilySpriteSlice(
            region: active
                ? FamilySpriteRegions.pageDotActive
                : FamilySpriteRegions.pageDotInactive,
            fit: BoxFit.contain,
            sampleInset: 1,
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
