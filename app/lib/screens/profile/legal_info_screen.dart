import 'package:flutter/material.dart';

import '../../core/support_links.dart';
import '../../widgets/pickstarpet_button.dart';

class LegalInfoScreen extends StatelessWidget {
  const LegalInfoScreen({super.key, required this.kind});

  final LegalInfoKind kind;

  @override
  Widget build(BuildContext context) {
    final title = switch (kind) {
      LegalInfoKind.privacy => '隐私政策',
      LegalInfoKind.terms => '用户协议',
      LegalInfoKind.support => '客服支持',
      LegalInfoKind.accountDelete => '删除账号/数据',
    };
    final body = switch (kind) {
      LegalInfoKind.privacy =>
        '我们只收集提供家庭任务、宠物成长和账号服务所需的信息。完整说明请查看在线隐私政策。',
      LegalInfoKind.terms =>
        '拾星小宠面向家长使用，孩子成员由家长创建和管理。完整约定请查看在线用户协议。',
      LegalInfoKind.support =>
        '订阅、账号、恢复购买或使用问题，可先查看帮助页 FAQ，或发送邮件至 ${SupportLinks.supportEmail}。',
      LegalInfoKind.accountDelete =>
        '可申请删除账号与相关家庭数据。处理完成后通常无法恢复。请发送邮件说明注册方式（手机号 / Apple）以便核实。',
    };

    return Scaffold(
      backgroundColor: const Color(0xFFFDF6E3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF6E3),
        foregroundColor: const Color(0xFF4D3623),
        title: Text(title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              body,
              style: const TextStyle(
                color: Color(0xFF5B4632),
                fontSize: 17,
                fontWeight: FontWeight.w700,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ..._actionButtons(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _actionButtons(BuildContext context) {
    return switch (kind) {
      LegalInfoKind.privacy => [
        PickStarPetButton(
          label: '查看完整隐私政策',
          onPressed: () => SupportLinks.openPrivacy(context),
        ),
      ],
      LegalInfoKind.terms => [
        PickStarPetButton(
          label: '查看完整用户协议',
          onPressed: () => SupportLinks.openTerms(context),
        ),
      ],
      LegalInfoKind.support => [
        PickStarPetButton(
          label: '打开帮助与支持',
          onPressed: () => SupportLinks.openSupportPage(context),
        ),
        const SizedBox(height: 12),
        PickStarPetButton(
          label: '发送邮件给客服',
          onPressed: () => SupportLinks.openSupportEmail(context),
        ),
      ],
      LegalInfoKind.accountDelete => [
        PickStarPetButton(
          label: '发送删除申请邮件',
          onPressed: () => SupportLinks.openDeleteAccountEmail(context),
        ),
        const SizedBox(height: 12),
        PickStarPetButton(
          label: '查看帮助说明',
          onPressed: () => SupportLinks.openSupportPage(context),
        ),
      ],
    };
  }
}

enum LegalInfoKind { privacy, terms, support, accountDelete }
