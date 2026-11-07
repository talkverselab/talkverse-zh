#!/usr/bin/env python3
"""한자 절벽(2026-11-07 재산출) → 앱 자료.

  ~/.venvs/zh/bin/python tools/hanzi_cliff_build.py [공용한자DB.json]

입력  data/cliff/zh_hanzi_top2500.tsv (rank char freq cum_pct word_region — tools/cliff/zh_cliff.py 결과)
출력  assets/data/hanzi/cliff/hanzi_cliff_zh.tsv   순위·글자·빈도·누적%·HSK — DB `hanzi` 시딩(2,000자, R5 상한)
      assets/data/hanzi/hanzi_cliff.json           HanziStagesScreen 형식(phases = R1~R5, stages = 20자 단원) — 「절벽 한자」 화면
구간 경계는 앱 코드 `HanziCliff.regionOf`(lib/services/hanzi_cliff.dart) 와 같아야 한다 — 바뀌면 둘 다 고친다.
글자 뜻·병음: 앱 안 단계 자료(209·HSK1500) → 공용 한자 DB 훈음(인자로 준 json, {글자:{kr_hun,pinyin}}) → 아래 손 뜻. 병음은 pypinyin.
번체 자막의 변환 잔재 글자(DROP)는 뺀다. 말뭉치 이름은 쓰지 않는다.
"""
import json, re, sys
from pypinyin import pinyin, Style

SRC = 'data/cliff/zh_hanzi_top2500.tsv'
TOP = 2000
BOUNDS = [(96, 'R1', 55), (129, 'R2', 60), (226, 'R3', 70), (411, 'R4', 80), (TOP, 'R5', None)]
DROP = set('琌硂璶穦碞笵眔筁')  # 번체→간체 변환 잔재(실제 쓰이지 않는 글자)
HAND = {  # 앱 단계 자료·공용 DB 에 없는 글자의 짧은 한국어 뜻
 '嘿':'헤이(부름)','歉':'사과하다(抱歉)','姆':'(음역) 므','迪':'(음역) 디','噢':'오(감탄)','嗨':'하이(인사)','莉':'(음역) 리','娜':'(음역) 나',
 '蒂':'(음역) 티·꼭지','玛':'(음역) 마','妮':'(음역) 니·소녀','莎':'(음역) 샤','呃':'어(머뭇)','菲':'(음역) 피','屁':'방귀·헛소리','哇':'와(감탄)',
 '尸':'시체','喔':'오(감탄)','妳':'너(여성, 번체)','啥':'뭐(什么)','谎':'거짓말','帕':'(음역) 파·손수건','哎':'아이(감탄)','兹':'(음역) 즈',
 '琳':'(음역) 린','吻':'입맞춤','绑':'묶다·납치','档':'서류·파일','屎':'똥','赚':'(돈을) 벌다','拖':'끌다·미루다','钥':'열쇠(钥匙)',
 '扎':'찌르다·묶다','娃':'아기·인형','扯':'끌다·잡아당기다','砸':'부수다·망치다','帐':'계정·장막','婊':'(욕) 창녀','踢':'차다','娅':'(음역) 야',
 '黛':'(음역) 다이·검푸른','呐':'나(어기)','咪':'(음역) 미·야옹','咒':'주문·저주','挖':'파다','盯':'노려보다','耍':'놀다·장난치다','蕾':'(음역) 레이·꽃봉오리',
 '稣':'(음역) 예수(耶稣)','爹':'아빠·아버지','拯':'구하다(拯救)','艘':'척(배)','哟':'요(어기)','厕':'화장실(厕所)','佬':'사내·놈','茨':'(음역) 츠',
 '萝':'무(萝卜)','趴':'엎드리다','扣':'잠그다·공제하다','瞎':'눈먼·함부로','妞':'계집애·아가씨','砍':'찍다·베다','杉':'삼나무','啰':'(어기) 뤄',
 '链':'사슬·체인','哼':'흥(콧소리)','趟':'번(왕복 횟수)','狠':'사납다·독하게','唔':'음(머뭇)','趁':'(기회를) 타다','夸':'칭찬·과장','矶':'(음역) 지',
 '摧':'부서뜨리다','茜':'(음역) 시','陌':'낯선(陌生)','扭':'비틀다','咯':'(어기) 뤄','甩':'내던지다·차버리다','隶':'속하다(隶属)','岩':'바위',
 '脖':'목(脖子)','妒':'질투','揍':'때리다','勾':'걸다·유혹하다','唉':'아이(한숨)','霉':'곰팡이·운 나쁜','罩':'덮개·마스크','撕':'찢다',
 '罐':'캔·단지','窝':'둥지·소굴','储':'저장하다','钮':'버튼(按钮)','逗':'놀리다·우습다','捡':'집다·줍다','妆':'화장','踩':'밟다','挨':'맞다·당하다',
 '僵':'굳다·교착','坎':'(음역) 캄·구덩이','咋':'어째서(방언)','睁':'(눈을) 뜨다','拦':'막다','擎':'받쳐 들다·엔진','氧':'산소(氧气)','诶':'에이(부름)','瘾':'중독(上瘾)',
}

