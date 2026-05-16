"""
MiniMax speech-2.8-hd 전체 생성 (743+ mp3, 캐릭터별 voice).

사용:
  $env:MINIMAX_API_KEY = "sk-api-..."
  python scripts/30_minimax_full.py
  # 또는 dry-run (몇 개 생성될지만):
  python scripts/30_minimax_full.py --dry

출력: C:/dev/talkverse_learning/assets/zh_data/audio/{hanzi,tone_matrix,dialog,l1_punchy}/*.mp3
       (기존 Edge TTS mp3 덮어씀 — 같은 path)
"""
import requests, os, sys, json, re, time
from pathlib import Path

API_KEY = os.environ.get('MINIMAX_API_KEY', '')
API_KEY = API_KEY.replace('\n', '').replace('\r', '').replace(' ', '').replace('\t', '').strip()
if not API_KEY:
    print('ERROR: MINIMAX_API_KEY 환경변수 set 필요')
    sys.exit(1)
print(f'[key] length={len(API_KEY)} (sanitized)')

DRY = '--dry' in sys.argv
FORCE = '--force' in sys.argv  # 기존 mp3 있어도 덮어쓰기 (MiniMax voice 적용 위해)
URL = 'https://api.minimax.io/v1/t2a_v2'
MODEL = 'speech-2.8-hd'

# === Voice 매핑 (젊은 친근 톤) ===
V_LEARN     = 'Chinese (Mandarin)_Lyrical_Voice'        # 한자·단어·통통 학습
V_MARK      = 'Chinese (Mandarin)_Pure-hearted_Boy'     # Mark 외국인 청년
V_LILY      = 'Chinese (Mandarin)_Soft_Girl'            # Lily 25 여
V_XIAOHONG  = 'Chinese (Mandarin)_Cute_Spirit'          # 小红 동생
V_MOM       = 'Chinese (Mandarin)_Warm-HeartedAunt'     # 엄마
V_DAD       = 'Chinese (Mandarin)_Sincere_Adult'        # 아빠
V_GRANDMA   = 'Chinese (Mandarin)_Kind-hearted_Elder'   # 할머니
V_GRANDPA   = 'Chinese (Mandarin)_Gentle_Senior'        # 할아버지
V_WANGGE    = 'Chinese (Mandarin)_Straightforward_Boy'  # 王哥 동료

# Stage direction (한국어) → voice 매핑
SPEAKER_VOICE = {
    'mark': V_MARK,
    'lily': V_LILY,
    '小丽': V_LILY,
    '小红': V_XIAOHONG,
    '동생': V_XIAOHONG,
    'lily 엄마': V_MOM, '엄마': V_MOM, '妈妈': V_MOM, '妈': V_MOM,
    'lily 아빠': V_DAD, '아빠': V_DAD, '爸爸': V_DAD, '爸': V_DAD,
    '할머니': V_GRANDMA, '奶奶': V_GRANDMA, '奶': V_GRANDMA,
    '할아버지': V_GRANDPA, '爷爷': V_GRANDPA, '爷': V_GRANDPA,
    '王哥': V_WANGGE, '동료': V_WANGGE, '老板': V_WANGGE,
}

# === 출력 위치 ===
ZH_DIR = 'D:/OneDrive/PROJECT/talkverse-learning/ZH'
OUT_BASE = Path('C:/dev/talkverse_learning/assets/zh_data/audio')
HANZI_DIR  = OUT_BASE / 'hanzi'
TONE_DIR   = OUT_BASE / 'tone_matrix'
DIALOG_DIR = OUT_BASE / 'dialog'
PUNCHY_DIR = OUT_BASE / 'l1_punchy'

