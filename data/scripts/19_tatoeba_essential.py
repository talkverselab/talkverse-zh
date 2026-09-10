"""
Build essential short sentences from 공개 예문 말뭉치 with importance score.

Inputs (공개 예문 말뭉치 extracted):
  D:/OneDrive/PROJECT/talkverse-learning/DATA_Curated/multi/공개 예문 말뭉치/
    sentences.csv         (id, lang, text)
    links.csv             (sentence_id, translation_id)

Strategy:
  1. Filter short sentences per language: ≤5 chars (zh/ja) or ≤5 words (en/ko)
  2. Count translation degree (how many other sentences this sentence is linked to)
     = importance proxy (more translations = more universal/important)
  3. For each (cmn ↔ eng ↔ kor ↔ jpn) pair, find sentences that have all 4 translations
  4. Score = translation_degree (raw, sortable)

Outputs (in DATA_Curated/multi/공개 예문 말뭉치/processed/):
  short_cmn.tsv             (id, text, length, translation_degree)
  short_eng.tsv
  short_kor.tsv
  short_jpn.tsv
  pivot_cmn_to_others.tsv   (cmn_id, cmn_text, eng_text, kor_text, jpn_text, importance)
  short_global_top.tsv      (top 1000 by importance, all 4 langs aligned)
"""
import os, csv, time
from collections import defaultdict, Counter

ROOT = r"D:/OneDrive/PROJECT/talkverse-learning/DATA_Curated/multi/공개 예문 말뭉치"
OUT = os.path.join(ROOT, "processed")
os.makedirs(OUT, exist_ok=True)

SENTENCES = os.path.join(ROOT, "sentences.csv")
LINKS     = os.path.join(ROOT, "links.csv")

# 22 talkverse target languages (ISO 639-3)
LANGS = {
    "cmn",  # 중국어 (만다린)
    "vie",  # 베트남어
    "kor",  # 한국어
    "jpn",  # 일본어
    "eng",  # 영어
    "tha",  # 태국어
    "ind",  # 인도네시아어
    "spa",  # 스페인어
    "fra",  # 프랑스어
    "deu",  # 독일어
    "ita",  # 이탈리아어
    "por",  # 포르투갈어
    "rus",  # 러시아어
    "ara",  # 아랍어
    "tur",  # 터키어
    "pes",  # 페르시아어
    "hin",  # 힌디어
    "mon",  # 몽골어
    "mya",  # 미얀마어
    "uzb",  # 우즈벡어
    "amh",  # 암하라어
    "hun",  # 헝가리어
}
# Asian-script langs (use char-length, not word-count)
ASIAN_LANGS = {"cmn","jpn","kor","tha","mya"}

print(f"[load] {SENTENCES}", flush=True)
t0 = time.time()
# sentences.csv format: id<TAB>lang<TAB>text
sent_text = {}
sent_lang = {}
n = 0
with open(SENTENCES, "r", encoding="utf-8") as f:
    for line in f:
        parts = line.rstrip("\n").split("\t")
        if len(parts) < 3: continue
        sid = int(parts[0]); lang = parts[1]; text = parts[2]
        if lang in LANGS:
            sent_text[sid] = text
            sent_lang[sid] = lang
        n += 1
        if n % 1_000_000 == 0:
            print(f"  ... read {n:,} lines, kept {len(sent_text):,}", flush=True)
print(f"[load] sentences.csv: {n:,} total, {len(sent_text):,} in 4 langs", flush=True)

# count by lang
lang_counts = Counter(sent_lang.values())
for k, v in lang_counts.items(): print(f"  {k}: {v:,}")

# Filter short
def is_short(lang, text):
    if lang in ASIAN_LANGS:
        return len([c for c in text if c.strip()]) <= 6  # 6자 이하 (Asian script)
    else:
        return len(text.split()) <= 5                      # 5단어 이하 (Western/space-separated)

short_ids = {sid for sid, lang in sent_lang.items() if is_short(lang, sent_text[sid])}
print(f"[filter] short sentences (≤5-6 by lang): {len(short_ids):,}", flush=True)

