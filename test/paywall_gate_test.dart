import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chinese_universe/data/entitlement.dart';
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
}