# === API call ===
def synth(text, voice_id, out_path, speed=0.9):
    if not FORCE and Path(out_path).exists() and Path(out_path).stat().st_size > 1000:
        return 'skip'
    if DRY:
        return 'dry'
    data = {
        'model': MODEL,
        'text': text,
        'voice_setting': {'voice_id': voice_id, 'speed': speed, 'vol': 1, 'pitch': 0},
        'audio_setting': {'sample_rate': 32000, 'bitrate': 128000, 'format': 'mp3', 'channel': 1},
    }
    try:
        r = requests.post(URL, headers={'Authorization': f'Bearer {API_KEY}'}, json=data, timeout=30)
        result = r.json()
        if result.get('base_resp', {}).get('status_code') == 0:
            audio = bytes.fromhex(result['data']['audio'])
            Path(out_path).parent.mkdir(parents=True, exist_ok=True)
            with open(out_path, 'wb') as f:
                f.write(audio)
            return 'ok'
        else:
            err = result.get('base_resp', {}).get('status_msg', 'unknown')
            print(f'  [err] {Path(out_path).name}: {err}')
            return 'err'
    except Exception as e:
        print(f'  [err] {Path(out_path).name}: {e}')
        return 'err'

CJK = re.compile(r'[一-鿿]')
PAREN_ASCII = re.compile(r'\([^)]*\)')
PAREN_FW = re.compile(r'（[^）]*）')  # full-width 괄호 ()

# === 1. 한자 387자 ===
def hanzi_chars():
    with open('C:/dev/talkverse_learning/assets/zh_data/core_hanzi_209.json', encoding='utf-8') as f:
        d = json.load(f)
    return [c['char'] for c in d['characters']]

# === 2. 성조 매트릭스 단어 ===
def tone_words():
    with open('C:/dev/talkverse_learning/assets/zh_data/tone_matrix_160.json', encoding='utf-8') as f:
        d = json.load(f)
    words = []
    for cell in d['matrix_4x4'].values():
        for w in cell['words']:
            words.append(w['word'])
    return list(dict.fromkeys(words))

# === 3. 다이얼로그 행 + speaker 추출 ===
EPS = ['ep1_matching', 'ep2_meal', 'ep3_family', 'ep4_conflict', 'ep5_future', 'ep6_routine']
ROW_RE = re.compile(r'^\|\s*(\d+)\s*\|\s*([^|]+?)\s*\|', re.MULTILINE)

def detect_voice(text):
    """stage direction (Mark)·(Lily)·(엄마)·(할머니) 등에서 voice 결정."""
    # ASCII 괄호 + full-width 괄호 (공식 중국 문장부호)
    for pat in [r'\(([^)]+)\)', r'（([^）]+)）']:
        for m in re.finditer(pat, text):
            speaker = m.group(1).strip().lower()
            for k, v in SPEAKER_VOICE.items():
                if k in speaker:
                    return v
    return None

def dialog_lines():
    """List of (ep_num, line_num, voice_id, text)."""
    out = []
    last_voice = V_LILY  # ep 시작 default = Lily 측 응답이 多
    for ep in EPS:
        ep_num = int(re.search(r'ep(\d+)', ep).group(1))
        path = f'{ZH_DIR}/Dialog/{ep}.md'
        try:
            with open(path, encoding='utf-8') as f:
                text = f.read()
        except FileNotFoundError:
            print(f'  [SKIP] file not found: {path}')
            continue
        n_matched = 0
        for m in ROW_RE.finditer(text):
            num = int(m.group(1))
            zh = m.group(2)
            zh_clean = re.sub(r'\*+', '', zh).strip()
            # speaker 추출
            v = detect_voice(zh_clean)
            if v:
                last_voice = v
            else:
                # stage direction 없으면 직전 화자와 alternate
                # ep1 첫 화자는 Mark (매칭 첫 메시지)
                if num == 1 and ep_num == 1:
                    last_voice = V_MARK
                else:
                    last_voice = V_MARK if last_voice == V_LILY else V_LILY
            # parens 제거 후 TTS (ASCII + 풀폭)
            text_for_tts = PAREN_ASCII.sub('', zh_clean)
            text_for_tts = PAREN_FW.sub('', text_for_tts)
            text_for_tts = re.sub(r'^[⚠️\s]+', '', text_for_tts).strip()
            if not CJK.search(text_for_tts):
                continue
            out.append((ep_num, num, last_voice, text_for_tts))
            n_matched += 1
        print(f'  [parse] {ep}: {n_matched} rows')
    return out

