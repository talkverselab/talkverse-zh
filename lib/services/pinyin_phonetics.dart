/// 병음 기초(성모 21 · 운모 36 · 성조 5) 발음 자료 — 「병음과 발음」 화면(2026-11-08, 일본어앱 「50음도와 발음」과 같은 짜임).
/// 소리는 예시 한자를 기기 음성(TTS)으로 읽는다. ko = 한국어 비슷한 소리, diff = 다른 점, place = 소리 나는 곳.
class PySound {
  final String py; // 표기(성모 b, 운모 ang, 성조 mā)
  final String ipa;
  final String ex; // 읽어 줄 예시 한자
  final String exPy; // 예시 병음
  final String hangul; // 한글 근사 표기(보조)
  final String place; // 소리 나는 곳·입모양
  final String ko; // 한국어에서 비슷한 소리
  final String diff; // 한국 화자가 주의할 점
  final bool consonant; // 조음 위치 그림을 보일지
  const PySound(this.py, this.ipa, this.ex, this.exPy, this.hangul, this.place, this.ko, this.diff, {this.consonant = false});
}

class PyGroup {
  final String name;
  final String hint;
  final List<PySound> items;
  const PyGroup(this.name, this.hint, this.items);
}

const _lips = '두 입술';
const _tip = '혀끝 · 윗잇몸';
const _back = '혀뿌리 · 여린입천장';
const _palate = '혓바닥 · 센입천장';
const _retro = '혀끝을 말아 올림(권설)';
const _dent = '혀끝 · 윗니 뒤';

/// 성모 21 — 소리 나는 곳별 여섯 묶음. 예시는 성모 연습에 쓰는 전통 음절(bo po mo fo …).
const pyInitials = <PyGroup>[
  PyGroup('입술', 'b p m f', [
    PySound('b', 'p', '波', 'bō', '뽀', _lips, 'ㅃ', '한국어 ㅂ보다 힘을 빼고 바람 없이. 영어 b 처럼 성대가 울리지 않는다(무기음).', consonant: true),
    PySound('p', 'pʰ', '坡', 'pō', '포', _lips, 'ㅍ', '입술을 터뜨리며 바람을 세게(유기음). 손바닥을 대면 바람이 느껴져야 한다.', consonant: true),
    PySound('m', 'm', '摸', 'mō', '모', _lips, 'ㅁ', '한국어 ㅁ과 거의 같다.', consonant: true),
    PySound('f', 'f', '佛', 'fó', '포(f)', '윗니 · 아랫입술', '없음(ㅍ 아님)', '아랫입술을 윗니에 살짝 대고 바람을 내보낸다. ㅍ처럼 두 입술을 붙이면 p 로 들린다.', consonant: true),
  ]),
  PyGroup('혀끝', 'd t n l', [
    PySound('d', 't', '得', 'dé', '뜨어', _tip, 'ㄸ', '한국어 ㄷ보다 바람 없이 단단하게(무기음).', consonant: true),
    PySound('t', 'tʰ', '特', 'tè', '트어', _tip, 'ㅌ', '바람을 세게 터뜨린다(유기음).', consonant: true),
    PySound('n', 'n', '讷', 'nè', '느어', _tip, 'ㄴ', '한국어 ㄴ과 같다. 끝소리 -n 과 -ng 를 구별해야 한다.', consonant: true),
    PySound('l', 'l', '勒', 'lè', '러', _tip, 'ㄹ(첫소리)', '혀끝을 윗잇몸에 붙인 채 옆으로 흘린다. 혀를 튕기는 한국어 ㄹ(r 소리)과 다르다.', consonant: true),
  ]),
  PyGroup('혀뿌리', 'g k h', [
    PySound('g', 'k', '哥', 'gē', '끄어', _back, 'ㄲ', '한국어 ㄱ보다 바람 없이(무기음). 첫소리에서도 g 는 ㄲ에 가깝게 들린다.', consonant: true),
    PySound('k', 'kʰ', '科', 'kē', '크어', _back, 'ㅋ', '바람을 세게(유기음).', consonant: true),
    PySound('h', 'x', '喝', 'hē', '흐어', _back, 'ㅎ', '목 안쪽(혀뿌리)에서 긁듯이 낸다. 한국어 ㅎ보다 마찰이 거칠다.', consonant: true),
  ]),
  PyGroup('혓바닥', 'j q x', [
    PySound('j', 'tɕ', '鸡', 'jī', '지', _palate, 'ㅈ(지)', '혀를 넓게 펴서 센입천장에 대고 바람 없이. 뒤에는 i·ü 계열만 온다(ju 의 u 는 ü).', consonant: true),
    PySound('q', 'tɕʰ', '七', 'qī', '치', _palate, 'ㅊ(치)', '영어 q(크)가 아니다. 바람을 세게 낸 「치」.', consonant: true),
    PySound('x', 'ɕ', '西', 'xī', '시', _palate, 'ㅅ(시)', '영어 x(크스)가 아니다. 입꼬리를 옆으로 당긴 「시」.', consonant: true),
  ]),
  PyGroup('혀말기', 'zh ch sh r', [
    PySound('zh', 'ʈʂ', '知', 'zhī', '즈(혀 말기)', _retro, '없음 — ㅈ에 가까움', '혀끝을 말아 입천장 앞쪽에 대고 바람 없이. 뒤의 i 는 「이」가 아니라 혀를 만 채 내는 「으」 소리.', consonant: true),
    PySound('ch', 'ʈʂʰ', '吃', 'chī', '츠(혀 말기)', _retro, '없음 — ㅊ에 가까움', 'zh 와 같은 혀 모양에 바람을 세게.', consonant: true),
    PySound('sh', 'ʂ', '诗', 'shī', '스(혀 말기)', _retro, '없음 — ㅅ에 가까움', '혀끝을 만 채 바람을 흘린다. 혀를 말지 않으면 s(쓰)로 들린다.', consonant: true),
    PySound('r', 'ʐ', '日', 'rì', '르(혀 말기)', _retro, '없음', '혀를 sh 처럼 만 채 목소리를 낸다. ㄹ과 ㅈ 사이. 영어 r 과도 다르다.', consonant: true),
  ]),
  PyGroup('혀끝-이', 'z c s', [
    PySound('z', 'ts', '资', 'zī', '쯔', _dent, 'ㅉ(쯔)', '혀끝을 윗니 뒤에 대고 바람 없이. 영어 z(즈)처럼 울리지 않는다.', consonant: true),
    PySound('c', 'tsʰ', '次', 'cì', '츠', _dent, 'ㅊ(츠)', '영어 c(크·스)가 아니다. 「츠」를 바람 세게.', consonant: true),
    PySound('s', 's', '思', 'sī', '쓰', _dent, 'ㅆ(쓰)', '혀끝을 윗니 뒤에. zh·ch·sh 와 짝으로 구별해 듣기.', consonant: true),
  ]),
];

