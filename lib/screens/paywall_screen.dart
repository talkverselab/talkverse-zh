import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../data/account.dart';
import '../data/purchase.dart';
import '../widgets/legal_links.dart';
import 'login_screen.dart';

/// 유료 잠금 시트 — 상품 고르기 + 인앱 결제(출시 점검 2026-11-09, 일본어앱 6ed3774 이식 + 최종 가격표: 정가 취소선·할인가).
/// 스토어 규정: 가격·기간·자동 갱신·해지 방법을 구매 버튼 가까이, 평생은 「서비스 운영 기간 동안」, 구매 복원, 미리 선택된 상품 없음,
/// 약관·개인정보처리방침 링크. 앱 안에서 사이트 가격을 안내·유도하지 않는다.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  static Future<void> show(BuildContext context) {
    Purchase.status.value = null;
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.xuanZhi,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (_) => const PaywallScreen(),
    );
  }

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  String? _sel; // 미리 고르지 않는다

  static String _won(int v) => '₩${v.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}';

  String _title(Plan p) => switch ((p.bundle, p.months)) {
        (false, 1) => tr('1개월'),
        (false, 3) => tr('3개월'),
        (false, 12) => tr('1년'),
        (false, _) => tr('평생 이용권(서비스 운영 기간 동안)'),
        (true, 12) => tr('종합 패키지 1년 — 모든 언어'),
        (true, _) => tr('종합 패키지 평생 — 모든 언어(서비스 운영 기간 동안)'),
      };

  String _terms(Plan p) => p.lifetime
      ? tr('한 번 결제 · 자동 갱신 없음')
      : trf('{0}마다 자동 갱신 · 언제든 해지', [p.months == 12 ? tr('1년') : trf('{0}개월', [p.months])]);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: Purchase.status,
      builder: (c, st, _) {
        if (st == 'done' || st == 'restored') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Navigator.canPop(c)) Navigator.pop(c);
          });
        }
        final busy = st == 'pending';
        return ValueListenableBuilder(
          valueListenable: Purchase.products,
          builder: (c, _, _) {
            final sel = _sel == null ? null : Purchase.plan(_sel!);
            final selPrice = sel == null ? null : Purchase.price(sel.id);
            return SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + bottomInset(context)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text(tr('유료 기능입니다'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.zhuHong)),
                  Text(tr('이용권 선택'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.mo)),
                  const SizedBox(height: 10),
                  _row(Icons.check_circle, tr('앞으로 추가되는 회화·장면 그림·회화 음성 전부, 추가 결제 없이')),
                  _row(Icons.check_circle, tr('로그인하면 아이폰·아이패드·안드로이드 어디서나')),
                  _row(Icons.check_circle_outline, tr('지금 있는 병음·한자·단어·회화·복습은 계속 무료'), muted: true),
                  const SizedBox(height: 10),
                  Text(tr('중국어'), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.moLight)),
                  const SizedBox(height: 6),
                  for (final p in Purchase.plans.where((x) => !x.bundle)) _planTile(p, busy),
                  const SizedBox(height: 8),
                  Text(tr('종합 패키지 — Talkverse 모든 언어 앱'), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.moLight)),
                  const SizedBox(height: 6),
                  for (final p in Purchase.plans.where((x) => x.bundle)) _planTile(p, busy),
                  const SizedBox(height: 10),
                  if (st == 'error') Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(tr('결제를 마치지 못했습니다. 다시 시도해 주세요.'), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700))),
                  if (st == 'nothing') Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(tr('복원할 구매가 없습니다.'), style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700))),
                  // 구매 버튼 바로 위: 고른 상품의 가격·기간·갱신·해지
                  if (sel != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        sel.lifetime
                            ? trf('{0} · {1} · 한 번 결제, 자동 갱신 없음', [_title(sel), selPrice ?? _won(sel.krw)])
                            : trf('{0} · {1} · 기간이 끝나면 같은 가격으로 자동 갱신됩니다. 갱신 24시간 전까지 해지하면 다음 결제가 되지 않습니다.', [_title(sel), selPrice ?? _won(sel.krw)]),
                        style: const TextStyle(fontSize: 12, color: AppColors.mo, height: 1.45, fontWeight: FontWeight.w600),
                      ),
                    ),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: AppColors.zhuHong, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(54), textStyle: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900), shape: const StadiumBorder()),
                    onPressed: busy || sel == null || selPrice == null ? null : () => Purchase.buy(sel.id),
                    child: busy
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : Text(sel == null
                            ? tr('이용권을 골라 주세요')
                            : selPrice == null
                                ? tr('스토어에 연결하는 중…')
                                : '${tr('구매')} · $selPrice'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isIOS
                        ? tr('구독 해지: 아이폰 설정 → 내 이름(Apple ID) → 구독 → 중국어유니버스 → 구독 취소')
                        : tr('구독 해지: Google Play → 프로필 → 결제 및 정기 결제 → 정기 결제 → 중국어유니버스 → 해지'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11.5, color: AppColors.moLight, height: 1.4),
                  ),
                  const SizedBox(height: 6),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(shape: const StadiumBorder(), side: const BorderSide(color: AppColors.line)),
                    onPressed: busy ? null : () => Purchase.restore(),
                    child: Text(tr('이전 구매 복원'), style: const TextStyle(color: AppColors.mo, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 6),
                  ValueListenableBuilder(
                    valueListenable: Account.user,
                    builder: (c, u, _) => u == null
                        ? TextButton(
                            onPressed: () => LoginScreen.open(context),
                            child: Text(tr('로그인하면 다른 기기에서도 이용권이 열립니다 (선택)'), style: const TextStyle(fontSize: 12.5, color: AppColors.zhuHongDeep)),
                          )
                        : Text(tr('로그인됨 — 구매는 Talkverse 계정에 기록되어 다른 기기에서도 열립니다.'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
                  ),
                  Text(
                    tr('결제는 App Store / Google Play 에서 처리됩니다. 표시 가격은 스토어 가격을 따르며 세금이 포함될 수 있습니다. 숨은 요금은 없습니다.'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, color: AppColors.muted, height: 1.4),
                  ),
                  const LegalLinks(),
                ]),
              ),
            );
          },
        );
      },
    );
  }

  Widget _planTile(Plan p, bool busy) {
    final on = _sel == p.id;
    final price = Purchase.price(p.id) ?? _won(p.krw);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Semantics(
        selected: on,
        button: true,
        label: '${_title(p)} $price ${_terms(p)}',
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: busy ? null : () => setState(() => _sel = p.id),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: on ? AppColors.zhuHong.withValues(alpha: 0.08) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: on ? AppColors.zhuHong : AppColors.line, width: on ? 2 : 1),
            ),
            child: Row(children: [
              Icon(on ? Icons.radio_button_checked : Icons.radio_button_off, size: 20, color: on ? AppColors.zhuHong : AppColors.muted),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_title(p), style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.mo)),
                  Text(_terms(p), style: const TextStyle(fontSize: 11.5, color: AppColors.moLight)),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                if (p.listKrw > p.krw)
                  Text(_won(p.listKrw), style: const TextStyle(fontSize: 11.5, color: AppColors.muted, decoration: TextDecoration.lineThrough)),
                Text(price, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.mo)),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _row(IconData icon, String text, {bool muted = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 18, color: muted ? AppColors.muted : AppColors.feiCui),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13.5, height: 1.35, color: muted ? AppColors.muted : AppColors.mo, fontWeight: FontWeight.w600))),
        ]),
      );
}
