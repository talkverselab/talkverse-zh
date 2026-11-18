import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_universe/services/dialogue_service.dart';
import 'package:chinese_universe/services/learner_prefs.dart';

Dialogue d(String scene) => Dialogue.fromJson({'id': 'r1_life_a1', 'region': 'R1', 'island': 'life', 'title': 't', 'scene': scene, 'speakers': {'A': '{name}'}, 'turns': []});

void main() {
  test('장면 설명의 학습자 → 이름·조사', () {
    LearnerPrefs.name.value = '';
    expect(d('학습자가 고른 노래').sceneShown, '내가 고른 노래');
    expect(d('학습자와 샤오리는').sceneShown, '나와 샤오리는');
    expect(d('학습자의 폰').sceneShown, '나의 폰');
    LearnerPrefs.name.value = '민준';
    expect(d('학습자가 고른 노래, 학습자를 따라온다').sceneShown, '민준이 고른 노래, 민준을 따라온다');
    LearnerPrefs.name.value = '지수';
    expect(d('학습자는 열심히').sceneShown, '지수는 열심히');
    expect(d('버스 정류장').sceneShown, '버스 정류장');
  });
}
