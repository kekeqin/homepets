import 'package:flutter/material.dart';

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
      LegalInfoKind.privacy => '我们只收集提供家庭任务、宠物成长和账号服务所需的信息。',
      LegalInfoKind.terms => 'HomePets 面向家长使用，孩子成员由家长创建和管理。',
      LegalInfoKind.support => '如需处理订阅、账号或数据问题，请联系 support@homepets.app。',
      LegalInfoKind.accountDelete => '你可以联系客服删除账号和相关家庭数据，处理完成后将无法恢复。',
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
        child: Text(
          body,
          style: const TextStyle(
            color: Color(0xFF5B4632),
            fontSize: 17,
            fontWeight: FontWeight.w700,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

enum LegalInfoKind { privacy, terms, support, accountDelete }
