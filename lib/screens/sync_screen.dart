import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/theme.dart';
import '../services/content_sync.dart';
import '../widgets/chinese_decor.dart';

/// 시작 로딩 화면 — 그림(장면 컷·단어 그림)을 기기에 내려받는 동안 진행률을 보이고, 끝나면 홈으로.
/// 「나중에」 = 앱을 먼저 열고 뒤에서 계속 받는다(사용자 지시 2026-11-04, 일본어앱 `sync_screen.dart` 를 옮김).
class SyncScreen extends StatefulWidget {
  final Widget next;
  const SyncScreen({super.key, required this.next});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  bool _left = false;

  @override
  void initState() {
    super.initState();
    ContentSync.instance.download().then((_) {
      if (mounted && !_left) _go();
    });
  }

  void _go() {
    _left = true;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, _, _) => widget.next,
      transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
      transitionDuration: const Duration(milliseconds: 350),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final (n, mb) = ContentSync.instance.estimate;
    return Scaffold(
      backgroundColor: AppColors.xuanZhi,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: ValueListenableBuilder<SyncProgress>(
                valueListenable: ContentSync.instance.progress,
                builder: (context, p, _) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Center(child: GradText(tr('중국어유니버스'), style: AppFonts.titleText(size: 26))),
                  const SizedBox(height: 28),
                  Text(tr('그림 준비 중'), textAlign: TextAlign.center, style: AppFonts.titleText(size: 18)),
                  const SizedBox(height: 8),
                  Text(tr('처음 한 번만 그림을 내려받습니다. 다음부터는 바로 열립니다.'), textAlign: TextAlign.center, style: AppFonts.uiText(size: 13, color: AppColors.moLight)),
                  const SizedBox(height: 22),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(value: p.total == 0 ? null : p.ratio, minHeight: 10, backgroundColor: AppColors.xuanZhiDeep, color: AppColors.copper),
                  ),
                  const SizedBox(height: 10),
                  Text('${p.done} / ${p.total}   ·   ${trf('그림 {0}장 · 약 {1}MB', [n, mb])}', textAlign: TextAlign.center, style: AppFonts.captionText(size: 12)),
                  const SizedBox(height: 28),
                  OutlinedButton(
                    onPressed: _go,
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.mo, side: const BorderSide(color: AppColors.line), shape: const StadiumBorder()),
                    child: Text(tr('나중에 — 앱 먼저 열기(뒤에서 계속 받음)'), style: AppFonts.uiText(size: 14, weight: FontWeight.w600)),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
