#!/usr/bin/env python3
"""화면 목록(열람률 분모) 내보내기 — uk 규격 2026-11-28 `~/talkverse/_shared/talkverse_usage/USAGE_LOG.md` §앱 5.

    python3 tool/usage_catalog.py [--build N] [--out tool/usage_catalog.json] [--offline]

화면 ID·tier 규칙은 `lib/data/usage_pages.dart` 의 표와 같다(바꾸면 둘 다):
  conv/<편 id>              회화 한 편        R0·R1 free, 그 밖 pro
  cur/<단계·급수>/<편 id>    커리큘럼 편 연습   HSK4·HSK5 exam, 판의 free → free, 그 밖 pro
  grammar/step<n>           문법 스텝         freeSteps(기본 2)까지 free, 그 밖 pro
  sense/<회차 id>            언어감각 회차      freeSenseLevels(기본 1)급까지 free, 그 밖 pro
  vocab/<묶음 id>            HSK 단어장 묶음    hsk4·hsk5 exam, 그 밖 free

내용은 앱이 실제로 보는 것과 같게 — 서버 원고(auth.talkverse.uk/art/script/zh, ScriptSync)와 서버 커리큘럼 판
(talkverse.uk/api/curriculum/zh)이 있으면 그것, 없으면 앱 묶음 assets/. 올리기는 uk(`tools/usage_catalog.sh zh <json>`).
"""
import argparse
import json
import os
import re
import sys
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA = os.path.join(ROOT, 'assets', 'data')
SCRIPT_ROOT = 'https://auth.talkverse.uk/art/script/zh'
PLAN_URL = 'https://talkverse.uk/api/curriculum/zh'
LATEST_URL = 'https://github.com/talkverselab/talkverse-zh/releases/download/latest/latest.json'
PAGE_RE = re.compile(r'^[\w./:#-]{1,120}$')
EXAM_KEYS = {'HSK4', 'HSK5', 'hsk4', 'hsk5'}  # Entitlement.examLevel
DIALOGUE_RE = re.compile(r'^dialogues/R[0-4]/[^/]+/[^/]+\.json$')


def fetch(url):
    try:
        with urllib.request.urlopen(urllib.request.Request(url, headers={'User-Agent': 'usage-catalog'}), timeout=20) as r:
            return r.read().decode('utf-8')
    except Exception:
        return None


class Script:
    """ScriptSync 와 같은 규칙: 서버 판 rev 가 앱 안 rev 보다 크면 서버 목록이 기준(빠진 편 숨김·새 편 더함)."""

    def __init__(self, offline):
        base = json.load(open(os.path.join(DATA, 'script_rev.json')))
        self.base_rev = base.get('rev', 0)
        self.base_files = set(base.get('files', {}))
        self.server = None
        if not offline:
            body = fetch(f'{SCRIPT_ROOT}/index.json')
            if body:
                j = json.loads(body)
                if j.get('rev', 0) > self.base_rev:
                    self.server = j
        self.rev = self.server['rev'] if self.server else self.base_rev

    def files(self):
        if self.server:
            return set(self.server.get('files', {}))
        on_disk = set()
        for dp, _, fs in os.walk(DATA):
            for f in fs:
                if f.endswith('.json'):
                    on_disk.add(os.path.relpath(os.path.join(dp, f), DATA))
        return on_disk

    def load(self, rel):
        if self.server and rel in self.server.get('files', {}):
            body = fetch(f'{SCRIPT_ROOT}/{rel}')
            if body:
                return json.loads(body)
        return json.load(open(os.path.join(DATA, rel)))


