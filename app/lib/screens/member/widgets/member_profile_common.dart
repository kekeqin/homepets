import 'package:flutter/material.dart';

class MemberProfileColors {
  static const background = Color(0xFFF9F1DE);
  static const shell = Color(0xFFF8EFD7);
  static const card = Color(0xFFFFFAEE);
  static const cardSoft = Color(0xFFF4EAD7);
  static const line = Color(0xFFE2D0A4);
  static const text = Color(0xFF6A501F);
  static const muted = Color(0xFF978056);
  static const green = Color(0xFF2C8C3B);
  static const greenSoft = Color(0xFFDFF0DA);
  static const gold = Color(0xFFF2C75B);
  static const goldDeep = Color(0xFF9A6710);
  static const blue = Color(0xFFCEE2F4);
  static const blueText = Color(0xFF48709C);
  static const coral = Color(0xFFCA765E);
  static const shadow = Color(0x14000000);
}

class MemberProfileGlow extends StatelessWidget {
  const MemberProfileGlow({super.key, required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class MemberProfileTopButton extends StatelessWidget {
  const MemberProfileTopButton({super.key, required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: MemberProfileColors.card.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: MemberProfileColors.shadow,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: MemberProfileColors.green, size: 20),
          ),
        ),
      ),
    );
  }
}

class MemberProfileSectionTitle extends StatelessWidget {
  const MemberProfileSectionTitle({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: MemberProfileColors.goldDeep,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            height: 1.45,
            color: MemberProfileColors.muted,
          ),
        ),
      ],
    );
  }
}

class MemberProfileEmptyCard extends StatelessWidget {
  const MemberProfileEmptyCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: MemberProfileColors.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: MemberProfileColors.shadow,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: MemberProfileColors.cardSoft,
            ),
            child: Icon(icon, color: MemberProfileColors.muted, size: 28),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: MemberProfileColors.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.55,
              color: MemberProfileColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}
