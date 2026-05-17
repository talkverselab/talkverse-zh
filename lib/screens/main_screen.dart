import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../widgets/chinese_decor.dart';
import 'conversation_screen.dart';
import 'hanzi_209_screen.dart';
import 'hanzi_screen.dart';
import 'hsk_screen.dart';
import 'phonetic_roots_screen.dart';
import 'profile_screen.dart';
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
    return Scaffold(
      backgroundColor: AppColors.xuanZhi,
      appBar: AppBar(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('中', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.jinBright)),
            SizedBox(width: 8),
            Text('중국어유니버스', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 1)),
          ],
        ),
        backgroundColor: AppColors.zhuHong,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: Center(child: Lantern(size: 22)),
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: CloudPattern(opacity: 0.06)),
          ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              const _HeroBanner(),
              const SizedBox(height: 16),
              const _StatsBar(),
              const SizedBox(height: 20),
              const GreekKeyDivider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  const SealStamp(text: '学', size: 24),
                  const SizedBox(width: 10),
                  Text(
                    '학습 모듈',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.mo,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _ModuleCard(
                title: '핵심 회화 200',
                subtitle: 'Mark · 小丽 매칭 → 미래. 5 ep × 40 turn.',
                sealText: '会话',
                accent: AppColors.zhuHong,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ConversationScreen()),
                ),
              ),
              _ModuleCard(
                title: '⭐ 회화 시작점 한자 209',
                subtitle: '회화 토큰 89% 청취. Talkverse 차별화 IP.',
                sealText: '209',
                accent: const Color(0xFFC62828),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const Hanzi209Screen()),
                ),
              ),
              _ModuleCard(
                title: '한자 빈도 Top 500',
                subtitle: 'opus zh_cn 빈도. HSK 분급 컬러.',
                sealText: '常用',
                accent: AppColors.jin,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HanziScreen()),
                ),
              ),
              _ModuleCard(
                title: '4성 매트릭스',
                subtitle: '4×4 + 경성 4. 160 단어 학습 트랙.',
                sealText: '声调',
                accent: const Color(0xFF1565C0),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ToneMatrixScreen()),
                ),
              ),
              _ModuleCard(
                title: '단어 빈도 2500',
                subtitle: 'R1·R2·R3·R4 구간. opus CD-weighted.',
                sealText: '词频',
                accent: AppColors.feiCui,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WordFreqScreen()),
                ),
              ),
              _ModuleCard(
                title: '발음부 + 한국 한자음',
                subtitle: '발음부 200 → HSK1-5 1500자. ⭐ 차별화 IP.',
                sealText: '声旁',
                accent: const Color(0xFF6A1B9A),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PhoneticRootsScreen()),
                ),
              ),
              _ModuleCard(
                title: 'HSK 한자 1-7급',
                subtitle: '신HSK 2021 분급 (krmanik).',
                sealText: 'HSK',
                accent: AppColors.jinDeep,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HskScreen()),
                ),
              ),
              const SizedBox(height: 24),
              const BrushDivider(),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  '중국어유니버스 · 2026',
                  style: TextStyle(
                    color: AppColors.moLight,
                    fontSize: 11,
                    letterSpacing: 4,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.zhuHongDeep, AppColors.zhuHong],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.jin, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.zhuHong.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 14,
            right: 14,
            child: Row(
              children: const [
                ChineseStar(size: 18, color: AppColors.jinBright),
                SizedBox(width: 4),
                ChineseStar(size: 10, color: AppColors.jinBright),
                SizedBox(width: 4),
                ChineseStar(size: 10, color: AppColors.jinBright),
                SizedBox(width: 4),
                ChineseStar(size: 10, color: AppColors.jinBright),
                SizedBox(width: 4),
                ChineseStar(size: 10, color: AppColors.jinBright),
              ],
            ),
          ),
          const Positioned(
            bottom: 14,
            right: 14,
            child: SealStamp(text: '正', size: 44),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 80, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '한국 학습자 전용',
                  style: TextStyle(
                    color: AppColors.jinBright,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '200자, 20일.',
                  style: TextStyle(
                    color: AppColors.xuanZhi,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '진짜 회화 시작점.',
                  style: TextStyle(
                    color: AppColors.xuanZhi.withValues(alpha: 0.92),
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Container(width: 40, height: 2, color: AppColors.jinBright),
                const SizedBox(height: 10),
                Text(
                  '한자 209자로 회화 토큰 89% 청취.\nPhase 2 sweet spot 진입.',
                  style: TextStyle(
                    color: AppColors.xuanZhi.withValues(alpha: 0.88),
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsBar extends StatelessWidget {
  const _StatsBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.xuanZhiDeep,
        border: Border.all(color: AppColors.jin.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          _StatCell(value: '209', label: '핵심 한자'),
          _Divider(),
          _StatCell(value: '89%', label: '청취 커버'),
          _Divider(),
          _StatCell(value: '2500', label: '단어 풀'),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 0.6, height: 56, color: AppColors.jin.withValues(alpha: 0.5));
  }
}

class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  const _StatCell({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.zhuHong,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.moLight,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String sealText;
  final Color accent;
  final VoidCallback? onTap;
  const _ModuleCard({
    required this.title,
    required this.subtitle,
    required this.sealText,
    required this.accent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.xuanZhi,
            border: Border.all(color: AppColors.jin.withValues(alpha: 0.45), width: 0.8),
            boxShadow: [
              BoxShadow(
                color: AppColors.mo.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(1, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                color: accent,
                alignment: Alignment.center,
                child: SealStamp(text: sealText, size: 40, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.mo,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.moLight,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(Icons.chevron_right, color: AppColors.zhuHong, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