/// 운모 36 — 단운모·복운모·콧소리·i 계·u 계·ü 계.
const pyFinals = <PyGroup>[
  PyGroup('단운모', 'a o e i u ü', [
    PySound('a', 'a', '啊', 'ā', '아', '입을 크게', '아', '한국어 「아」보다 입을 더 크게 벌린다.'),
    PySound('o', 'o', '哦', 'ō', '오', '입술을 둥글게', '오(워)', 'b·p·m·f 뒤에서는 「우오」처럼 짧은 w 가 붙어 들린다.'),
    PySound('e', 'ɤ', '饿', 'è', '으어', '입술을 펴고 혀를 뒤로', '어 ↔ 으 사이', '한국어 「에」가 아니다. 입술을 펴고 「으」에서 「어」로 미끄러지듯.'),
    PySound('i', 'i', '一', 'yī', '이', '입꼬리를 옆으로', '이', 'zh·ch·sh·r·z·c·s 뒤의 i 는 「이」가 아니라 「으」에 가까운 다른 소리.'),
    PySound('u', 'u', '五', 'wǔ', '우', '입술을 앞으로 오므림', '우', '한국어 「우」보다 입술을 더 내민다.'),
    PySound('ü', 'y', '鱼', 'yú', '위(한 번에)', '「이」 혀 + 「우」 입술', '위', '「우이」로 나누지 말고 입술을 오므린 채 「이」를 낸다. j·q·x·y 뒤에서는 점 없이 u 로 쓴다(ju·qu·xu·yu).'),
  ]),
  PyGroup('복운모', 'ai ei ao ou er', [
    PySound('ai', 'ai̯', '爱', 'ài', '아이', '아 → 이', '아이', '두 소리를 따로 내지 말고 한 음절로 미끄러지게.'),
    PySound('ei', 'ei̯', '黑', 'hēi', '에이', '에 → 이', '에이', 'e 단독(으어)과 소리가 다르다.'),
    PySound('ao', 'au̯', '奥', 'ào', '아오', '아 → 우', '아오', '끝은 「오」보다 「우」 쪽으로 닫힌다.'),
    PySound('ou', 'ou̯', '欧', 'ōu', '어우', '오 → 우', '어우', '「오우」보다 시작이 약간 「어」에 가깝다.'),
    PySound('er', 'ɚ', '二', 'èr', '얼', '혀를 말며', '얼', '「어」를 내면서 혀끝을 말아 올린다. 끝에 붙는 儿化(-r)도 같은 혀 모양.'),
  ]),
  PyGroup('콧소리', 'an en ang eng ong', [
    PySound('an', 'an', '安', 'ān', '안', '혀끝을 윗잇몸에 붙이며 끝', '안', '-n 은 혀끝을 붙여 끝낸다(받침 ㄴ).'),
    PySound('en', 'ən', '恩', 'ēn', '언', '혀끝 붙이며 끝', '언', '「엔」이 아니라 「언」.'),
    PySound('ang', 'ɑŋ', '昂', 'áng', '앙', '혀뿌리를 올려 코로', '앙', '-ng 은 받침 ㅇ. -n(안)과 꼭 구별해야 뜻이 바뀐다.'),
    PySound('eng', 'ɤŋ', '冷', 'lěng', '엉', '혀뿌리 · 코', '엉', '「엥」이 아니라 「엉」.'),
    PySound('ong', 'ʊŋ', '东', 'dōng', '웅', '입술 둥글게 · 코', '옹 ↔ 웅', '「옹」보다 「웅」에 가깝다.'),
  ]),
  PyGroup('i 계', 'ia ie iao iu ian in iang ing iong', [
    PySound('ia', 'ja', '呀', 'yā', '야', '이 → 아', '야', ''),
    PySound('ie', 'jɛ', '耶', 'yē', '예', '이 → 에', '예', 'e 단독(으어)과 달리 여기서는 「에」.'),
    PySound('iao', 'jau̯', '要', 'yào', '야오', '이 → 아 → 우', '야오', ''),
    PySound('iu', 'jou̯', '有', 'yǒu', '여우', '이 → 오 → 우', '여우·유', '표기는 iu 지만 가운데 o 가 숨어 있다(iou). 3성에서 「여우」가 또렷하다.'),
    PySound('ian', 'jɛn', '烟', 'yān', '옌', '이 → 에 → n', '옌', '「이안」이 아니라 「옌」. a 가 「에」로 바뀐다.'),
    PySound('in', 'in', '因', 'yīn', '인', '이 · 혀끝 붙임', '인', '-ing(잉)과 구별.'),
    PySound('iang', 'jɑŋ', '羊', 'yáng', '양', '이 → 앙', '양', ''),
    PySound('ing', 'iŋ', '英', 'yīng', '잉', '이 · 코', '잉', ''),
    PySound('iong', 'jʊŋ', '用', 'yòng', '융', '이 → 웅', '융', ''),
  ]),
  PyGroup('u 계', 'ua uo uai ui uan un uang', [
    PySound('ua', 'wa', '哇', 'wā', '와', '우 → 아', '와', ''),
    PySound('uo', 'wo', '我', 'wǒ', '워', '우 → 오', '워', ''),
    PySound('uai', 'wai̯', '外', 'wài', '와이', '우 → 아 → 이', '와이', ''),
    PySound('ui', 'wei̯', '位', 'wèi', '웨이', '우 → 에 → 이', '웨이', '표기는 ui 지만 가운데 e 가 숨어 있다(uei). 「우이」가 아니다.'),
    PySound('uan', 'wan', '万', 'wàn', '완', '우 → 안', '완', 'j·q·x·y 뒤의 uan 은 üan(위엔).'),
    PySound('un', 'wən', '文', 'wén', '원', '우 → 언', '운·원', '표기는 un 이지만 실제는 uen(우언). j·q·x·y 뒤의 un 은 ün(윈).'),
    PySound('uang', 'wɑŋ', '王', 'wáng', '왕', '우 → 앙', '왕', ''),
  ]),
  PyGroup('ü 계', 'üe üan ün', [
    PySound('üe', 'ɥɛ', '月', 'yuè', '위에', 'ü → 에', '웨', '입술을 오므린 ü 에서 「에」로. 표기는 yue·jue·que·xue.'),
    PySound('üan', 'ɥɛn', '元', 'yuán', '위엔', 'ü → 에 → n', '위안', '「위안」보다 「위엔」에 가깝다.'),
    PySound('ün', 'yn', '云', 'yún', '윈', 'ü · 혀끝 붙임', '윈', ''),
  ]),
];

