import 'package:flutter/material.dart';

import '../models/family_member_view_data.dart';
import 'family_empty_card.dart';
import 'family_member_card.dart';

class FamilyMemberGrid extends StatelessWidget {
  const FamilyMemberGrid({
    super.key,
    required this.members,
    required this.entryAnimation,
    required this.onMemberTap,
  });

  static const int maxDisplayMembers = 8;
  static const List<String> _cardAssets = <String>[
    'assets/images/ui/member_card_1.png',
    'assets/images/ui/member_card_2.png',
    'assets/images/ui/member_card_3.png',
    'assets/images/ui/member_card_4.png',
  ];
  static const List<String> _portraitAssets = <String>[
    'assets/images/ui/person_male.png',
    'assets/images/ui/person_boy.png',
    'assets/images/ui/person_girl.png',
    'assets/images/ui/person_female.png',
  ];
  static const double _cardAspectRatio = 385 / 598;
  static const List<PortraitStyle> _portraitStyles = <PortraitStyle>[
    PortraitStyle(scale: 1.12, dx: -0.01, dy: 0.05),
    PortraitStyle(scale: 1.14, dx: 0.00, dy: 0.09),
    PortraitStyle(scale: 1.44, dx: -0.01, dy: 0.13),
    PortraitStyle(scale: 1.16, dx: 0.00, dy: 0.08),
  ];

  final List<FamilyMemberViewData> members;
  final Animation<double> entryAnimation;
  final ValueChanged<FamilyMemberViewData> onMemberTap;

  @override
  Widget build(BuildContext context) {
    final visibleMembers = List<FamilyMemberViewData?>.generate(
      maxDisplayMembers,
      (index) => index < members.length ? members[index] : null,
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
    required List<FamilyMemberViewData?> members,
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
    required FamilyMemberViewData? member,
  }) {
    final start = (0.18 + index * 0.08).clamp(0.0, 0.82).toDouble();
    final end = (start + 0.32).clamp(0.0, 1.0).toDouble();
    final moveCurve = CurvedAnimation(
      parent: entryAnimation,
      curve: Interval(start, end, curve: Curves.easeOutBack),
    );
    final fadeCurve = CurvedAnimation(
      parent: entryAnimation,
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
              ? FamilyEmptyCard(cardAsset: cardAsset)
              : FamilyMemberCard(
                  member: member,
                  cardAsset: cardAsset,
                  portraitAsset: portraitAsset,
                  portraitStyle: portraitStyle,
                  onDetailTap: () => onMemberTap(member),
                ),
        ),
      ),
    );
  }
}
