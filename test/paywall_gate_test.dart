import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chinese_universe/data/entitlement.dart';
import 'package:chinese_universe/data/purchase.dart';
import 'package:chinese_universe/services/curriculum_service.dart';

const _plan = '{"rev":2,"freeSteps":2,"freeSenseLevels":1,"stages":[{"n":1,"dialogueIds":["a"],"free":true},{"n":2,"dialogueIds":["b"],"free":false},{"n":3,"dialogueIds":["c"]}],'
    '"prep":[{"id":"hsk","title":"HSK 준비","levels":[{"id":"HSK1","dialogueIds":["a"],"free":false},{"id":"HSK2","dialogueIds":["b"]}]}]}';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('잠금 경계: 1단계 열림 · 2단계·HSK 잠김 · 문법 3스텝·언어감각 2급부터 잠김 · 이용권 있으면 열림', () async {
    final svc = CurriculumService.instance;
    svc.plan = CurriculumPlan.parse(_plan);
    expect([svc.unitFree('1'), svc.unitFree('2'), svc.unitFree('3'), svc.unitFree('HSK1'), svc.unitFree('HSK2')], [true, false, false, false, false]);
    expect([Entitlement.dialogueFree('R1'), Entitlement.dialogueFree('R2'), Entitlement.dialogueFree('R4')], [true, false, false]);
    expect([Entitlement.stepFree(2), Entitlement.stepFree(3)], [true, false]);
    expect([Entitlement.senseLevelFree(1), Entitlement.senseLevelFree(2)], [true, false]);
    await Entitlement.set(false);
    expect(Entitlement.premium, isFalse);
    await Entitlement.set(true); // 이용권 있음(기기 스위치로 흉내)
    expect(Entitlement.premium, isTrue);
    await Entitlement.set(false);
    // 판이 없으면 기본값: 회화 R0·R1 만 무료
    svc.plan = null;
    expect([svc.unitFree('R1'), svc.unitFree('R2')], [true, false]);
    expect([Entitlement.stepFree(2), Entitlement.stepFree(3), Entitlement.senseLevelFree(2)], [true, false, false]);
  });

  test('서버 free 값이 바뀌면 그대로 따름(2단계를 무료로 풀기)', () {
    final svc = CurriculumService.instance;
    svc.plan = CurriculumPlan.parse(_plan.replaceFirst('"free":false}', '"free":true}'));
    expect(svc.unitFree('2'), isTrue);
    svc.plan = CurriculumPlan.parse(_plan.replaceFirst('"freeSteps":2', '"freeSteps":5'));
    expect(Entitlement.stepFree(5), isTrue);
    svc.plan = null;
  });

  test('HSK 4·5급 = 시험 칸: 상품별로 누가 여는지(프로만으로는 안 열림) · 화면 판정은 임시로 프로와 같음', () async {
    expect([for (final k in ['HSK3', 'HSK4', 'HSK5', 'hsk3', 'hsk4', 'hsk5', '2']) Entitlement.examLevel(k)].join(','), 'false,true,true,false,true,true,false');
    final far = DateTime.now().add(const Duration(days: 30)).millisecondsSinceEpoch;
    final past = DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch;
    String who(Map<String, int> m) {
      Purchase.owned.value = m;
      return '${Purchase.owns('zh')}/${Purchase.ownsExam('zh')}';
    }
    expect(who({'lang_zh_1y': far}), 'true/false'); // 프로
    expect(who({'lang_zh_exam_1m': far}), 'true/true'); // 프로+HSK
    expect(who({'lang_zh_exam_1m': past}), 'false/false'); // 기한 지남
    expect(who({'lang_zh_life': 0}), 'true/true'); // 언어 평생(시험 포함)
    expect(who({'all_1y': far}), 'true/true');
    expect(who({'all_life': 0}), 'true/true');
    expect(who({'lang_ja_exam_1y': far}), 'false/false'); // 다른 언어
    Purchase.owned.value = const {};
    // 서버 권한 규격 전까지: 시험 칸 판정 = 프로
    await Entitlement.set(false);
    expect([Entitlement.open(false, exam: true), Entitlement.open(true, exam: true), Entitlement.open(true)].join(','), 'false,false,true');
    await Entitlement.set(true);
    expect(Entitlement.open(false, exam: true), isTrue);
    await Entitlement.set(false);
  });
}
