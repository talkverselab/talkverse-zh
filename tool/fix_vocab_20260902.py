# -*- coding: utf-8 -*-
"""2026-09-02 vocab 데이터 정리:
1) 연예인 인명 섹션 삭제
2) 단어>인사·기본 표현(문형 채우기) → 표현>필수 표현의 해당 문형 섹션으로 병합
3) 섹션 내 중복 아이콘을 변형 이모지 풀로 차별화 (요리형태 우선)
"""
import json, io

W='assets/data/vocab/travel_words.json'; E='assets/data/vocab/travel_expressions.json'
w=json.load(open(W,encoding='utf-8')); e=json.load(open(E,encoding='utf-8'))

# 1) 인명 섹션 삭제
for t in w['themes']:
    before=len(t['sections'])
    t['sections']=[s for s in t['sections'] if '연예인' not in s['title']]
    if len(t['sections'])!=before: print('deleted celeb section in', t['title'])

# 2) basics 이동
basics=next(t for t in w['themes'] if '인사' in t['title'])
ebasics=next(t for t in e['themes'] if t['id']=='basics')
moved=0
leftover=[]
for s in basics['sections']:
    if s['title'].startswith('기본 회화 —'):
        tgt=next((es for es in ebasics['sections'] if es['title']==s['title']), None)
        if tgt:
            for x in s['words']: x.pop('ic',None)
            tgt['words'].extend(s['words']); moved+=len(s['words'])
        else:
            leftover.append(s)
    else:
        leftover.append(s)
# 남은 섹션(이런 상황에서...)은 기본 단어 테마로
bw=next(t for t in w['themes'] if t['id']=='basicwords')
for s in leftover:
    bw['sections'].append(s)
w['themes']=[t for t in w['themes'] if t is not basics]
print('moved to expr:', moved, '| leftover sections → basicwords:', len(leftover))

# 3) 아이콘 차별화 — 요리형태 키워드 우선 오버라이드
FORM=[('그라탕','🧀'),('죽','🥣'),('완자','🍢'),('샤브샤브','🥘'),('마라탕','🌶️'),
      ('볶음면','🥡'),('냉면','🥶'),('볶음밥','🍚'),('튀김','🍤'),('빵','🥮'),
      ('전골','🥘'),('훈툰','🥟'),('차슈','🥓')]
POOL={
 '🥟':['🥟','🥠','🫓','🍡','🥮','🍞','🧆','🍘'],
 '🍜':['🍜','🍝','🥡','🍛','🌾'],
 '🍵':['🍵','🫖','🍶','🥛','🌿','🍂','🌱','🫗','🍃'],
 '🍖':['🍖','🥓','🍗','🥘','🍢','🥩'],
 '🥩':['🥩','🥘','🍢','🍄'],
 '🦀':['🦀','🥣','🧀','🍢','🥬','🍳','🦞'],
 '🦐':['🦐','🍤','🌶️','🥘','🍥'],
 '🐟':['🐟','🍤','🐠','🎏','🍲','🎣'],
 '🦪':['🦪','🐚','🥬'],
 '🦆':['🦆','🍗','🥘','🫕'],
 '🐔':['🐔','🍗','🥘','♨️'],
 '🍲':['🍲','🥘','🫕','♨️'],
 '🥣':['🥣','🍲','🥄'],
 '🍚':['🍚','🍛','🥡','🍙'],
 '🍗':['🍗','🍖','🥓'],
 '🧴':['🧴','🧼','🧽','💄','🧪','🪥','🫧','🛁','🌸','🌿','🍯','🥥','🧊','💧'],
 '👜':['👜','🎒','👝','💼','🛍️','👛','🧳'],
 '👗':['👗','👚','🧵','👘','🩱','🎀'],
 '📿':['📿','💠','🧿','🪬','⚜️','🔮'],
 '🧥':['🧥','🧦','🧤','🦺','👔'],
 '💍':['💍','💎','📿','👑'],
 '💎':['💎','💍','🔶','🔷'],
 '🧣':['🧣','🧤','🧢','👒'],
 '🌿':['🌿','🍀','🌱','🪴'],
 '🩺':['🩺','💊','🌡️','🧬','🫀','🦴','💉','🧘','🛌'],
 '💆':['💆','🧖','🛀','🤲','💅','🧘','🪷','🕯️'],
 '🦶':['🦶','🦵','🩴','👣'],
 '🛕':['🛕','⛩️','🕍','🏯','🗼','🕌','⛲','🪷','🐉'],
 '🏛️':['🏛️','🏯','🏰','🗿','🏟️','⛲'],
 '🏞️':['🏞️','⛰️','🌄','🗻'],
 '🛍️':['🛍️','🏬','🏪','🛒','💳','🏷️'],
 '🏙️':['🏙️','🌆','🌃','🌉'],
 '🏮':['🏮','🎐','🪭','🏘️'],
 '🎬':['🎬','🎥','📽️','🎞️','🍿','📺','🎭','🎪','🎟️','🌟','🎫'],
 '🎤':['🎤','🎶','🎧','🎹','📣'],
 '👤':['👤','🧑','👥','🫂','🙍','🙎'],
 '⏱️':['⏱️','⏰','🕐','⌛','🕒','🕕','🕘','🕛'],
 '📅':['📅','🗓️','📆'],
}
KEYCAP={'1':'1️⃣','2':'2️⃣','3':'3️⃣','4':'4️⃣','5':'5️⃣','6':'6️⃣','7':'7️⃣','8':'8️⃣','9':'9️⃣','10':'🔟','0':'0️⃣','100':'💯'}
changed=0
for t in w['themes']:
    for s in t['sections']:
        used=set()
        for x in s['words']:
            ic=x.get('ic','')
            if not ic: continue
            # 숫자 키캡
            if ic=='🔢':
                import re
                m=re.match(r'^(\d+)', x['ko'].strip())
                if m and m.group(1) in KEYCAP:
                    nic=KEYCAP[m.group(1)]
                    if nic!=ic: x['ic']=nic; changed+=1
                    used.add(x['ic']); continue
            # 요리형태 오버라이드 (음식 테마에서만)
            if t['id']=='food':
                for kw,em in FORM:
                    if kw in x['ko'] and em not in used:
                        if em!=ic: changed+=1
                        x['ic']=em; break
            # 섹션 내 중복이면 풀에서 대체
            cur=x['ic'] if 'ic' in x else ic
            if cur in used:
                for alt in POOL.get(cur,[cur]):
                    if alt not in used:
                        if alt!=cur: changed+=1
                        x['ic']=alt; break
            used.add(x['ic'])
print('icon variations applied:', changed)

json.dump(w, open(W,'w',encoding='utf-8'), ensure_ascii=False, indent=1)
json.dump(e, open(E,'w',encoding='utf-8'), ensure_ascii=False, indent=1)
wc=sum(len(s['words']) for t in w['themes'] for s in t['sections'])
ec=sum(len(s['words']) for t in e['themes'] for s in t['sections'])
print('final words:',wc,'expressions:',ec)