# === 4. L1 통통 문장 100 ===
def l1_punchy():
    """l1_10day.json에서 100문장 추출."""
    path = 'C:/dev/talkverse_learning/assets/zh_data/l1_10day.json'
    if not Path(path).exists():
        return []
    with open(path, encoding='utf-8') as f:
        d = json.load(f)
    out = []
    for day in d.get('days', []):
        day_num = day['day']
        for i, s in enumerate(day.get('sentences', []), 1):
            zh = s.get('zh', '')
            if zh and CJK.search(zh):
                out.append((day_num, i, zh))
    return out

# === Main ===
def main():
    chars = hanzi_chars()
    words = tone_words()
    dialogs = dialog_lines()
    punchy = l1_punchy()

    print(f'[load] hanzi {len(chars)} / words {len(words)} / dialogs {len(dialogs)} / punchy {len(punchy)}')
    total = len(chars) + len(words) + len(dialogs) + len(punchy)
    print(f'[total] {total} mp3 to generate')
    if DRY:
        print('[DRY RUN] 실제 생성 안 함. 종료.')
        return

    # 비용 추정
    char_total = sum(len(c) for c in chars) + sum(len(w) for w in words) + \
                 sum(len(t[3]) for t in dialogs) + sum(len(p[2]) for p in punchy)
    cost = char_total / 1_000_000 * 100  # speech-2.8-hd HD = $100/M
    print(f'[cost] 약 {char_total:,} chars × $100/M = ${cost:.3f}')
    print()

    counter = {'ok': 0, 'skip': 0, 'err': 0}

    # 1. 한자
    print('=== 한자 387 ===')
    for ch in chars:
        out = HANZI_DIR / f'{ch}.mp3'
        result = synth(ch, V_LEARN, out)
        counter[result] = counter.get(result, 0) + 1
        if result == 'ok':
            time.sleep(0.05)  # rate limit 회피

    # 2. 단어
    print('\n=== 성조 매트릭스 160단어 ===')
    for w in words:
        out = TONE_DIR / f'{w}.mp3'
        result = synth(w, V_LEARN, out)
        counter[result] = counter.get(result, 0) + 1
        if result == 'ok':
            time.sleep(0.05)

    # 3. 다이얼로그
    print('\n=== 다이얼로그 240문장 (캐릭터별 voice) ===')
    voice_count = {}
    for ep, num, voice, text in dialogs:
        out = DIALOG_DIR / f'ep{ep}_{num:03d}.mp3'
        result = synth(text, voice, out)
        counter[result] = counter.get(result, 0) + 1
        voice_count[voice] = voice_count.get(voice, 0) + 1
        if result == 'ok':
            time.sleep(0.05)
    print('Voice 분포:')
    for v, n in sorted(voice_count.items(), key=lambda x: -x[1]):
        print(f'  {v}: {n}')

    # 4. 통통 100
    print('\n=== L1 통통 100문장 ===')
    for day_num, i, zh in punchy:
        out = PUNCHY_DIR / f'd{day_num}_{i}.mp3'
        result = synth(zh, V_LEARN, out)
        counter[result] = counter.get(result, 0) + 1
        if result == 'ok':
            time.sleep(0.05)

    # 5. manifest.json 갱신
    manifest = {
        'version': 'v2-minimax',
        'voice_default': V_LEARN,
        'note': 'MiniMax speech-2.8-hd, 캐릭터별 voice 분배',
        'voices': {
            'learn': V_LEARN, 'mark': V_MARK, 'lily': V_LILY,
            'xiaohong': V_XIAOHONG, 'mom': V_MOM, 'dad': V_DAD,
            'grandma': V_GRANDMA, 'grandpa': V_GRANDPA, 'wangge': V_WANGGE,
        },
        'stats': {
            'hanzi': len(chars),
            'tone_matrix': len(words),
            'dialog': len(dialogs),
            'l1_punchy': len(punchy),
            'total': total,
        },
        'files': {},  # 기존 manifest 유지 안 함, audioplayers는 직접 path 매칭
    }
    with open(OUT_BASE / 'manifest.json', 'w', encoding='utf-8') as f:
        json.dump(manifest, f, ensure_ascii=False, indent=2)

    print()
    print(f'=== 결과: {counter} ===')
    print(f'생성: {counter.get("ok",0)} / 기존 skip: {counter.get("skip",0)} / 에러: {counter.get("err",0)}')

if __name__ == '__main__':
    main()
