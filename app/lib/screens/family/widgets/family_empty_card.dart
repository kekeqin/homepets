import 'package:flutter/material.dart';

import 'family_sprite_slice.dart';

class FamilyEmptyCard extends StatelessWidget {
  const FamilyEmptyCard({
    super.key,
    required this.canAddMembers,
    required this.onAddTap,
  });

  final bool canAddMembers;
  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E9).withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFEAB56B), width: 1.4),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 82,
                height: 82,
                child: FamilySpriteSlice(
                  region: FamilySpriteRegions.emptyPetPaw,
                  sampleInset: 2,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '\u8fd8\u6ca1\u6709\u5bb6\u5ead\u6210\u5458',
                style: TextStyle(
                  color: Color(0xFF734C2B),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                canAddMembers
                    ? '\u5148\u9080\u8bf7\u4e00\u4f4d\u6210\u5458\uff0c'
                          '\u8fd9\u91cc\u5c31\u4f1a\u5f00\u59cb\u8bb0\u5f55\u5168\u5bb6\u7684'
                          '\u6210\u957f\u6545\u4e8b\u3002'
                    : '\u7b49\u5bb6\u957f\u6dfb\u52a0\u6210\u5458\u540e\uff0c'
                          '\u8fd9\u91cc\u5c31\u4f1a\u51fa\u73b0\u5bb6\u5ead\u6210\u5458\u5361\u7247\u3002',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF8F7356),
                  fontSize: 14,
                  height: 1.55,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (canAddMembers) ...[
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: onAddTap,
                  child: const SizedBox(
                    width: 166,
                    height: 54,
                    child: FamilySpriteSlice(
                      region: FamilySpriteRegions.addMemberButton,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
