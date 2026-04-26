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
  static const _steps = [
    _OnboardingStep(
      title: '第一步：创建家庭',
      description: '家长先创建一个家庭空间，家里的成员、任务和宠物都会放在这里。',
      illustration: _IllustrationKind.createFamily,
      accentColor: Color(0xFFA9C68A),
    ),
    _OnboardingStep(
      title: '第二步：添加孩子',
      description: '为孩子添加成员资料，并选择一只专属宠物作为成长伙伴。',
      illustration: _IllustrationKind.addChild,
      accentColor: Color(0xFFF6A5A5),
    ),
    _OnboardingStep(
      title: '第三步：发布亲子任务',
      description: '家长设置整理玩具、阅读、运动等任务，和孩子一起约定完成目标。',
      illustration: _IllustrationKind.publishTask,
      accentColor: Color(0xFFF2D27B),
    ),
    _OnboardingStep(
      title: '第四步：喂养宠物升级',
      description: '孩子完成任务后获得食物，用来喂养宠物，宠物会慢慢升级。',
      illustration: _IllustrationKind.feedPet,
      accentColor: Color(0xFFC79B6E),
    ),
  ];

  final _controller = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _markOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(ApiConstants.onboardingKey, true);
  }

  Future<void> _finishAndGo(String location) async {
    await _markOnboardingDone();
    if (mounted) {
      context.go(location);
    }
  }

  Future<void> _skipOnboarding() {
    return _finishAndGo('/login');
  }

  Future<void> _startUsing() {
    return _finishAndGo('/register');
  }

  void _goNext() {
    if (_currentPage == _steps.length - 1) {
      _startUsing();
      return;
    }

    _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _steps.length - 1;

    return Scaffold(
      backgroundColor: _OnboardingPalette.pageBottom,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_OnboardingPalette.pageTop, _OnboardingPalette.pageBottom],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _steps.length,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemBuilder: (context, index) {
                    return _OnboardingStepPage(
                      step: _steps[index],
                      pageNumber: index + 1,
                      pageCount: _steps.length,
                    );
                  },
                ),
              ),
              _OnboardingFooter(
                currentPage: _currentPage,
                pageCount: _steps.length,
                isLastPage: isLastPage,
                onSkip: _skipOnboarding,
                onNext: _goNext,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPalette {
  static const pageTop = Color(0xFFFFF8EC);
  static const pageBottom = Color(0xFFF1E2C8);
  static const panel = Color(0xFFFFF4E4);
  static const panelSoft = Color(0xFFF6E6C8);
  static const line = Color(0xFFD8BFA6);
  static const ink = Color(0xFF4A3A2A);
  static const text = Color(0xFF684328);
  static const muted = Color(0xFF8B6F55);
  static const green = Color(0xFF8FAF7A);
  static const pink = Color(0xFFF6A5A5);
  static const yellow = Color(0xFFF2D27B);
}

enum _IllustrationKind { createFamily, addChild, publishTask, feedPet }

class _OnboardingStep {
  const _OnboardingStep({
    required this.title,
    required this.description,
    required this.illustration,
    required this.accentColor,
  });

  final String title;
  final String description;
  final _IllustrationKind illustration;
  final Color accentColor;
}

class _OnboardingStepPage extends StatelessWidget {
  const _OnboardingStepPage({
    required this.step,
    required this.pageNumber,
    required this.pageCount,
  });

  final _OnboardingStep step;
  final int pageNumber;
  final int pageCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 560;
        final illustrationHeight = compact ? 232.0 : 318.0;
        final topGap = compact ? 8.0 : 18.0;
        final titleGap = compact ? 20.0 : 30.0;

        return Padding(
          padding: EdgeInsets.fromLTRB(24, topGap, 24, compact ? 10 : 18),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StepCounter(pageNumber: pageNumber, pageCount: pageCount),
                  SizedBox(height: compact ? 12 : 18),
                  _OnboardingIllustration(
                    kind: step.illustration,
                    height: illustrationHeight,
                    accentColor: step.accentColor,
                  ),
                  SizedBox(height: titleGap),
                  Text(
                    step.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _OnboardingPalette.text,
                      fontSize: compact ? 24 : 28,
                      fontWeight: FontWeight.w900,
                      height: 1.18,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    step.description,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _OnboardingPalette.muted,
                      fontSize: compact ? 14 : 16,
                      fontWeight: FontWeight.w600,
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StepCounter extends StatelessWidget {
  const _StepCounter({required this.pageNumber, required this.pageCount});

  final int pageNumber;
  final int pageCount;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _OnboardingPalette.line),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        child: Text(
          '教程 $pageNumber / $pageCount',
          style: const TextStyle(
            color: _OnboardingPalette.muted,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _OnboardingIllustration extends StatelessWidget {
  const _OnboardingIllustration({
    required this.kind,
    required this.height,
    required this.accentColor,
  });

  static const _familyAsset = 'assets/images/ui/family_man_trim.png';
  static const _addMemberAsset = 'assets/images/ui/add_member_flow_screen.png';
  static const _taskAsset = 'assets/images/ui/task_sheet.png';
  static const _catAsset = 'assets/images/pets/cat_sit.png';
  static const _basketAsset = 'assets/images/ui/shop_basket.png';

  final _IllustrationKind kind;
  final double height;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(32);

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: _OnboardingPalette.panel,
        borderRadius: borderRadius,
        border: Border.all(color: _OnboardingPalette.line, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A6B3608),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _IllustrationBackdropPainter(accentColor),
            ),
          ),
          Positioned.fill(child: _buildScene(context)),
        ],
      ),
    );
  }

  Widget _buildScene(BuildContext context) {
    switch (kind) {
      case _IllustrationKind.createFamily:
        return _CreateFamilyIllustration(asset: _familyAsset);
      case _IllustrationKind.addChild:
        return _AddChildIllustration(asset: _addMemberAsset);
      case _IllustrationKind.publishTask:
        return _PublishTaskIllustration(asset: _taskAsset);
      case _IllustrationKind.feedPet:
        return _FeedPetIllustration(
          catAsset: _catAsset,
          basketAsset: _basketAsset,
        );
    }
  }
}

