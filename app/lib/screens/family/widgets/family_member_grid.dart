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
        final crossAxisCount = switch (constraints.maxWidth) {
          >= 1080 => 4,
          >= 760 => 3,
          _ => 2,
        };
        final spacing = constraints.maxWidth >= 760 ? 14.0 : 12.0;
        final childAspectRatio = constraints.maxWidth >= 980
            ? 1.0
            : constraints.maxWidth >= 760
            ? 0.92
            : 0.84;

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

        final grid = GridView.builder(
          shrinkWrap: true,
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
        );

        if (_pageCount <= 1) {
          return grid;
        }

        return Column(
          children: [
            GestureDetector(
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
                  child: grid,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              key: const Key('family_member_grid_page_dots'),
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var index = 0; index < _pageCount; index++)
                  GestureDetector(
                    onTap: () => _setPage(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: index == _currentPage ? 14 : 5,
                      height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: index == _currentPage
                            ? const Color(0xFFE0A25B)
                            : const Color(0xFFE7DACB),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
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
