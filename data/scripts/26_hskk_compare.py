"""
26_hskk_compare.py
==================
Compare talkverse ZH learning content (209 hanzi + 200-sentence dialog)
against HSKK (Hanyu Shuiping Kouyu Kaoshi · 汉语水平口语考试) vocabulary tiers.

HSKK is the speaking-test counterpart of HSK and does NOT publish its own
vocabulary syllabus. The Hanban / 汉考国际 official guidelines map HSKK
levels to the HSK written-test vocabulary as follows:

    HSKK 初级 (Elementary, ~200 most-common words)  ≈ HSK 1 ∪ HSK 2
    HSKK 中级 (Intermediate, ~900 words)            ≈ HSK 3 ∪ HSK 4
    HSKK 高级 (Advanced,    ~3000 words)            ≈ HSK 5 ∪ HSK 6

We therefore use the official 新HSK 3.0 (2021《国际中文教育中文水平等级标准》)
word & character lists as a proxy for HSKK tiers.

Inputs
------
  - C:/dev/talkverse_learning/assets/zh_data/core_hanzi_209.json
  - D:/OneDrive/PROJECT/talkverse-learning/ZH/Dialog/ep*_*.md
  - D:/OneDrive/DATA_Processed/zh_opus/wordlists/HSK_zispace_2021.txt
  - D:/OneDrive/DATA_Processed/zh_opus/wordlists/HSK_hanzi_{1..6,7-9}.txt

Outputs
-------
  - D:/OneDrive/DATA_Processed/zh_opus/output/hskk_compare_summary.tsv
  - D:/OneDrive/DATA_Processed/zh_opus/output/hskk_209hanzi_distribution.tsv
  - D:/OneDrive/DATA_Processed/zh_opus/output/hskk_dialog_word_distribution.tsv
  - D:/OneDrive/DATA_Processed/zh_opus/output/hskk_elementary_uncovered.tsv
  - D:/OneDrive/DATA_Processed/zh_opus/output/hskk_intermediate_uncovered.tsv
  - D:/OneDrive/DATA_Processed/zh_opus/output/hskk_advanced_uncovered.tsv
  - D:/OneDrive/DATA_Processed/zh_opus/output/hskk_dialog_words_outside_hskk.tsv
  - D:/OneDrive/DATA_Processed/zh_opus/output/hskk_dialog_hanzi_outside_209.tsv
  - D:/OneDrive/DATA_Processed/zh_opus/output/hskk_summary.json
"""
import json
import os
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

import jieba

# ---- paths ----
TALKVERSE_HANZI = Path(r"C:/dev/talkverse_learning/assets/zh_data/core_hanzi_209.json")
DIALOG_DIR      = Path(r"D:/OneDrive/PROJECT/talkverse-learning/ZH/Dialog")
WL_DIR          = Path(r"D:/OneDrive/DATA_Processed/zh_opus/wordlists")
OUT_DIR         = Path(r"D:/OneDrive/DATA_Processed/zh_opus/output")
OUT_DIR.mkdir(parents=True, exist_ok=True)

HSK_WORDS_FILE  = WL_DIR / "HSK_zispace_2021.txt"
HSK_HANZI_FILES = {
    "HSK1":   WL_DIR / "HSK_hanzi_1.txt",
    "HSK2":   WL_DIR / "HSK_hanzi_2.txt",
    "HSK3":   WL_DIR / "HSK_hanzi_3.txt",
    "HSK4":   WL_DIR / "HSK_hanzi_4.txt",
    "HSK5":   WL_DIR / "HSK_hanzi_5.txt",
    "HSK6":   WL_DIR / "HSK_hanzi_6.txt",
    "HSK7-9": WL_DIR / "HSK_hanzi_7-9.txt",
}

LEVEL_ORDER = ["HSK1", "HSK2", "HSK3", "HSK4", "HSK5", "HSK6", "HSK7-9"]
HSKK_TIERS  = {
    "HSKK_elementary":  {"HSK1", "HSK2"},
    "HSKK_intermediate":{"HSK3", "HSK4"},
    "HSKK_advanced":    {"HSK5", "HSK6"},
}
HSKK_LABEL = {
    "HSKK_elementary":  "HSKK 初级",
    "HSKK_intermediate":"HSKK 中级",
    "HSKK_advanced":    "HSKK 高级",
}

