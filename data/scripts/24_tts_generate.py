"""
Pre-generate ZH TTS mp3 files using Edge TTS (Azure Neural, free).

Inputs:
  - core_hanzi_209.json  → 209 single-char mp3
  - tone_matrix_160.json → 160 word mp3
  - ZH/Dialog/ep1-5.md   → 200 sentence mp3 (parsed)

Output dir:
  C:/dev/talkverse_learning/assets/zh_data/audio/{hanzi,tone_matrix,dialog}/
  + manifest.json (path mapping for Flutter loader)

Voices:
  - Hanzi (single char): zh-CN-XiaoxiaoNeural (여성 표준 학습)
  - Tone matrix words:    zh-CN-XiaoxiaoNeural
  - Dialog (모두):        zh-CN-XiaoxiaoNeural (출시 전 캐릭터 분리 — TTS_OUTRO_NOTE.md 참조)

🔁 출시 전 교체 권장: MiniMax 海螺 Speech-02 (네이티브 1티어, 감정 표현 1위)
"""
import asyncio, json, re, os
from pathlib import Path
import edge_tts

# === Config ===
HANZI_JSON = "D:/OneDrive/PROJECT/talkverse-learning/ZH/Word/core_hanzi_209.json"
TONE_JSON  = "D:/OneDrive/PROJECT/talkverse-learning/ZH/Word/tone_matrix_160.json"
DIALOG_DIR = "D:/OneDrive/PROJECT/talkverse-learning/ZH/Dialog"
EPS = ["ep1_matching", "ep2_meal", "ep3_family", "ep4_conflict", "ep5_future"]

OUT_BASE = Path("C:/dev/talkverse_learning/assets/zh_data/audio")
HANZI_DIR  = OUT_BASE / "hanzi"
TONE_DIR   = OUT_BASE / "tone_matrix"
DIALOG_OUT = OUT_BASE / "dialog"

VOICE_DEFAULT = "zh-CN-XiaoxiaoNeural"  # 여성, 표준 학습 톤
RATE = "-10%"   # 학습용 약간 느리게
VOLUME = "+0%"

CONCURRENCY = 8  # 동시 다운로드 (rate limit 회피)

# === Helpers ===
async def synth(text: str, out_path: Path, voice=VOICE_DEFAULT, rate=RATE):
    """Generate mp3 for given text. Skip if file exists & non-empty."""
    if out_path.exists() and out_path.stat().st_size > 1000:
        return "skip"
    out_path.parent.mkdir(parents=True, exist_ok=True)
    try:
        communicate = edge_tts.Communicate(text, voice, rate=rate, volume=VOLUME)
        await communicate.save(str(out_path))
        return "ok"
    except Exception as e:
        print(f"  [err] {out_path.name}: {e}")
        return "err"

async def bounded(sem, coro):
    async with sem:
        return await coro

def safe_filename(text: str, max_len=40) -> str:
    """Filesystem-safe filename — strip punctuation, keep CJK & ascii alnum."""
    keep = re.sub(r"[^一-鿿\w-]", "", text)
    return keep[:max_len] or "_"

# === 1) Hanzi 209 ===
def load_hanzi():
    with open(HANZI_JSON, encoding="utf-8") as f:
        data = json.load(f)
    return [c["char"] for c in data["characters"]]

# === 2) Tone matrix 160 ===
def load_tone_words():
    with open(TONE_JSON, encoding="utf-8") as f:
        data = json.load(f)
    words = []
    for cell in data["matrix_4x4"].values():
        for w in cell["words"]:
            words.append(w["word"])
    return list(dict.fromkeys(words))  # dedup, preserve order

# === 3) Dialog sentences ===
ROW_RE = re.compile(r"^\|\s*(\d+)\s*\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|", re.MULTILINE)
CJK = re.compile(r"[一-鿿]")

def load_dialog_sentences():
    """List of (ep, num, zh_clean) — only rows with actual hanzi."""
    out = []
    for ep in EPS:
        path = Path(DIALOG_DIR) / f"{ep}.md"
        text = path.read_text(encoding="utf-8")
        for m in ROW_RE.finditer(text):
            num = int(m.group(1))
            zh = m.group(2)
            zh_clean = re.sub(r"\*+", "", zh).strip()
            # strip stage directions in parens
            zh_for_tts = re.sub(r"\([^)]*\)", "", zh_clean).strip()
            zh_for_tts = re.sub(r"（[^）]*）", "", zh_for_tts).strip()
            zh_for_tts = re.sub(r"^[⚠️\s]+", "", zh_for_tts)
            # only synth if contains CJK
            if CJK.search(zh_for_tts):
                out.append((ep, num, zh_for_tts))
    return out

# === Main ===
async def main():
    print("[load] sources...")
    hanzi = load_hanzi()
    words = load_tone_words()
    dialogs = load_dialog_sentences()
    print(f"  hanzi: {len(hanzi)}")
    print(f"  tone words: {len(words)}")
    print(f"  dialog sentences: {len(dialogs)}")

    sem = asyncio.Semaphore(CONCURRENCY)
    tasks = []
    manifest = {"hanzi": {}, "tone_matrix": {}, "dialog": {}}

    # 1) Hanzi
    for ch in hanzi:
        out = HANZI_DIR / f"{ch}.mp3"
        manifest["hanzi"][ch] = f"assets/zh_data/audio/hanzi/{ch}.mp3"
        tasks.append(bounded(sem, synth(ch, out)))

    # 2) Tone words
    for w in words:
        out = TONE_DIR / f"{w}.mp3"
        manifest["tone_matrix"][w] = f"assets/zh_data/audio/tone_matrix/{w}.mp3"
        tasks.append(bounded(sem, synth(w, out)))

    # 3) Dialog — ep_num as filename
    for ep, num, zh in dialogs:
        ep_short = ep.split("_")[0]  # ep1, ep2, ...
        fname = f"{ep_short}_{num:03d}.mp3"
        out = DIALOG_OUT / fname
        manifest["dialog"][f"{ep_short}_{num}"] = {
            "path": f"assets/zh_data/audio/dialog/{fname}",
            "text": zh,
        }
        tasks.append(bounded(sem, synth(zh, out)))

    print(f"\n[synth] total tasks: {len(tasks)}")
    print(f"[synth] running with concurrency={CONCURRENCY}...")
    results = await asyncio.gather(*tasks, return_exceptions=False)

    n_ok = sum(1 for r in results if r == "ok")
    n_skip = sum(1 for r in results if r == "skip")
    n_err = sum(1 for r in results if r == "err")
    print(f"\n=== 결과 ===")
    print(f"  생성: {n_ok}")
    print(f"  skip (이미 존재): {n_skip}")
    print(f"  에러: {n_err}")

    # Save manifest
    manifest_path = OUT_BASE / "manifest.json"
    with open(manifest_path, "w", encoding="utf-8") as f:
        json.dump({
            "version": "v1-edge-tts",
            "voice": VOICE_DEFAULT,
            "rate": RATE,
            "note": "Edge TTS (Azure Neural). 출시 전 MiniMax 海螺 Speech-02로 교체 권장.",
            "stats": {
                "hanzi": len(manifest["hanzi"]),
                "tone_matrix": len(manifest["tone_matrix"]),
                "dialog": len(manifest["dialog"]),
            },
            "files": manifest,
        }, f, ensure_ascii=False, indent=2)
    print(f"\n[manifest] {manifest_path}")

if __name__ == "__main__":
    asyncio.run(main())
