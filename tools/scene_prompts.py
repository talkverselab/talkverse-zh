#!/usr/bin/env python3
"""편 JSON → 장면 컷 그림 요청문. A·B 대화 한 쌍(연속 두 턴) = 컷 1장, 말풍선·글자 없음(사용자 지시 2026-11-02).
  python3 tools/scene_prompts.py <편.json> <코드 접두어>   → data/review/art/<편id>/cut<n>_req.md 를 쓰고 컷 수를 출력
컷 그림은 tools/grok_image.py 로 한 장씩(인물 기준 그림 data/review/art/chars_zh01.jpg 첨부) 받아 같은 폴더 cut<n>.jpg 로 저장한다.
"""
import json, os, re, sys
e = json.load(open(sys.argv[1], encoding='utf-8')); pre = sys.argv[2]
BATCH = '--batch' in sys.argv  # 컷 4개까지 한 요청(그림 4장) — 2026-11-02 일본어앱 확인
out = f"data/review/art/{e['id']}"; os.makedirs(out, exist_ok=True)
# 인물 기준 그림 data/review/art/chars_zh01.jpg (2026-11-02, 중국 배경) — 이름은 편 JSON speakers 값
CHAR = {'小丽': '샤오리(小丽, 20대 중반 중국 여성 — 어깨 길이 검은 생머리·앞머리, 베이지 니트 + 차이나 칼라 연두 카디건, 옥 귀걸이)',
        '小丽 / Lily': '샤오리(小丽, 20대 중반 중국 여성 — 어깨 길이 검은 생머리·앞머리, 베이지 니트 + 차이나 칼라 연두 카디건, 옥 귀걸이)',
        '悦': '위에(悦, 20대 후반 중국 여성 — 높은 포니테일·붉은 립, 빨간 크롭 재킷 + 검은 원피스, 금색 링 귀걸이, 먼저 다가가는 자신감)',
        '浩然': '하오란(浩然, 중국 아이돌·배우 연습생 느낌 20대 초 남성 — 가운데 가르마 커튼 앞머리, 흰 차이나 칼라 셔츠 + 검은 롱 코트, 작은 은색 귀걸이, 무심한 듯 다정)',
        '店员': '점원(중국 편의점 직원, 20대 여성, 앞치마·명찰 없음)',
        '服务员': '종업원(중국 식당 직원, 20대, 앞치마)',
        '司机': '택시 기사(중국인 40대 남성, 반팔 셔츠, 친근한 표정)',
        '大叔': '아저씨(중국인 50대 남성, 셔츠·점퍼, 넉살 좋은 표정)',
        '阿姨': '아주머니(중국인 50대 여성, 화사한 꽃무늬 상의, 부채, 광장무 차림)',
        '外卖小哥': '배달 기사(중국인 20대 남성, 노란 배달 재킷·헬멧, 글자 없는 상자)',
        '老板': '야시장 사장(중국인 40대 여성, 앞치마, 넉살 좋은 웃음)',
        '妈妈': '학습자의 엄마(한국인 50대 여성, 단발·가디건, 집 거실에서 폰을 봄)',
        'Mark': '학습자(한국인 20대, 인디고 #635BFF 후드티·백팩 — 성별은 첨부 기준 그림의 남/여 중 하나, 편 안에서 통일)',
        '{name}': '학습자(한국인 20대, 인디고 #635BFF 후드티·백팩 — 성별은 첨부 기준 그림의 남/여 중 하나, 편 안에서 통일)'}
def who(s):
    n = e['speakers'].get(s, s); return CHAR.get(n, f'{n}(조연)')
turns = e['turns']; cuts = [turns[i:i + 2] for i in range(0, len(turns), 2)]
people = ' / '.join(who(s) for s in e['speakers'])
GENDER = {'F': '**여성**', 'M': '**남성**'}.get(e.get('learner_gender'), '남/여 중 하나(편 안에서 통일)')
people = people.replace('성별은 첨부 기준 그림의 남/여 중 하나, 편 안에서 통일', f'학습자는 첨부 기준 그림의 {GENDER} 쪽')
CHAT = ('\n**채팅 편**: 두 사람은 서로 다른 장소에 있다 — 각자 자기 자리에서 폰을 보는 모습으로, 화면을 세로로 반 나눠 왼쪽/오른쪽에 한 사람씩(또는 한 사람을 크게, 상대는 작은 둥근 창). 같은 소파·같은 방에 두지 말 것.'
        if e.get('kind') == 'chat' else '')
