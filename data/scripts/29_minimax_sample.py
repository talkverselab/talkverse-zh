"""
MiniMax voice sample 생성 — 13개 후보.

사용:
  $env:MINIMAX_API_KEY = "sk-api-..."
  python scripts/29_minimax_sample.py

출력: D:/temp_minimax_samples/*.mp3 (13개)
"""
import requests, os, sys

API_KEY = os.environ.get('MINIMAX_API_KEY', '')
# PowerShell 줄바꿈·공백 제거 (continuation prompt 입력 시 newline 섞임 방지)
API_KEY = API_KEY.replace('\n', '').replace('\r', '').replace(' ', '').replace('\t', '').strip()
if not API_KEY:
    print('ERROR: MINIMAX_API_KEY 환경변수 set 필요')
    print('PowerShell: $env:MINIMAX_API_KEY = "sk-api-..."')
    sys.exit(1)
print(f'[key] length={len(API_KEY)} (sanitized)')

URL = 'https://api.minimax.io/v1/t2a_v2'
TEXT = '你好啊! 我叫小丽。今天天气真好。'  # 학습 sample (어조사 + 인사 + 인명)

# 13 voice 후보 (캐릭터 매핑)
CANDIDATES = {
    '학습_표준_Lyrical':       'Chinese (Mandarin)_Lyrical_Voice',
    '학습_표준_Intellectual':  'Chinese (Mandarin)_IntellectualGirl',
    'Mark_Pure':              'Chinese (Mandarin)_Pure-hearted_Boy',
    'Mark_Straight':          'Chinese (Mandarin)_Straightforward_Boy',
    'Lily_Soft':              'Chinese (Mandarin)_Soft_Girl',
    'Lily_WarmHeart':         'Chinese (Mandarin)_Warm_HeartedGirl',
    '小红_Cute':              'Chinese (Mandarin)_Cute_Spirit',
    '小红_Crisp':             'Chinese (Mandarin)_Crisp_Girl',
    '엄마_Aunt':              'Chinese (Mandarin)_Warm-HeartedAunt',
    '아빠_Sincere':           'Chinese (Mandarin)_Sincere_Adult',
    '할머니_Elder':            'Chinese (Mandarin)_Kind-hearted_Elder',
    '할아버지_Gentle':         'Chinese (Mandarin)_Gentle_Senior',
    '방송_Announcer':          'Chinese (Mandarin)_Male_Announcer',
}

OUT = 'D:/temp_minimax_samples'
os.makedirs(OUT, exist_ok=True)

print(f'Sample text: {TEXT}')
print(f'후보 voice {len(CANDIDATES)}개 생성:\n')

success = 0
fail = 0
for name, voice_id in CANDIDATES.items():
    data = {
        'model': 'speech-2.8-hd',
        'text': TEXT,
        'voice_setting': {
            'voice_id': voice_id,
            'speed': 0.9,
            'vol': 1,
            'pitch': 0,
        },
        'audio_setting': {
            'sample_rate': 32000,
            'bitrate': 128000,
            'format': 'mp3',
            'channel': 1,
        },
    }
    try:
        r = requests.post(URL, headers={'Authorization': f'Bearer {API_KEY}'},
                          json=data, timeout=30)
        result = r.json()
        if result.get('base_resp', {}).get('status_code') == 0:
            audio_hex = result['data']['audio']
            audio_bytes = bytes.fromhex(audio_hex)
            out_path = f'{OUT}/{name}.mp3'
            with open(out_path, 'wb') as f:
                f.write(audio_bytes)
            print(f'  ✅ {name:<25} → {out_path} ({len(audio_bytes)/1024:.1f}KB)')
            success += 1
        else:
            err = result.get('base_resp', {}).get('status_msg', 'unknown')
            print(f'  ❌ {name:<25} — {err}')
            fail += 1
    except Exception as e:
        print(f'  ❌ {name:<25} — exception: {e}')
        fail += 1

print(f'\n=== 결과: 성공 {success} / 실패 {fail} ===')
print(f'폴더: {OUT}')
print('Windows 탐색기에서 들어보고 마음에 드는 voice 알려주세요.')