# ----------------------------------------------------------------------
# 1) Load HSK 3.0 word & hanzi lists
# ----------------------------------------------------------------------

def load_hsk_words(path: Path):
    """word -> level. Word fields may contain '∣' separated alt forms."""
    word2level = {}
    level2words = defaultdict(set)
    LMAP = {"一级":"HSK1","二级":"HSK2","三级":"HSK3","四级":"HSK4",
            "五级":"HSK5","六级":"HSK6","高等":"HSK7-9"}
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.rstrip("\n")
            if not line or line.startswith("#"):
                continue
            parts = line.split("\t")
            if len(parts) < 5:
                continue
            word_field, _pos, _pinyin, _ord, level = parts[:5]
            lbl = LMAP.get(level, level)
            for w in word_field.split("∣"):
                w = w.strip()
                if not w:
                    continue
                word2level.setdefault(w, lbl)
                level2words[lbl].add(w)
    return word2level, level2words

def load_hsk_hanzi():
    char2level = {}
    level2chars = defaultdict(set)
    for lvl, p in HSK_HANZI_FILES.items():
        with open(p, encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                # files look like "1\t爱"; take last field
                parts = line.split("\t")
                ch = parts[-1].strip()
                if len(ch) == 1:
                    char2level.setdefault(ch, lvl)
                    level2chars[lvl].add(ch)
    return char2level, level2chars

# ----------------------------------------------------------------------
# 2) Load talkverse content
# ----------------------------------------------------------------------

def load_209_hanzi():
    data = json.load(open(TALKVERSE_HANZI, encoding="utf-8"))
    chars = []
    char2hsk = {}  # talkverse-internal hsk_char_level
    for c in data["characters"]:
        ch = c["char"]
        chars.append(ch)
        char2hsk[ch] = c.get("hsk_char_level", "")
    return chars, char2hsk

# Markdown table cell: pull Chinese text from the 中文 column.
# Pattern: lines starting with "| <num> |" - the second cell is 中文.
ROW_RE = re.compile(r"^\|\s*\d+\s*\|(.*?)\|", re.MULTILINE)
# strip markdown emphasis markers, latin chars, punctuation but keep CJK
LATIN_RE = re.compile(r"[A-Za-z0-9_]+")
CJK_RE = re.compile(r"[一-鿿]")

def extract_dialog_sentences():
    """Return (list of (ep, sentence_idx, raw, clean)). clean = CJK-only run."""
    out = []
    md_files = sorted(DIALOG_DIR.glob("ep*_*.md"))
    for mf in md_files:
        ep = mf.stem  # ep1_matching
        text = mf.read_text(encoding="utf-8")
        # find all rows; iterate paragraphs
        idx = 0
        for m in ROW_RE.finditer(text):
            cell = m.group(1)
            # strip bold markers
            cell = cell.replace("**", "").replace("*", "")
            # strip latin words and digits (Mark, Lily, …)
            cell = LATIN_RE.sub(" ", cell)
            # collapse spaces
            cell = re.sub(r"\s+", " ", cell).strip()
            if not CJK_RE.search(cell):
                continue
            idx += 1
            out.append((ep, idx, cell))
    return out, md_files

def tokenize_jieba(sentences):
    """Return (token_counter, hanzi_counter)."""
    tok_cnt = Counter()
    han_cnt = Counter()
    # silence jieba init logs
    jieba.setLogLevel(60)
    for ep, i, s in sentences:
        for w in jieba.lcut(s):
            w = w.strip()
            # drop punctuation and pure non-CJK tokens
            if not w or not CJK_RE.search(w):
                continue
            # but keep tokens that are pure CJK chars (incl. punctuation chars excluded)
            tok_cnt[w] += 1
        for ch in s:
            if CJK_RE.match(ch):
                han_cnt[ch] += 1
    return tok_cnt, han_cnt

# ----------------------------------------------------------------------
# 3) Analysis
# ----------------------------------------------------------------------

def hskk_tier_for_word(word, word2level):
    lvl = word2level.get(word)
    if lvl is None:
        return None, None
    for tier, lvls in HSKK_TIERS.items():
        if lvl in lvls:
            return tier, lvl
    return None, lvl  # e.g. HSK7-9 = beyond HSKK 高级

def hskk_tier_for_char(ch, char2level):
    lvl = char2level.get(ch)
    if lvl is None:
        return None, None
    for tier, lvls in HSKK_TIERS.items():
        if lvl in lvls:
            return tier, lvl
    return None, lvl

# ----------------------------------------------------------------------
# Main
# ----------------------------------------------------------------------

def main():
    print("[1/5] Loading HSK 3.0 word and hanzi lists…")
    word2level, level2words = load_hsk_words(HSK_WORDS_FILE)
    char2level, level2chars = load_hsk_hanzi()
    print(f"      HSK words: {len(word2level):,}")
    for lvl in LEVEL_ORDER:
        print(f"        {lvl}: {len(level2words[lvl]):,} words / "
              f"{len(level2chars[lvl]):,} chars")
    # HSKK tier sizes (proxy)
    hskk_word_sets = {}
    hskk_char_sets = {}
    for tier, lvls in HSKK_TIERS.items():
        wset = set().union(*(level2words[l] for l in lvls))
        cset = set().union(*(level2chars[l] for l in lvls))
        hskk_word_sets[tier] = wset
        hskk_char_sets[tier] = cset
        print(f"      {HSKK_LABEL[tier]} proxy: {len(wset):,} words, {len(cset):,} chars")

    print("\n[2/5] Loading talkverse 209 hanzi…")
    chars209, char2hsk_self = load_209_hanzi()
    print(f"      {len(chars209)} chars (self-tagged distribution: "
          f"{Counter(char2hsk_self.values())})")

    print("\n[3/5] Loading 200-sentence dialog & tokenizing with jieba…")
    sentences, md_files = extract_dialog_sentences()
    print(f"      {len(md_files)} files, {len(sentences)} sentences")
    tok_cnt, han_cnt = tokenize_jieba(sentences)
    print(f"      tokens: {sum(tok_cnt.values()):,} (unique {len(tok_cnt):,}); "
          f"hanzi instances: {sum(han_cnt.values()):,} (unique {len(han_cnt):,})")

    # ------------------------------------------------------------------
    # Analysis 1: 209 hanzi -> HSK level distribution
    # ------------------------------------------------------------------
    print("\n[4/5] Analysis 1: 209 hanzi -> HSKK level distribution…")
    hanzi_dist = Counter()
    rows = []
    for ch in chars209:
        tier, lvl = hskk_tier_for_char(ch, char2level)
        bucket = lvl if lvl else "outside_HSK"
        hanzi_dist[bucket] += 1
        rows.append((ch, lvl or "", tier or ""))
    with open(OUT_DIR / "hskk_209hanzi_distribution.tsv", "w",
              encoding="utf-8", newline="") as f:
        f.write("char\thsk_level\thskk_tier\n")
        for ch, lvl, tier in rows:
            f.write(f"{ch}\t{lvl}\t{tier}\n")
    print(f"      209 hanzi by HSK level: {dict(hanzi_dist)}")

    # ------------------------------------------------------------------
    # Analysis 2: 200-sentence words -> HSKK distribution
    # ------------------------------------------------------------------
    print("\n[4/5] Analysis 2: dialog tokens -> HSKK word distribution…")
    word_dist = Counter()       # type-level
    word_token_dist = Counter() # token-level (frequency-weighted)
    dialog_word_rows = []
    for w, fq in tok_cnt.most_common():
        tier, lvl = hskk_tier_for_word(w, word2level)
        bucket = lvl if lvl else "outside_HSK"
        word_dist[bucket] += 1
        word_token_dist[bucket] += fq
        dialog_word_rows.append((w, fq, lvl or "", tier or ""))
    with open(OUT_DIR / "hskk_dialog_word_distribution.tsv", "w",
              encoding="utf-8", newline="") as f:
        f.write("word\tfreq\thsk_level\thskk_tier\n")
        for w, fq, lvl, tier in dialog_word_rows:
            f.write(f"{w}\t{fq}\t{lvl}\t{tier}\n")
    print(f"      dialog unique tokens by HSK level (types):  {dict(word_dist)}")
    print(f"      dialog unique tokens by HSK level (tokens): {dict(word_token_dist)}")

    # ------------------------------------------------------------------
    # Analysis 3,4: HSKK tier coverage (what fraction of each HSKK tier
    # is covered by talkverse content?). Coverage measured TWO ways:
    #   (a) word-level: dialog tokens hitting HSKK words
    #   (b) char-level: 209 hanzi hitting HSKK chars
    # ------------------------------------------------------------------
    print("\n[4/5] Analysis 3-4: HSKK tier coverage by talkverse…")
    dialog_words = set(tok_cnt.keys())
    coverage = {}
    for tier, lvls in HSKK_TIERS.items():
        wset = hskk_word_sets[tier]
        cset = hskk_char_sets[tier]
        word_hit = wset & dialog_words
        char_hit = cset & set(chars209)
        coverage[tier] = {
            "tier_label": HSKK_LABEL[tier],
            "hsk_levels_used": sorted(lvls),
            "tier_word_total": len(wset),
            "tier_char_total": len(cset),
            "covered_words": len(word_hit),
            "covered_chars": len(char_hit),
            "word_cov_pct": round(len(word_hit)/len(wset)*100, 2) if wset else 0,
            "char_cov_pct": round(len(char_hit)/len(cset)*100, 2) if cset else 0,
        }
        print(f"      {HSKK_LABEL[tier]:>14}: "
              f"words {len(word_hit):>4}/{len(wset):>4} "
              f"({coverage[tier]['word_cov_pct']:>5.2f}%)  "
              f"chars {len(char_hit):>4}/{len(cset):>4} "
              f"({coverage[tier]['char_cov_pct']:>5.2f}%)")

        # uncovered word lists (helps: which to add next)
        uncov = sorted(wset - dialog_words)
        out_name = {"HSKK_elementary":"hskk_elementary_uncovered.tsv",
                    "HSKK_intermediate":"hskk_intermediate_uncovered.tsv",
                    "HSKK_advanced":"hskk_advanced_uncovered.tsv"}[tier]
        with open(OUT_DIR / out_name, "w", encoding="utf-8", newline="") as f:
            f.write("hskk_tier\tword\thsk_level\n")
            for w in uncov:
                f.write(f"{HSKK_LABEL[tier]}\t{w}\t{word2level[w]}\n")

    # ------------------------------------------------------------------
    # Analysis 5: dialog words OUTSIDE HSKK (= outside HSK 1-6)
    # ("colloquial / movie-subtitle" words HSKK doesn't teach)
    # ------------------------------------------------------------------
    print("\n[4/5] Analysis 5: dialog words OUTSIDE HSKK (HSK 1-6)…")
    hsk16_words = set().union(*(level2words[l] for l in
                                ["HSK1","HSK2","HSK3","HSK4","HSK5","HSK6"]))
    outside_rows = []
    for w, fq in tok_cnt.most_common():
        if w not in hsk16_words:
            lvl = word2level.get(w, "")  # may be HSK7-9 or empty
            outside_rows.append((w, fq, lvl))
    with open(OUT_DIR / "hskk_dialog_words_outside_hskk.tsv", "w",
              encoding="utf-8", newline="") as f:
        f.write("word\tfreq\thsk_level_if_any\n")
        for w, fq, lvl in outside_rows:
            f.write(f"{w}\t{fq}\t{lvl}\n")
    n_outside = len(outside_rows)
    n_total   = len(tok_cnt)
    n_outside_tokens = sum(fq for _,fq,_ in outside_rows)
    n_total_tokens   = sum(tok_cnt.values())
    print(f"      {n_outside}/{n_total} unique tokens outside HSKK "
          f"({n_outside/n_total*100:.1f}% of types, "
          f"{n_outside_tokens/n_total_tokens*100:.1f}% of tokens)")

    # ------------------------------------------------------------------
    # Bonus: dialog hanzi outside the 209 set
    # ------------------------------------------------------------------
    extra_hanzi = []
    set209 = set(chars209)
    for ch, fq in han_cnt.most_common():
        if ch not in set209:
            extra_hanzi.append((ch, fq, char2level.get(ch, "")))
    with open(OUT_DIR / "hskk_dialog_hanzi_outside_209.tsv", "w",
              encoding="utf-8", newline="") as f:
        f.write("char\tfreq\thsk_level\n")
        for ch, fq, lvl in extra_hanzi:
            f.write(f"{ch}\t{fq}\t{lvl}\n")
    print(f"      dialog uses {len(extra_hanzi)} hanzi NOT in 209-set "
          f"({sum(fq for _,fq,_ in extra_hanzi)} occurrences)")

    # ------------------------------------------------------------------
    # Summary TSV + JSON
    # ------------------------------------------------------------------
    print("\n[5/5] Writing summary…")
    summary = {
        "method": (
            "HSKK has no published vocabulary syllabus; we use 新HSK 3.0 (2021) "
            "as the official proxy. HSKK 初级 = HSK1+2, 中级 = HSK3+4, "
            "高级 = HSK5+6 (per Hanban / 汉考国际 guidelines)."
        ),
        "talkverse_inputs": {
            "core_hanzi_count": len(chars209),
            "dialog_files": [p.name for p in md_files],
            "dialog_sentences": len(sentences),
            "dialog_unique_tokens": len(tok_cnt),
            "dialog_total_tokens":  sum(tok_cnt.values()),
            "dialog_unique_hanzi":  len(han_cnt),
        },
        "hskk_tier_sizes": {
            tier: {"words": len(hskk_word_sets[tier]),
                   "chars": len(hskk_char_sets[tier])}
            for tier in HSKK_TIERS
        },
        "hanzi_209_by_hsk_level": dict(hanzi_dist),
        "dialog_token_types_by_hsk_level":  dict(word_dist),
        "dialog_token_freq_by_hsk_level":   dict(word_token_dist),
        "coverage_by_hskk_tier": coverage,
        "dialog_outside_hskk": {
            "unique_tokens": n_outside,
            "unique_pct": round(n_outside/n_total*100, 2),
            "token_pct": round(n_outside_tokens/n_total_tokens*100, 2),
        },
        "dialog_hanzi_outside_209": {
            "unique_chars": len(extra_hanzi),
            "occurrences": sum(fq for _,fq,_ in extra_hanzi),
        },
    }
    with open(OUT_DIR / "hskk_summary.json", "w", encoding="utf-8") as f:
        json.dump(summary, f, ensure_ascii=False, indent=2)

    # Pretty TSV
    with open(OUT_DIR / "hskk_compare_summary.tsv", "w",
              encoding="utf-8", newline="") as f:
        f.write("tier\thsk_levels\tword_total\tword_covered\tword_cov_pct\t"
                "char_total\tchar_covered\tchar_cov_pct\n")
        for tier, info in coverage.items():
            f.write(f"{info['tier_label']}\t{'+'.join(info['hsk_levels_used'])}\t"
                    f"{info['tier_word_total']}\t{info['covered_words']}\t"
                    f"{info['word_cov_pct']}\t"
                    f"{info['tier_char_total']}\t{info['covered_chars']}\t"
                    f"{info['char_cov_pct']}\n")

    print(f"\n[done] outputs in {OUT_DIR}")
    for fn in [
        "hskk_compare_summary.tsv",
        "hskk_summary.json",
        "hskk_209hanzi_distribution.tsv",
        "hskk_dialog_word_distribution.tsv",
        "hskk_elementary_uncovered.tsv",
        "hskk_intermediate_uncovered.tsv",
        "hskk_advanced_uncovered.tsv",
        "hskk_dialog_words_outside_hskk.tsv",
        "hskk_dialog_hanzi_outside_209.tsv",
    ]:
        p = OUT_DIR / fn
        print(f"  - {p}  ({p.stat().st_size:,} bytes)")

if __name__ == "__main__":
    main()
