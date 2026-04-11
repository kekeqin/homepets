import 'package:flutter/material.dart';

import 'member_profile_ipad_screen.dart';
import 'member_profile_screen.dart';

class MemberDetailScreen extends StatelessWidget {
  const MemberDetailScreen({
    super.key,
    required this.memberId,
    required this.nickname,
    required this.role,
  });

  final int memberId;
  final String nickname;
  final String role;

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width >= 900;
    if (isTablet) {
      return MemberProfileIpadScreen(
        memberId: memberId,
        nickname: nickname,
        role: role,
      );
    }

    return MemberProfileScreen(
      memberId: memberId,
      nickname: nickname,
      role: role,
    );
  }
}