# Load links: sentence_id<TAB>translation_id (bidirectional, dedupe)
print(f"[load] {LINKS}", flush=True)
links = defaultdict(set)  # sid -> set of translation sids
n = 0
with open(LINKS, "r", encoding="utf-8") as f:
    for line in f:
        parts = line.rstrip("\n").split("\t")
        if len(parts) < 2: continue
        try:
            a = int(parts[0]); b = int(parts[1])
        except ValueError:
            continue
        # only keep links where both endpoints are in our 4 langs
        if a in sent_lang and b in sent_lang:
            links[a].add(b)
        n += 1
        if n % 5_000_000 == 0:
            print(f"  ... read {n:,} links", flush=True)
print(f"[load] links.csv: {n:,} total, {len(links):,} sentences with at least one link", flush=True)

# Per-lang short sentence with translation degree (across all langs incl. non-4)
def degree_all(sid):
    # also count links that go OUT of our 4 langs (proxy for global importance)
    return len(links.get(sid, set()))

# But we re-walk all sentences to get full degree (any lang)
print(f"[link counts] computing total degree (any lang)", flush=True)
all_degree = defaultdict(int)
n = 0
with open(LINKS, "r", encoding="utf-8") as f:
    for line in f:
        parts = line.rstrip("\n").split("\t")
        if len(parts) < 2: continue
        try:
            a = int(parts[0]); b = int(parts[1])
        except ValueError: continue
        all_degree[a] += 1
        n += 1
print(f"[link counts] processed {n:,} link rows, {len(all_degree):,} sentences with links", flush=True)

# Save per-lang short sentences
for lang in LANGS:
    out_path = os.path.join(OUT, f"short_{lang}.tsv")
    rows = []
    for sid, l in sent_lang.items():
        if l != lang: continue
        if sid not in short_ids: continue
        text = sent_text[sid]
        deg = all_degree.get(sid, 0)
        if deg < 1: continue
        length = len(text.replace(" ", "")) if lang in ("cmn","jpn") else len(text.split())
        rows.append((deg, sid, text, length))
    rows.sort(key=lambda r: -r[0])
    with open(out_path, "w", encoding="utf-8", newline="") as f:
        w = csv.writer(f, delimiter="\t", lineterminator="\n")
        w.writerow(["importance(deg)","sid","text","length"])
        for deg, sid, text, length in rows:
            w.writerow([deg, sid, text, length])
    print(f"[done] {out_path}: {len(rows):,} short sentences", flush=True)

# Build pivot: for each PIVOT lang short sentence, find aligned translations in all other langs
PIVOTS = ["vie", "cmn"]  # 사용자 우선: 베트남어 먼저, 중국어 두번째
OTHER_LANGS = sorted(LANGS - set(PIVOTS))   # 다른 20개