if BATCH:
    groups = [cuts[i:i + 4] for i in range(0, len(cuts), 4)]
    for gi, grp in enumerate(groups, 1):
        lines = []
        for j, pair in enumerate(grp):
            k = (gi - 1) * 4 + j + 1
            d = ' → '.join(f"{e['speakers'].get(t['speaker'], t['speaker'])}: 「{re.sub(r'\(.*?\)', '', t['ko']).strip()}」" for t in pair)
            lines.append(f"컷 {k}: {d}")
        txt = f"""[{pre}-B{gi}] 회화 장면 컷 **{len(grp)}장**(한 요청에 {len(grp)}장, 컷 번호 순서대로) — 편 「{e['title']}」({e['id']}), 전체 {len(cuts)}컷 중 {(gi-1)*4+1}~{(gi-1)*4+len(grp)}. 첨부 1번 = 인물 기준 그림(얼굴·머리·옷을 그대로 유지), 첨부 2번 = 앱 화면 톤(시안 zh01).
스타일(모든 컷 공통): 부드러운 3D 점토/펠트 인형, 둥근 얼굴, 파스텔 배경, 중국 도시·생활 공간(찻집·골목·지하철·아파트 등, 글자 없는 간판), 밝고 따뜻한 조명(밤 장면도 가로등·간판 불빛으로 밝게), 부드러운 그림자. 가로 16:9. 같은 편이므로 장소·옷·조명이 컷끼리 이어져야 함.
장면: {e['scene']}
등장: {people}{CHAT}
각 컷의 순간(그림에 글자로 넣지 말 것 — 표정·몸짓·소품으로만):
""" + '\n'.join(lines) + """
반드시: **말풍선·글자·간판 글씨·자막·숫자·로고 없음**(대사는 앱이 얹는다 — 인물 머리 위쪽 여백). 두 인물이 모두 보이게, 말하는 사람이 조금 더 앞에. 실존 인물·브랜드 금지.
출력: 그림 """ + f"{len(grp)}" + """장만, 컷 번호 순서대로. 설명 없이.
"""
        open(f"{out}/batch{gi}_req.md", 'w', encoding='utf-8').write(txt)
    print(len(groups)); sys.exit(0)
for k, pair in enumerate(cuts, 1):
    desc = ' → '.join(f"{e['speakers'].get(t['speaker'], t['speaker'])}: 「{re.sub(r'\(.*?\)', '', t['ko']).strip()}」" for t in pair)
    txt = f"""[{pre}-{k}] 회화 장면 컷 {k}/{len(cuts)} — 편 「{e['title']}」({e['id']}). 첨부 1번 = 인물 기준 그림(얼굴·머리·옷을 그대로 유지), 첨부 2번 = 앱 화면 톤(시안 zh01).
스타일: 부드러운 3D 점토/펠트 인형, 둥근 얼굴, 파스텔 배경, 중국 도시·생활 공간(찻집·골목·지하철·아파트 등, 글자 없는 간판), 밝고 따뜻한 조명(어두운 밤 장면도 가로등·간판 불빛으로 밝게), 부드러운 그림자. 가로 16:9.
장면: {e['scene']}
등장: {people}{CHAT}
이 컷의 순간(그림에 글자로 넣지 말 것 — 표정·몸짓·소품으로만 표현): {desc}
반드시: **말풍선·글자·간판 글씨·자막·숫자·로고 없음**(대사는 앱이 나중에 얹는다 — 말풍선이 들어갈 여백을 인물 머리 위쪽에 남길 것). 두 인물이 모두 보이게, 말하는 사람이 조금 더 앞에. 실존 인물·브랜드 금지.
출력: 그림 1장만. 설명 없이.
"""
    open(f"{out}/cut{k}_req.md", 'w', encoding='utf-8').write(txt)
print(len(cuts))
