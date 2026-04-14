import 'package:flutter/material.dart';

class FamilyEmptyCard extends StatelessWidget {
  const FamilyEmptyCard({super.key, required this.cardAsset});

  final String cardAsset;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 385 / 598,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned.fill(
            child: Image.asset(
              cardAsset,
              fit: BoxFit.contain,
              color: Colors.white.withValues(alpha: 0.25),
              colorBlendMode: BlendMode.srcATop,
              filterQuality: FilterQuality.high,
            ),
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                '待加入成员',
                style: TextStyle(
                  color: Color(0xFF644124),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
