"""모든 회화를 8턴 단위로 재구성 (2026-09-08).

- L1 : 5 에피소드 × 40턴 → 각 5개 × 8턴  (ep1_1 … ep1_5, 제목 '매칭 ①')
- L2/L3 : 13턴(1편 14턴) → ① 1~8턴, ② 9~끝 + 이어쓰기(3턴/2턴, 별도 에이전트) → 8턴
- L4 : 이미 8턴, 변경 없음

1단계(기본): 분할 + 이어쓰기 작업 파일 생성   python split_dialogues_8.py
2단계(--merge): 에이전트 결과(zh,ko) 병합 + pypinyin 병음   python split_dialogues_8.py --merge
"""
import json, sys, io, copy, re
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
ROOT = r'C:\Users\Johnjeon\talkverse\zh\assets\data\dialogues\north'
SP = r'C:\Users\Johnjeon\AppData\Local\Temp\claude\C--Users-Johnjeon-talkverse-zh\0f30ac9b-148d-43f6-97b2-e93497af23d0\scratchpad'
CIRC = '①②③④⑤⑥⑦⑧'
N = 8


def renum(turns):
    return [dict(t, num=i + 1) for i, t in enumerate(turns)]


def load(level):
    return json.load(open(f'{ROOT}\\{level}.json', encoding='utf-8'))


def save(level, d):
    json.dump(d, open(f'{ROOT}\\{level}.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=1)


def split_l1():
    d = load('L1')
    if d.get('schema', '').startswith('v6'):
        print('L1 already split');
        return
    out = []
    for ep in d['episodes']:
        turns = ep['turns']
        parts = [turns[i:i + N] for i in range(0, len(turns), N)]
        for k, p in enumerate(parts):
            e = copy.deepcopy(ep)
            e['id'] = f"{ep['id']}_{k + 1}"
            e['title'] = f"{ep['title']} {CIRC[k]}"
            e['parent'] = ep['id']
            e['turns'] = renum(p)
            out.append(e)
    d['episodes'] = out
    d['schema'] = 'v6-8turn-split'
    d['kpi'] = {'episodes': len(out), 'turns_per_episode': N, 'turns_total': sum(len(e['turns']) for e in out)}
    save('L1', d)
    print('L1 →', len(out), 'episodes ×', N)


def split_l23(level):
    d = load(level)
    if d.get('schema', '').startswith('v6'):
        print(level, 'already split');
        return
    out, tasks = [], []
    for dl in d['dialogues']:
        turns = dl['turns']
        a = copy.deepcopy(dl)
        a['id'], a['title'], a['parent'] = f"{dl['id']}_1", f"{dl['title']} ①", dl['id']
        a['turns'] = renum(turns[:N])
        b = copy.deepcopy(dl)
        b['id'], b['title'], b['parent'] = f"{dl['id']}_2", f"{dl['title']} ②", dl['id']
        tail = turns[N:]
        b['turns'] = renum(tail)
        b['_needs'] = N - len(tail)
        out += [a, b]
        if b['_needs'] > 0:
            last = tail[-1]['speaker'] if tail else turns[-1]['speaker']
            tasks.append({
                'id': b['id'], 'title': dl['title'], 'scenario': dl.get('scenario', ''),
                'turns_so_far': [{'speaker': t['speaker'], 'zh': t['zh'], 'ko': t['ko']} for t in turns],
                'add': b['_needs'], 'next_speaker': 'A' if last == 'B' else 'B',
            })
    d['dialogues'] = out
    d['schema'] = 'v6-8turn-split'
    d['characters_note'] = d.get('characters')
    save(level, d)
    json.dump({'level': level, 'characters': d.get('characters'), 'tasks': tasks},
              open(f'{SP}\\ext_{level}.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print(level, '→', len(out), 'dialogues; need extension:', len(tasks), 'turns to write:', sum(t['add'] for t in tasks))


def merge(level):
    from pypinyin import pinyin, Style
    d = load(level)
    res = json.load(open(f'{SP}\\ext_{level}_out.json', encoding='utf-8'))
    n = 0
    for dl in d['dialogues']:
        need = dl.pop('_needs', 0)
        if need <= 0:
            continue
        new = res.get(dl['id'])
        if not new or len(new) < need:
            print('MISSING', dl['id']);
            continue
        for t in new[:need]:
            py = ' '.join(x[0] for x in pinyin(t['zh'], style=Style.TONE))
            py = re.sub(r'\s+([，。？！,.?!])', r'\1', py)
            py = py[:1].upper() + py[1:]
            dl['turns'].append({'num': 0, 'speaker': t['speaker'], 'zh': t['zh'], 'pinyin': py,
                                'ko': t['ko'], 'note': None, 'tags': ['ext']})
            n += 1
        dl['turns'] = renum(dl['turns'])
    bad = [dl['id'] for dl in d['dialogues'] if len(dl['turns']) != N]
    d['kpi'] = {'dialogues': len(d['dialogues']), 'turns_per_dialogue': N,
                'turns_total': sum(len(x['turns']) for x in d['dialogues'])}
    save(level, d)
    print(level, 'merged', n, 'turns; not 8:', bad)


if __name__ == '__main__':
    if '--merge' in sys.argv:
        for lv in ('L2', 'L3'):
            merge(lv)
    else:
        split_l1()
        for lv in ('L2', 'L3'):
            split_l23(lv)
