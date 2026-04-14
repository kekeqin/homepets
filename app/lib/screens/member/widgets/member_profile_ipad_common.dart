import 'package:flutter/material.dart';

class MemberProfileIpadColors {
  static const background = Color(0xFFFFFBF2);
  static const shell = Color(0xFFF7F0DE);
  static const card = Color(0xFFFFFFFF);
  static const cardSoft = Color(0xFFF7F3E9);
  static const text = Color(0xFF43391E);
  static const muted = Color(0xFF7B6E4B);
  static const green = Color(0xFF15752E);
  static const greenSoft = Color(0xFFD6ECC8);
  static const blue = Color(0xFFDDECF9);
  static const blueText = Color(0xFF2F5985);
  static const gold = Color(0xFFF4E2A8);
  static const goldText = Color(0xFF8A6508);
  static const coral = Color(0xFFF7DED5);
  static const coralText = Color(0xFFAE4B2F);
}

class MemberProfileIpadMetricCard extends StatelessWidget {
  const MemberProfileIpadMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.background,
    required this.foreground,
    required this.icon,
  });

  final String label;
  final String value;
  final Color background;
  final Color foreground;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: foreground),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: foreground,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class MemberProfileIpadPanelCard extends StatelessWidget {
  const MemberProfileIpadPanelCard({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MemberProfileIpadColors.card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: MemberProfileIpadColors.text,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class MemberProfileIpadPill extends StatelessWidget {
  const MemberProfileIpadPill({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: foreground,
        ),
      ),
    );
  }
}