for pivot_lang in PIVOTS:
    print(f"\n[pivot:{pivot_lang}] building alignment to other 20 langs", flush=True)
    pivot_rows = []
    pivot_short = [sid for sid in short_ids if sent_lang[sid] == pivot_lang]
    print(f"  {pivot_lang} short: {len(pivot_short):,}", flush=True)

    # === PASS 1: collect raw counts per src ===
    raw_rows = []
    for sid in pivot_short:
        text = sent_text[sid]
        per_lang_t = {l: [] for l in OTHER_LANGS}
        for tid in links.get(sid, set()):
            l = sent_lang.get(tid); t = sent_text.get(tid)
            if l in per_lang_t:
                per_lang_t[l].append(t)
        raw_rows.append({"sid": sid, "text": text, "per_lang_t": per_lang_t})

    # === PASS 2: build per-lang percentile lookup (v3 relative scoring) ===
    # For each lang, collect all NON-ZERO scores across this pivot's src set.
    # Then percentile_<lang>(score) = rank-position in the sorted score list.
    print(f"  building per-lang percentile distributions ...", flush=True)
    lang_score_sorted = {}  # lang -> sorted list of (score, count)
    for l in OTHER_LANGS:
        scores = sorted([len(r["per_lang_t"][l]) for r in raw_rows if r["per_lang_t"][l]])
        lang_score_sorted[l] = scores  # ascending

    def percentile(lang, score):
        if score == 0: return 0
        arr = lang_score_sorted[lang]
        if not arr: return 0
        # number of values < score → low rank → high percentile uses ≤
        # use rank = (#values <= score) / total × 100
        # binary search insert position for score+1 to get count <=
        lo, hi = 0, len(arr)
        while lo < hi:
            mid = (lo + hi) // 2
            if arr[mid] <= score: lo = mid + 1
            else: hi = mid
        # lo = # of arr elements <= score
        return round(lo / len(arr) * 100)

    # === PASS 3: assign per-lang percentile + global aggregate ===
    # 두 차원 점수 부여:
    #   1) pct_<lang>  — 그 언어 안에서 percentile rank (학습자별 정렬용)
    #   2) global_pct  — sum(pct_<lang>)/20 — 모든 언어에서 percentile 평균
    #                    (= 모든 언어에서 핵심이면 100, 좁으면 자동 페널티)
    # raw_<lang>은 참고용 절대 카운트.
    # 정렬은 global_pct desc 기본. 학습자별 정렬은 사용자가 ORDER BY pct_<native> DESC 로 직접.
    n_other = len(OTHER_LANGS)  # 20
    for r in raw_rows:
        per_lang_t = r["per_lang_t"]
        per_lang_score = {l: len(per_lang_t[l]) for l in OTHER_LANGS}
        per_lang_pct   = {l: percentile(l, per_lang_score[l]) for l in OTHER_LANGS}
        global_pct = round(sum(per_lang_pct.values()) / n_other, 1)
        n_covered = sum(1 for s in per_lang_score.values() if s >= 1)
        row = {
            "src_id": r["sid"],
            "src": r["text"],
            "global_pct": global_pct,                  # ⭐ percentile 평균 (정렬 기본)
            "n_langs_covered": n_covered,
        }
        for l in OTHER_LANGS:
            row[f"pct_{l}"] = per_lang_pct[l]          # ⭐ 언어별 percentile (학습자별)
            row[f"raw_{l}"] = per_lang_score[l]        # 참고용 절대 카운트
            row[l] = " | ".join(per_lang_t[l][:3]) if per_lang_t[l] else ""
        pivot_rows.append(row)

    # 정렬: global_pct desc 기본 + 보조로 n_langs_covered
    pivot_rows.sort(key=lambda r: (-r["global_pct"], -r["n_langs_covered"]))

    fields = ["src_id","src","global_pct","n_langs_covered"] + \
             [f"pct_{l}" for l in OTHER_LANGS] + \
             [f"raw_{l}" for l in OTHER_LANGS] + OTHER_LANGS
    OUT_PIVOT = os.path.join(OUT, f"pivot_{pivot_lang}_to_others.tsv")
    with open(OUT_PIVOT, "w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fields, delimiter="\t", lineterminator="\n")
        w.writeheader()
        for r in pivot_rows:
            w.writerow(r)
    print(f"[done] {OUT_PIVOT}: {len(pivot_rows):,} rows", flush=True)

    # Stats v3 (final)
    print(f"=== {pivot_lang} pivot stats (v3 final: pct_<lang> + global_pct) ===")
    print(f"  --- global_pct distribution ---")
    for thr in [90, 80, 70, 50, 30, 10]:
        c = sum(1 for r in pivot_rows if r["global_pct"] >= thr)
        print(f"  global_pct ≥ {thr:>2}: {c:,}")
    print(f"  --- n_langs_covered distribution ---")
    for n in [20, 15, 10, 5, 3, 1]:
        c = sum(1 for r in pivot_rows if r["n_langs_covered"] >= n)
        print(f"  ≥{n:>2} langs covered: {c:,}")

    # Top 1000 by importance
    top_global = pivot_rows[:1000]
    OUT_TOP = os.path.join(OUT, f"short_global_top1000_{pivot_lang}.tsv")
    with open(OUT_TOP, "w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fields, delimiter="\t", lineterminator="\n")
        w.writeheader()
        for r in top_global:
            w.writerow(r)
    print(f"[done] {OUT_TOP}: top 1000 most-aligned short sentences", flush=True)

print()
print(f"[done] elapsed={time.time()-t0:.1f}s")
