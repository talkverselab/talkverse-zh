#!/usr/bin/env python3
"""생성된 문장 조각을 받아쓰기로 검사하고(품질 기준 = ja docs/DIALOGUE_AUDIO.md §5, b189b0c), 나쁜 조각의 재생성 작업을 만든다(mlx-whisper·pypinyin·librosa 필요 — venv ~/.venvs/tts_zh).
  python qa.py <wav폴더> <편id>... [--jobs <moss_jobs.json>]   결과는 <wav폴더>/qa.json 에 쌓인다(조각 → sim·dur·tries·ok)
중국어 비교: 받아쓰기(whisper language zh)와 본문을 **한자만 남겨 성조 없는 병음**으로 바꿔 견준다(번체·동음자 흡수, 숫자→한자).
§5 기준: 유사도 ≥ 0.90 · **첫 한자·끝 한자가 빠지면 불합격** · 최대 음량 ≥ -30dB · 클리핑 0 · 말 속도 = 중국어 참고 음성(VoxCPM2) 속도 중앙값(한자/초)의 0.75~1.15배(pack 이 1.15배까지 당기므로 ×1.15 뒤에도 0.75 미만이면 미달)
· 잡음 바닥(무음 구간만) ≤ NOISE_MAX. **수치는 체일 뿐** — 받아쓰기 1.0 인 조각은 잡음·속도만으로 다시 만들지 않는다.
재생성본은 PC 의 out/zh/retake/<편>/<조각>.t<N>.wav — 받아 온 뒤 다시 돌리면 가장 잘 나온 판을 본 파일로 고른다. 세 번 해도 나쁘면 가장 나은 판을 쓰고 qa.json 에 ok=false 로 남긴다."""
import difflib, glob, json, os, re, shutil, statistics, subprocess, sys
import mlx_whisper
from pypinyin import lazy_pinyin
import ttslib as L
M = 'mlx-community/whisper-large-v3-turbo'
LANG, REF, OUT = 'Chinese', 'ref_zh', 'zh'
DIG = str.maketrans('0123456789', '零一二三四五六七八九')
SIM_MIN = 0.90
REF_SPEED = [L.V.get('ref_speed_hanzi_per_sec') or 4.0]   # 한자/초 — voices.json 의 측정값(없으면 main 이 <wav>/ref_zh 로 잰다). 절대값을 다른 언어에 쓰지 말 것
NOISE_MAX = -55.0   # §5 조각 기준(무음 구간 RMS). 받아쓰기 1.0 이면 적용하지 않는다


def hanzi(s):
    return L.HAN.findall(s.translate(DIG))


PARTICLES = set('哦喽啊呢吧呀嘛啦哈呗哟嘞咯呐嗳哎诶欸嘿唉')


def strip_particles(h):
    """끝 어조사를 뗀 한자 목록(전부 어조사면 원본 그대로)."""
    i = len(h)
    while i > 1 and h[i - 1] in PARTICLES:
        i -= 1
    return h[:i]


def norm(s):
    """한자만 남겨 성조 없는 병음 문자열로(비교용)."""
    return ''.join(lazy_pinyin(''.join(hanzi(s))))


def dur(f):
    return float(subprocess.run(['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', f], capture_output=True, text=True).stdout or 0)


def speech_dur(f):
    import librosa
    y, sr = librosa.load(f, sr=16000)
    yt, _ = librosa.effects.trim(y, top_db=40)
    return len(yt) / sr


def ref_speed(d):
    """참고 음성(VoxCPM2) 말 속도 중앙값(한자/초) — 언어마다 한 번 재서 voices.json 에 적는다."""
    v = []
    for f in glob.glob(f'{d}/*.wav'):
        voice, emo = os.path.basename(f)[:-4].rsplit('_', 1)
        text = L.V['base_text'] if emo == 'base' else L.V['emotions'].get(emo, {}).get('ref', '')
        n = len(hanzi(text)); sp = speech_dur(f)
        if n and sp > 0:
            v.append(n / sp)
    return statistics.median(v) if v else None


def score(f, text):
    h = hanzi(text); n = len(h); d = dur(f)
    pk, nf, clip = L.audio_stats(f)
    if d <= 0 or pk < -30:                 # 거의 무음으로 나온 조각(생성 실패)
        return 0.0, d
    if clip > 0.0005:                      # 클리핑
        return 0.0, d
    if d > 2.2 + 0.45 * n or d < 0.08 * n:  # 한자 하나 ≈ 0.2~0.4초(거친 체)
        return 0.0, d
    if n <= 2:                             # 한두 글자는 받아쓰기를 믿을 수 없다 — 길이만 본다
        return (1.0 if d <= 2.0 else 0.0), d
    r = mlx_whisper.transcribe(f, path_or_hf_repo=M, language='zh', condition_on_previous_text=False)
    g = norm(r['text']); w = norm(text)
    sim = difflib.SequenceMatcher(None, w, g).ratio()
    if sim < 1.0:                          # §5: 받아쓰기 1.0 인 조각은 잡음·속도 수치만으로 다시 만들지 않는다
        sp = speech_dur(f); ratio = (n / sp) / REF_SPEED[0] if sp > 0 else 1.0   # 말 속도 = 참고 음성 중앙값 대비
        if ratio * 1.15 < 0.75 or ratio > 1.15:
            return 0.0, d
        if nf is not None and nf > NOISE_MAX:
            return 0.0, d
    gh = hanzi(r['text'])
    if gh:                                 # 첫 한자·끝 한자가 빠지면 점수와 무관하게 불합격(소리로 견줌)
        he, ge = strip_particles(h), strip_particles(gh)   # 문장 끝 어조사(哦/喽/啊/呢…)는 whisper 가 자주 바꿔 쓰므로 그 앞 글자로 견준다
        if lazy_pinyin(h[0])[0] != lazy_pinyin(gh[0])[0] or (he and ge and lazy_pinyin(he[-1])[0] != lazy_pinyin(ge[-1])[0]):
            sim = min(sim, SIM_MIN - 0.01)
    else:
        sim = 0.0
    return sim, d


def main():
    a = sys.argv[1:]; jobs_out = None
    if '--jobs' in a:
        i = a.index('--jobs'); jobs_out = a[i + 1]; a = a[:i] + a[i + 2:]
    wav, eps = a[0], a[1:]
    if not L.V.get('ref_speed_hanzi_per_sec') and os.path.isdir(f'{wav}/{REF}'):
        rs = ref_speed(f'{wav}/{REF}')
        if rs:
            REF_SPEED[0] = rs
    print(f'참고 음성 속도 중앙값 {REF_SPEED[0]:.2f}한자/초 → 허용 {REF_SPEED[0]*0.75:.2f}~{REF_SPEED[0]*1.15:.2f}')
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
            q['ok'] = q['sim'] >= SIM_MIN
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
