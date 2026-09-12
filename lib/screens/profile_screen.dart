import 'package:flutter/material.dart';

import 'update_screen.dart';

import '../core/theme.dart';
import '../widgets/chinese_decor.dart';
import '../core/l10n.dart';


class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.xuanZhi,
      appBar: AppBar(title: Text(tr('프로필 · 설정'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const UpdateEntryTile(),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.zhuHongDeep, AppColors.zhuHong],
              ),
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
                        style: TextStyle(
                          color: AppColors.xuanZhi,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tr('Day 1 · 입문'),
                        style: TextStyle(
                          color: AppColors.jinBright,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(tr('설정'),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: AppColors.mo,
                letterSpacing: 2,
              )),
          const SizedBox(height: 8),
          _SettingsGroup(items: [
            _SettingItem(
                icon: Icons.language,
                title: tr('언어 / Language'),
                subtitle: '${AppLangPrefs.lang.value.label}  →  ${AppLangPrefs.peekNext().label}',
                onTap: AppLangPrefs.next),
            _SettingItem(icon: Icons.volume_up, title: tr('TTS 음성'), subtitle: 'zh-CN-XiaoxiaoNeural'),
            _SettingItem(icon: Icons.palette, title: tr('테마'), subtitle: tr('낮 · 중국풍 #DE2910')),
          ]),
          const SizedBox(height: 16),
          Text(tr('정보'),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: AppColors.mo,
                letterSpacing: 2,
              )),
          const SizedBox(height: 8),
          _SettingsGroup(items: [
            _SettingItem(icon: Icons.info_outline, title: tr('앱 버전'), subtitle: tr('0.2.0 · alpha 중국풍')),
            _SettingItem(icon: Icons.code, title: 'Stack', subtitle: 'Flutter 3.41 · Material 3 · SQLite'),
            _SettingItem(icon: Icons.copyright, title: tr('저작권'), subtitle: tr('중국어유니버스 · 2026')),
          ]),
          const SizedBox(height: 20),
          const BrushDivider(),
          const SizedBox(height: 12),
          Center(
            child: XiText(size: 24),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              tr('학해무애 · 学海无涯'),
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
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<_SettingItem> items;
  const _SettingsGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.xuanZhi,
        border: Border.all(color: AppColors.jin.withValues(alpha: 0.5)),
      ),
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
              title: Text(items[i].title,
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.mo)),
              subtitle: Text(items[i].subtitle,
                  style: const TextStyle(color: AppColors.moLight, fontSize: 11)),
              trailing: const Icon(Icons.chevron_right, color: AppColors.zhuHong, size: 18),
            ),
            if (i < items.length - 1)
              Container(height: 0.5, color: AppColors.jin.withValues(alpha: 0.3)),
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
