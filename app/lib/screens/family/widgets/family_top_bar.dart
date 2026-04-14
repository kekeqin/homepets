import 'package:flutter/material.dart';

class FamilyTopBar extends StatelessWidget {
  const FamilyTopBar({
    super.key,
    required this.title,
    required this.showRefresh,
    required this.loading,
    required this.onBack,
    required this.onRefresh,
  });

  final String title;
  final bool showRefresh;
  final bool loading;
  final VoidCallback onBack;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF2E5CF).withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF7A5733).withValues(alpha: 0.45),
          ),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: onBack,
              tooltip: '返回主页',
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Color(0xFF694426),
              ),
              visualDensity: VisualDensity.compact,
            ),
            const Icon(Icons.family_restroom_rounded, color: Color(0xFF694426)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$title·家庭',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF57351B),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (showRefresh)
              IconButton(
                onPressed: loading ? null : () => onRefresh(),
                tooltip: '刷新',
                icon: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.1,
                          color: Color(0xFF57351B),
                        ),
                      )
                    : const Icon(Icons.refresh_rounded),
              ),
          ],
        ),
      ),
    );
  }
}