def has_content(j):  # GrammarSteps.hasContent
    return any(isinstance(j.get(k), list) and j[k] for k in ('patterns', 'stages', 'sentences', 'points'))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--build', type=int)
    ap.add_argument('--out', default=os.path.join(ROOT, 'tool', 'usage_catalog.json'))
    ap.add_argument('--offline', action='store_true', help='서버를 보지 않고 앱 묶음만')
    a = ap.parse_args()

    sc = Script(a.offline)
    plan_raw = None if a.offline else fetch(PLAN_URL)
    plan = json.loads(plan_raw) if plan_raw else None
    if not plan or not plan.get('stages'):
        plan = json.load(open(os.path.join(ROOT, 'assets', 'curriculum_zh.json')))
    free_steps = int(plan.get('freeSteps') or 2)
    free_sense = int(plan.get('freeSenseLevels') or 1)

    pages = []

    def add(page, tier, title):
        if not PAGE_RE.match(page):
            sys.exit(f'화면 ID 규칙 위반: {page!r}')
        pages.append({'page': page, 'tier': tier, 'title': title})

    # 회화 한 편
    dialogues = {}
    for rel in sorted(p for p in sc.files() if DIALOGUE_RE.match(p)):
        d = sc.load(rel)
        did = d.get('id') or os.path.basename(rel)[:-5]
        region = rel.split('/')[1]
        dialogues[did] = d
        add(f'conv/{did}', 'free' if region in ('R0', 'R1') else 'pro', d.get('title', did))

    # 커리큘럼 편 연습(단계·준비 급수별)
    units = []
    for s in plan.get('stages', []):
        n = str(s['n'])
        units.append((n, s.get('title') or f'{n}단계', s['free'] if isinstance(s.get('free'), bool) else n == '1', s.get('dialogueIds', [])))
    for p in plan.get('prep', []):
        for m in p.get('levels', []):
            units.append((str(m['id']), m.get('title') or m['id'], m.get('free') is True, m.get('dialogueIds', [])))
    for key, title, free, ids in units:
        tier = 'exam' if key in EXAM_KEYS else ('free' if free else 'pro')
        for did in ids:
            if did in dialogues:  # 앱에 없는(숨긴) 편은 열 수 없다
                add(f'cur/{key}/{did}', tier, f"{title} · {dialogues[did].get('title', did)}")

    # 문법 스텝
    steps = sc.load('grammar/steps.json').get('steps', [])
    for e in sorted(steps, key=lambda e: e.get('step', 0)):
        n, f = int(e.get('step') or 0), e.get('file') or ''
        if n < 1 or not f:
            continue
        try:
            j = sc.load(f)
        except Exception:
            continue
        if not has_content(j):
            continue
        add(f'grammar/step{n}', 'free' if n <= free_steps else 'pro', (e.get('title') or '').strip() or j.get('title') or f'L{n}')

    # 언어감각 회차(SenseCourse.withoutEmpty — 빈 회차·급은 빠진다)
    sense = sc.load('grammar/sense_course.json')
    lv_no = 0
    for lv in sense.get('levels', []):
        ls = [l for l in lv.get('lessons', []) if l.get('open') is not None or l.get('sentences') or l.get('points')]
        if not ls:
            continue
        lv_no += 1
        for l in ls:
            add(f"sense/{l['id']}", 'free' if lv_no <= free_sense else 'pro', l.get('title') or l['id'])

    # HSK 단어장 묶음(주제별 단어·표현은 hasTravelData=false 라 메뉴에 없음)
    for t in json.load(open(os.path.join(DATA, 'vocab', 'hsk_words.json'))).get('themes', []):
        add(f"vocab/{t['id']}", 'exam' if t['id'] in EXAM_KEYS else 'free', t.get('title') or t['id'])

    if len({p['page'] for p in pages}) != len(pages):
        sys.exit('화면 ID 가 겹친다')

    build = a.build
    if build is None:
        lj = None if a.offline else fetch(LATEST_URL)
        build = int(json.loads(lj)['build']) if lj else 0

    out = {'build': build, 'pages': pages}
    with open(a.out, 'w', encoding='utf-8') as f:
        json.dump(out, f, ensure_ascii=False, indent=1)
        f.write('\n')
    cnt = {}
    for p in pages:
        k = (p['page'].split('/')[0], p['tier'])
        cnt[k] = cnt.get(k, 0) + 1
    print(f'{a.out}: build {build}, 원고 rev {sc.rev}, {len(pages)}개 화면')
    for (kind, tier), n in sorted(cnt.items()):
        print(f'  {kind:8} {tier:5} {n}')


if __name__ == '__main__':
    main()
