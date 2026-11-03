"""세션 리뷰 최종본(final/<id>.txt: 'n S: zh / pinyin / ko [/ note]')을 편 JSON 에 반영."""
import json,sys,glob,re,subprocess
R='/Users/talkverse/talkverse/zh'
for id_ in sys.argv[1:]:
    p=glob.glob(f'{R}/assets/data/dialogues/R1/*/{id_}.json')[0]
    e=json.load(open(p,encoding='utf-8'))
    lines=[l.strip() for l in open(f'data/review/final/{id_}.txt',encoding='utf-8') if l.strip()]
    turns=[]
    for l in lines:
        m=re.match(r'(\d+) ([AB]): (.*)',l); assert m,l
        parts=[x.strip() for x in m.group(3).split(' / ')]
        n=int(m.group(1)); old=e['turns'][n-1] if n-1<len(e['turns']) else {'tags':[]}
        t={'num':n,'speaker':m.group(2),'zh':parts[0],'pinyin':parts[1],'rd':'','ko':parts[2],
           'note':parts[3] if len(parts)>3 else old.get('note',''),'tags':old.get('tags',[])}
        turns.append(t)
    e['turns']=turns
    e['review']={'grok_rewrite':f'data/review/{id_}_grok_rewrite.md','model':'전문가','final':'세션 리뷰'}
    json.dump(e,open(p,'w',encoding='utf-8'),ensure_ascii=False,indent=1)
    subprocess.run(['dart','run','tool/fill_rd.dart',p],cwd=R,capture_output=True)
    print(id_,len(turns),'턴 반영')
