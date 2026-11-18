#!/usr/bin/env python3
"""언어감각 과정(일본어앱 「언어감각 익히기」와 같은 꼴, 2026-11-18 사용자 지시 「지금 일본어 앱만큼」) — 원고 tools/sense/sense_course_src.json
→ 병음을 붙여 assets/data/grammar/sense_course.json. 원고(문장)는 이 세션이 새로 쓴 것.
  ~/.venvs/zh/bin/python tools/sense/build_sense_course.py
병음: 앱 HSK 단어장(경성까지 적힘) + EXTRA 로 가장 긴 낱말을 찾아 붙여 쓰고, 不·一 변조·경성 个 를 맞춘다(회화 원고와 같은 꼴). 고칠 것은 EXTRA·SINGLE 에.
문장 표시 {글자|번호} = 같은 번호끼리 중국어·한국어에서 같은 색."""
import json, re, sys
from pathlib import Path
import unicodedata
from pypinyin import pinyin as _py, Style

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / 'tools/sense/sense_course_src.json'
OUT = ROOT / 'assets/data/grammar/sense_course.json'
MARK = re.compile(r'\{([^|}]+)\|(\d+)\}')
PUNCT = {'，': ',', '。': '.', '？': '?', '！': '!', '…': '…', '“': '"', '”': '"', '、': ',', '：': ':'}
# 낱말 사전 = 앱의 HSK 단어장 병음(경성까지 적힘) + 아래 보탬(앞선다). 낱말은 붙여 쓰고 낱말 사이는 띄운다.
EXTRA = {'钥匙': 'yào shi', '重庆': 'Chóng qìng', '韩国': 'Hán guó', '北京': 'Běi jīng', '汉语': 'Hàn yǔ', '电影票': 'diàn yǐng piào', '游泳圈': 'yóu yǒng quān', '罐头': 'guàn tou',
         '奶茶': 'nǎi chá', '蛋糕': 'dàn gāo', '火锅': 'huǒ guō', '菜谱': 'cài pǔ', '魅力': 'mèi lì', '高铁': 'gāo tiě', '海边': 'hǎi biān', '座位': 'zuò wèi', '位子': 'wèi zi',
         '本子': 'běn zi', '笨蛋': 'bèn dàn', '身边': 'shēn biān', '钱包': 'qián bāo', '隔壁': 'gé bì', '门口': 'mén kǒu', '洗手间': 'xǐ shǒu jiān', '黑色': 'hēi sè', '红色': 'hóng sè',
         '路边': 'lù biān', '小猫': 'xiǎo māo', '网上': 'wǎng shang', '那儿': 'nàr', '这儿': 'zhèr', '哪儿': 'nǎr', '玩儿': 'wánr', '有点儿': 'yǒu diǎnr', '早点儿': 'zǎo diǎnr',
         '看看': 'kàn kan', '等等': 'děng deng', '慢慢': 'màn màn', '哈哈': 'hā hā', '原来': 'yuán lái', '拍照': 'pāi zhào', '饺子': 'jiǎo zi', '照片': 'zhào piàn',
         '秘密': 'mì mì', '回去': 'huí qu', '回来': 'huí lai', '最里面': 'zuì lǐ mian', '下面': 'xià mian', '真的': 'zhēn de', '谁': 'shéi', '嗯': 'ńg', '月亮': 'yuè liang',
         '只有': 'zhǐ yǒu', '只是': 'zhǐ shì', '打开': 'dǎ kāi', '多少': 'duō shao', '学生': 'xué sheng', '先生': 'xiān sheng',
         '一个': 'yī | ge', '这个': 'zhè | ge', '那个': 'nà | ge', '几个': 'jǐ | ge', '是不是': 'shì | bu | shì', '打电话': 'dǎ | diàn huà', '擦一擦': 'cā | yi | cā',
         '最里面': 'zuì | lǐ mian', '一遍': 'yī | biàn', '对不起': 'duì bu qǐ', '关上': 'guān | shang', '多少钱': 'duō shao | qián', '知道': 'zhī dao', '电影票': 'diàn yǐng | piào',
         '游泳圈': 'yóu yǒng | quān', '手里': 'shǒu | li', '二十': 'èr shí', '每天': 'měi tiān', '每次': 'měi cì', '聊天': 'liáo tiān', '有空': 'yǒu | kòng', '周六': 'zhōu liù',
         '发音': 'fā yīn', '在家': 'zài | jiā', '完了': 'wán | le',
         '面包': 'miàn bāo', '米饭': 'mǐ fàn', '苹果': 'píng guǒ', '自行车': 'zì xíng chē', '批评': 'pī píng', '妹妹': 'mèi mei', '妈妈': 'mā ma', '衣服': 'yī fu', '喜欢': 'xǐ huan'}
SINGLE = {'谁': 'shéi', '嗯': 'ńg', '个': 'ge', '了': 'le', '的': 'de', '得': 'de', '地': 'de', '过': 'guo', '吗': 'ma', '呢': 'ne', '吧': 'ba', '啊': 'a', '着': 'zhe', '上': 'shang', '里': 'li', '们': 'men'}
SINGLE_HEAD = {'上', '里'}   # 문장 첫머리면 사전 성조


