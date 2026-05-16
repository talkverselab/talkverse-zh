import 'package:flutter/material.dart';

import 'conversation_screen.dart';
import 'hanzi_209_screen.dart';
import 'hanzi_screen.dart';
import 'hsk_screen.dart';
import 'profile_screen.dart';
import 'phonetic_roots_screen.dart';
import 'tone_matrix_screen.dart';
import 'word_freq_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;

  static const List<Widget> _screens = [
    HomeScreen(),
    ConversationScreen(),
    HanziScreen(),
    HskScreen(),
    ProfileScreen(),
  ];

  static const List<NavigationDestination> _tabs = [
    NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: '홈'),
    NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: '회화'),
    NavigationDestination(icon: Icon(Icons.text_fields_outlined), selectedIcon: Icon(Icons.text_fields), label: '한자'),
    NavigationDestination(icon: Icon(Icons.school_outlined), selectedIcon: Icon(Icons.school), label: 'HSK'),
    NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: '프로필'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: _tabs,
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('중국어유니버스'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primary, cs.primary.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '200자, 20일.',
                  style: TextStyle(
                    color: cs.onPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '진짜 회화 시작점.',
                  style: TextStyle(
                    color: cs.onPrimary.withValues(alpha: 0.9),
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '한자 209자로 회화 토큰 89% 청취.\nPhase 2 sweet spot 진입.',
                  style: TextStyle(
                    color: cs.onPrimary.withValues(alpha: 0.85),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _StatRow(),
          const SizedBox(height: 24),
          Text('학습 모듈', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _ModuleCard(
            icon: Icons.chat_bubble,
            title: '핵심 회화 200',
            subtitle: 'Mark·小丽 매칭 → 미래. 5 ep × 40 turn.',
            color: cs.primary,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ConversationScreen()),
            ),
          ),
          _ModuleCard(
            icon: Icons.star,
            title: 'Phase 2 한자 209자',
            subtitle: '회화 토큰 89% 커버. ⭐ 차별화 IP.',
            color: const Color(0xFFE53935),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Hanzi209Screen()),
            ),
          ),
          _ModuleCard(
            icon: Icons.text_fields,
            title: '한자 Top 500',
            subtitle: 'opus zh_cn 빈도. HSK 분급 컬러.',
            color: cs.secondary,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HanziScreen()),
            ),
          ),
          _ModuleCard(
            icon: Icons.graphic_eq,
            title: '성조 매트릭스',
            subtitle: '4×4 = 16 + 경성 4. 160 단어 트랙.',
            color: const Color(0xFF1E88E5),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ToneMatrixScreen()),
            ),
          ),
          _ModuleCard(
            icon: Icons.list_alt,
            title: '단어 빈도 2500',
            subtitle: 'R1·R2·R3·R4 구간. opus CD-weighted.',
            color: const Color(0xFF43A047),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WordFreqScreen()),
            ),
          ),
          _ModuleCard(
            icon: Icons.scatter_plot,
            title: '발음부 (성부)',
            subtitle: '한자 발음부 + 한국 한자음 매핑. ⭐ IP.',
            color: const Color(0xFFAB47BC),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PhoneticRootsScreen()),
            ),
          ),
          _ModuleCard(
            icon: Icons.school,
            title: 'HSK 한자 1-7급',
            subtitle: '신HSK 2021 분급 (krmanik).',
            color: cs.tertiary,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HskScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(value: '209', label: 'Phase 2 한자')),
        SizedBox(width: 12),
        Expanded(child: _StatCard(value: '89%', label: '청취 커버')),
        SizedBox(width: 12),
        Expanded(child: _StatCard(value: '2500', label: '단어 풀')),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cs.primary)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
  const _ModuleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
