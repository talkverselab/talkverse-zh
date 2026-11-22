#!/usr/bin/python3
"""문장 조각 wav → 턴별 mp4(AAC) → R2 `audio/zh/<편>/<턴>_<m|f>.mp4` + D1 `audio_lines`(lang='zh', 그 편의 줄을 지우고 다시 넣는다). 한국어앱 pack.py 를 중국어로.
모든 턴에 남성판·여성판 두 파일·두 줄(본문 text(중국어)·reading(병음)·rd(한글 독음)·ko(한국어 뜻) 포함). 두 판의 소리가 같아도 따로 올린다 — 구조를 단순하게.
§5(b189b0c): 조각마다 앞뒤 무음을 자르고 조각 안 쉼 ≤0.25초로 줄인 뒤 0.18초 간격으로 잇는다(「…」이 있던 조각 경계는 0.25초). 느린 조각(한자/초 < 참고 음성 중앙값×0.9)은 음높이를 유지한 채 최대 1.15배. 최종 mp4 의 가장 긴 무음 > 0.6초면 로그에 적는다. 소리 크기 -18 LUFS.
  python3 tools/tts/pack.py <wav폴더> <편id>... [--upload]
목록 = data/tts/audio_zh.json(리뷰 페이지용). 주소에는 ?v=<sha1 앞 8자리>(서버 캐시가 1년)."""
import datetime, hashlib, json, os, re, subprocess, sys, tempfile
from concurrent.futures import ThreadPoolExecutor
import ttslib as L
R = L.R
TRIM = ('silenceremove=start_periods=1:start_threshold=-45dB:start_silence=0.03,areverse,'
        'silenceremove=start_periods=1:start_threshold=-45dB:start_silence=0.05,areverse,'
        'silenceremove=stop_periods=-1:stop_duration=0.25:stop_threshold=-45dB:stop_silence=0.25')
GAP, GAP_DOTS, MAX_TEMPO, MAX_SIL = 0.18, 0.25, 1.15, 0.6
# 재생성 3번 뒤에도 받아쓰기 점수가 이 아래인 조각이 든 턴은 D1 목록에 넣지 않는다(파일은 올림) — 앱이 기기 TTS 로 읽는다(11/23 uk). 경계 0.85~0.9 는 넣음.
LIST_MIN = 0.85


def bad_segs(wav):
    qf = f'{wav}/qa.json'
    Q = json.load(open(qf, encoding='utf-8')) if os.path.exists(qf) else {}
    return {k for k, v in Q.items() if isinstance(v, dict) and 'sim' in v and v['sim'] < LIST_MIN}
SLOW = [(L.V.get('ref_speed_hanzi_per_sec') or 4.0) * 0.9]   # 한자/초 — 참고 음성 중앙값(voices.json)의 0.9배 미만이면 당긴다
W = ['npx', '-y', 'wrangler@4']


def run(*a):
    subprocess.run(a, check=True, capture_output=True)


def gapfile(tmp, sec):
    g = f'{tmp}/gap{sec}.wav'
    if not os.path.exists(g):
        run('ffmpeg', '-y', '-f', 'lavfi', '-i', 'anullsrc=r=24000:cl=mono', '-t', str(sec), g)
    return g


def build(wav, ep, num, tag, segs, pause, out, tmp):
    parts = []
    for i, (_, text) in enumerate(segs):
        o = f'{tmp}/{ep}_{num}_{i}_{tag}.wav'
        src = f'{wav}/{ep}/{num:02d}_{i}_{tag}.wav'
        run('ffmpeg', '-y', '-i', src, '-af', TRIM, '-ar', '24000', '-ac', '1', o)
        if os.path.getsize(o) < 1000:            # 소리가 작아 무음 자르기에 전부 잘려 나간 조각(ffmpeg 는 0 을 돌려준다) → 자르지 않고 쓴다
            run('ffmpeg', '-y', '-i', src, '-ar', '24000', '-ac', '1', o)
        n = len(L.HAN.findall(text)); d = dur(o)
        if n >= 3 and d > 0 and n / d < SLOW[0]:  # 느린 조각은 속도만 올린다(음높이 유지)
            t = min(MAX_TEMPO, SLOW[0] / (n / d)); o2 = o[:-4] + '_t.wav'
            run('ffmpeg', '-y', '-i', o, '-af', f'atempo={t:.3f}', o2); o = o2
        parts.append(o)
    seq = []
    if pause and pause[0][0]:                    # 턴 첫머리의 「…」 → 0.25초 쉼
        seq.append(gapfile(tmp, GAP_DOTS))
    for i, p in enumerate(parts):
        if i:
            dots = (pause[i - 1][1] or pause[i][0]) if pause else False
            seq.append(gapfile(tmp, GAP_DOTS if dots else GAP))
        seq.append(p)
    lst = f'{tmp}/{ep}_{num}_{tag}.txt'; open(lst, 'w').write(''.join(f"file '{x}'\n" for x in seq))
    j = f'{tmp}/{ep}_{num}_{tag}_j.wav'; run('ffmpeg', '-y', '-f', 'concat', '-safe', '0', '-i', lst, '-c', 'copy', j)
    run('ffmpeg', '-y', '-i', j, '-af', 'apad=pad_dur=0.12,loudnorm=I=-18:TP=-1.5:LRA=11,aresample=44100', '-ac', '1',
        '-c:a', 'aac', '-b:a', '80k', '-movflags', '+faststart', '-f', 'mp4', '-map_metadata', '-1', out)
    ms = max_silence(out)
    if ms > MAX_SIL:
        print(f'  무음 {ms:.2f}초 > {MAX_SIL}: {ep} {num:02d}_{tag}', flush=True)
    return dur(out)


