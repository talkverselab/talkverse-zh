import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'font_licenses_screen.dart';
import 'login_screen.dart';
import 'paywall_screen.dart';
import 'about_screen.dart';

import '../core/pane.dart';
import '../core/theme.dart';
import '../widgets/chinese_decor.dart';
import '../core/l10n.dart';
import '../data/account.dart';
import '../data/entitlement.dart';
import '../data/purchase.dart';
import '../widgets/legal_links.dart';
import '../services/ko_reading.dart';
import '../services/learner_prefs.dart';
import '../widgets/achievement_desk.dart';

/// 프로필 · 설정 — 계정(Talkverse ID·평생 이용권) · 성과 · 학습자 프로필(이름·성별 → 회화 「나」) · 설정 · 정보.
/// embedded = 「나」 탭 안(앱바·스크롤 없이 바깥 ListView 에 들어감) — 일본어앱 구조(2026-11-02).
class ProfileScreen extends StatefulWidget {
  final bool embedded;
  const ProfileScreen({super.key, this.embedded = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _version = '…';

  @override
  void initState() {
    super.initState();
    KoReadingPrefs.show.addListener(_refresh);
    PackageInfo.fromPlatform().then((i) {
      if (mounted) setState(() => _version = '${i.version} (${i.buildNumber})');
    }).catchError((_) {});
  }

  @override
  void dispose() {
    KoReadingPrefs.show.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _editName() async {
    final c = TextEditingController(text: LearnerPrefs.name.value);
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('이름')),
        content: TextField(
          controller: c,
          maxLength: 20,
          autofocus: true,
          decoration: InputDecoration(hintText: tr('회화 속 「나」로 나와요')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('취소'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text), child: Text(tr('저장'))),
        ],
      ),
    );
    if (v == null) return;
    await LearnerPrefs.setName(v);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.zhuHongDeep, AppColors.zhuHong]),
          border: Border.all(color: AppColors.jin, width: 1.5),
        ),
        child: Row(
          children: [
            const SealStamp(text: '学', size: 60),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('학습자'),
                    style: TextStyle(color: AppColors.xuanZhi, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tr('Day 1 · 입문'),
                    style: TextStyle(color: AppColors.jinBright, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      Text(
        tr('계정'),
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.mo, letterSpacing: 2),
      ),
      const SizedBox(height: 8),
      const _AccountSection(),
      const SizedBox(height: 18),
      Text(
        tr('성과'),
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.mo, letterSpacing: 2),
      ),
      const SizedBox(height: 8),
      const AchievementDesk(),
      const SizedBox(height: 18),
      Text(
        tr('학습자 프로필'),
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.mo, letterSpacing: 2),
      ),
      const SizedBox(height: 8),
      _SettingsGroup(
        items: [
          _SettingItem(
            icon: Icons.badge_outlined,
            title: tr('이름'),
            subtitle: LearnerPrefs.name.value.isNotEmpty ? trf('{0} — 회화 속 「나」로 나와요', [LearnerPrefs.name.value]) : tr('없음 — 회화에서 「○○」로 보여요'),
            onTap: _editName,
          ),
          _SettingItem(
            icon: LearnerPrefs.isFemale ? Icons.face_3 : Icons.face,
            title: tr('성별 (화자 「나」의 목소리)'),
            subtitle: LearnerPrefs.isFemale ? tr('여성 — 탭하면 남성') : tr('남성 — 탭하면 여성'),
            onTap: () async {
              await LearnerPrefs.setGender(LearnerPrefs.isFemale ? 'male' : 'female');
              if (mounted) setState(() {});
            },
          ),
        ],
      ),
      const SizedBox(height: 18),
      Text(
        tr('설정'),
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.mo, letterSpacing: 2),
      ),
      const SizedBox(height: 8),
      _SettingsGroup(
        items: [
          _SettingItem(
            icon: Icons.language,
            title: tr('언어 / Language'),
            subtitle: '${AppLangPrefs.lang.value.label}  →  ${AppLangPrefs.peekNext().label}',
            onTap: AppLangPrefs.next,
          ),
          _SettingItem(
            icon: Icons.translate,
            title: tr('읽기 보조(병음·독음)'),
            subtitle: KoReadingPrefs.show.value ? tr('표시 — 탭하면 숨김') : tr('숨김(기본) — 탭하면 표시'),
            onTap: () => KoReadingPrefs.toggleWithHint(context),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Text(
        tr('정보'),
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.mo, letterSpacing: 2),
      ),
      const SizedBox(height: 8),
      _SettingsGroup(
        items: [
          _SettingItem(icon: Icons.menu_book_outlined, title: tr('앱 소개'), subtitle: tr('절벽구간 — 단어·한자 기준과 산출 방식'), onTap: () => openPane(context, (_) => const AboutScreen())),
          _SettingItem(icon: Icons.info_outline, title: tr('앱 버전'), subtitle: _version),
          _SettingItem(icon: Icons.description_outlined, title: tr('이용약관'), subtitle: 'talkverse.uk/terms', onTap: () => Legal.open(Legal.terms)),
          _SettingItem(icon: Icons.privacy_tip_outlined, title: tr('개인정보처리방침'), subtitle: 'talkverse.uk/talkverse/zh/privacy', onTap: () => Legal.open(Legal.privacy)),
          _SettingItem(icon: Icons.copyright, title: tr('저작권'), subtitle: tr('중국어유니버스 · 2026')),
          _SettingItem(
            icon: Icons.font_download_outlined,
            title: tr('글꼴 라이선스'),
            subtitle: 'Pretendard · Noto Sans SC · LXGW WenKai GB · Noto Sans — SIL OFL 1.1',
            onTap: () => openPane(context, (_) => const FontLicensesScreen()),
          ),
        ],
      ),
      const SizedBox(height: 20),
      const BrushDivider(),
      const SizedBox(height: 12),
      Center(child: XiText(size: 24)),
      const SizedBox(height: 4),
      Center(
        child: Text(tr('학해무애 · 学海无涯'), style: TextStyle(color: AppColors.moLight, fontSize: 11, letterSpacing: 4)),
      ),
      const SizedBox(height: 32),
    ];
    if (widget.embedded) return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
    return Scaffold(
      backgroundColor: AppColors.xuanZhi,
      appBar: AppBar(title: Text(tr('프로필 · 설정'))),
      body: SafeArea(
        top: false,
        child: ListView(padding: const EdgeInsets.all(16), children: children),
      ),
    );
  }
}

