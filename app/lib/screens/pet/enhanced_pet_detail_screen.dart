import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../models/pet.dart';
import '../family/family_screen.dart';
import '../profile/profile_screen.dart';

class EnhancedPetDetailScreen extends ConsumerStatefulWidget {
  final Pet pet;

  const EnhancedPetDetailScreen({super.key, required this.pet});

  @override
  ConsumerState<EnhancedPetDetailScreen> createState() =>
      _EnhancedPetDetailScreenState();
}

class _EnhancedPetDetailScreenState
    extends ConsumerState<EnhancedPetDetailScreen> {
  List<Map<String, dynamic>> _growthHistory = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadGrowthHistory();
  }

  Future<void> _loadGrowthHistory() async {
    setState(() => _loading = true);
    try {
      final dio = ref.read(apiClientProvider).dio;
      final resp = await dio.get('/api/pets/${widget.pet.id}/history');
      setState(() {
        _growthHistory = (resp.data as List).cast<Map<String, dynamic>>();
      });
    } catch (_) {
      // Use sample data
      setState(() {
        _growthHistory = [
          {'action': '刷牙', 'points': 10, 'icon': 'brush', 'time': '今天 08:30'},
          {'action': '乱丢玩具', 'points': -5, 'icon': 'toys', 'time': '今天 10:15'},
          {'action': '早睡', 'points': 25, 'icon': 'bedtime', 'time': '昨天 20:30'},
        ];
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pet = widget.pet;
    final mood = _getPetMood();
    final age = _calculateAge();
    final evolutionProgress = pet.experience / (pet.levelThreshold ?? 1);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('宠物详情'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildPetHeader(pet, mood),
                const SizedBox(height: 16),
                _buildPetInfo(pet, age),
                const SizedBox(height: 16),
                _buildEvolutionProgress(pet, evolutionProgress),
                const SizedBox(height: 16),
                _buildGrowthJourney(),
                const SizedBox(height: 16),
                _buildEvolutionPath(pet),
                const SizedBox(height: 80),
              ],
            ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildPetHeader(Pet pet, String mood) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade400, Colors.purple.shade300],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.mood, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(mood, style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bolt, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '等级 ${pet.level}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(pet.displayEmoji, style: const TextStyle(fontSize: 80)),
          const SizedBox(height: 8),
          Text(
            pet.name,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetInfo(Pet pet, String age) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cake, color: Colors.pink),
                const SizedBox(width: 8),
                Text('$age 天龄', style: const TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.category, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  _getPetTypeName(pet.petType),
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvolutionProgress(Pet pet, double progress) {
    final nextForm = _getNextForm(pet.level);
    final currentExp = pet.experience;
    final threshold = pet.levelThreshold ?? 1000;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '进化进度',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text('下一形态: $nextForm'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          minHeight: 12,
                          backgroundColor: Colors.grey[200],
                          valueColor: const AlwaysStoppedAnimation(
                            Colors.purple,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$currentExp/$threshold',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '距离 $nextForm 还差 ${threshold - currentExp} 点！',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrowthJourney() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '成长历程',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_growthHistory.isEmpty)
              const Center(
                child: Text('暂无记录', style: TextStyle(color: Colors.grey)),
              )
            else
              ..._growthHistory.map((item) => _buildHistoryItem(item)),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> item) {
    final points = item['points'] as int;
    final isPositive = points >= 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isPositive ? Colors.green : Colors.red).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getHistoryIcon(item['icon'] ?? ''),
              color: isPositive ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['action'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  item['time'] ?? '',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Text(
            '${isPositive ? '+' : ''}$points',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isPositive ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvolutionPath(Pet pet) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '进化路径',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildEvolutionStage(pet.name, true, pet.level),
                _buildEvolutionArrow(),
                _buildEvolutionStage(_getNextForm(pet.level), false, 20),
                _buildEvolutionArrow(),
                _buildEvolutionStage('远古之灵', false, 50),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvolutionStage(String name, bool isCurrent, int level) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCurrent
                  ? Colors.purple.withOpacity(0.1)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: isCurrent ? Border.all(color: Colors.purple) : null,
            ),
            child: Column(
              children: [
                Icon(
                  isCurrent ? Icons.pets : Icons.lock,
                  color: isCurrent ? Colors.purple : Colors.grey,
                  size: 32,
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    color: isCurrent ? Colors.purple : Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  '等级 $level',
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvolutionArrow() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Icon(Icons.arrow_forward, color: Colors.grey, size: 20),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.pets,
                label: '首页',
                onTap: () => context.go('/home'),
              ),
              _NavItem(
                icon: Icons.assignment,
                label: '任务',
                onTap: () => context.go('/home?panel=tasks'),
              ),
              _NavItem(icon: Icons.redeem, label: '商店', onTap: () {}),
              _NavItem(
                icon: Icons.group,
                label: '家庭',
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const FamilyScreen()),
                ),
              ),
              _NavItem(
                icon: Icons.person,
                label: '我的',
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPetMood() {
    final happiness = widget.pet.experience / (widget.pet.levelThreshold ?? 1);
    if (happiness > 0.8) return '快乐';
    if (happiness > 0.5) return '满足';
    if (happiness > 0.3) return '一般';
    return '需要关爱';
  }

  String _calculateAge() {
    // Calculate age in days
    return '24';
  }

  String _getNextForm(int level) {
    if (level < 20) return '大恶魔';
    if (level < 50) return '远古之灵';
    return '传说形态';
  }

  String _getPetTypeName(String type) {
    switch (type) {
      case 'cat':
        return '猫咪类型';
      case 'dog':
        return '狗狗类型';
      case 'rabbit':
        return '兔子类型';
      case 'bird':
        return '小鸟类型';
      case 'turtle':
        return '乌龟类型';
      case 'fish':
        return '金鱼类型';
      default:
        return '宠物类型';
    }
  }

  IconData _getHistoryIcon(String icon) {
    switch (icon) {
      case 'brush':
        return Icons.brush;
      case 'toys':
        return Icons.toys;
      case 'bedtime':
        return Icons.bedtime;
      default:
        return Icons.history;
    }
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.grey, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
