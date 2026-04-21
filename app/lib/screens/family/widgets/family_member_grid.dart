import 'package:flutter/material.dart';

import '../models/family_member_view_data.dart';
import 'family_empty_card.dart';
import 'family_member_card.dart';

class FamilyMemberGrid extends StatefulWidget {
  const FamilyMemberGrid({
    super.key,
    required this.members,
    required this.entryAnimation,
    required this.onMemberTap,
    required this.canAddMembers,
    required this.onAddMemberTap,
  });

  static const int maxDisplayMembers = 8;

  final List<FamilyMemberViewData> members;
  final Animation<double> entryAnimation;
  final ValueChanged<FamilyMemberViewData> onMemberTap;
  final bool canAddMembers;
  final VoidCallback onAddMemberTap;

  @override
  State<FamilyMemberGrid> createState() => _FamilyMemberGridState();
}

class _FamilyMemberGridState extends State<FamilyMemberGrid> {
  static const int _collapsedMemberCount = 4;

  bool _expanded = false;

  @override
  void didUpdateWidget(covariant FamilyMemberGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.members.length <= _collapsedMemberCount && _expanded) {
      setState(() {
        _expanded = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 980
            ? 4
            : constraints.maxWidth >= 700
            ? 3
            : 2;
        final spacing = constraints.maxWidth >= 700 ? 18.0 : 14.0;
        final childAspectRatio = constraints.maxWidth >= 700 ? 1.32 : 1.22;
        final hasOverflow = widget.members.length > _collapsedMemberCount;
        final visibleMembers = hasOverflow && !_expanded
            ? widget.members.take(_collapsedMemberCount).toList(growable: false)
            : widget.members;
        final remainingCount = widget.members.length - _collapsedMemberCount;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Text(
                '成员',
                style: TextStyle(
                  color: Color(0xFFD4B59A),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (widget.members.isEmpty)
              FamilyEmptyCard(
                canAddMembers: widget.canAddMembers,
                onAddTap: widget.onAddMemberTap,
              )
            else
              Column(
                children: [
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: visibleMembers.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: spacing,
                      mainAxisSpacing: spacing,
                      childAspectRatio: childAspectRatio,
                    ),
                    itemBuilder: (context, index) {
                      final member = visibleMembers[index];
                      return _AnimatedMemberCard(
                        index: index,
                        entryAnimation: widget.entryAnimation,
                        child: FamilyMemberCard(
                          member: member,
                          onDetailTap: () => widget.onMemberTap(member),
                        ),
                      );
                    },
                  ),
                  if (hasOverflow) ...[
                    const SizedBox(height: 12),
                    _MemberOverflowToggle(
                      expanded: _expanded,
                      remainingCount: remainingCount,
                      onTap: () {
                        setState(() {
                          _expanded = !_expanded;
                        });
                      },
                    ),
                  ],
                ],
              ),
          ],
        );
      },
    );
  }
}

class _MemberOverflowToggle extends StatelessWidget {
  const _MemberOverflowToggle({
    required this.expanded,
    required this.remainingCount,
    required this.onTap,
  });

  final bool expanded;
  final int remainingCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = const Color(0xFFC78743);

    return Align(
      alignment: Alignment.center,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF2E2),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFF0DDC8)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  expanded ? '收起成员' : '展开剩余 $remainingCount 位',
                  style: TextStyle(
                    color: foregroundColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: foregroundColor,
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
    final start = (0.18 + index * 0.08).clamp(0.0, 0.82).toDouble();
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