class _CreateFamilyIllustration extends StatelessWidget {
  const _CreateFamilyIllustration({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          left: 18,
          top: 18,
          child: _SoftIconBadge(
            icon: Icons.home_rounded,
            color: _OnboardingPalette.green,
          ),
        ),
        Positioned(
          right: 22,
          top: 30,
          child: _SoftIconBadge(
            icon: Icons.favorite_rounded,
            color: _OnboardingPalette.pink,
            size: 42,
          ),
        ),
        Positioned(
          left: 22,
          right: 18,
          bottom: 14,
          child: Image.asset(
            asset,
            height: 220,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      ],
    );
  }
}

class _AddChildIllustration extends StatelessWidget {
  const _AddChildIllustration({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          top: 20,
          left: 28,
          child: _SoftIconBadge(
            icon: Icons.child_care_rounded,
            color: _OnboardingPalette.pink,
          ),
        ),
        Positioned(
          right: 24,
          top: 42,
          child: _SoftIconBadge(
            icon: Icons.pets_rounded,
            color: _OnboardingPalette.green,
            size: 42,
          ),
        ),
        Positioned(
          top: 28,
          bottom: 24,
          width: 170,
          child: _PhoneMockup(
            child: Image.asset(
              asset,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
      ],
    );
  }
}

class _PublishTaskIllustration extends StatelessWidget {
  const _PublishTaskIllustration({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          left: 24,
          top: 28,
          child: _SoftIconBadge(
            icon: Icons.edit_note_rounded,
            color: _OnboardingPalette.yellow,
          ),
        ),
        Positioned(
          right: 22,
          bottom: 28,
          child: _SoftIconBadge(
            icon: Icons.check_rounded,
            color: _OnboardingPalette.green,
            size: 42,
          ),
        ),
        Positioned(
          top: 18,
          bottom: 10,
          width: 210,
          child: Transform.rotate(
            angle: -0.035,
            child: Image.asset(
              asset,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      ],
    );
  }
}

class _FeedPetIllustration extends StatelessWidget {
  const _FeedPetIllustration({
    required this.catAsset,
    required this.basketAsset,
  });

