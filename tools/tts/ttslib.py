"""회화 음성 공통(중국어): 감정 계획 + 편 JSON → 턴별 남성판·여성판(본문 넷 + 읽을 조각). 일본어앱·한국어앱 tools/tts/ttslib.py 와 같은 구조.
D1 audio_lines 열에 맞춘 이름: text = 중국어 본문(zh), reading = 병음(pinyin, 성조 부호), rd = 한글 독음, ko = 한국어 뜻.
모든 턴에 m·f 두 판, 판마다 본문과 mp4 하나. 소리 낼 글이 없는 턴(지문·「……」)만 뺀다."""
import glob, json, os, re
R = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
V = json.load(open(f'{R}/data/tts/voices.json', encoding='utf-8'))
EP = {os.path.basename(p)[:-5]: p for p in glob.glob(f'{R}/assets/data/dialogues/R*/*/*.json')}
HAN = re.compile(r'[一-鿿]')
SIL = re.compile(r'[\s…。、，！？!?.,~♪]|\([^)]*\)|（[^）]*）')
# 한국어 뜻(ko) 칸의 조사 — 이름을 넣은 뒤 받침에 맞춘다(한국어앱 ttslib 와 같음)
JOSA = {'은': '는', '는': '은', '이': '가', '가': '이', '을': '를', '를': '을', '과': '와', '와': '과', '이라고': '라고', '라고': '이라고', '아': '야', '야': '아',
        '으로': '로', '로': '으로', '이랑': '랑', '랑': '이랑', '이야': '야', '이에요': '예요', '예요': '이에요', '이라는': '라는', '라는': '이라는', '이요': '요', '요': '이요'}
BATCHIM = {'은', '이', '을', '과', '이라고', '아', '으로', '이랑', '이야', '이에요', '이라는', '이요'}
_J = r'(이라고|이라는|이에요|이요|이랑|이야|으로|라고|라는|예요|은|는|이|가|을|를|과|와|아|야|로|랑|요)(?![가-힣])'


def _josa(word, j):
    c = word[-1]
    if not ('가' <= c <= '힣'):
        return j
    has = (ord(c) - 0xAC00) % 28 != 0
    if j in ('으로', '로') and (ord(c) - 0xAC00) % 28 == 8:
        return '로'
    if j in ('야', '이야'):
        return j if has else '야'
    return j if (j in BATCHIM) == has else JOSA.get(j, j)


def fills(P, g):
    out = {}
    for k, x in V['fill'].items():
        out[k] = x.get(g) or x
    out.update(P.get('fill', {}))
    return out


def fill(s, F, key):
    """자리 채우기. key = text(중국어) · reading(병음) · rd(한글 독음) · ko(한국어 뜻, 조사 맞춤)."""
    if '{' not in s:
        return s
    if key == 'ko':
        def rep(m):
            w = F.get('{' + m.group(1) + '}', {}).get('ko')
            return m.group(0) if w is None else w + _josa(w, m.group(2))
        s = re.sub(r'\{(\w+)\}' + _J, rep, s)
    for k, x in F.items():
        s = s.replace(k, x.get(key) or x['text'])
    return s


def turns(ep):
    """[{num, speaker, m:{voice,text,reading,rd,ko,segs:[(감정,읽기)]}, f:{…}, same:bool}] — 소리 없는 턴은 뺀다."""
    P = json.load(open(f'{R}/data/tts/plan/{ep}.json', encoding='utf-8')); d = json.load(open(EP[ep], encoding='utf-8'))
    out = []
    for t in d['turns']:
        T = P['turns'][str(t['num'])]; row = {'num': t['num'], 'speaker': t['speaker']}
        for g in 'mf':
            X = T.get(g) or {}; F = fills(P, g)
            segs = [(s[0], fill(s[-1], F, 'text').strip()) for s in (X.get('segs') or T['segs'])]
            segs = [s for s in segs if SIL.sub('', s[1])]
            row[g] = {'voice': ('am' if g == 'm' else 'af') if t['speaker'] == 'A' else P['cast'][t['speaker']],
                      'text': fill(X.get('text') or t['zh'], F, 'text'), 'reading': fill(X.get('reading') or t.get('pinyin', ''), F, 'reading'),
                      'rd': fill(X.get('rd') or t.get('rd', ''), F, 'rd'), 'ko': fill(X.get('ko') or t.get('ko', ''), F, 'ko'), 'segs': segs}
        if not row['m']['segs'] or not row['f']['segs']:
            continue
        row['same'] = row['m']['voice'] == row['f']['voice'] and row['m']['segs'] == row['f']['segs']
        out.append(row)
    return out


def seg_files(ep):
    """생성할 조각 [(파일이름, 목소리, 감정, 읽기)] — 두 판이 같으면 c 하나, 다르면 m·f."""
    out = []
    for r in turns(ep):
        for tag in (['c'] if r['same'] else ['m', 'f']):
            x = r['m' if tag == 'c' else tag]
            for i, (emo, text) in enumerate(x['segs']):
                out.append((f"{r['num']:02d}_{i}_{tag}.wav", x['voice'], emo, text))
    return out


def planned():
    """감정 계획이 있는 편 id(정렬)."""
    return sorted(os.path.basename(p)[:-5] for p in glob.glob(f'{R}/data/tts/plan/*.json') if os.path.basename(p)[:-5] in EP)
