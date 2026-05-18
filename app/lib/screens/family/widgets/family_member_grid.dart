import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../models/pet.dart';
import '../../../models/pet_artwork.dart';
import '../models/family_member_view_data.dart';
import 'family_empty_card.dart';
import 'family_member_card.dart';
import 'family_sprite_slice.dart';

typedef FamilyPetTap = void Function(Pet pet, String? avatarAssetPath);

class FamilyMemberGrid extends StatefulWidget {
  const FamilyMemberGrid({
    super.key,
    required this.members,
    required this.entryAnimation,
    required this.canAddMembers,
    required this.onAddMemberTap,
    this.petAvatarAssetPathsById = const <int, String>{},
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
  final Map<int, String> petAvatarAssetPathsById;
  final FamilyPetTap? onPetTap;
  final bool Function(FamilyMemberViewData member)? canEditAvatar;
  final ValueChanged<FamilyMemberViewData>? onAvatarEditTap;
  final int? updatingAvatarMemberId;
  final bool Function(FamilyMemberViewData member)? canDeleteMember;
  final ValueChanged<FamilyMemberViewData>? onMemberLongPress;

  @override
  State<FamilyMemberGrid> createState() => _FamilyMemberGridState();
}

class _FamilyMemberGridState extends State<FamilyMemberGrid> {
  static const int _visibleSlotCount = 4;

  int _currentPage = 0;
  double _dragDelta = 0;
  bool _movingForward = true;

  int get _slotCount {
    if (widget.members.isEmpty) {
      return 0;
    }
    final includeInviteSlot =
        widget.canAddMembers &&
        widget.members.length < FamilyMemberGrid.maxDisplayMembers;
    return widget.members.length + (includeInviteSlot ? 1 : 0);
  }

  int get _pageCount {
    final slots = _slotCount;
    if (slots == 0) {
      return 1;
    }
    return (slots / _visibleSlotCount).ceil();
  }

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

  String? _petAvatarAssetPathForMember(FamilyMemberViewData member) {
    final pet = member.pet;
    final petType = pet?.petType ?? member.petType;
    if (petType == null) {
      return null;
    }

    final effectivePetId = pet?.id ?? member.petId;
    final providedAssetPath = effectivePetId == null
        ? null
        : widget.petAvatarAssetPathsById[effectivePetId];
    if (providedAssetPath != null) {
      return providedAssetPath;
    }

    final seed = pet?.id ?? member.petId ?? member.id;
    return defaultHomePetDetailAvatarAssetPath(petType, seed);
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

  Widget _buildSlot(int slotIndex) {
    final memberIndex = _currentPage * _visibleSlotCount + slotIndex;
    final showInviteSlot =
        widget.canAddMembers &&
        widget.members.length < FamilyMemberGrid.maxDisplayMembers &&
        memberIndex == widget.members.length;

    if (memberIndex >= widget.members.length) {
      if (!showInviteSlot) {
        return const SizedBox.shrink();
      }
      return _AnimatedMemberCard(
        index: slotIndex,
        entryAnimation: widget.entryAnimation,
        child: FamilyEmptyCard(
          compact: true,
          canAddMembers: widget.canAddMembers,
          onAddTap: widget.onAddMemberTap,
        ),
      );
    }

    final member = widget.members[memberIndex];
    final pet = member.pet;
    final petAvatarAssetPath = _petAvatarAssetPathForMember(member);

    return _AnimatedMemberCard(
      index: slotIndex,
      entryAnimation: widget.entryAnimation,
      child: FamilyMemberCard(
        member: member,
        displaySlot: memberIndex,
        petAvatarAssetPath: petAvatarAssetPath,
        onPetTap: pet != null
            ? () => widget.onPetTap?.call(pet, petAvatarAssetPath)
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
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (widget.members.isEmpty) {
          return Center(
            child: FractionallySizedBox(
              widthFactor: constraints.maxWidth < 430 ? 0.96 : 0.66,
              heightFactor: constraints.hasBoundedHeight ? 0.72 : null,
              child: FamilyEmptyCard(
                canAddMembers: widget.canAddMembers,
                onAddTap: widget.onAddMemberTap,
              ),
            ),
          );
        }

        final compact = constraints.maxWidth < 430;
        final sideControlWidth = compact ? 24.0 : 32.0;
        final sideGap = compact ? 3.0 : 8.0;
        final spacing = compact ? 10.0 : 14.0;
        const crossAxisCount = 2;
        final hasBoundedHeight =
            constraints.hasBoundedHeight && constraints.maxHeight.isFinite;
        final footerHeight = compact ? 34.0 : 40.0;
        final gridWidth =
            (constraints.maxWidth - sideControlWidth * 2 - sideGap * 2)
                .clamp(0.0, constraints.maxWidth)
                .toDouble();
        final availableGridHeight = hasBoundedHeight
            ? (constraints.maxHeight - footerHeight)
                  .clamp(0.0, double.infinity)
                  .toDouble()
            : double.infinity;
        final cardWidth =
            (gridWidth - spacing * (crossAxisCount - 1)) / crossAxisCount;
        final targetCardHeight = cardWidth / 0.72;
        final slotHeight = hasBoundedHeight
            ? ((availableGridHeight - spacing) / 2)
                  .clamp(132.0, double.infinity)
                  .toDouble()
            : targetCardHeight;
        final cardHeight = hasBoundedHeight
            ? math.min(slotHeight, targetCardHeight)
            : targetCardHeight;
        final gridHeight = cardHeight * 2 + spacing;
        final contentHeight = hasBoundedHeight
            ? constraints.maxHeight
            : gridHeight + footerHeight;
        final showPaging = _pageCount > 1;

        final grid = SizedBox(
          width: gridWidth,
          height: gridHeight,
          child: GridView.builder(
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _visibleSlotCount,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: cardWidth / cardHeight,
            ),
            itemBuilder: (context, index) => _buildSlot(index),
          ),
        );

        return SizedBox(
          height: contentHeight,
          width: double.infinity,
          child: Column(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: sideControlWidth,
                      child: showPaging
                          ? _PageArrowButton(
                              key: const Key('family_member_grid_prev'),
                              enabled: _currentPage > 0,
                              onTap: () => _setPage(_currentPage - 1),
                            )
                          : const SizedBox.shrink(),
                    ),
                    SizedBox(width: sideGap),
                    Expanded(
                      child: Center(
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
                              child: Align(
                                alignment: Alignment.center,
                                child: grid,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: sideGap),
                    SizedBox(
                      width: sideControlWidth,
                      child: showPaging
                          ? _PageArrowButton(
                              key: const Key('family_member_grid_next'),
                              enabled: _currentPage < _pageCount - 1,
                              flipped: true,
                              onTap: () => _setPage(_currentPage + 1),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              SizedBox(
                key: const Key('family_member_grid_page_dots'),
                height: footerHeight,
                child: _PageText(
                  currentPage: _currentPage + 1,
                  pageCount: _pageCount,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PageArrowButton extends StatelessWidget {
  const _PageArrowButton({
    super.key,
    required this.enabled,
    required this.onTap,
    this.flipped = false,
  });

  final bool enabled;
  final VoidCallback onTap;
  final bool flipped;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: flipped ? '下一页' : '上一页',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 160),
          opacity: enabled ? 1 : 0.34,
          child: Transform.scale(
            scaleX: flipped ? -1 : 1,
            child: Image.asset(
              FamilyPopupAssets.pageArrow,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
              isAntiAlias: true,
            ),
          ),
        ),
      ),
    );
  }
}

class _PageText extends StatelessWidget {
  const _PageText({required this.currentPage, required this.pageCount});

  final int currentPage;
  final int pageCount;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$currentPage / $pageCount 页',
        style: const TextStyle(
          color: Color(0xFF3F230D),
          fontSize: 28,
          height: 1,
          fontWeight: FontWeight.w900,
          shadows: [
            Shadow(
              color: Colors.white,
              offset: Offset(0, 1.3),
              blurRadius: 0.2,
            ),
            Shadow(
              color: Color(0x99FFFFFF),
              offset: Offset(1.1, 0),
              blurRadius: 0.2,
            ),
          ],
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