  final String catAsset;
  final String basketAsset;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          top: 22,
          left: 30,
          child: _SoftIconBadge(
            icon: Icons.restaurant_rounded,
            color: _OnboardingPalette.yellow,
          ),
        ),
        Positioned(
          right: 30,
          top: 32,
          child: _SoftIconBadge(
            icon: Icons.auto_awesome_rounded,
            color: _OnboardingPalette.pink,
            size: 44,
          ),
        ),
        Positioned(
          right: 26,
          bottom: 18,
          child: Image.asset(
            basketAsset,
            height: 92,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
        Positioned(
          left: 32,
          right: 66,
          bottom: -36,
          child: Image.asset(
            catAsset,
            height: 260,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      ],
    );
  }
}

class _PhoneMockup extends StatelessWidget {
  const _PhoneMockup({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _OnboardingPalette.ink, width: 2.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x186B3608),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _SoftIconBadge extends StatelessWidget {
  const _SoftIconBadge({
    required this.icon,
    required this.color,
    this.size = 48,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _OnboardingPalette.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x126B3608),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: size * 0.52),
    );
  }
}

class _IllustrationBackdropPainter extends CustomPainter {
  const _IllustrationBackdropPainter(this.accentColor);

  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    paint.color = _OnboardingPalette.panelSoft;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          18,
          size.height * 0.2,
          size.width - 36,
          size.height * 0.58,
        ),
        const Radius.circular(32),
      ),
      paint,
    );

    paint.color = accentColor.withValues(alpha: 0.42);
    final path = Path()
      ..moveTo(0, size.height * 0.7)
      ..quadraticBezierTo(
        size.width * 0.22,
        size.height * 0.6,
        size.width * 0.46,
        size.height * 0.7,
      )
      ..quadraticBezierTo(
        size.width * 0.74,
        size.height * 0.82,
        size.width,
        size.height * 0.68,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);

    paint
      ..color = Colors.white.withValues(alpha: 0.46)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var x = 28.0; x < size.width - 22; x += 28) {
      canvas.drawLine(
        Offset(x, size.height * 0.16),
        Offset(x + 10, size.height * 0.16),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _IllustrationBackdropPainter oldDelegate) {
    return oldDelegate.accentColor != accentColor;
  }
}

class _OnboardingFooter extends StatelessWidget {
  const _OnboardingFooter({
    required this.currentPage,
    required this.pageCount,
    required this.isLastPage,
    required this.onSkip,
    required this.onNext,
  });

  final int currentPage;
  final int pageCount;
  final bool isLastPage;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
      child: Row(
        children: [
          SizedBox(
            width: 76,
            height: 46,
            child: TextButton(
              onPressed: onSkip,
              style: TextButton.styleFrom(
                foregroundColor: _OnboardingPalette.muted,
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
              child: const Text('跳过'),
            ),
          ),
          Expanded(
            child: Center(
              child: _PageIndicator(
                currentPage: currentPage,
                pageCount: pageCount,
              ),
            ),
          ),
          SizedBox(
            width: isLastPage ? 104 : 88,
            height: 46,
            child: FilledButton(
              onPressed: onNext,
              style: FilledButton.styleFrom(
                backgroundColor: _OnboardingPalette.green,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              child: Text(isLastPage ? '开始使用' : '下一步'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.currentPage, required this.pageCount});

  final int currentPage;
  final int pageCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        pageCount,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: index == currentPage ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: index == currentPage
                ? _OnboardingPalette.green
                : _OnboardingPalette.line,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}
