import json,glob,sys
R='/Users/talkverse/talkverse/zh'
for id_ in open(sys.argv[1]).read().split():
    e=json.load(open(glob.glob(f'{R}/assets/data/dialogues/R*/*/{id_}.json')[0]))
    reg={'casual':'반말(친구·연인)','polite':'존댓말'}.get(e.get('register'),e.get('register'))
    h=[f"=== {id_}",f"title: {e['title']}",f"scene: {e['scene']}",f"B: {e['speakers'].get('B','')}",f"register: {reg}"]
    for t in e['turns']:
        emo=t.get('emotion','')
        emo=t.get('emotion','')
        h.append(f"{t['num']} {t['speaker']} | 뜻: {t['ko']} | 문법: {t['note']} | 감정: {emo}")
    open(f'src/{id_}.txt','w').write('\n'.join(h)+'\n')