def _dict():
    d = json.load(open(ROOT / 'assets/data/vocab/hsk_words.json', encoding='utf-8'))
    w = {x['zh']: x['rd'] for th in d['themes'] for s in th['sections'] for x in s['words'] if len(x['zh']) > 1}
    w.update(EXTRA)
    return w


WORDS = _dict()


def tone(s):
    for c in unicodedata.normalize('NFD', s):
        if c in '\u0304\u0301\u030c\u0300':
            return '\u0304\u0301\u030c\u0300'.index(c) + 1
    return 0


def retone(s, t):
    """음절의 성조 표시를 t(1~4, 0 = 경성)로."""
    base = ''.join(c for c in unicodedata.normalize('NFD', s) if c not in '\u0304\u0301\u030c\u0300')
    if t == 0: return unicodedata.normalize('NFC', base)
    m = '\u0304\u0301\u030c\u0300'[t - 1]
    for v in ('a', 'e', 'ou', 'o'):
        i = base.lower().find(v)
        if i >= 0: return unicodedata.normalize('NFC', base[:i + 1] + m + base[i + 1:])
    i = max(base.lower().rfind(v) for v in 'iuüv')
    return unicodedata.normalize('NFC', base[:i + 1] + m + base[i + 1:])


MIDDLE_BU = re.compile(r'(听不懂|看不清|找不到|吃不完|去不去|好不好|是不是|看不见)')


def pinyin(zh):
    plain = MARK.sub(lambda m: m.group(1), zh)
    toks = []   # [(글자들, [음절…])] / 문장부호
    i = 0
    while i < len(plain):
        c = plain[i]
        if c in PUNCT:
            toks.append((c, None)); i += 1; continue
        for n in (4, 3, 2):
            w = plain[i:i + n]
            if len(w) == n and w in WORDS:
                toks.append((w, WORDS[w].split())); i += n; break
        else:
            if c in SINGLE and not (c in SINGLE_HEAD and (not toks or toks[-1][1] is None)):
                s = SINGLE[c]
            elif c == '只':
                s = 'zhī'
            else:
                s = _py(c, style=Style.TONE)[0][0]
            toks.append((c, [s])); i += 1
    # 个 는 경성(个子·个人 낱말 제외), 不·一 변조. 「|」 = 한 사전 항목 안의 낱말 경계(띄어 씀)
    flat = [(ti, k) for ti, (w, ss) in enumerate(toks) if ss for k in range(len(ss)) if ss[k] != '|']
    chars = ''.join(w for w, ss in toks if ss)
    mid = {m.start() + 1 for m in MIDDLE_BU.finditer(chars)}
    for pos, (ti, k) in enumerate(flat):
        w, ss = toks[ti]
        ch = w[sum(1 for x in ss[:k] if x != '|')]
        nxt = toks[flat[pos + 1][0]][1][flat[pos + 1][1]] if pos + 1 < len(flat) else None
        if ch == '个' and w not in ('个子', '个人'): ss[k] = 'ge'
        elif ch == '不':
            ss[k] = 'bu' if (pos in mid or w in ('对不起', '是不是')) else ('bú' if nxt and tone(nxt) == 4 else 'bù')
        elif ch == '一' and w not in ('第一', '一一', '擦一擦'):
            if nxt is None: ss[k] = 'yī'
            elif nxt == 'ge' or tone(nxt) == 4: ss[k] = 'yí'
            else: ss[k] = 'yì'
    out, cap = '', True
    for w, ss in toks:
        if ss is None:
            p = PUNCT[w]
            if p == '"':
                out += (' "' if not out.endswith(' ') and out and (out.count('"') % 2 == 0) else '"')
            else:
                out += p
            if w in '。？！': cap = True
            continue
        s = ''.join(ss).replace('|', ' ')
        if cap: s = s[:1].upper() + s[1:]; cap = False
        if out and not out.endswith((' ', '"')) or (out.endswith('"') and out.count('"') % 2 == 0):
            out += ' '
        out += s
    out = re.sub(r'([,.?!:…])(?=[^\s,.?!:…"])', r'\1 ', out)
    return re.sub(r'\s+', ' ', out).strip()


def check_marks(s):
    a = {m.group(2) for m in MARK.finditer(s['zh'])}; b = {m.group(2) for m in MARK.finditer(s['ko'])}
    if a != b: print('번호 어긋남', a ^ b, s['zh'], s['ko'], file=sys.stderr)


def main():
    d = json.load(open(SRC, encoding='utf-8'))
    n = 0
    for lv in d['levels']:
        for ls in lv['lessons']:
            ss = ls.get('sentences', []) + [s for p in ls.get('points', []) for s in p['sentences']]
            for s in ss:
                s['pinyin'] = pinyin(s['zh']); n += 1
                if ls['kind'] == 'memorize': check_marks(s)
    d['_meta'] = '언어감각 과정 — tools/sense/build_sense_course.py 가 만든다(원고는 tools/sense/sense_course_src.json)'
    OUT.write_text(json.dumps(d, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')
    print('문장', n, '→', OUT.relative_to(ROOT))
    if '-v' in sys.argv:
        for lv in d['levels']:
            for ls in lv['lessons']:
                for s in ls.get('sentences', []) + [s for p in ls.get('points', []) for s in p['sentences']]:
                    print(MARK.sub(lambda m: m.group(1), s['zh']), '|', s['pinyin'])


if __name__ == '__main__':
    main()