/// Talkverse 계정(선택) — 로그인 전: 로그인 / 후: 이름·이메일·로그아웃·계정 삭제(스토어 심사 요구) + 평생 이용권·구매 복원.
/// 한자앱 me_screen `_account` 를 옮김(2026-11-02).
class _AccountSection extends StatelessWidget {
  const _AccountSection();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, dynamic>?>(
      valueListenable: Account.user,
      builder: (context, u, _) => ValueListenableBuilder<String?>(
        valueListenable: Purchase.status,
        builder: (context, st, _) => _SettingsGroup(
          items: [
            if (u == null)
              _SettingItem(
                icon: Icons.account_circle_outlined,
                title: tr('로그인'),
                subtitle: tr('Talkverse 계정 하나로 모든 앱에서'),
                onTap: () => LoginScreen.open(context),
              )
            else ...[
              _SettingItem(icon: Icons.account_circle, title: (u['display_name'] as String?) ?? tr('이름 없음'), subtitle: (u['email'] as String?) ?? ''),
              _SettingItem(icon: Icons.logout, title: tr('로그아웃'), subtitle: '', onTap: Account.signOut),
              _SettingItem(icon: Icons.person_remove_outlined, title: tr('계정 삭제'), subtitle: '', onTap: () => _confirmDelete(context)),
            ],
            _SettingItem(
              icon: Icons.workspace_premium_outlined,
              title: tr('이용권'),
              subtitle: Entitlement.premium ? tr('보유 중') : tr('1개월·3개월·1년·평생 · 구매 또는 이전 구매 복원'),
              onTap: () => PaywallScreen.show(context),
            ),
            _SettingItem(
              icon: Icons.restore,
              title: tr('구매 복원'),
              subtitle: switch (st) {
                'pending' => tr('확인 중…'),
                'restored' => tr('복원했습니다'),
                'nothing' => tr('복원할 구매가 없습니다'),
                _ => tr('이전에 산 이용권을 이 기기에서 다시 엽니다'),
              },
              onTap: Purchase.restore,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(tr('계정을 삭제할까요?')),
        content: Text(tr('Talkverse 계정과 이름·이메일·로그인 정보가 지워지고 모든 기기에서 로그아웃됩니다. 이 기기의 학습 기록은 그대로 남습니다. 되돌릴 수 없습니다.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(tr('취소'))),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(tr('삭제'), style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Account.deleteAccount();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('삭제하지 못했습니다. 네트워크를 확인하고 다시 시도해 주세요.'))));
      }
    }
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<_SettingItem> items;
  const _SettingsGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    // ListTile 은 가장 가까운 Material 에 잉크를 그리므로 색 있는 Container 대신 Material 로 감싼다
    return Material(
      color: AppColors.xuanZhi,
      shape: Border.all(color: AppColors.jin.withValues(alpha: 0.5)),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            ListTile(
              onTap: items[i].onTap,
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.zhuHong.withValues(alpha: 0.1),
                  border: Border.all(color: AppColors.zhuHong, width: 0.8),
                ),
                child: Icon(items[i].icon, color: AppColors.zhuHong, size: 18),
              ),
              title: Text(
                items[i].title,
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.mo),
              ),
              subtitle: items[i].subtitle.isEmpty ? null : Text(items[i].subtitle, style: const TextStyle(color: AppColors.moLight, fontSize: 11)),
              trailing: const Icon(Icons.chevron_right, color: AppColors.zhuHong, size: 18),
            ),
            if (i < items.length - 1) Container(height: 0.5, color: AppColors.jin.withValues(alpha: 0.3)),
          ],
        ],
      ),
    );
  }
}

class _SettingItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  _SettingItem({required this.icon, required this.title, required this.subtitle, this.onTap});
}
