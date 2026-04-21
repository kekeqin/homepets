import 'package:flutter/material.dart';

class FamilyHintCard extends StatelessWidget {
  const FamilyHintCard({super.key, required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFCF7),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFF0E1D1)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1DE),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFEAD7C1)),
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Color(0xFFE39B58),
                  size: 30,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF734C2B),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF8E7356),
                  fontSize: 13,
                  height: 1.65,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