def dur(f):
    return float(subprocess.run(['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', f], capture_output=True, text=True).stdout or 0)


def max_silence(f):
    """파일 안(앞뒤 제외) 가장 긴 무음 길이(초, -40dB 기준)."""
    o = subprocess.run(['ffmpeg', '-hide_banner', '-i', f, '-af', 'silencedetect=noise=-40dB:d=0.2', '-f', 'null', '-'], capture_output=True, text=True).stderr
    ends = [float(x) for x in re.findall(r'silence_end: ([\d.]+)', o)]; durs = [float(x) for x in re.findall(r'silence_duration: ([\d.]+)', o)]
    total = dur(f)
    inner = [d for e, d in zip(ends, durs) if e < total - 0.05 and e - d > 0.05]
    return max(inner) if inner else 0.0


def put(r):
    for _ in range(3):
        x = subprocess.run(W + ['r2', 'object', 'put', f"talkverse-art/{r['key']}", '--file', r['f'], '--content-type', 'audio/mp4', '--remote'], cwd=R, capture_output=True, text=True)
        if x.returncode == 0:
            return None
    return r['key'] + ' ' + x.stderr[-200:]


def main():
    UP = '--upload' in sys.argv; a = [x for x in sys.argv[1:] if x != '--upload']; wav, eps = a[0], a[1:]
    tmp = tempfile.mkdtemp(); q = lambda s: "'" + s.replace("'", "''") + "'"
    mf = f'{R}/data/tts/audio_zh.json'; BAD = bad_segs(wav)
    for ep in eps:
        rows = []
        for t in L.turns(ep):
            for g in 'mf':
                x = t[g]; tag = 'c' if t['same'] else g; f = f"{tmp}/{ep}_{t['num']:02d}_{g}.mp4"
                d = build(wav, ep, t['num'], tag, x['segs'], x.get('pause'), f, tmp)
                rows.append(dict(turn=t['num'], voice=g, speaker=x['voice'], emotion='+'.join(s[0] for s in x['segs']), key=f"audio/zh/{ep}/{t['num']:02d}_{g}.mp4",
                                 sha1=hashlib.sha1(open(f, 'rb').read()).hexdigest(), ms=int(d * 1000), text=x['text'], reading=x['reading'], rd=x['rd'], ko=x['ko'], f=f,
                                 bad=any(f"{ep}/{t['num']:02d}_{i}_{tag}.wav" in BAD for i in range(len(x['segs'])))))
        if UP:
            with ThreadPoolExecutor(8) as ex:
                err = [e for e in ex.map(put, rows) if e]
            if err:
                sys.exit('R2 실패 ' + ' | '.join(err[:3]))
            now = datetime.datetime.now(datetime.UTC).strftime('%Y-%m-%d %H:%M:%S')
            sql = [f"DELETE FROM audio_lines WHERE lang='zh' AND episode='{ep}';"] + [
                "INSERT INTO audio_lines (lang,episode,turn,voice,speaker,emotion,key,ms,sha1,text,reading,rd,ko,created_at) VALUES "
                f"('zh','{ep}',{r['turn']},'{r['voice']}','{r['speaker']}','{r['emotion']}','{r['key']}',{r['ms']},'{r['sha1']}',{q(r['text'])},{q(r['reading'])},{q(r['rd'])},{q(r['ko'])},'{now}');" for r in rows if not r['bad']]
            sf = f'{tmp}/{ep}.sql'; open(sf, 'w', encoding='utf-8').write('\n'.join(sql) + '\n')
            x = subprocess.run(W + ['d1', 'execute', 'talkverse-db', '--remote', '--file', sf, '-y'], cwd=R, capture_output=True, text=True)
            if x.returncode:
                sys.exit('D1 실패 ' + ep + x.stderr[-400:] + x.stdout[-300:])
        M = json.load(open(mf, encoding='utf-8')) if os.path.exists(mf) else {}
        M[ep] = [{k: v for k, v in r.items() if k not in ('f', 'text', 'reading', 'rd', 'ko', 'bad') or (k == 'bad' and v)} for r in rows]
        json.dump(M, open(mf, 'w', encoding='utf-8'), ensure_ascii=False, indent=0)
        nb = sum(r['bad'] for r in rows)
        print(ep, len(rows), '줄', f'(목록 뺌 {nb})' if nb else '', sum(r['ms'] for r in rows) // 1000, '초', '올림' if UP else '안 올림', flush=True)


if __name__ == '__main__':
    main()