def region(rank):
    for b, r, _ in BOUNDS:
        if rank <= b: return r
    return 'R5+'

rows = [l.rstrip('\n').split('\t') for l in open(SRC, encoding='utf-8')][1:]
rows = [r for r in rows if r[1] not in DROP]
tot = None
# 누적% 는 원 자료의 것을 그대로(잔재 글자는 0.1% 미만) — 순위만 다시 매긴다.
info = {}
for a in ['assets/data/hanzi/hanzi_stages.json', 'assets/data/hanzi/hanzi_hsk1500.json']:
    for st in json.load(open(a, encoding='utf-8'))['stages']:
        for c in st['chars']:
            info.setdefault(c['char'], {'pinyin_raw': c.get('pinyin_raw'), 'meaning': c.get('meaning'), 'hsk': c.get('hsk')})
shared = json.load(open(sys.argv[1], encoding='utf-8')) if len(sys.argv) > 1 else {}
hsk_of = {}
for st in json.load(open('assets/data/hanzi/hanzi_hsk1500.json', encoding='utf-8'))['stages']:
    for c in st['chars']: hsk_of[c['char']] = c.get('hsk') or ''

def raw_pinyin(ch):
    p = pinyin(ch, style=Style.TONE3, neutral_tone_with_five=True)[0][0]
    return p

chars = []; missing = []
for i, (rk, ch, fq, cum, _) in enumerate(rows[:TOP], 1):
    m = info.get(ch)
    if m and m.get('meaning'):
        mean, praw = m['meaning'], m.get('pinyin_raw') or raw_pinyin(ch)
    elif ch in shared and shared[ch].get('kr_hun'):
        mean, praw = shared[ch]['kr_hun'], raw_pinyin(ch)
    elif ch in HAND:
        mean, praw = HAND[ch], raw_pinyin(ch)
    else:
        mean, praw = '', raw_pinyin(ch); missing.append(ch)
    chars.append({'rank': i, 'char': ch, 'freq': int(fq), 'cum_pct': round(float(cum), 2), 'pinyin_raw': praw, 'meaning': mean, 'hsk': hsk_of.get(ch, m.get('hsk', '') if m else '') or '', 'region': region(i)})
if missing: print('뜻 없는 글자', len(missing), ''.join(missing))

with open('assets/data/hanzi/cliff/hanzi_cliff_zh.tsv', 'w', encoding='utf-8') as f:
    for c in chars: f.write(f"{c['rank']}\t{c['char']}\t{c['freq']}\t{c['cum_pct']}\t{c['hsk'] or '-'}\n")

phases = []; lo = 1
for b, r, pct in BOUNDS:
    phases.append({'phase': len(phases) + 1, 'name': r, 'from': lo, 'to': b, 'count': b - lo + 1, 'coverage_pct': chars[b - 1]['cum_pct']}); lo = b + 1
stages = []; lo = 1
for ph in phases:
    seg = chars[ph['from'] - 1:ph['to']]
    for k in range(0, len(seg), 20):
        chunk = seg[k:k + 20]
        stages.append({'stage': len(stages) + 1, 'phase': ph['phase'], 'coverage_pct': chunk[-1]['cum_pct'],
                       'chars': [{'char': c['char'], 'meaning': c['meaning'], 'pinyin_raw': c['pinyin_raw'], 'hsk': c['hsk'], 'rank': c['rank']} for c in chunk]})
out = {'title': '절벽 한자', 'subtitle': '영화·드라마 대사 한자 빈도 — R1~R4 누적 55/60/70/80%, R5 2,000자',
       'total': len(chars), 'phases': phases, 'stages': stages}
json.dump(out, open('assets/data/hanzi/hanzi_cliff.json', 'w', encoding='utf-8'), ensure_ascii=False, separators=(',', ':'))
print('글자', len(chars), '단원', len(stages), [(p['name'], p['to'], p['coverage_pct']) for p in phases])
