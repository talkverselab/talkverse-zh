#!/usr/bin/env python3
"""생성된 문장 조각을 받아쓰기로 검사하고, 나쁜 조각의 재생성 작업을 만든다(mlx-whisper·pypinyin 필요).
  python qa.py <wav폴더> <편id>... [--jobs <moss_jobs.json>]   결과는 <wav폴더>/qa.json 에 쌓인다(조각 → sim·dur·tries·ok)
중국어: 받아쓰기(whisper language zh)와 본문을 **한자만 남겨 성조 없는 병음**으로 바꿔 견준다 — whisper 가 번체·동음 한자를 내도 소리가 같으면 같게 본다.
숫자는 한자로(3个 → 三个). 나쁨 = 비슷함 0.72 미만, 길이가 글자 수에 견줘 지나치게 길거나 짧음, 최대 음량 -30dB 미만(생성 실패).
재생성본은 PC 의 out/zh/retake/<편>/<조각>.t<N>.wav — 받아 온 뒤 다시 돌리면 가장 잘 나온 판을 본 파일로 고른다. 세 번 해도 나쁘면 가장 나은 판을 쓰고 qa.json 에 ok=false 로 남긴다."""
import difflib, glob, json, os, re, shutil, subprocess, sys
import mlx_whisper
from pypinyin import lazy_pinyin
import ttslib as L
M = 'mlx-community/whisper-large-v3-turbo'
LANG, REF, OUT = 'Chinese', 'ref_zh', 'zh'
DIG = str.maketrans('0123456789', '零一二三四五六七八九')


def norm(s):
    """한자만 남겨 성조 없는 병음 문자열로(비교용)."""
    s = s.translate(DIG)
    return ''.join(lazy_pinyin(''.join(L.HAN.findall(s))))


def dur(f):
    return float(subprocess.run(['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', f], capture_output=True, text=True).stdout or 0)


def peak(f):
    o = subprocess.run(['ffmpeg', '-hide_banner', '-i', f, '-af', 'volumedetect', '-f', 'null', '-'], capture_output=True, text=True).stderr
    m = re.search(r'max_volume: (-?[\d.]+) dB', o)
    return float(m.group(1)) if m else -99.0


def score(f, text):
    n = len(L.HAN.findall(text)); d = dur(f)
    if d <= 0 or peak(f) < -30:            # 거의 무음으로 나온 조각(생성 실패)
        return 0.0, d
    if d > 2.2 + 0.45 * n or d < 0.08 * n:  # 한자 하나 ≈ 0.2~0.4초
        return 0.0, d
    if n <= 2:                            # 한두 글자는 받아쓰기를 믿을 수 없다 — 길이만 본다
        return (1.0 if d <= 2.0 else 0.0), d
    g = norm(mlx_whisper.transcribe(f, path_or_hf_repo=M, language='zh', condition_on_previous_text=False)['text'])
    return difflib.SequenceMatcher(None, norm(text), g).ratio(), d


def main():
    a = sys.argv[1:]; jobs_out = None
    if '--jobs' in a:
        i = a.index('--jobs'); jobs_out = a[i + 1]; a = a[:i] + a[i + 2:]
    wav, eps = a[0], a[1:]
    qf = f'{wav}/qa.json'; Q = json.load(open(qf, encoding='utf-8')) if os.path.exists(qf) else {}
    jobs = []; bad = 0
    for ep in eps:
        for name, voice, emo, text in L.seg_files(ep):
            k = f'{ep}/{name}'; f = f'{wav}/{k}'; q = Q.setdefault(k, {'tries': 0})
            if not os.path.exists(f):
                q.update(sim=0.0, ok=False); bad += 1; continue
            if 'sim' not in q:
                q['sim'], q['dur'] = score(f, text)
            for c in sorted(glob.glob(f'{wav}/retake/{k[:-4]}.t*.wav')):          # 받아 온 재생성본 중 더 나은 것을 본 파일로
                s, d = score(c, text)
                if s > q['sim']:
                    shutil.copy(c, f); q['sim'], q['dur'] = s, d
                os.remove(c)
            q['ok'] = q['sim'] >= 0.72
            if not q['ok']:
                bad += 1
                if q['tries'] < 3:
                    q['tries'] += 1
                    jobs.append({'out': f"{OUT}/retake/{k[:-4]}.t{q['tries']}.wav", 'text': text, 'language': LANG, 'reference': f'out/{REF}/{voice}_{emo}.wav', 'seed': 42 + 97 * q['tries']})
    json.dump(Q, open(qf, 'w', encoding='utf-8'), ensure_ascii=False, indent=0)
    if jobs_out:
        json.dump(jobs, open(jobs_out, 'w', encoding='utf-8'), ensure_ascii=False, indent=0)
    print(f'QA 편 {len(eps)} 나쁨 {bad} 재생성 {len(jobs)}')


if __name__ == '__main__':
    main()
