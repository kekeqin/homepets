import 'package:flutter/material.dart';

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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFF0DDCE), width: 1.3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E4),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFF0D9C1)),
            ),
            child: const Icon(
              Icons.family_restroom_rounded,
              color: Color(0xFFE09A4E),
              size: 34,
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
            FilledButton.icon(
              onPressed: onAddTap,
              icon: const Icon(Icons.add_rounded),
              label: const Text('\u6dfb\u52a0\u6210\u5458'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE6A35C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
