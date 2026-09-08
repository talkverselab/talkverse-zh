"""2026-09-08: 남은 번호성조 병음 → 성조 부호, 어휘 rd 의 숫자 앞뒤 띄어쓰기.

- grammar/lesson*.json  chunks.*.pinyin  'yi1 ge5' → 'yī ge'
- vocab/*.json          rd  'shì4hào' → 'shì 4 hào'
"""
import json, re, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
ROOT = r'C:\Users\Johnjeon\talkverse\zh\assets\data'

MARKS = {'a': 'āáǎà', 'e': 'ēéěè', 'i': 'īíǐì', 'o': 'ōóǒò', 'u': 'ūúǔù', 'ü': 'ǖǘǚǜ',
         'A': 'ĀÁǍÀ', 'E': 'ĒÉĚÈ', 'I': 'ĪÍǏÌ', 'O': 'ŌÓǑÒ', 'U': 'ŪÚǓÙ'}


def syl(s):
    s = s.replace('u:', 'ü').replace('U:', 'Ü')
    m = re.match(r'^([A-Za-zü:Ü]+)([0-5])$', s)
    if not m:
        return s
    letters, tone = m.group(1), int(m.group(2))
    if tone in (0, 5):
        return letters
    low = letters.lower()
    idx = -1
    for v in 'aeo':
        if v in low:
            idx = low.index(v)
            break
    if idx < 0:
        for i in range(len(low) - 1, -1, -1):
            if low[i] in 'iouü':
                idx = i
                break
    if idx < 0:
        return letters
    ch = letters[idx]
    return letters[:idx] + MARKS.get(ch, ch * 4)[tone - 1] + letters[idx + 1:]


def toned(p):
    return ' '.join(syl(x) for x in p.split(' '))


n = 0
for f in ('lesson1', 'lesson2'):
    p = f'{ROOT}\\grammar\\{f}.json'
    d = json.load(open(p, encoding='utf-8'))
    for k, v in d.get('chunks', {}).items():
        py = v.get('pinyin')
        if isinstance(py, str) and re.search(r'[a-z][0-5]', py):
            v['pinyin'] = toned(py)
            n += 1
    json.dump(d, open(p, 'w', encoding='utf-8'), ensure_ascii=False, indent=2)
print('grammar chunks converted:', n)

m = 0
for f in ('travel_words', 'travel_expressions'):
    p = f'{ROOT}\\vocab\\{f}.json'
    s = open(p, encoding='utf-8').read()
    d = json.loads(s)
    def walk(o):
        global m
        if isinstance(o, dict):
            rd = o.get('rd')
            if isinstance(rd, str) and re.search(r'\d', rd):
                new = re.sub(r'(?<=[^\s\d])(?=\d)', ' ', rd)
                new = re.sub(r'(?<=\d)(?=[^\s\d.:])', ' ', new)
                new = re.sub(r'\s+', ' ', new).strip()
                if new != rd:
                    o['rd'] = new
                    m += 1
            for v in o.values():
                walk(v)
        elif isinstance(o, list):
            for v in o:
                walk(v)
    walk(d)
    json.dump(d, open(p, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
print('vocab rd spacing fixed:', m)
