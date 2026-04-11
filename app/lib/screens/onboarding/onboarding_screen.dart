import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  final _pages = const [
    _OnboardingPage(
      icon: Icons.pets,
      title: '宠物养成',
      description: '为家庭成员选择专属宠物，通过完成任务喂养宠物并慢慢升级。',
    ),
    _OnboardingPage(
      icon: Icons.task_alt,
      title: '任务互动',
      description: '家长发布任务，孩子完成任务后获得积分，和宠物一起成长。',
    ),
    _OnboardingPage(
      icon: Icons.family_restroom,
      title: '家庭联结',
      description: '创建家庭小组，邀请成员加入，让亲子互动变得更轻松有趣。',
    ),
  ];

  Future<void> _markOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(ApiConstants.onboardingKey, true);
  }

  Future<void> _goToLogin() async {
    await _markOnboardingDone();
    if (mounted) {
      context.go('/login');
    }
  }

  Future<void> _goToRegister() async {
    await _markOnboardingDone();
    if (mounted) {
      context.go('/register');
    }
  }

  void _goNext() {
    _controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF6E3),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) => _pages[index],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: index == _currentPage ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: index == _currentPage
                        ? const Color(0xFF006B1B)
                        : const Color(0xFFD7CEB6),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: isLastPage ? _goToLogin : _goNext,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF006B1B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    isLastPage ? '去登录' : '下一步',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: isLastPage ? _goToRegister : _goToLogin,
              child: Text(
                isLastPage ? '还没有账号？去注册' : '已有账号，直接登录',
                style: const TextStyle(
                  color: Color(0xFF755700),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFD7FFC3), Color(0xFFFFE9B0)],
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14006B1B),
                  blurRadius: 24,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            child: Icon(icon, size: 90, color: const Color(0xFF006B1B)),
          ),
          const SizedBox(height: 36),
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Color(0xFF755700),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              height: 1.6,
              color: Color(0xFF8A7752),
            ),
          ),
        ],
      ),
    );
  }
}
