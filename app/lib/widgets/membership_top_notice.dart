import 'dart:async';

import 'package:flutter/material.dart';

const String membershipRequiredMessage = '试用期已结束，请开通会员后继续操作';

class MembershipTopNotice {
  MembershipTopNotice._();

  static OverlayEntry? _entry;
  static Timer? _timer;

  static void show(
    BuildContext context, {
    String message = membershipRequiredMessage,
    VoidCallback? onTap,
    Duration duration = const Duration(milliseconds: 2400),
  }) {
    _timer?.cancel();
    _entry?.remove();
    _timer = null;
    _entry = null;

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(
            16,
            MediaQuery.paddingOf(context).top + 16,
            16,
            16,
          ),
        ),
      );
      return;
    }

    final topPadding = MediaQuery.paddingOf(context).top;
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        left: 16,
        right: 16,
        top: topPadding + 12,
        child: SafeArea(
          bottom: false,
          child: _MembershipNoticeCard(message: message, onTap: onTap),
        ),
      ),
    );

    _entry = entry;
    overlay.insert(entry);
    _timer = Timer(duration, () {
      if (_entry != entry) {
        return;
      }
      entry.remove();
      _entry = null;
      _timer = null;
    });
  }

  static void clear() {
    _timer?.cancel();
    _entry?.remove();
    _timer = null;
    _entry = null;
  }
}

class MembershipStatusBanner extends StatelessWidget {
  const MembershipStatusBanner({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _MembershipNoticeCard(
      message: membershipRequiredMessage,
      persistent: true,
      onTap: onTap,
    );
  }
}

class _MembershipNoticeCard extends StatelessWidget {
  const _MembershipNoticeCard({
    required this.message,
    this.persistent = false,
    this.onTap,
  });

  final String message;
  final bool persistent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5D6).withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7BF69), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x27604429),
            blurRadius: 16,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_rounded,
              color: const Color(0xFF8A5B20),
              size: persistent ? 18 : 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF654526),
                  fontSize: persistent ? 14 : 15,
                  fontWeight: FontWeight.w900,
                  height: 1.12,
                ),
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 8),
              Text(
                '去开通',
                style: TextStyle(
                  color: const Color(0xFF9C5C12),
                  fontSize: persistent ? 13 : 14,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    return Material(
      color: Colors.transparent,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: onTap == null
              ? IgnorePointer(child: content)
              : InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: onTap,
                  child: content,
                ),
        ),
      ),
    );
  }
}
