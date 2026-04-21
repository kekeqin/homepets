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
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF9),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFF0E1D1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF2E2),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE7D2BE)),
            ),
            child: const Icon(
              Icons.family_restroom_rounded,
              color: Color(0xFFCE8F4B),
              size: 30,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            '成员还没有加入',
            style: TextStyle(
              color: Color(0xFF734C2B),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            canAddMembers ? '先添加一位家庭成员，主页就会热闹起来。' : '等家长添加成员后，这里会显示全家的成长卡片。',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF8F7356),
              fontSize: 13,
              height: 1.55,
            ),
          ),
          if (canAddMembers) ...[
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onAddTap,
              icon: const Icon(Icons.add_rounded),
              label: const Text('添加成员'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEAA35E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
