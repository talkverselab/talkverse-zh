import json, re
SRC = r'C:\Users\Johnjeon\OneDrive\전자책\01.03_중국어\co-Trip 여행 중국어.md'
OUTW = r'C:\Users\Johnjeon\talkverse\zh\assets\data\vocab\travel_words.json'
OUTE = r'C:\Users\Johnjeon\talkverse\zh\assets\data\vocab\travel_expressions.json'
THEMES = [
    (9,66,'basics','인사·기본 표현','👋'),(154,335,'basics','인사·기본 표현','👋'),
    (2947,2973,'basics','인사·기본 표현','👋'),(68,153,'places','지역·지명','🗺️'),
    (337,919,'food','맛집·음식','🍜'),(920,1503,'shopping','쇼핑','🛍️'),
    (1504,1752,'beauty','뷰티·마사지','💆'),(1753,1985,'sightsee','관광','🏯'),
    (1986,2183,'enter','엔터테인먼트','🎤'),(2184,2349,'hotel','호텔','🏨'),
    (2350,2535,'transport','교통·공항','✈️'),(2536,2625,'life','생활 편의','📮'),
    (2626,2769,'trouble','긴급·건강','🚨'),(2770,2825,'korea','한국 소개','🇰🇷'),
    (2826,2946,'basicwords','기본 단어','🔢'),(5159,5233,'basicwords','기본 단어','🔢'),
]
WORDISH = re.compile(r'LOOK|단어|단어장|지명|WORD|메뉴 읽|사이즈|숫자|요일|계절|신체')
SENT_PUNCT = re.compile(r'[。！？!?]')
lines = open(SRC, encoding='utf-8').read().split('\n')

def zh_len(z):
    return len(re.sub(r'[^\u4e00-\u9fff]', '', z))

def build(kind):
    themes, order = {}, []
    for a,b,tid,title,emoji in THEMES:
        if tid not in themes:
            themes[tid] = {'id':tid,'title':title,'emoji':emoji,'sections':[]}
            order.append(tid)
        cur=None; curname=''
        for ln in lines[a-1:b]:
            ln=ln.strip()
            if ln.startswith('## '):
                curname = re.sub(r'^\(이어짐\)\s*','',ln[3:].strip())
                cur={'title':curname,'words':[]}
                themes[tid]['sections'].append(cur)
                continue
            if ln.startswith('|') and cur is not None:
                cells=[c.strip() for c in ln.strip('|').split('|')]
                if len(cells)<3: continue
                ko,zh,rd = cells[0],cells[1],cells[2]
                if ko in ('한국어','---') or set(ko)<=set('-: ') or not zh or set(zh)<=set('-: '):
                    continue
                cur['words'].append({'ko':ko,'zh':zh,'rd':rd})
    for t in themes.values():
        secs=[]
        for s in t['sections']:
            if not s['words']: continue
            # 섹션 분류: 제목 규칙 우선, 아니면 평균 한자 길이
            if WORDISH.search(s['title']):
                is_word=True
            else:
                n=len(s['words'])
                punct=sum(1 for w in s['words'] if SENT_PUNCT.search(w['zh']))
                avg=sum(zh_len(w['zh']) for w in s['words'])/n
                # 문장부호가 30% 이상이면 표현으로 (인사·대답류 짧은 문장 포함)
                is_word = (punct/n) < 0.3 and avg<=4.5
            if (kind=='w')!=is_word: continue
            if secs and secs[-1]['title']==s['title']:
                secs[-1]['words'].extend(s['words'])
            else:
                secs.append(s)
        t['sections']=secs
    out=[themes[t] for t in order if themes[t]['sections']]
    if kind=='e':
        for t in out:
            if t['id']=='basics':
                t['title']='필수 표현'; t['emoji']='💬'
    return out

for kind,path,label in (('w',OUTW,'단어'),('e',OUTE,'표현')):
    ths=build(kind)
    json.dump({'_meta':f'co-Trip 여행 중국어 — 주제별 {label}','themes':ths},
              open(path,'w',encoding='utf-8'),ensure_ascii=False,indent=1)
    tot=sum(len(s['words']) for t in ths for s in t['sections'])
    print(f'--- {label} ({len(ths)}테마 {tot}항목) ---')
    for t in ths:
        n=sum(len(s['words']) for s in t['sections'])
        print(f"  {t['emoji']} {t['title']}: {n}")
