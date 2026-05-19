import 'package:flutter/material.dart';

class FamilyEmptyCard extends StatelessWidget {
  const FamilyEmptyCard({
    super.key,
    required this.canAddMembers,
    required this.onAddTap,
    this.compact = false,
  });

  final bool canAddMembers;
  final VoidCallback onAddTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final card = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 18 : 24),
        border: Border.all(
          color: const Color(0xFF3F230D),
          width: compact ? 2.2 : 2.6,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(compact ? 15 : 21),
        child: Padding(
          padding: EdgeInsets.all(compact ? 9 : 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: compact ? 34 : 46,
                child: _InviteNamePlate(compact: compact),
              ),
              Expanded(
                child: Center(child: _InviteSilhouette(compact: compact)),
              ),
              SizedBox(
                height: compact ? 50 : 58,
                child: _InviteFooter(
                  compact: compact,
                  canAddMembers: canAddMembers,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!canAddMembers) {
      return card;
    }

    return Tooltip(
      message: '邀请成员',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onAddTap,
        child: card,
      ),
    );
  }
}

class _InviteNamePlate extends StatelessWidget {
  const _InviteNamePlate({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFEF6).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(compact ? 15 : 18),
        border: Border.all(
          color: const Color(0xFFF2A12A),
          width: compact ? 1.3 : 1.6,
        ),
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '邀请成员',
            maxLines: 1,
            style: TextStyle(
              color: const Color(0xFF3E230F),
              fontSize: compact ? 24 : 30,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _InviteSilhouette extends StatelessWidget {
  const _InviteSilhouette({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 112.0 : 142.0;
    return SizedBox(
      width: size,
      height: size * 1.13,
      child: CustomPaint(
        painter: _InviteSilhouettePainter(),
        child: const Center(
          child: Icon(Icons.add_rounded, color: Colors.white, size: 52),
        ),
      ),
    );
  }
}

class _InviteFooter extends StatelessWidget {
  const _InviteFooter({required this.compact, required this.canAddMembers});

  final bool compact;
  final bool canAddMembers;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF3).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(compact ? 15 : 18),
        border: Border.all(
          color: const Color(0xFFF3A52F),
          width: compact ? 1.2 : 1.5,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 14),
        child: Row(
          children: [
            const Icon(Icons.pets_rounded, color: Color(0xFF6E3B10), size: 30),
            SizedBox(width: compact ? 8 : 12),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  canAddMembers ? '点击邀请' : '等待家长邀请',
                  maxLines: 1,
                  style: TextStyle(
                    color: const Color(0xFF3F230D),
                    fontSize: compact ? 19 : 22,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InviteSilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE4CBA8).withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = const Color(0xFF9E7041).withValues(alpha: 0.82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..addOval(
        Rect.fromCenter(
          center: Offset(size.width * 0.50, size.height * 0.28),
          width: size.width * 0.50,
          height: size.height * 0.44,
        ),
      )
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.width * 0.20,
            size.height * 0.46,
            size.width * 0.60,
            size.height * 0.48,
          ),
          Radius.circular(size.width * 0.26),
        ),
      );
    canvas.drawPath(path, paint);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _InviteSilhouettePainter oldDelegate) => false;
}