/// 성조 — 같은 음절 ma 로 비교.
const pyTones = <PyGroup>[
  PyGroup('4성 + 경성', 'mā má mǎ mà ma', [
    PySound('mā', '55', '妈', 'mā', '1성', '높고 평평하게', '「아—」 길게 노래하듯', '처음부터 끝까지 높이를 그대로. 한국어로 말할 때보다 높게 시작한다.'),
    PySound('má', '35', '麻', 'má', '2성', '중간에서 위로', '「응?」 되물을 때', '아래에서 위로 쭉 올린다. 끝까지 올려야 3성과 헷갈리지 않는다.'),
    PySound('mǎ', '214', '马', 'mǎ', '3성', '낮게 내렸다가', '「아~」 실망할 때', '혼자 읽을 때만 끝을 올리고, 말 중간에서는 낮게 눌러만 준다(반3성). 3성+3성은 앞이 2성으로 바뀐다(你好 ní hǎo).'),
    PySound('mà', '51', '骂', 'mà', '4성', '높은 데서 뚝', '「야!」 단호하게', '위에서 아래로 짧고 세게 떨어뜨린다.'),
    PySound('ma', '경성', '吗', 'ma', '경성', '짧고 가볍게', '조사처럼 약하게', '성조 부호가 없다. 앞 음절 높이에 따라 짧게 붙는다(吗·呢·的·了).'),
  ]),
];
